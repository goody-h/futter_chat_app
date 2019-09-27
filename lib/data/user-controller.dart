import './user-manager.dart';
import 'dart:async';
export './user.dart';

class UserController with UserListener {
  UserController({this.tag}) {
    UserManager.instance.setListener(this);
  }

  UserController.recentMessages(): this(tag: "recent-messages");

  UserController.recentStatus(): this(tag: "recent-status");

  final _controller = StreamController<List<Friend>>.broadcast();  

  Stream<List<Friend>> get stream => _controller.stream.asBroadcastStream();

  final String tag;

  @override
  String get listenTag => tag;

  void onUserChange(List<Friend> user) {
    _controller.sink.add(user);
  }

  dispose() {
    UserManager.instance.removeListener(tag: tag);
    _controller.close();
  }
}