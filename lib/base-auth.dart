import 'package:flutter/material.dart';
import 'dart:async';
import './data/user-manager.dart';
import './data/message-manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef WidgetCallback = Widget Function();

class AuthRoute extends StatelessWidget {
  AuthRoute({Key key, @required this.authChild, this.notAuthChild})
      : super(key: key);
  final WidgetCallback authChild;
  final WidgetCallback notAuthChild;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthManager.instance.authStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != AuthState.unknown) {
          if (snapshot.data == AuthState.notAuth) {
            if (notAuthChild != null) {
              return notAuthChild();
            } else {
              Navigator.popUntil(
                  context, (route) => ModalRoute.withName("/")(route));
              return null;
            }
          }
          return authChild();
        } else {
          // loading view
          return SplashLoader();
        }
      },
    );
  }
}

class SplashLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

enum AuthState { unknown, auth, notAuth }

class AuthManager {
  AuthManager._constructor() {
    _controller.sink.add(AuthState.unknown);

    checkInternalAuthState();

    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      if (user != null) {
        getThisUser(user);
      } else {
        setState(AuthState.notAuth);
      }
    });
  }

  checkInternalAuthState() async {
    if (await UserManager.instance.getThisUser() != null) {
      setState(AuthState.auth);
    } else {
      setState(AuthState.notAuth);
    }
  }

  setState(AuthState state) {
    _controller.sink.add(state);
    switch (state) {
      case AuthState.auth:
        // start app listeners
        MessageManager.instance.init();

        break;
      case AuthState.notAuth:
        UserManager.instance.removeThisUser();
        MessageManager.instance.clearAllData();

        // cancel and dispose app listeners
        // clear user data

        break;
      default:
        break;
    }
  }

  getThisUser(FirebaseUser user) async {
    await UserManager.instance.getThisUser(uid: user.uid);
    setState(AuthState.auth);
  }

  final _controller = StreamController<AuthState>.broadcast();

  Stream<AuthState> get authStream =>
      _controller.stream.asBroadcastStream();

  static AuthManager _instance;

  static AuthManager get instance {
    if (_instance == null) {
      _instance = AuthManager._constructor();
    }
    return _instance;
  }

  Future<String> login(SignInInfo info) async {
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: info.email,
        password: info.password,
      );
      return result.user != null? "success" : "failed";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> signup(SignUpInfo info) async {
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: info.email,
        password: info.password,
      );

      info.uid = result.user.uid;

      await UserManager.instance.createUser(info);

      print("success");

      return "success";
    
    } catch (e) {
      return e.toString();
    }
  }

  dispose() {
    _controller.close();
  }
}

class SignInInfo {
  String email;
  String password;
}