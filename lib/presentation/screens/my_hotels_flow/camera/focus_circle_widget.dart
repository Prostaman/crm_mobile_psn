  import 'package:flutter/material.dart';

Widget showCircle(double x, double y) {
    return Positioned(
        top: y - 20,
        left: x - 20,
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
        ));
  }