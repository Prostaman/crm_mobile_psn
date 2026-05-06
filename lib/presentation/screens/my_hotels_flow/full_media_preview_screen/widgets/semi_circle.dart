import 'package:flutter/material.dart';

class SemiCirclePainter extends CustomPainter {
  final double startAngle;
  final double sweepAngle;
  double? center = 0;

  SemiCirclePainter({
    required this.startAngle,
    required this.sweepAngle,
    this.center
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Color.fromRGBO(28, 28, 28, 0.5);

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center!, size.height / 2),
        height: size.height,
        width: size.width,
      ),
      startAngle, //math.pi/2,
      sweepAngle, // -math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
