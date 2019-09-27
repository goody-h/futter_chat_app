import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import './user-manager.dart';
import './message-database.dart';
import './message.dart';
export './message.dart';

typedef NewMessageCallback = void Function(List<Message> messages,
    {bool isUpdate, bool isPrevious});
typedef VoidCallback = void Function(List<String>);

class MessageListener {
  MessageListener({
    this.listenTag,
    this.minSize = 0,
    this.onNewMessage,
  });
  final String listenTag;
  final int minSize;
  final NewMessageCallback onNewMessage;
}

class MessageManager {
  MessageManager._constructor();

  MessageListener listener;

  StreamSubscription firestoreMessageListener;

  init() {
    fetchFirestoreMessages();
  }

  fetchFirestoreMessages() {
    if (firestoreMessageListener == null) {
      firestoreMessageListener = Firestore.instance
          .collectionGroup("messages")
          .where("sentTo", arrayContains: UserManager.instance.thisUser.uid)
          .where(
            "lastUpdate",
            isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
                UserManager.instance.thisUser.lastMessageFetch),
          )
          .orderBy("lastUpdate", descending: true)
          .orderBy("timestamp", descending: true)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) => snapshot.documentChanges
              .map((change) => change.document)
              .where((doc) => !doc.metadata.isFromCache)
              .map((doc) => doc.data
                ..addEntries([MapEntry("messageId", doc.documentID)])
                ..update("timestamp", (stamp) {
                  return (stamp as Timestamp).millisecondsSinceEpoch;
                })))
          .listen((messages) async {

        await handleMessages(messages);
        if (messages.isNotEmpty) {
          final lastFetch = (messages.first["lastUpdate"] as Timestamp)
              .millisecondsSinceEpoch;
          UserManager.instance.setLastMessageFetchTime(lastFetch);

          for (var message in messages) {
            setMessageStatus(
                message["messageId"], message["roomId"], "received");
          }
        }
      });
    }
  }

  setMessageStatus(String messageId, String roomId, String status) {
    Firestore.instance
        .collection("chatRooms")
        .document(roomId)
        .collection("messages")
        .document(messageId)
        .collection("messageExtra")
        .document("status")
        .setData({UserManager.instance.thisUser.uid: status}, merge: true);
  }

  handleMessages(Iterable<Map<String, dynamic>> messages) async {
    final messageHandlers = MessageHandlerBuilder();

    print(messages.length);

    for (var message in messages) {
      message
        ..update("sentTo", (list) {
          return (list as List<dynamic>).fold<String>("", (fold, value) {
            return fold != "" ? fold + "," + value : value;
          });
        })
        ..remove("lastUpdate");

      messageHandlers[message["type"]]?.handleMessage(message);
    }

    await messageHandlers.processMessages();

    await messageHandlers.finishAll();

    messageHandlers.notify(listener);
  }

  setListener(MessageListener listener) {
    if (listener != null) {
      this.listener = listener;
      _notifyListener();
    }
  }

  _notifyListener() async {
    List<Message> messages = [];
    switch (listener.listenTag) {
      case "friend-request":
        messages = await FriendRequestHandler.getReceivedRequests();
        break;
      default:
        messages = await TextMessageHandler.getMessages(
          listener.listenTag,
          unreadCount: listener.minSize,
        );
    }
    listener.onNewMessage(messages);
  }

  loadMessagesBefore(int timestamp) async {
    final messages = await TextMessageHandler.getMessages(listener.listenTag,
        timeLimit: timestamp);
    listener.onNewMessage(messages, isPrevious: true);
  }

  makeFriendRequest(User user, String action) async {
    final thisUser = UserManager.instance.thisUser;
    final roomId = user.resolveRoomId(thisUser.uid);
    final messageRef = Firestore.instance
        .collection("chatRooms")
        .document(roomId)
        .collection("messages");

    final messagePayload = {
      "type": "friend-request",
      "sentTo": [user.uid, thisUser.uid],
      "userId": thisUser.uid,
      "username": thisUser.username,
      "roomId": roomId,
      "timestamp": FieldValue.serverTimestamp(),
      "lastUpdate": FieldValue.serverTimestamp(),
      "action": action,
    };

    await messageRef.document("${roomId}_${thisUser.uid}").setData(messagePayload);
  }

  sendRequest(User user) async {
    await makeFriendRequest(user, "request");
  }

  acceptRequest(User user) async {
    await makeFriendRequest(user, "accept");
  }

  declineRequest(User user) async {
    await makeFriendRequest(user, "decline");
  }

  cancelRequest(User user) async {
    await makeFriendRequest(user, "cancel");
  }

  sendMessage({Friend user, String message}) async {
    final thisUser = UserManager.instance.thisUser;
    final roomId = user.resolveRoomId(thisUser.uid);
    final messageRef = Firestore.instance
        .collection("chatRooms")
        .document(roomId)
        .collection("messages");

    final messageId = messageRef.add({"userId": thisUser.uid});

    final messagePayload = {
      "type": "text",
      "sentTo": user.composition
        ..remove(thisUser.uid)
        ..add(thisUser.uid),
      "userId": thisUser.uid,
      "username": thisUser.username,
      "roomId": roomId,
      "timestamp": FieldValue.serverTimestamp(),
      "lastUpdate": FieldValue.serverTimestamp(),
      "text": message,
      "state": "sent"
    };

    messageRef.document((await messageId).documentID).setData(messagePayload);

    final localPayload = {}
      ..addEntries(messagePayload.entries)
      ..addEntries([MapEntry("messageId", (await messageId).documentID)])
      ..update("state", (_) => "sending")
      ..update("timestamp", (_) => Timestamp.now().millisecondsSinceEpoch);

    handleMessages([localPayload]);
  }

  // this is a one way callback, the listener does not necessarily require a response
  deleteMessages(String roomId, List<TextMessage> messages,
      {bool forEveryOne = false}) async {
    String thisUID = UserManager.instance.thisUser.uid;

    for (var message in messages.where((m) => m.roomId == roomId)) {
      final messageRef = Firestore.instance
          .collection("chatRooms")
          .document(message.roomId)
          .collection("messages")
          .document(message.messageId);
      if (!forEveryOne) {
        MessageDatabase.instance.deleteMessage(message.messageId);
        if (message.state == "sending") {
          messageRef.delete();
          messageRef.collection("messageExtra").document("status").delete();
        }
      } else {
        if (message.userId == thisUID) {
          final map = message.toMap()
            ..remove("messageId")
            ..updateAll((key, value) {
              switch (key) {
                case "text":
                  return "";
                case "state":
                  return value + "deleted";
                case "timestamp":
                  return Timestamp.fromMillisecondsSinceEpoch(value);
                case "sentTo":
                  return (value as String).split(",");
                default:
                  return value;
              }
            })
            ..addEntries({"lastUpdate": FieldValue.serverTimestamp()}.entries);
          messageRef.setData(map, merge: true);
        }
      }
    }

    if (!forEveryOne) {
      TextMessageHandler.setLastUserMessage(roomId, shouldIncrease: false);
    } else {
      final localUpdate = messages.map((m) => m.toMap()
        ..updateAll((key, value) {
          switch (key) {
            case "text":
              return "";
            case "state":
              return value + "deleted";
            case "sentTo":
              return (value as String).split(",");
            default:
              return value;
          }
        }));
      handleMessages(localUpdate);
    }
  }

  removeListener({String roomId}) {
    if (listener != null && (roomId == null || roomId == listener.listenTag)) {
      listener = null;
    }
  }

  clearAllData() async {
    firestoreMessageListener?.cancel();
    firestoreMessageListener = null;

    await MessageDatabase.instance.clearDatabase();
  }

  static MessageManager _instance;

  static MessageManager get instance {
    if (_instance == null) {
      _instance = MessageManager._constructor();
    }

    return _instance;
  }
}

