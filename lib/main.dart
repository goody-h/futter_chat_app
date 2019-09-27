import 'package:flutter/material.dart';
import './app/home.dart';
import './app/chat-room.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
      onGenerateRoute: (settings) {
        if (settings.name == "/chatRoom") {
          return MaterialPageRoute(
            builder: (context) {
              return ChatRoomRoute(user: settings.arguments,);
            }
          );
        }
        return null;
      },
    );
  }
}
