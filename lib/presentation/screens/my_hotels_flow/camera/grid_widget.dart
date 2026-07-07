import 'package:flutter/material.dart';

//applyOpacity(Colors.white, 0.5)
class GridOverlay extends StatelessWidget {
  // GridOverlay(this.width, this.height);

  // final double width;
  // final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return CustomPaint(
          size: Size(width, height),
          painter: GridPainter(),
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final Paint darkPaint;
  final Paint lightPaint;

  GridPainter()
      : darkPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..isAntiAlias = true
          ..blendMode = BlendMode.srcOver,
        lightPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..isAntiAlias = true
          ..blendMode = BlendMode.srcOver;

  @override
  void paint(Canvas canvas, Size size) {
    const int rows = 3;
    const int cols = 3;

    final double rowHeight = size.height / rows;
    final double colWidth = size.width / cols;

    // Горизонтальні лінії
    for (int i = 1; i < rows; i++) {
      final dy = i * rowHeight;

      canvas.drawLine(
        Offset(0, dy),
        Offset(size.width, dy),
        darkPaint,
      );

      canvas.drawLine(
        Offset(0, dy),
        Offset(size.width, dy),
        lightPaint,
      );
    }

    // Вертикальні лінії
    for (int i = 1; i < cols; i++) {
      final dx = i * colWidth;

      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx, size.height),
        darkPaint,
      );

      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx, size.height),
        lightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
