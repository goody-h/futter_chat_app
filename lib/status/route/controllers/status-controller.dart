import 'package:flutter/material.dart';
import './status-progress-controller.dart';

class StatusController {
  StatusController({
    this.controller,
    this.canPlay,
    this.onFinish,
    this.onLoad,
  });

  final ProgressController controller;
  final bool canPlay;
  final VoidCallback onFinish;
  final VoidCallback onLoad;
}
