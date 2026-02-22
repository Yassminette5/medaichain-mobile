import 'package:flutter/material.dart';

class RulerPainter extends CustomPainter {
  final int min;
  final int max;
  final double scrollOffset;
  final double itemWidth;
  final Color color;

  RulerPainter({
    required this.min,
    required this.max,
    required this.scrollOffset,
    required this.itemWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    final labelStyle = TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final double startX = size.width / 2 - scrollOffset;

    for (int i = min; i <= max; i++) {
      final double x = startX + (i - min) * itemWidth;

      // Only draw if within visible range (roughly)
      if (x < -itemWidth || x > size.width + itemWidth) continue;

      double lineHeight = 15;
      if (i % 5 == 0) {
        lineHeight = 35;
        // Draw label
        final textPainter = TextPainter(
          text: TextSpan(text: '$i', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height - textPainter.height - 5),
        );
      } else if (i % 1 == 0) {
        lineHeight = 15;
      }

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, lineHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.color != color;
  }
}
