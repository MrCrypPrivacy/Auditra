import 'dart:math' as math;

import 'package:flutter/material.dart';

class DonutSegment {
  final double value;
  final Color color;

  const DonutSegment({required this.value, required this.color});
}

class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final double strokeWidth;

  const DonutChart({super.key, required this.segments, this.strokeWidth = 22});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: constraints.biggest,
          painter: _DonutPainter(segments: segments, strokeWidth: strokeWidth),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;

  _DonutPainter({required this.segments, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0 || size.shortestSide <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = (segment.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.segments != segments;
}
