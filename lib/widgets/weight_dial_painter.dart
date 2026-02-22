import 'package:flutter/material.dart';
import 'dart:math' as math;

class WeightDialPainter extends CustomPainter {
  final int currentWeight;
  final int minWeight;
  final int maxWeight;
  final Color tealColor;

  WeightDialPainter({
    required this.currentWeight,
    required this.minWeight,
    required this.maxWeight,
    required this.tealColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Configuration
    const double startAngle = 135 * (math.pi / 180); // Bottom-left
    const double sweepAngle = 270 * (math.pi / 180); // 3/4 circle
    final int totalTicks = maxWeight - minWeight;
    
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // Draw ticks and numbers
    for (int i = 0; i <= totalTicks; i++) {
      final value = minWeight + i;
      final angle = startAngle + (i / totalTicks) * sweepAngle;
      
      final double innerOffset = 15.0;
      final double outerOffset = 5.0;
      
      double length = 8.0;
      bool showNumber = false;
      
      if (value % 10 == 0) {
        length = 15.0;
        showNumber = true;
      } else if (value % 5 == 0) {
        length = 12.0;
      } else {
        length = 8.0;
      }

      final p1 = Offset(
        center.dx + (radius - outerOffset) * math.cos(angle),
        center.dy + (radius - outerOffset) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - outerOffset - length) * math.cos(angle),
        center.dy + (radius - outerOffset - length) * math.sin(angle),
      );

      canvas.drawLine(p1, p2, paint..color = Colors.black87..strokeWidth = (value % 10 == 0 ? 2.0 : 1.0));

      if (showNumber) {
        final textStyle = TextStyle(
          color: Colors.white60,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        );
        final textPainter = TextPainter(
          text: TextSpan(text: '$value', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        
        final textRadius = radius - 35;
        final textOffset = Offset(
          center.dx + textRadius * math.cos(angle) - textPainter.width / 2,
          center.dy + textRadius * math.sin(angle) - textPainter.height / 2,
        );
        
        canvas.save();
        canvas.translate(textOffset.dx + textPainter.width/2, textOffset.dy + textPainter.height/2);
        // canvas.rotate(angle + math.pi/2); // Optional: rotate numbers
        textPainter.paint(canvas, Offset(-textPainter.width/2, -textPainter.height/2));
        canvas.restore();
      }
    }

    // Draw teal indicator line
    final currentAngle = startAngle + ((currentWeight - minWeight) / totalTicks) * sweepAngle;
    final indicatorPaint = Paint()
      ..color = tealColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final indicatorP1 = Offset(
      center.dx + (radius - 50) * math.cos(currentAngle),
      center.dy + (radius - 50) * math.sin(currentAngle),
    );
    final indicatorP2 = Offset(
      center.dx + (radius - 5) * math.cos(currentAngle),
      center.dy + (radius - 5) * math.sin(currentAngle),
    );
    canvas.drawLine(indicatorP1, indicatorP2, indicatorPaint);
    
    // Draw inner light grey arc
    final innerArcPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 15.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 60),
      startAngle + 30 * (math.pi/180),
      150 * (math.pi/180),
      false,
      innerArcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant WeightDialPainter oldDelegate) {
    return oldDelegate.currentWeight != currentWeight ||
        oldDelegate.minWeight != minWeight ||
        oldDelegate.maxWeight != maxWeight ||
        oldDelegate.tealColor != tealColor;
  }
}
