import 'package:flutter/material.dart';
import 'view-utils.dart';
import '../data/user-controller.dart';
import '../data/message.dart';
import 'package:intl/intl.dart';
import '../data/user-manager.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<ChatPage> {
  UserController recentManager;

  @override
  void initState() {
    super.initState();
    recentManager = UserController.recentMessages();
  }

  @override
  void dispose() {
    super.dispose();
    recentManager.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Friend>>(
      stream: recentManager.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final recent = snapshot.data;
          return ListView.builder(
            itemCount: recent.length,
            itemBuilder: (context, position) {
              return _RecentItem(
                key: ValueKey(recent[position].uid),
                user: recent[position],
              );
            },
          );
        }
        return null;
      },
    );
  }
}

class _RecentItem extends StatelessWidget {
  _RecentItem({Key key, this.user}) : super(key: key);

  final Friend user;

  Icon _getIconForMessageState(String state) {
    IconData icon = Icons.done;
    Color color = Colors.grey;

    switch (state) {
      case "all-read":
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case "received":
        icon = Icons.done_all;
        break;
    }

    return Icon(
      icon,
      color: color,
      size: 15,
    );
  }

  Widget _buildMessage(Message message) {
    if (message is TextMessage) {
      return Row(
        children: <Widget>[
          message.userId == UserManager.instance.thisUser.uid
              ? Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: _getIconForMessageState(message.state),
                )
              : null,
          Text(
            message.text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final button = Container(
      height: 60,
      child: IconButton(
        icon: Icon(Icons.bubble_chart, color: Colors.blue),
        tooltip: 'View story',
        onPressed: () {
          // open status route
        },
      ),
    );

    final cont = InkWell(
      onTap: () => {
        // open chatting route
      },
      child: Padding(
        padding: EdgeInsets.only(top: 10, left: 10, right: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    ProfileRound(
                      src: user.picUrl,
                      onClick: () {
                        // open user profile dialog
                      },
                    ),
                    user.messageCount > 0
                        ? Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              padding: EdgeInsets.only(
                                  top: 3, bottom: 2, left: 4, right: 3),
                              decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                "${user.messageCount}",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          )
                        : null
                  ],
                ),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(user.username),
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: _buildMessage(user.lastMessage),
                        ),
                      ],
                    ),
                  ),
                ),
                Stack(
                  children: <Widget>[
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Text(
                        DateFormat("HH:mm").format(
                          DateTime.fromMillisecondsSinceEpoch(
                            user.lastMessage.timeStamp,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    button
                  ],
                )
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 9, left: 60),
              height: 1,
              color: Color.fromRGBO(0xe4, 0xe4, 0xf5, 1),
            )
          ],
        ),
      ),
    );

    return cont;
  }
}
