import 'package:flutter/material.dart';

import '../../../core/format/duration_format.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/behavior_metrics.dart';
import '../domain/fill.dart';

class BehaviorScreen extends StatelessWidget {
  final List<Fill> fills;

  const BehaviorScreen({super.key, required this.fills});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;
    final summary = BehaviorMetrics().compute(fills);

    Widget card(String title, Widget child) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.title.copyWith(color: theme.textPrimary)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
    }

    Widget statLine(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.body.copyWith(color: theme.textSecondary)),
            Text(value, style: AppTypography.body.copyWith(color: theme.textPrimary)),
          ],
        ),
      );
    }

    Widget profileBar(String label, double percent, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: AppTypography.body.copyWith(color: theme.textPrimary)),
                Text('${(percent * 100).toStringAsFixed(0)}%', style: AppTypography.body.copyWith(color: theme.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                backgroundColor: theme.background,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    Widget pairList(String title, List<PairStat> pairs, {bool showPnl = true}) {
      if (pairs.isEmpty) {
        return Text(l10n.noDataLabel, style: AppTypography.caption.copyWith(color: theme.textSecondary));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.body.copyWith(color: theme.textSecondary)),
          const SizedBox(height: 8),
          ...pairs.map((p) {
            final valueText = showPnl ? p.pnl.toStringAsFixed(2) : '${p.tradeCount} ${l10n.tradesUnitLabel}';
            final valueColor = showPnl
                ? (p.pnl >= 0 ? theme.positive : theme.negative)
                : theme.textPrimary;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p.coin, style: AppTypography.body.copyWith(color: theme.textPrimary)),
                  Text(valueText, style: AppTypography.body.copyWith(color: valueColor)),
                ],
              ),
            );
          }),
        ],
      );
    }

    final hasData = summary.mostTraded.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.sidebarBehavior, style: AppTypography.display.copyWith(color: theme.textPrimary)),
          const SizedBox(height: 24),
          if (!hasData)
            Text(l10n.noDataLabel, style: AppTypography.body.copyWith(color: theme.textSecondary))
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: card(
                    l10n.traderProfileTitle,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileBar(l10n.scalperLabel, summary.traderProfile.scalperPercent, theme.accent),
                        profileBar(l10n.dayTraderLabel, summary.traderProfile.dayTraderPercent, theme.accent),
                        profileBar(l10n.swingLabel, summary.traderProfile.swingPercent, theme.accent),
                        const SizedBox(height: 12),
                        statLine(l10n.avgDurationLabel, formatDuration(summary.traderProfile.averageDuration)),
                        statLine(l10n.longestDurationLabel, formatDuration(summary.traderProfile.longestDuration)),
                        statLine(l10n.shortestDurationLabel, formatDuration(summary.traderProfile.shortestDuration)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: card(
                    l10n.streaksTitle,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        statLine(
                          l10n.longestWinStreakLabel,
                          '${summary.longestWinStreak.length} (${summary.longestWinStreak.netPnl.toStringAsFixed(2)})',
                        ),
                        statLine(
                          l10n.longestLossStreakLabel,
                          '${summary.longestLossStreak.length} (${summary.longestLossStreak.netPnl.toStringAsFixed(2)})',
                        ),
                        statLine(l10n.avgWinStreakLabel, summary.averageWinStreak.toStringAsFixed(1)),
                        statLine(l10n.avgLossStreakLabel, summary.averageLossStreak.toStringAsFixed(1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            card(
              l10n.pairsTitle,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: pairList(l10n.mostTradedLabel, summary.mostTraded, showPnl: false)),
                  const SizedBox(width: 24),
                  Expanded(child: pairList(l10n.mostProfitableLabel, summary.mostProfitable)),
                  const SizedBox(width: 24),
                  Expanded(child: pairList(l10n.leastProfitableLabel, summary.leastProfitable)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            card(
              l10n.sizeCorrelationTitle,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: summary.sizeCorrelation.map((bucket) {
                  final label = switch (bucket.label) {
                    'small' => l10n.smallSizeLabel,
                    'medium' => l10n.mediumSizeLabel,
                    _ => l10n.largeSizeLabel,
                  };
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: AppTypography.body.copyWith(color: theme.textPrimary)),
                          const SizedBox(height: 8),
                          Text(
                            '${(bucket.winRate * 100).toStringAsFixed(1)}%',
                            style: AppTypography.title.copyWith(color: theme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bucket.avgPnl.toStringAsFixed(2),
                            style: AppTypography.caption.copyWith(
                              color: bucket.avgPnl >= 0 ? theme.positive : theme.negative,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
