import 'package:flutter/material.dart';
import './controllers/status-progress-controller.dart';

class ProgressPainter extends CustomPainter {
  ProgressPainter({this.statusCount = 0, this.viewCount = 0, this.seekValue});

  final mSpace = 10.0;
  final int statusCount;
  final int viewCount;
  final double seekValue;

  static Paint getPaint(Color color) => Paint()
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..color = color;

  final mActivePaint = getPaint(Colors.white);
  final mInactivePaint = getPaint(Colors.grey);

  @override
  void paint(Canvas canvas, Size size) {
    final mWidth = size.width;
    final mHeight = size.height;
    var space = mSpace / ((statusCount ~/ 10.0) + 1);
    if (statusCount < 2) {
      space = 0.0;
    }

    final length = statusCount > 0
        ? (mWidth - (statusCount - 1) * space) / statusCount
        : 0;

    mActivePaint.strokeWidth = mHeight;
    mInactivePaint.strokeWidth = mHeight;

    // draw progress

    for (var i = 0; i < statusCount - 1; i++) {
      final startX = (length + space) * i;
      final endX = startX + length;
      final mPaint = i < viewCount ? mActivePaint : mInactivePaint;

      canvas.drawLine(
          Offset(startX, mHeight / 2.0), Offset(endX, mHeight / 2.0), mPaint);

      if (i == viewCount && seekValue > 0) {
        final end = startX + length * seekValue;
        canvas.drawLine(Offset(startX, mHeight / 2.0),
            Offset(end, mHeight / 2.0), mActivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class StatusProgress extends StatefulWidget {
  StatusProgress({Key key, this.controller}) : super(key: key);

  final ProgressController controller;

  @override
  State<StatefulWidget> createState() {
    return StatusProgressState();
  }
}

class StatusProgressState extends State<StatusProgress> {
  @override
  void initState() {
    super.initState();
    widget.controller.addProgressListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5),
      child: CustomPaint(
        size: Size(double.infinity, 2),
        willChange: true,
        isComplex: true,
        painter: ProgressPainter(
          statusCount: widget.controller.getStatusCount(),
          viewCount: widget.controller.getViewCount(),
          seekValue: widget.controller.getSeekValue(),
        ),
      ),
    );
  }
}
