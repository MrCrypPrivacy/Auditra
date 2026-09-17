import 'package:flutter/material.dart';

import '../../../../core/theme/theme_controller.dart';

class WinRateBarChart extends StatefulWidget {
  final List<String> labels;
  final List<double> winRates;
  final List<int> counts;
  final Color labelColor;

  const WinRateBarChart({
    super.key,
    required this.labels,
    required this.winRates,
    required this.counts,
    required this.labelColor,
  });

  @override
  State<WinRateBarChart> createState() => _WinRateBarChartState();
}

class _WinRateBarChartState extends State<WinRateBarChart> {
  int? _hoverIndex;

  static const _leftPad = 32.0;
  static const _rightPad = 32.0;
  static const _bottomPad = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) => _updateHover(event.localPosition, constraints.biggest),
          onExit: (_) => setState(() => _hoverIndex = null),
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _BarPainter(
                  labels: widget.labels,
                  winRates: widget.winRates,
                  counts: widget.counts,
                  positive: theme.positive,
                  negative: theme.negative,
                  lineColor: theme.textPrimary,
                  labelColor: widget.labelColor,
                  hoverIndex: _hoverIndex,
                ),
              ),
              if (_hoverIndex != null) _buildTooltip(context, constraints.biggest),
            ],
          ),
        );
      },
    );
  }

  void _updateHover(Offset position, Size size) {
    if (position.dx < _leftPad || position.dx > size.width - _rightPad) {
      setState(() => _hoverIndex = null);
      return;
    }
    final chartWidth = size.width - _leftPad - _rightPad;
    final slot = chartWidth / widget.labels.length;
    final index = ((position.dx - _leftPad) / slot).floor().clamp(0, widget.labels.length - 1);
    setState(() => _hoverIndex = index);
  }

  Widget _buildTooltip(BuildContext context, Size size) {
    final theme = AppThemeScope.themeOf(context);
    final index = _hoverIndex!;
    final chartWidth = size.width - _leftPad - _rightPad;
    final slot = chartWidth / widget.labels.length;
    final x = _leftPad + slot * index + slot / 2;

    return Positioned(
      left: (x - 55).clamp(0.0, size.width - 110),
      top: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${(widget.winRates[index] * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textPrimary),
            ),
            Text(
              '${widget.counts[index]}',
              style: TextStyle(fontSize: 10, color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<String> labels;
  final List<double> winRates;
  final List<int> counts;
  final Color positive;
  final Color negative;
  final Color lineColor;
  final Color labelColor;
  final int? hoverIndex;

  _BarPainter({
    required this.labels,
    required this.winRates,
    required this.counts,
    required this.positive,
    required this.negative,
    required this.lineColor,
    required this.labelColor,
    required this.hoverIndex,
  });

  static const _leftPad = 32.0;
  static const _rightPad = 32.0;
  static const _bottomPad = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - _leftPad - _rightPad;
    final chartHeight = size.height - _bottomPad;
    final slot = chartWidth / labels.length;
    final barWidth = (slot * 0.6).clamp(1.0, slot);
    final maxCount = counts.fold<int>(0, (a, b) => a > b ? a : b);

    for (final pct in [0, 25, 50, 75, 100]) {
      final y = chartHeight - (pct / 100) * chartHeight;
      canvas.drawLine(
        Offset(_leftPad, y),
        Offset(size.width - _rightPad, y),
        Paint()
          ..color = labelColor.withOpacity(0.15)
          ..strokeWidth = 1,
      );
      final tp = TextPainter(
        text: TextSpan(text: '$pct', style: TextStyle(fontSize: 8, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_leftPad - tp.width - 4, y - tp.height / 2));
    }

    for (var i = 0; i < labels.length; i++) {
      final value = winRates[i].clamp(0.0, 1.0);
      final barHeight = value * chartHeight;
      final left = _leftPad + i * slot + (slot - barWidth) / 2;
      final isHovered = hoverIndex == i;
      final color = value >= 0.5 ? positive : negative;

      canvas.drawRect(
        Rect.fromLTWH(left, chartHeight - barHeight, barWidth, barHeight),
        Paint()..color = isHovered ? color : color.withOpacity(0.85),
      );

      if (labels[i].isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(text: labels[i], style: TextStyle(fontSize: 9, color: labelColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(_leftPad + i * slot + (slot - tp.width) / 2, chartHeight + 2));
      }
    }

    if (maxCount > 0) {
      final path = Path();
      for (var i = 0; i < counts.length; i++) {
        final x = _leftPad + i * slot + slot / 2;
        final y = chartHeight - (counts[i] / maxCount) * chartHeight;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, Paint()..color = lineColor..strokeWidth = 1.5..style = PaintingStyle.stroke);

      for (final pct in [0, 50, 100]) {
        final y = chartHeight - (pct / 100) * chartHeight;
        final value = (maxCount * pct / 100).round();
        final tp = TextPainter(
          text: TextSpan(text: '$value', style: TextStyle(fontSize: 8, color: labelColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(size.width - _rightPad + 4, y - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) {
    return oldDelegate.winRates != winRates || oldDelegate.hoverIndex != hoverIndex;
  }
}
