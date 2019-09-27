import 'package:flutter/material.dart';
import '../base-auth.dart';
import '../data/user-manager.dart';
import './recent.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuthRoute(
      authChild: () => Recent(),
      notAuthChild: () => Auth(),
    );
  }
}

class Auth extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AuthState();
  }
}

class AuthState extends State<Auth> {
  bool isLogin;

  @override
  void initState() {
    super.initState();
    isLogin = false;
  }

  void toggleAuthAction() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Auth"),
      ),
      body: isLogin
          ? Login(toggleAction: toggleAuthAction)
          : SignUp(toggleAction: toggleAuthAction),
    );
  }
}

typedef StringCallback = void Function(String);

class Input extends StatelessWidget {
  Input({Key key, this.hint, this.isPassword = false, this.onChange})
      : super(key: key);
  final String hint;
  final bool isPassword;
  final StringCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: TextField(
        onChanged: onChange,
        obscureText: isPassword,
        style: TextStyle(
          fontSize: 16,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(3, 9, 3, 9),
          hintText: hint,
          border: InputBorder.none,
          hintStyle: TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class Login extends StatelessWidget {
  Login({Key key, this.toggleAction}) : super(key: key);
  final VoidCallback toggleAction;
  final SignInInfo info = SignInInfo();

  void login() {
    AuthManager.instance.login(info);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Input(
          hint: "Email",
          onChange: (username) => info.email = username,
        ),
        Input(
          hint: "Password",
          isPassword: true,
          onChange: (pass) => info.password = pass,
        ),
        Padding(
          padding: EdgeInsets.all(20),
          child: RaisedButton(
            color: Colors.blueAccent,
            child: Text("Login"),
            onPressed: login,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(30),
          child: FlatButton(
            color: Colors.amber,
            onPressed: toggleAction,
            child: Text("Need an Account?"),
          ),
        )
      ],
    );
  }
}

class SignUp extends StatelessWidget {
  SignUp({Key key, this.toggleAction}) : super(key: key);
  final VoidCallback toggleAction;
  final SignUpInfo info = SignUpInfo();

  void signup() {
    AuthManager.instance.signup(info);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Input(
            hint: "Email",
            onChange: (email) => info.email = email,
          ),
          Input(
            hint: "Username",
            onChange: (username) => info.username = username,
          ),
          Input(
            hint: "bio",
            onChange: (bio) => info.bio = bio,
          ),
          Input(
            hint: "Password",
            isPassword: true,
            onChange: (pass) => info.password = pass,
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: RaisedButton(
              color: Colors.blueAccent,
              child: Text("Signup"),
              onPressed: signup,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(30),
            child: FlatButton(
              color: Colors.amber,
              onPressed: toggleAction,
              child: Text("Have an Account?"),
            ),
          )
        ],
      ),
    );
  }
}
