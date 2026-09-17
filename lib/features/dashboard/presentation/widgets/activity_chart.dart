import 'package:flutter/material.dart';

import '../../../../core/theme/theme_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/time_pattern_metrics.dart';

class ActivityChart extends StatefulWidget {
  final List<DailyActivity> daily;

  const ActivityChart({super.key, required this.daily});

  @override
  State<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<ActivityChart> {
  int? _hoverIndex;

  static const _leftPad = 28.0;
  static const _rightPad = 32.0;
  static const _bottomPad = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);

    if (widget.daily.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noClosedTrades,
          style: TextStyle(color: theme.textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) => _updateHover(event.localPosition, constraints.biggest),
          onExit: (_) => setState(() => _hoverIndex = null),
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _ActivityPainter(
                  daily: widget.daily,
                  longColor: theme.positive,
                  shortColor: theme.negative,
                  lineColor: theme.textPrimary,
                  labelColor: theme.textSecondary,
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
    final slot = chartWidth / widget.daily.length;
    final index = ((position.dx - _leftPad) / slot).floor().clamp(0, widget.daily.length - 1);
    setState(() => _hoverIndex = index);
  }

  Widget _buildTooltip(BuildContext context, Size size) {
    final theme = AppThemeScope.themeOf(context);
    final entry = widget.daily[_hoverIndex!];
    final chartWidth = size.width - _leftPad - _rightPad;
    final slot = chartWidth / widget.daily.length;
    final x = _leftPad + slot * _hoverIndex! + slot / 2;

    return Positioned(
      left: (x - 60).clamp(0.0, size.width - 120),
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
            Text('${entry.day.day}/${entry.day.month}', style: TextStyle(fontSize: 10, color: theme.textSecondary)),
            Text('Longs: ${entry.longs}', style: TextStyle(fontSize: 11, color: theme.positive)),
            Text('Shorts: ${entry.shorts}', style: TextStyle(fontSize: 11, color: theme.negative)),
            Text(
              'Win rate: ${(entry.winRate * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 11, color: theme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityPainter extends CustomPainter {
  final List<DailyActivity> daily;
  final Color longColor;
  final Color shortColor;
  final Color lineColor;
  final Color labelColor;
  final int? hoverIndex;

  _ActivityPainter({
    required this.daily,
    required this.longColor,
    required this.shortColor,
    required this.lineColor,
    required this.labelColor,
    required this.hoverIndex,
  });

  static const _leftPad = 28.0;
  static const _rightPad = 32.0;
  static const _bottomPad = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final maxCount = daily
        .map((d) => d.longs > d.shorts ? d.longs : d.shorts)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final scale = maxCount == 0 ? 1 : maxCount;

    final chartWidth = size.width - _leftPad - _rightPad;
    final chartHeight = size.height - _bottomPad;
    final slot = chartWidth / daily.length;
    final barWidth = (slot * 0.35).clamp(1.0, slot);

    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = chartHeight - fraction * chartHeight;
      final value = (maxCount * fraction).round();
      final tp = TextPainter(
        text: TextSpan(text: '$value', style: TextStyle(fontSize: 8, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_leftPad - tp.width - 4, y - tp.height / 2));
      canvas.drawLine(
        Offset(_leftPad, y),
        Offset(size.width - _rightPad, y),
        Paint()
          ..color = labelColor.withOpacity(0.12)
          ..strokeWidth = 1,
      );
    }

    for (var i = 0; i < daily.length; i++) {
      final entry = daily[i];
      final centerX = _leftPad + i * slot + slot / 2;
      final isHovered = hoverIndex == i;

      final longHeight = (entry.longs / scale) * chartHeight;
      final shortHeight = (entry.shorts / scale) * chartHeight;

      canvas.drawRect(
        Rect.fromLTWH(centerX - barWidth - 2, chartHeight - longHeight, barWidth, longHeight),
        Paint()..color = isHovered ? longColor : longColor.withOpacity(0.85),
      );
      canvas.drawRect(
        Rect.fromLTWH(centerX + 2, chartHeight - shortHeight, barWidth, shortHeight),
        Paint()..color = isHovered ? shortColor : shortColor.withOpacity(0.85),
      );
    }

    final linePath = Path();
    for (var i = 0; i < daily.length; i++) {
      final centerX = _leftPad + i * slot + slot / 2;
      final y = chartHeight - (daily[i].winRate * chartHeight);
      if (i == 0) {
        linePath.moveTo(centerX, y);
      } else {
        linePath.lineTo(centerX, y);
      }
    }
    canvas.drawPath(linePath, Paint()..color = lineColor..strokeWidth = 1.5..style = PaintingStyle.stroke);

    for (final pct in [0, 50, 100]) {
      final y = chartHeight - (pct / 100) * chartHeight;
      final tp = TextPainter(
        text: TextSpan(text: '$pct%', style: TextStyle(fontSize: 8, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - _rightPad + 4, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityPainter oldDelegate) {
    return oldDelegate.daily != daily || oldDelegate.hoverIndex != hoverIndex;
  }
}