class MessageHandlerBuilder {
  final Map<String, MessageHandler> handlers = {};

  List<MessageHandler> get values => handlers.values.toList();

  MessageHandler operator [](String handler) {
    return handlers[handler] ?? buildHandler(handler);
  }

  processMessages() async {
    for (var handler in values) {
      await handler.processMessages();
    }
  }

  finishAll() async {
    for (var handler in values) {
      await handler.finish();
    }
  }

  notify(MessageListener listener) {
    for (var handler in values) {
      handler.notifyListener(listener);
    }
  }

  MessageHandler buildHandler(String handler) {
    switch (handler) {
      case "friend-request":
        handlers.addEntries([MapEntry(handler, FriendRequestHandler())]);
        break;
      case "text":
        handlers.addEntries([MapEntry(handler, TextMessageHandler())]);
        break;
    }
    return handlers[handler];
  }
}

abstract class MessageHandler {
  notifyListener(MessageListener listener);
  handleMessage(Map<String, dynamic> message);
  processMessages();
  finish() {}
}

class FriendRequestHandler extends MessageHandler {
  List<FriendRequest> requests = [];

  @override
  handleMessage(Map<String, dynamic> request) {
    final fRequest = FriendRequest.fromMap(request);

    //requests are processed from oldest to latest
    requests.insert(0, fRequest);
  }

