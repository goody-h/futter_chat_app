import 'package:flutter/material.dart';
import 'dart:math';
import './status-group-info.dart';
import './controllers/controllers.dart';
import './status/status.dart';

typedef ClickTickerCallback = int Function();

class StatusGroupTab extends StatefulWidget {
  StatusGroupTab({
    Key key,
    this.group,
    this.controller,
    this.canPlay,
    this.getClickTick,
    this.onFinish,
    this.prevStatus,
  }) : super(key: key);

  final StatusGroup group;
  final ProgressController controller;
  final bool canPlay;
  final ClickTickerCallback getClickTick;
  final VoidCallback onFinish;
  final VoidCallback prevStatus;

  @override
  State<StatefulWidget> createState() {
    return StatusGroupTabState();
  }
}


class StatusGroupTabState extends State<StatusGroupTab> {
  bool waitLoad = true;

  void nextStatus() {
    waitLoad = true;

    if (widget.group.lastStatus < widget.group.statusCount - 1) {
      setState(() {
        widget.group.lastStatus++;
        widget.controller.resetAnimator();
      });
    } else {
      widget.onFinish();
    }
  }

  void prevStatus() {
    waitLoad = true;

    if (widget.group.lastStatus > 0) {
      setState(() {
        widget.group.lastStatus--;
        widget.controller.resetAnimator();
      });
    } else {
      widget.prevStatus();
    }
  }

  void onLoad() {
    if (waitLoad) {
      widget.group.viewCount =
          max(widget.group.viewCount, widget.group.lastStatus + 1);
      waitLoad = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (t) {
        final maxClickTick = 3;
        if (widget.getClickTick() < maxClickTick) {
          // execute click
          print("click occured, tick = ${widget.getClickTick()}");

          // run condition to check offset origin
          if (t.globalPosition.dx < 100) {
            print("back click");
            prevStatus();
          } else {
            print("foward click");
            nextStatus();
          }
        } else {
          print("click cancelled, tick = ${widget.getClickTick()}");
        }
      },
      child: Builder(
        builder: (context) {
          final controller = StatusController(
            controller: widget.controller,
            canPlay: widget.canPlay,
            onFinish: nextStatus,
            onLoad: onLoad,
          );

          final data = widget.group.statuses[widget.group.lastStatus];

          switch (data.runtimeType) {
            case TextData:
              return TextStatus(
                data: data,
                statusController: controller,
              );
            case ImageData:
              return ImageStatus(
                data: data,
                statusController: controller,
              );
            default:
          }
        },
      ),
    );
  }
}