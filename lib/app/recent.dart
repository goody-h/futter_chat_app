import 'package:flutter/material.dart';
import '../data/user-controller.dart';
import '../data/user-manager.dart';
import '../screens/view-utils.dart';
import '../data/message.dart';
import 'package:intl/intl.dart';
import '../data/message-manager.dart';

class Recent extends StatelessWidget {
  final controller = UserController.recentMessages();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("chat"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text("users"),
            FutureBuilder<List<User>>(
              future: UserManager.instance.getAllUsers(),
              builder: (context, snap) {
                if (snap.hasData) {
                  final users = snap.data;

                  print("get ${users.length}");
                  return StreamBuilder<ThisUser>(
                    stream: UserManager.instance.thisUserStream,
                    builder: (context, snap) {
                      print(snap.hasData);
                      if (snap.hasData) {
                        final thisU = snap.data;

                        print("this userstream");
                        return Column(
                          children: users.map((user) {
                            final state = thisU.friendsConfig[user.uid]?.mode ??
                                "not-friends";
                            var action = "Add friend";

                            switch (state) {
                              case "not-friends":
                                action = "Add friend";
                                break;
                              case "friends":
                                action = "Unfriend";
                                break;
                              case "received-request":
                                action = "Accept";
                                break;
                              case "sent-request":
                                action = "Cancel";
                                break;
                            }

                            return Row(
                              children: <Widget>[
                                Text(user.username),
                                FlatButton(
                                  child: Text(action),
                                  onPressed: () {
                                    switch (state) {
                                      case "not-friends":
                                        MessageManager.instance
                                            .sendRequest(user);
                                        break;
                                      case "friends":
                                        break;
                                      case "received-request":
                                        MessageManager.instance
                                            .acceptRequest(user);
                                        break;
                                      case "sent-request":
                                        MessageManager.instance
                                            .cancelRequest(user);
                                        break;
                                    }
                                  },
                                ),
                              ],
                            );
                          }).toList(),
                        );
                      }
                      return Container();
                    },
                  );
                }
                return Container();
              },
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Text("messages"),
            ),
            StreamBuilder<List<Friend>>(
              stream: controller.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final friends = snapshot.data;
                  return Column(
                    children: friends.map((friend) => _RecentItem(user: friend,)).toList(),
                  );
                }
                return Container(
                  child: Center(
                    child: Text("No recent messages"),
                  ),
                );
              },
            )
          ],
        ),
      ),
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
      onTap: () {
        // open chatting route
        Navigator.of(context).pushNamed("/chatRoom", arguments: user);
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
