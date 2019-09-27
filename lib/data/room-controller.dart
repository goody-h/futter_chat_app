import 'dart:async';
import './message-manager.dart';
import './user-manager.dart';
export './user.dart';

class RoomData {
  Map<String, TextMessage> _messages = {};
  Friend user;
  List<TextMessage> get messages => _messages.values.toList()
    ..sort((first, second) => second.timeStamp.compareTo(first.timeStamp));
  updateMessageStatus() {
    if (_messages.isNotEmpty && user.messageCount > 0) {
      for (var i = 0; i < user.messageCount; i++) {
        final message = messages[i];
        MessageManager.instance
            .setMessageStatus(message.messageId, message.roomId, "seen");
      }
      user.messageCount = 0;
      UserManager.instance.clearUnread(user.uid);
    }
  }
}

class RoomManager with UserListener {
  RoomManager.fromUser(User user)
      : roomId =
            (user).resolveRoomId(UserManager.instance.thisUser.uid),
        userId = (user).uid {
    mListener = MessageListener(
      listenTag: roomId,
      minSize: user is Friend? user.messageCount : 0,
      onNewMessage: onNewMessages,
    );

    MessageManager.instance.setListener(mListener);
    UserManager.instance.setListener(this);

    if (user is Friend) {
      data.user = user;
      _controller.sink.add(data);
    }
  }

  final String roomId;
  final String userId;

  @override
  String get listenTag => userId;

  final _controller = StreamController<RoomData>.broadcast();
  RoomData data = RoomData();
  MessageListener mListener;

  Stream<RoomData> get stream => _controller.stream.asBroadcastStream();

  loadPreviousMessages() {
    MessageManager.instance.loadMessagesBefore(getLastMessage().timeStamp);
  }

  Future<void> sendMessage(String message) async {
    final user = (await stream.lastWhere((data) => data.user != null)).user;

    MessageManager.instance.sendMessage(user: user, message: message);
  }

  deleteMessages(List<TextMessage> messages, bool forEveryOne) {
    String thisUID = UserManager.instance.thisUser.uid;

    for (var message in messages.where((m) => m.roomId == roomId)) {
      if (!forEveryOne) {
        data._messages.remove(message.messageId);
      } else {
        if (message.userId == thisUID) {
          final update = TextMessage.fromMap(message.toMap()
            ..update("text", (_) => "")
            ..update("state", (state) => state + "deleted"));

          data._messages[message.messageId] = update;
        }
      }
    }
    _controller.sink.add(data);
    MessageManager.instance
        .deleteMessages(roomId, messages, forEveryOne: forEveryOne);
  }

  TextMessage getLastMessage() => data.messages.last;

  void onNewMessages(List<TextMessage> messages,
      {bool isUpdate = false, bool isPrevious = false}) {
    if (isUpdate) {
      for (var message in messages) {
        if (data._messages.containsKey(message.messageId)) {
          data.messages[message.messageId] = message;
        }
      }
    } else {
      data._messages.addEntries(
          messages.map((message) => MapEntry(message.messageId, message)));

      if (isPrevious) {
        // do some updates
      }
    }

    _controller.sink.add(data);
  }

  @override
  void onUserChange(List<Friend> user) {
    if (user != null && user.isNotEmpty) {
      data.user = user[0];
    }
    _controller.sink.add(data);
  }

  dispose() {
    _controller.close();
  }
}