  @override
  processMessages() async {
    final thisUserUpdate = {
      "addRequest": <String>[],
      "removeRequest": <String>[],
    };

    for (var request in requests) {
      switch (request.action) {
        case "request":
          await MessageDatabase.instance.addRequest(request.toMap());
          if (request.userId != UserManager.instance.thisUser.uid) {
            thisUserUpdate["addRequest"].add(request.messageId);
          }
          break;
        case "decline":
        case "accept":
        case "cancel":
          await MessageDatabase.instance.removeRequest(request.roomId);
          if (request.userId != UserManager.instance.thisUser.uid) {
            thisUserUpdate["removeRequest"].add(request.messageId);
          }
          break;
      }
    }

    if (thisUserUpdate["addRequest"].isNotEmpty) {
      UserManager.instance.addUnseenRequest(thisUserUpdate["addRequest"]);
    }
    if (thisUserUpdate["removeRequest"].isNotEmpty) {
      UserManager.instance
          .removeUnseenRequests(thisUserUpdate["removeRequest"]);
    }
  }

  @override
  notifyListener(MessageListener listener) {
    if (listener != null && listener.listenTag == 'friend-request') {
      listener.onNewMessage(requests);
    } else {
      // send message to notification manager
    }
  }

  static Future<List<FriendRequest>> getReceivedRequests() async {
    return (await MessageDatabase.instance
            .getRequests(UserManager.instance.thisUser.uid))
        .map((value) => FriendRequest.fromMap(value)).toList();
  }
}

class TextMessageHandler extends MessageHandler {
  Map<String, List<TextMessage>> newMessages = {};
  Map<String, List<TextMessage>> oldMessages = {};

  @override
  handleMessage(Map<String, dynamic> message) {
    final tMessage = TextMessage.fromMap(message);
    final holder =
        tMessage.timeStamp > UserManager.instance.thisUser.lastMessageFetch
            ? newMessages
            : oldMessages;

    if (holder.containsKey(tMessage.roomId)) {
      holder[tMessage.roomId].add(tMessage);
    } else {
      holder.addEntries([
        MapEntry(tMessage.roomId, [tMessage])
      ]);
    }
  }

  @override
  processMessages() async {
    for (var message in newMessages.values.reduce((value, element) {
      return value..addAll(element);
    })) {
      await MessageDatabase.instance.addMessage(message.toMap());
    }

    for (var message in oldMessages.values.reduce((value, element) {
      return value..addAll(element);
    })) {
      int updateCount =
          await MessageDatabase.instance.updateMessage(message.toMap());
      if (updateCount == 0) {
        oldMessages[message.roomId].remove(message);
      }
    }
  }

  @override
  notifyListener(MessageListener listener) {
    if (listener != null) {
      if (newMessages.containsKey(listener.listenTag)) {
        listener.onNewMessage(newMessages[listener.listenTag]);
      }
      if (oldMessages.containsKey(listener.listenTag)) {
        listener.onNewMessage(oldMessages[listener.listenTag], isUpdate: true);
      }
    }

    getUpdateduserIds().remove(listener?.listenTag ?? "");

    // get unread message count for roomids not equal to listener id
    // get unread messages for roomids not equal to listener id
    // send messages to notification manager
  }

  List<String> getUpdateduserIds() {
    final thisUID = UserManager.instance.thisUser.uid;
    var messages = <String>[]
      ..addAll(newMessages.values.map((l) => l[0].resolveUID(thisUID)))
      ..addAll(oldMessages.values.map((l) => l[0].resolveUID(thisUID)));

    return messages.fold<List<String>>([], (value, element) {
      return value.contains(element) ? value : value
        ..add(element);
    });
  }


  List<String> getUpdatedRoomIds() {
    var messages = <String>[]
      ..addAll(newMessages.keys)
      ..addAll(oldMessages.keys);

    return messages.fold<List<String>>([], (value, element) {
      return value.contains(element) ? value : value
        ..add(element);
    });
  }

  @override
  finish() async {
    for (var roomId in getUpdatedRoomIds()) {
      await setLastUserMessage(roomId, unreadCount: newMessages[roomId].length);
    }
  }

  static setLastUserMessage(String roomId,
      {int unreadCount = 1, bool shouldIncrease = true}) async {
    final map = await MessageDatabase.instance.getLastMessage(roomId);
    if (map != null) {
      final message = TextMessage.fromMap(map);
      UserManager.instance.setLastUserMessage(
          message: message,
          userId: message.resolveUID(UserManager.instance.thisUser.uid),
          unreadCount: unreadCount,
          increaseCount: shouldIncrease);
    }
  }

  static Future<List<TextMessage>> getMessages(
    String roomId, {
    int timeLimit,
    int unreadCount = 0,
  }) async {
    return (await MessageDatabase.instance
            .getMessages(roomId, startAt: timeLimit, unreadCount: unreadCount))
        .map((value) => TextMessage.fromMap(value)).toList();
  }
}
