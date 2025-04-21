import 'package:flutter/material.dart';

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
        final gridPaint = Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke;

        return CustomPaint(
          size: Size(width, height),
          painter: GridPainter(gridPaint: gridPaint),
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final Paint gridPaint;

  GridPainter({required this.gridPaint});

  @override
  void paint(Canvas canvas, Size size) {
    const int rows = 3;
    const int cols = 3;

    final double rowHeight = size.height / rows;
    final double colWidth = size.width / cols;

    for (int i = 1; i < rows; i++) {
      final double dy = i * rowHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    for (int i = 1; i < cols; i++) {
      final double dx = i * colWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
