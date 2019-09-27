import 'package:flutter/material.dart';
import '../status-group-info.dart';

abstract class OnProgressFinish {
  void onFinish();
}

class ProgressController {
  ProgressController({TickerProvider vsync, this.group}) {
    controller =
        AnimationController(vsync: vsync, duration: Duration(seconds: 10));

    controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && onFinishListener != null) {
        onFinishListener.onFinish();
      }
    });
  }

  StatusGroup group;
  AnimationController controller;
  bool isPreview = false;

  OnProgressFinish onFinishListener;

  int getViewCount() => group.lastStatus;
  int getStatusCount() => group.statusCount;
  double getSeekValue() {
    return isPreview ? 0 : controller.value;
  }

  dispose() {
    controller.dispose();
  }

  updateGroup(StatusGroup group, {bool reset = true, bool preview = false}) {
    this.group = group;
    isPreview = preview;
    if (reset && !preview) {
      resetAnimator();
    } else {
      controller.notifyListeners();
    }
  }

  resetAnimator() {
    pause(onFinishListener);
    controller.reset();
    controller.notifyListeners();
  }

  start(OnProgressFinish listener) {
    _addFinishListener(listener);
    if (!controller.isAnimating) {
      controller.forward();
    }
  }

  pause(OnProgressFinish listener) {
    if (controller.isAnimating && listener == onFinishListener) {
      controller.stop();
    }
  }

  setSeekValue(double value) {
    controller.value = value;
    controller.notifyListeners();
  }

  void addProgressListener(VoidCallback listener) {
    controller.addListener(listener);
  }

  _addFinishListener(OnProgressFinish listener) {
    if (listener != onFinishListener) {
      onFinishListener = listener;
    }
  }

  void removeProgressListener(OnProgressFinish listener) {
    if (listener == onFinishListener) {
      onFinishListener = null;
    }
  }
}

