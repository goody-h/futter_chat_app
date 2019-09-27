import 'dart:convert';

abstract class Message {
  Message.fromMap(String type, Map<String, dynamic> map)
      : this(
            type: type,
            userId: map["userId"],
            username: map["username"],
            roomId: map["roomId"],
            timeStamp: map["timestamp"],
            messageId: map["messageId"],
            sentTo: (map["sentTo"] as String).split(","));
  Message({
    this.type,
    this.messageId,
    this.userId,
    this.username,
    this.roomId,
    this.timeStamp,
    this.sentTo,
  });
  final messageId;
  final String type;
  final String userId;
  final String username;
  final String roomId;
  final int timeStamp;
  final List<String> sentTo;

  Map<String, dynamic> toMap() {
    return {
      "messageId": messageId,
      "type": type,
      "userId": userId,
      "username": username,
      "roomId": roomId,
      "timestamp": timeStamp,
      "sentTo": sentTo.fold<String>("", (fold, value) {
        return fold != "" ? fold + "," + value : value;
      }),
    };
  }
}

class TextMessage extends Message {
  TextMessage.fromMap(Map<String, dynamic> map)
      : text = map["text"],
        state = map["state"],
        super.fromMap("text", map);

  TextMessage({
    this.text,
    this.state,
    String messageId,
    String userId,
    String username,
    String roomId,
    int timeStamp,
  }) : super(
          type: "text",
          messageId: messageId,
          userId: userId,
          username: username,
          roomId: roomId,
          timeStamp: timeStamp,
        );
  final String text;
  final String state;

  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addEntries({
        "text": text,
        "state": state,
      }.entries);
  }

  String toJsonString() {
    return json.encode(toMap());
  }

  String resolveUID(String thisUserId) {
    return (roomId.split("-&&-")..remove(thisUserId)).elementAt(0);
  }

  static TextMessage getMessageFromString(String value) {
    return value != null && value != ""
        ? TextMessage.fromMap(json.decode(value))
        : null;
  }
}

class FriendRequest extends Message {
  FriendRequest.fromMap(Map<String, dynamic> map)
      : action = map["action"],
        super.fromMap("friend-request", map);
  FriendRequest({
    this.action,
    String userId,
    String username,
    String roomId,
    int timeStamp,
  }) : super(
          type: "friend-request",
          userId: userId,
          username: username,
          roomId: roomId,
          timeStamp: timeStamp,
        );

  final String action;

  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addEntries({
        "action": action,
      }.entries);
  }
}
