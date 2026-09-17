import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/typography.dart';
import '../../application/time_pattern_metrics.dart';

class _DayCell {
  final int day;
  final Color color;
  final bool hasData;

  const _DayCell({required this.day, required this.color, required this.hasData});
}

class CalendarHeatmap extends StatelessWidget {
  final List<DailyActivity> daily;
  final bool showMonthLabel;

  const CalendarHeatmap({super.key, required this.daily, this.showMonthLabel = true});

  static const double _cellSize = 42;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final locale = Localizations.localeOf(context).toString();

    if (daily.isEmpty) {
      return const SizedBox.shrink();
    }

    final byMonth = <String, List<DailyActivity>>{};
    for (final entry in daily) {
      final key = '${entry.day.year}-${entry.day.month}';
      byMonth.putIfAbsent(key, () => []).add(entry);
    }

    final monthKeys = byMonth.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('-').map(int.parse).toList();
        final bParts = b.split('-').map(int.parse).toList();
        if (aParts[0] != bParts[0]) return bParts[0].compareTo(aParts[0]);
        return bParts[1].compareTo(aParts[1]);
      });

    final maxAbsPnl = daily.map((d) => d.pnl.abs()).fold<double>(0, (a, b) => a > b ? a : b);

    // Captured once, right at the true entry point of this widget, so it
    // reflects exactly what our real parent gives us — nothing downstream
    // (in particular, a Column with mainAxisSize.min further down, which
    // passes an unbounded height to a non-flex child) gets a chance to lose
    // or loosen this value before we can enforce it.
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final perMonthMaxHeight =
            outerConstraints.maxHeight.isFinite ? outerConstraints.maxHeight / monthKeys.length : double.infinity;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: monthKeys.map((key) {
            final entries = byMonth[key]!;
            final firstDay = entries.first.day;
            final monthLabel = DateFormat.yMMMM(locale).format(DateTime(firstDay.year, firstDay.month));
            final pnlByDay = {for (final e in entries) e.day.day: e.pnl};

            final daysInMonth = DateTime(firstDay.year, firstDay.month + 1, 0).day;
            final firstWeekday = DateTime(firstDay.year, firstDay.month, 1).weekday;
            final totalCells = (firstWeekday - 1) + daysInMonth;
            final rows = (totalCells / 7).ceil();

            final cellData = <_DayCell?>[];
            for (var i = 1; i < firstWeekday; i++) {
              cellData.add(null);
            }
            for (var day = 1; day <= daysInMonth; day++) {
              final pnl = pnlByDay[day];
              Color color = theme.background;
              if (pnl != null && maxAbsPnl > 0) {
                final intensity = (pnl.abs() / maxAbsPnl).clamp(0.15, 1.0);
                color = (pnl >= 0 ? theme.positive : theme.negative).withOpacity(intensity);
              }
              cellData.add(_DayCell(day: day, color: color, hasData: pnl != null));
            }
            while (cellData.length < rows * 7) {
              cellData.add(null);
            }

            Widget cellBox(_DayCell? c) {
              return Container(
                width: _cellSize,
                height: _cellSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c?.color ?? theme.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: c == null
                    ? null
                    : Text(
                        '${c.day}',
                        style: TextStyle(fontSize: 11, color: c.hasData ? Colors.black87 : theme.textSecondary),
                      ),
              );
            }

            final labelHeight = showMonthLabel ? 28.0 : 0.0;
            final gridMaxHeight =
                perMonthMaxHeight.isFinite ? perMonthMaxHeight - 8 - labelHeight : double.infinity;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showMonthLabel) ...[
                    Text(monthLabel, style: AppTypography.body.copyWith(color: theme.textSecondary)),
                    const SizedBox(height: 8),
                  ],
                  // ConstrainedBox enforces the height we captured above; it
                  // is a hard cap that wins regardless of anything an
                  // intervening Column does to the constraints on its way
                  // down, so AspectRatio can no longer size itself off width
                  // alone and overflow the real budget.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: outerConstraints.maxWidth, maxHeight: gridMaxHeight),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 7 / rows,
                        child: GridView.count(
                          crossAxisCount: 7,
                          childAspectRatio: 1,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3,
                          children: cellData.map(cellBox).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
