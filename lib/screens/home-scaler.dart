import 'package:flutter/material.dart';

class Scale extends StatelessWidget {
  Scale({Key key, this.origin, this.child}) : super(key: key);

  final double origin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.diagonal3Values(1.25, 2.5, 1);
    matrix.setTranslationRaw(0, -origin, 0);

    return Transform(
      transform: matrix,
      child: child,
    );
  }
}

class DownScale extends StatelessWidget {
  DownScale({Key key, this.origin, this.child, this.factor = 1})
      : super(key: key);

  final double origin;
  final Widget child;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.diagonal3Values(0.8, 0.4, 1);
    matrix.setTranslationRaw(0, origin * 0.4 * factor, 0);

    return Transform(
      transform: matrix,
      child: child,
    );
  }
}
