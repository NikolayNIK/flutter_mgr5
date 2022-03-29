import 'package:flutter/painting.dart';

extension PathOffset on Path {

  void moveToOffset(Offset point) {
    moveTo(point.dx, point.dy);
  }

  void lineToOffset(Offset point) {
    lineTo(point.dx, point.dy);
  }
}