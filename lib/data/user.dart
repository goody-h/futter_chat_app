import './message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import './userdatabase.dart';

class User {
  User.fromMap(Map<String, dynamic> userMap)
      : this(
          username: userMap["username"],
          uid: userMap["uid"],
          bio: userMap["bio"],
          picUrl: userMap["picUrl"],
        );
  User({this.username, this.uid, this.bio, this.picUrl});
  String username;
  String uid;
  String bio;
  String picUrl;

  String resolveRoomId (String otherId) {
    if (uid == otherId) {
      return null;
    } else if (isGroup()) {
      return uid;
    }
    return uid.compareTo(otherId) == -1 ? "$uid-&&-$otherId" : "$otherId-&&-$uid";  
  }

  bool isGroup() {
    return uid.endsWith("-group");
  }

  @override
  String toString() {
    return "username: $username\n" +
      "uid: $uid\n" +
      "bio: $bio\n" +
      "picUrl: $picUrl\n";
  }
}

class Friend extends User {
  Friend.fromMap(Map<String, dynamic> userMap)
      : messageCount = userMap["message_count"] ?? 0,
        lastStatusTime = userMap["last_status_time"] ?? 0,
        lastMessage = TextMessage.getMessageFromString(userMap["last_message"]),
        composition = (userMap["composition"] as String).split(","),
        super.fromMap(userMap);

  int messageCount;
  TextMessage lastMessage;
  int lastStatusTime;
  List<String> composition;
}

class ThisUser extends User {
  ThisUser(
    String uid,
    Map<String, dynamic> userData,
    Map<String, dynamic> appData,
    Map<String, dynamic> localData,
    Map<String, dynamic> friendsConfig,
  )   : lastStatusFetch = appData["lastStatusFetch"] ?? Timestamp.now().millisecondsSinceEpoch,
        lastMessageFetch = appData["lastMessageFetch"] ?? Timestamp.now().millisecondsSinceEpoch,
        lastUserFetch = localData["lastUserFetch"] ?? 0,
        unSeenRequests = localData["unSeenRequests"] ?? [],
        friendsConfig = friendsConfig.map((key, value) => MapEntry(
              key,
              FriendConfig(key, value["mode"]),
            )),
        super.fromMap(userData..addEntries([MapEntry("uid", uid)]));

  // app cloud data
  int lastStatusFetch;
  int lastMessageFetch;

  // app data only
  final int lastUserFetch;
  final List<String> unSeenRequests;

  // friends config
  final Map<String, FriendConfig> friendsConfig;

  @override
  String toString() {
    return super.toString() +
      "\nlastStatusFetch: $lastStatusFetch\n" +
      "lastMessageFetch: $lastMessageFetch\n" +
      "lastUserFetch: $lastUserFetch\n" + 
      "friendsConfig: \n${json.encode(friendsConfig.map((k,v)=>MapEntry(k, v.toString())))}"; 
  }

  static Future<ThisUser> getUserFromSnapshot(
      String uid, QuerySnapshot snapshot) async {
    final maps = snapshot.documentChanges
        .map((change) => change.document)
        .map((doc) => MapEntry(doc.documentID, json.encode(doc.data)))
        .toList();
    maps.add(MapEntry("uid", uid));

    await UserDataBase.instance.setThisUser(Map.fromEntries(maps));

    return await getUserFromDatabase();
  }

  static Future<ThisUser> getUserFromDatabase() async {
    final userMap = await UserDataBase.instance.getThisUser();

    if (userMap != null) {
      final uid = userMap["uid"];
      final userData = json.decode(userMap["userData"]);
      final appData = json.decode(userMap["appData"] ?? "{}");
      final localData = json.decode(userMap["localData"] ?? "{}");
      final friendsConfig = json.decode(userMap["friendsConfig"] ?? "{}");

      return ThisUser(uid, userData, appData, localData, friendsConfig);
    }
    return null;
  }

  static String get thisUserSQLScheme {
    return "uid TEXT NOT NULL UNIQUE," +
        " userData TEXT NOT NULL, friendsConfig TEXT," +
        " appData TEXT, localData TEXT";
  }
}

class FriendConfig {
  FriendConfig(this.uid, this.mode);
  String uid;
  String mode;
  @override
    String toString() {
      return "[uid: $uid, mode: $mode]";
    }
}
