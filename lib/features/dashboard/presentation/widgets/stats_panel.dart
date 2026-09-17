import 'package:flutter/material.dart';

import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/pnl_metrics.dart';

class StatsPanel extends StatelessWidget {
  final PnlSummary summary;

  const StatsPanel({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;

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
          Text(l10n.statsPanelTitle, style: AppTypography.title.copyWith(color: theme.textPrimary)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: IntrinsicHeight(
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatItem(label: l10n.totalPnlLabel, value: summary.totalPnl),
                    const SizedBox(height: 20),
                    _StatItem(label: l10n.averageLossLabel, value: summary.averageLoss),
                    const SizedBox(height: 20),
                    _StatItem(label: l10n.expectancyLabel, value: summary.mathematicalExpectancy),
                    const SizedBox(height: 20),
                    _StatItem(label: l10n.maxLossLabel, value: summary.maxLoss),
                    const SizedBox(height: 20),
                    _StatItem(label: l10n.maxDrawdownLabel, value: -summary.maxDrawdown),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              VerticalDivider(color: theme.border, width: 1, thickness: 1),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatItem(label: l10n.winRateLabel, percentage: summary.winRate),
                    const SizedBox(height: 20),
                    _StatItem(label: l10n.averageWinLabel, value: summary.averageWin),
                    const SizedBox(height: 20),
                    _StatItem(label: l10n.riskRewardLabel, value: summary.riskRewardRatio, neutral: true),
                    const SizedBox(height: 20),
                    _StatItem(label: l10n.maxWinLabel, value: summary.maxWin),
                    const SizedBox(height: 20),
                    _StatItem(label: l10n.drawdownPercentLabel, percentage: -summary.maxDrawdownPercent / 100, neutral: true),
                  ],
                ),
              ),
            ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final double? value;
  final double? percentage;
  final bool neutral;

  const _StatItem({required this.label, this.value, this.percentage, this.neutral = false});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);

    Color valueColor = theme.textPrimary;
    String displayValue;

    if (percentage != null) {
      displayValue = '${(percentage! * 100).toStringAsFixed(1)}%';
    } else {
      final v = value ?? 0;
      displayValue = v.toStringAsFixed(2);
      if (!neutral) {
        valueColor = v > 0 ? theme.positive : (v < 0 ? theme.negative : theme.textPrimary);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: theme.textSecondary)),
        const SizedBox(height: 6),
        Text(displayValue, style: AppTypography.title.copyWith(color: valueColor)),
      ],
    );
  }
}
