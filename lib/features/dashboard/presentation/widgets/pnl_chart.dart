import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/format/axis_format.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';

class PnlChart extends StatefulWidget {
  final List<double> cumulativePnl;
  final List<DateTime> times;

  const PnlChart({super.key, required this.cumulativePnl, this.times = const []});

  @override
  State<PnlChart> createState() => _PnlChartState();
}

class _PnlChartState extends State<PnlChart> {
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);

    if (widget.cumulativePnl.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noClosedTrades,
          style: TextStyle(color: theme.textSecondary),
        ),
      );
    }

    final locale = Localizations.localeOf(context).toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) => _updateHover(event.localPosition, constraints.biggest),
          onExit: (_) => setState(() => _hoverIndex = null),
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _PnlLinePainter(
                  values: widget.cumulativePnl,
                  positive: theme.positive,
                  negative: theme.negative,
                  axisColor: theme.border,
                  labelColor: theme.textSecondary,
                  hoverIndex: _hoverIndex,
                ),
              ),
              if (_hoverIndex != null && _hoverIndex! < widget.cumulativePnl.length)
                _buildTooltip(context, locale, constraints.biggest),
            ],
          ),
        );
      },
    );
  }

  void _updateHover(Offset position, Size size) {
    const leftPad = 56.0;
    if (position.dx < leftPad) {
      setState(() => _hoverIndex = null);
      return;
    }
    final chartWidth = size.width - leftPad;
    final ratio = ((position.dx - leftPad) / chartWidth).clamp(0.0, 1.0);
    final index = (ratio * (widget.cumulativePnl.length - 1)).round();
    setState(() => _hoverIndex = index);
  }

  Widget _buildTooltip(BuildContext context, String locale, Size size) {
    final theme = AppThemeScope.themeOf(context);
    final index = _hoverIndex!;
    final value = widget.cumulativePnl[index];
    const leftPad = 56.0;
    final chartWidth = size.width - leftPad;
    final x = leftPad + (widget.cumulativePnl.length <= 1
        ? 0
        : chartWidth * index / (widget.cumulativePnl.length - 1));

    final dateLabel = index < widget.times.length
        ? DateFormat.yMd(locale).format(widget.times[index].toLocal())
        : '';

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
            if (dateLabel.isNotEmpty)
              Text(dateLabel, style: TextStyle(fontSize: 10, color: theme.textSecondary)),
            Text(
              formatAxisNumber(value),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PnlLinePainter extends CustomPainter {
  final List<double> values;
  final Color positive;
  final Color negative;
  final Color axisColor;
  final Color labelColor;
  final int? hoverIndex;

  _PnlLinePainter({
    required this.values,
    required this.positive,
    required this.negative,
    required this.axisColor,
    required this.labelColor,
    required this.hoverIndex,
  });

  static const _leftPad = 56.0;
  static const _bottomPad = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 1e-9 ? 1.0 : maxValue - minValue;

    final chartWidth = size.width - _leftPad;
    final chartHeight = size.height - _bottomPad;

    final ticks = niceAxisTicks(minValue, maxValue);
    for (final tick in ticks) {
      final y = chartHeight - ((tick - minValue) / range) * chartHeight;
      canvas.drawLine(
        Offset(_leftPad, y),
        Offset(size.width, y),
        Paint()
          ..color = axisColor.withOpacity(0.3)
          ..strokeWidth = 1,
      );
      final tp = TextPainter(
        text: TextSpan(text: formatAxisNumber(tick), style: TextStyle(fontSize: 9, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    final path = Path();
    final divisor = (values.length - 1).clamp(1, values.length);

    for (var i = 0; i < values.length; i++) {
      final x = _leftPad + chartWidth * (i / divisor);
      final y = chartHeight - ((values[i] - minValue) / range) * chartHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = values.last >= 0 ? positive : negative
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    if (hoverIndex != null && hoverIndex! < values.length) {
      final i = hoverIndex!;
      final x = _leftPad + chartWidth * (i / divisor);
      final y = chartHeight - ((values[i] - minValue) / range) * chartHeight;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, chartHeight),
        Paint()
          ..color = labelColor.withOpacity(0.3)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = values[i] >= 0 ? positive : negative);
    }
  }

  @override
  bool shouldRepaint(covariant _PnlLinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.hoverIndex != hoverIndex;
  }
}
