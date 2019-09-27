import 'package:flutter/material.dart';
import '../controllers/controllers.dart';
import './status-info.dart';

class ImageData extends StatusData {
  ImageData() : super(id: "");
  String bitmap;
  String url;
  String comment;
}

class ImageStatus extends StatefulWidget {
  ImageStatus({this.data, this.statusController})
      : super(key: ValueKey(data.id));
  final ImageData data;
  final StatusController statusController;

  @override
  State<StatefulWidget> createState() {
    return _ImageStatusState();
  }
}

class _ImageStatusState extends State<ImageStatus> with OnProgressFinish {
  bool isLoaded = false;
  bool isFinished = false;
  Image _image;

  ScaleUpdateDetails scale = ScaleUpdateDetails();

  @override
  void initState() { 
    super.initState();
    // write initialisation code for image
  }

  @override
  void onFinish() {
    isFinished = true;
    widget.statusController.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoaded && widget.statusController.canPlay && !isFinished) {
      widget.statusController.controller.start(this);
      widget.statusController.onLoad();
    } else {
      widget.statusController.controller.pause(this);
    }
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: isLoaded ? _image : Image.asset("name"),
    );
  }
}
