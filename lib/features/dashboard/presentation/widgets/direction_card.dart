import 'package:flutter/material.dart';

import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/time_pattern_metrics.dart';
import 'donut_chart.dart';

class DirectionCard extends StatelessWidget {
  final DirectionStat longStats;
  final DirectionStat shortStats;

  const DirectionCard({super.key, required this.longStats, required this.shortStats});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;

    Widget legendColumn(String label, Color accent, DirectionStat stat, CrossAxisAlignment align) {
      return Column(
        crossAxisAlignment: align,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.body.copyWith(color: theme.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Text('${stat.count} ${l10n.tradesUnitLabel}', style: AppTypography.caption.copyWith(color: theme.textSecondary)),
          const SizedBox(height: 6),
          Text('${(stat.winRate * 100).toStringAsFixed(1)}%', style: AppTypography.title.copyWith(color: theme.textPrimary)),
          const SizedBox(height: 6),
          Text(
            stat.pnl.toStringAsFixed(2),
            style: AppTypography.body.copyWith(color: stat.pnl >= 0 ? theme.positive : theme.negative),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: legendColumn(l10n.longsLegendLabel, theme.positive, longStats, CrossAxisAlignment.start)),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: DonutChart(
              segments: [
                DonutSegment(value: longStats.count.toDouble(), color: theme.positive),
                DonutSegment(value: shortStats.count.toDouble(), color: theme.negative),
              ],
            ),
          ),
        ),
        Expanded(child: legendColumn(l10n.shortsLegendLabel, theme.negative, shortStats, CrossAxisAlignment.end)),
      ],
    );
  }
}
