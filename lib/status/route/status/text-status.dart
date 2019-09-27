import 'package:flutter/material.dart';
import '../controllers/controllers.dart';
import './status-info.dart';

class TextData extends StatusData {
  TextData() : super(id: "");
  String text;
  Color backColor;
}

class TextStatus extends StatefulWidget {
  TextStatus({this.data, this.statusController})
      : super(key: ValueKey(data.id));
  final TextData data;
  final StatusController statusController;

  @override
  State<StatefulWidget> createState() {
    return TextStatusState();
  }
}

class TextStatusState extends State<TextStatus> with OnProgressFinish {
  bool isFinished = false;

  @override
  void onFinish() {
    isFinished = true;
    widget.statusController.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.statusController.canPlay && !isFinished) {
      widget.statusController.controller.start(this);
      widget.statusController.onLoad();
    } else {
      widget.statusController.controller.pause(this);
    }
    return OrientationBuilder(
      builder: (context, orientation) {
        EdgeInsets insets;
        if (orientation == Orientation.portrait) {
          insets = EdgeInsets.only(top: 30, bottom: 60, left: 20, right: 20);
        } else {
          insets = EdgeInsets.only(
              top: 20,
              bottom: 20,
              left: 30 +
                  (MediaQuery.of(context).padding.left == 0.0 ? 0.0 : 1.0) * 30,
              right: 30 +
                  (MediaQuery.of(context).padding.right == 0.0 ? 0.0 : 1.0) *
                      30);
        }
        return Container(
          padding: insets,
          color: widget.data.backColor,
          height: double.infinity,
          width: double.infinity,
          child: Center(
            child: Text(
              widget.data.text,
            ),
          ),
        );
      },
    );
  }
}
