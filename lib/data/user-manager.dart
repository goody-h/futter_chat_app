import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import './message.dart';
import './user.dart';
import './userdatabase.dart';
export './user.dart';

abstract class UserListener {
  String get listenTag;
  void onUserChange(List<Friend> users);
}

class SignUpInfo {
  String uid;
  String username;
  String bio;
 
  String email;
  String password;


  Map<String, dynamic> toMap() {
    return {
      "username": username,
      "bio": bio,
      "picUrl": "default"
    };
  }
}


// user manager started by auth manager
class UserManager {
  UserListener listener;
  ThisUser thisUser;

  Stream<Future<ThisUser>> dataStream;

  StreamSubscription firestoreThisUserListener;
  StreamSubscription friendsInfoSubscription;

  final _controller = StreamController<ThisUser>.broadcast();

  UserManager._constructor();

  Stream<ThisUser> get thisUserStream {

    return _controller.stream;
  }

  Future<void> addUnseenRequest(List<String> requests) async {
    await UserDataBase.instance.updateThisUserLocalData(addRequests: requests);
    setThisUser(await _getUserFromDatabase());
  }

  Future<void> removeUnseenRequests(List<String> requests) async {
    await UserDataBase.instance
        .updateThisUserLocalData(removeRequests: requests);
    setThisUser(await _getUserFromDatabase());
  }

  Future<void> setLastUserFetch(int lastUserFetch) async {
    await UserDataBase.instance
        .updateThisUserLocalData(lastUserFetch: lastUserFetch);
    setThisUser(await _getUserFromDatabase());
  }

  Future<User> fetchUser(String uid) async {
    final snapshot =
        await Firestore.instance.collection("users").document(uid).get();
    return User.fromMap(snapshot.data);
  }

  // note: remove later
  Future<List<User>> getAllUsers() async {
    final snapshot =
        await Firestore.instance.collection("users").getDocuments();
    return snapshot.documents.map((doc) => User.fromMap(doc.data..addEntries({"uid": doc.documentID}.entries))).toList();
  }

  Future<String> getUserState(User user) async {
    return thisUser.friendsConfig[user.uid]?.mode ?? "not-friends";
  }

  Future<ThisUser> getThisUser({String uid}) async {
    final localUser = await _getUserFromDatabase();

    if (localUser != null && (uid == null || uid == localUser.uid)) {
      setThisUser(localUser);
      _listenToUserData(thisUser.uid);
      return thisUser;
    } else if (uid != null) {
      return await _listenToUserData(uid);
    }
    return null;
  }

  void removeThisUser() async {
    disposeData();
    await UserDataBase.instance.clearDatabase();
  }

  Future<ThisUser> _getUserFromDatabase() async {
    return await ThisUser.getUserFromDatabase();
  }

  Future<ThisUser> _listenToUserData(String uid) async {
    if (dataStream == null) {
      dataStream = Firestore.instance
          .collection("users")
          .document(uid)
          .collection("config")
          .snapshots()
          .map((snapshot) => ThisUser.getUserFromSnapshot(uid, snapshot));

      firestoreThisUserListener = dataStream.listen((snapshot) async {
        setThisUser(await snapshot);
      });
    }

    return setThisUser(
        await await dataStream.lastWhere((user) => user != null));
  }

  ThisUser setThisUser(ThisUser user) {
    thisUser = user;
    _controller.sink.add(thisUser);
    if (friendsInfoSubscription == null) {
      _listenToFriendsInfo();
    }
    return thisUser;
  }

  _listenToFriendsInfo() {
    friendsInfoSubscription = Firestore.instance
        .collectionGroup("data")
        .where("friends", arrayContains: thisUser.uid)
        .where(
          "lastUpdate",
          isGreaterThan:
              Timestamp.fromMillisecondsSinceEpoch(thisUser.lastUserFetch),
        )
        .orderBy("lastUpdate", descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          print("chages: ${snapshot.documentChanges.length}");
          return snapshot.documentChanges
            .map((change) => change.document)
            .where((doc) { 
              print("isCache: ${doc.metadata.isFromCache}");
              return !doc.metadata.isFromCache;})
            .map(
              (doc) => doc.data
                ..addEntries([MapEntry("uid", doc.documentID)])
                ..update("composition", (list) {
                  return (list as List<dynamic>).fold<String>("", (fold, value) {
                    return fold != "" ? fold + "," + value : value;
                  });
                })
                ..update("lastUpdate", (stamp) {
                  return (stamp as Timestamp).millisecondsSinceEpoch;
                }),
            ).toList();
            })


