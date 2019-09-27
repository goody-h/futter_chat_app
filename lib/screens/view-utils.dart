import 'package:flutter/material.dart';

class ProfileRound extends StatelessWidget {
  ProfileRound(
      {Key key,
      this.size = 60,
      this.src,
      this.onClick,
      this.shouldClick = true})
      : super(key: key);
      
  final double size;
  final String src;
  final VoidCallback onClick;
  final bool shouldClick;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: shouldClick ? (onClick != null ? onClick : () {}) : null,
      child: ClipOval(
        child: Image.asset(
          "assets/images/profile_pic.jpg",
          height: size,
          width: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
