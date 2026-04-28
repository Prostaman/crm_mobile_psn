import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

Widget zoomCircle(double _currentScale) {
  return Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.black45,
    ),
    padding: EdgeInsets.all(8),
    child: Text(
      "$_currentScale",
      style: textStyle(size: 10, color: Colors.white),
    ),
  );
}
