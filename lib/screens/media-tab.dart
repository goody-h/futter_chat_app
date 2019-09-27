import 'package:flutter/material.dart';
import 'home-scaler.dart';
import 'dart:math';

class MediaPage extends StatelessWidget {
  MediaPage({Key key, this.offset, this.offsetWidth, this.color, this.origin})
      : super(key: key);

  final double offset;
  final double offsetWidth;
  final Color color;
  final double origin;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(-offsetWidth, 0.0),
      child: Container(
        color: color,
        child: DownScale(
          factor: 0.5,
          origin: origin,
          child: Transform.translate(
            offset: Offset(offsetWidth, 0.0),
            child: Container(
              child: MediaRing(
                offset: offset,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MediaRing extends StatelessWidget {
  MediaRing({Key key, this.offset}) : super(key: key);

  final double offset;

  @override
  Widget build(BuildContext context) {
    final circle = Center(
      child: Container(
        width: 175.0,
        height: 175.0,
        decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: <Color>[
                Color.fromARGB(0xff, 0x11, 0x80, 0xff),
                Color.fromARGB(0xdc, 0x11, 0x80, 0xff),
                Color.fromARGB(0xa0, 0x11, 0x80, 0xff),
              ],
            ),
            shape: BoxShape.circle),
      ),
    );

    var factor = 180 * offset;
    if (offset == 0) {
      factor = 180;
    }

    final cam = pi * (180 - factor) / 180;
    final gal = pi * (300 - factor) / 180;
    final vid = pi * (420 - factor) / 180;

    return Stack(
      children: <Widget>[
        circle,
        Center(
          child: CircleBox(
            angle: cam,
            iconData: Icons.camera_alt,
            onTap: () => {},
          ),
        ),
        Center(
          child: CircleBox(
            angle: gal,
            iconData: Icons.photo_library,
            onTap: () => {},
          ),
        ),
        Center(
          child: CircleBox(
            angle: vid,
            iconData: Icons.videocam,
            onTap: () => {},
          ),
        ),
      ],
    );
  }
}

class CircleBox extends StatelessWidget {
  final GestureTapCallback onTap;
  final IconData iconData;
  final double angle;

  CircleBox({Key key, this.angle = 0, this.onTap, this.iconData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 225,
      height: 225,
      child: Transform.rotate(
        angle: angle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Transform.rotate(
              angle: -angle,
              child: CircleButton(
                iconData: iconData,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircleButton extends StatelessWidget {
  final GestureTapCallback onTap;
  final IconData iconData;

  CircleButton({Key key, this.onTap, this.iconData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double size = 50.0;

    return InkResponse(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData,
          color: Colors.white,
        ),
      ),
    );
  }
}
