import 'package:flutter/material.dart';

import '../../../../core/format/axis_format.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/time_pattern_metrics.dart';

class DailyPnlChart extends StatefulWidget {
  final List<DailyActivity> daily;

  const DailyPnlChart({super.key, required this.daily});

  @override
  State<DailyPnlChart> createState() => _DailyPnlChartState();
}

class _DailyPnlChartState extends State<DailyPnlChart> {
  int? _hoverIndex;

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
                painter: _DailyBarPainter(
                  daily: widget.daily,
                  positive: theme.positive,
                  negative: theme.negative,
                  axisColor: theme.border,
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

  static const _leftPad = 48.0;
  static const _bottomPad = 16.0;

  void _updateHover(Offset position, Size size) {
    if (position.dx < _leftPad || position.dy > size.height - _bottomPad) {
      setState(() => _hoverIndex = null);
      return;
    }
    final chartWidth = size.width - _leftPad;
    final slot = chartWidth / widget.daily.length;
    final index = ((position.dx - _leftPad) / slot).floor().clamp(0, widget.daily.length - 1);
    setState(() => _hoverIndex = index);
  }

  Widget _buildTooltip(BuildContext context, Size size) {
    final theme = AppThemeScope.themeOf(context);
    final entry = widget.daily[_hoverIndex!];
    final chartWidth = size.width - _leftPad;
    final slot = chartWidth / widget.daily.length;
    final x = _leftPad + slot * _hoverIndex! + slot / 2;

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
            Text('${entry.day.day}/${entry.day.month}', style: TextStyle(fontSize: 10, color: theme.textSecondary)),
            Text(
              formatAxisNumber(entry.pnl),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: entry.pnl >= 0 ? theme.positive : theme.negative,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyBarPainter extends CustomPainter {
  final List<DailyActivity> daily;
  final Color positive;
  final Color negative;
  final Color axisColor;
  final Color labelColor;
  final int? hoverIndex;

  _DailyBarPainter({
    required this.daily,
    required this.positive,
    required this.negative,
    required this.axisColor,
    required this.labelColor,
    required this.hoverIndex,
  });

  static const _leftPad = 48.0;
  static const _bottomPad = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final values = daily.map((d) => d.pnl).toList();
    final maxAbs = values.map((v) => v.abs()).fold<double>(0, (a, b) => a > b ? a : b);
    final scale = maxAbs == 0 ? 1.0 : maxAbs;

    final chartWidth = size.width - _leftPad;
    final chartHeight = size.height - _bottomPad;
    final zeroY = chartHeight / 2;

    final ticks = [-maxAbs, -maxAbs / 2, 0.0, maxAbs / 2, maxAbs];
    for (final tick in ticks) {
      final y = zeroY - (tick / scale) * zeroY;
      canvas.drawLine(
        Offset(_leftPad, y),
        Offset(size.width, y),
        Paint()
          ..color = axisColor.withOpacity(0.25)
          ..strokeWidth = 1,
      );
      final tp = TextPainter(
        text: TextSpan(text: formatAxisNumber(tick), style: TextStyle(fontSize: 9, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    final barWidth = chartWidth / values.length;
    final gap = barWidth * 0.25;

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final barHeight = (value.abs() / scale) * zeroY;
      final left = _leftPad + i * barWidth + gap / 2;
      final width = barWidth - gap;

      final rect = value >= 0
          ? Rect.fromLTWH(left, zeroY - barHeight, width, barHeight)
          : Rect.fromLTWH(left, zeroY, width, barHeight);

      final isHovered = hoverIndex == i;
      final color = value >= 0 ? positive : negative;
      canvas.drawRect(rect, Paint()..color = isHovered ? color : color.withOpacity(0.85));

      if (values.length <= 31 && (i % 5 == 0 || i == values.length - 1)) {
        final tp = TextPainter(
          text: TextSpan(text: '${daily[i].day.day}', style: TextStyle(fontSize: 8, color: labelColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(left + width / 2 - tp.width / 2, chartHeight + 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DailyBarPainter oldDelegate) {
    return oldDelegate.daily != daily || oldDelegate.hoverIndex != hoverIndex;
  }
}
