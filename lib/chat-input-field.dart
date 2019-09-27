import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  ChatInput({Key key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return ChatInputState();
  }
}

class ChatInputState extends State<ChatInput> {
  TextField input;
  Widget _getButtonItem(
      {IconData icon, double rotate = 0, VoidCallback onPressed}) {
    return Container(
      height: 38,
      width: 38,
      child: FloatingActionButton(
        elevation: 0,
        backgroundColor: Colors.transparent,
        onPressed: onPressed,
        child: Transform.rotate(
          angle: rotate,
          child: Icon(
            icon,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  FocusNode getFocusNode() {
    return input.focusNode;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Container(
            margin: EdgeInsets.all(2),
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _getButtonItem(
                  icon: Icons.insert_emoticon,
                  onPressed: () {},
                ),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 200,
                    ),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: input = TextField(
                        maxLines: null,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.fromLTRB(3, 9, 3, 9),
                          hintText: "Type a Message",
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _getButtonItem(
                  icon: Icons.attachment,
                  rotate: 45,
                  onPressed: () {},
                ),
                _getButtonItem(
                  icon: Icons.camera_alt,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 48,
          width: 48,
          margin: EdgeInsets.all(2),
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor: Colors.red,
            onPressed: () {},
            child: Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
