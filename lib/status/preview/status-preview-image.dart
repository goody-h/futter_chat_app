import 'package:flutter/material.dart';
import 'dart:math';

class StatusImage extends StatelessWidget {
  final double size = 60;
  static const double stroke = 2;
  final double margin = stroke + 8;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      child: Stack(
      children: <Widget>[
        CustomPaint(
          size: Size.square(size),
          painter: RingPainter(
            strokeWidth: stroke,
            statusCount: 10,
            viewCount: 3,
          ),
        ),
        Center(
          child: ClipOval(
            child: Image.asset(
              "assets/images/profile_pic.jpg",
              height: size - margin,
              width: size - margin,
              fit: BoxFit.cover,
            ),
          ),
        )
      ],
    ),
    );
  }
}

class RingPainter extends CustomPainter {
  RingPainter(
      {this.strokeWidth = 0, this.statusCount = 0, this.viewCount = 0}) {
    mSpace = 10;
    activePaintBorder = getBorderPaint(Colors.blue);
    inactivePaintBorder = getBorderPaint(Colors.grey);
  }

  Paint getBorderPaint(Color color) => Paint()
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..color = color;

  Rect mRect;
  double strokeWidth;
  double mSpace;

  int statusCount;
  int viewCount;

  Paint activePaintBorder;
  Paint inactivePaintBorder;

  @override
  void paint(Canvas canvas, Size size) {
    mRect = Rect.fromPoints(Offset(strokeWidth / 2, strokeWidth / 2),
        Offset(size.width - strokeWidth / 2, size.height - strokeWidth / 2));

    // Draw Border
    double wS = mSpace / ((statusCount ~/ 10) + 1);
    if (statusCount < 2) {
      wS = 0;
    }

    double sw = (360.0 / statusCount) - wS;

    for (int i = 0; i < statusCount; i++) {
      Path arc = new Path();
      arc.arcTo(mRect, degToRad(270 - wS / 2 - (wS + sw) * i), degToRad(-sw), true);

      if (i < viewCount)
        canvas.drawPath(arc, inactivePaintBorder);
      else
        canvas.drawPath(arc, activePaintBorder);
    }
  }

  double degToRad(double angleInDeg) => angleInDeg * pi / 180;

  @override
  bool shouldRepaint(RingPainter oldDelegate) {
    return statusCount != oldDelegate.statusCount ||
        viewCount != oldDelegate.viewCount;
  }
}
