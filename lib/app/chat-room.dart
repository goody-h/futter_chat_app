import 'package:flutter/material.dart';
import '../base-auth.dart';
import '../data/room-controller.dart';
import './home.dart';

class ChatRoomRoute extends StatelessWidget {
  ChatRoomRoute({Key key, this.user}) : super(key: key);
  final User user;
  @override
  Widget build(BuildContext context) {
    return AuthRoute(
      authChild: () => ChatRoom(
        user: user,
      ),
    );
  }
}

class TextHolder {
  String text = "";
}

class ChatRoom extends StatelessWidget {
  ChatRoom({Key key, User user})
      : manager = RoomManager.fromUser(user),
        super(key: key);
  final RoomManager manager;
  final holder = TextHolder();

  void setText(String text) {
    holder.text = text;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RoomData>(
      stream: manager.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data;
          Scaffold(
            appBar: AppBar(
              title: Text("Room: ${data.user.username}"),
            ),
            body: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: ListView(
                    reverse: true,
                    children: data.messages
                        .map(
                          (message) => Padding(
                            padding: EdgeInsets.all(10),
                            child: Text("${message.username}: ${message.text}"),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Input(
                      hint: "Type a message!",
                      onChange: setText,
                    ),
                    RaisedButton(
                      color: Colors.red,
                      child: Text("Send"),
                      onPressed: () {
                        manager.sendMessage(holder.text);
                      },
                    )
                  ],
                )
              ],
            ),
          );
        }
        return Text("no message");
      },
    );
  }
}