        .listen((users) async {
      
      
      await updateUsers(users);

      print("user update ${users.length}");

      if (users.isNotEmpty) {
        final lastFetch = users.first["lastUpdate"];
        UserDataBase.instance.updateThisUserLocalData(lastUserFetch: lastFetch);
      }
    });
  }

  updateUsers(List<Map<String, dynamic>> users) async {
    for (var user in users) {
      await UserDataBase.instance.updateUser(user);
      _notifyListener([user["uid"]]);
    }

    _notifyListener(["messages", "status"]);
  }

  getThisUserRef(String doc) => Firestore.instance
      .collection("users")
      .document(thisUser.uid)
      .collection("config")
      .document("appData");

  setLastMessageFetchTime(int time) {
    getThisUserRef("appData").updateData({"lastMessageFetch": time});
    thisUser.lastMessageFetch = time;
  }

  setLastStatusFetchTime(int time) {
    getThisUserRef("appData").updateData({"lastStatusFetch": time});
    thisUser.lastStatusFetch = time;
  }

  _notifyListener(List<String> tags) async {
    if (listener != null) {
      if (tags.contains("messages") &&
          listener.listenTag == "recent-messages") {
        final users = await UserDataBase.instance.getRecentlyMessagedUsers();
        print(users.length);
        listener.onUserChange(users.map((map) => Friend.fromMap(map)).toList());
      } else if (tags.contains("status") &&
          listener.listenTag == "recent-status") {
        final users = await UserDataBase.instance
            .getUsersWithCurrentStatus(DateTime.now().millisecondsSinceEpoch);
        listener.onUserChange(users.map((map) => Friend.fromMap(map)).toList());
      } else if (tags.contains(listener.listenTag)) {
        final userMap = await UserDataBase.instance.getUser(listener.listenTag);
        if (userMap != null) {
          listener.onUserChange([Friend.fromMap(userMap)]);
        }
      }
    }
  }

  setLastUserMessage({
    TextMessage message,
    String userId,
    int unreadCount = 1,
    bool increaseCount = true,
  }) async {
    await UserDataBase.instance.updateLastUserMessage(userId, message,
        count: unreadCount, increaseCount: increaseCount);

    _notifyListener(["messages"]);
  }

  clearUnread(String userId) async {
    await UserDataBase.instance.updateReadMessages(userId);

    _notifyListener(["messages"]);
  }

  setLastUserStatusTime({int timeStamp, String userId}) async {
    await UserDataBase.instance.updateLastUserStatus(userId, timeStamp);

    _notifyListener(["messages"]);
  }

  setListener(UserListener listener) {
    if (listener != null) {
      this.listener = listener;
      _notifyListener(["messages", "status", listener.listenTag]);
    }
  }

  removeListener({String tag}) {
    if (listener != null && (tag == null || tag == listener.listenTag)) {
      listener = null;
    }
  }

  createUser(SignUpInfo info) async {
    await Firestore.instance
          .collection("users")
          .document(info.uid)
          .collection("config")
          .document("userData").setData(info.toMap(), merge: true);
  }

  static UserManager _instance;

  static UserManager get instance {
    if (_instance == null) {
      _instance = UserManager._constructor();
    }

    if (_instance.thisUser != null) {
      _instance.test();
    }

    return _instance;
  }

  test() async {
    //print(thisUser.toString());
    
  }

  disposeData() {
    dispose();
    firestoreThisUserListener = null;
    friendsInfoSubscription = null;
    listener = null;
    thisUser = null;
  }

  dispose() {
    firestoreThisUserListener?.cancel();
    friendsInfoSubscription?.cancel();
    _controller.close();
  }
}
