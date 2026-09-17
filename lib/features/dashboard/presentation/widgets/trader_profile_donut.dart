import 'package:flutter/material.dart';

import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/behavior_metrics.dart';
import 'donut_chart.dart';

class TraderProfileDonut extends StatelessWidget {
  final TraderProfile profile;

  const TraderProfileDonut({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;

    final scalperColor = theme.accent;
    final dayTraderColor = theme.accent.withOpacity(0.6);
    final swingColor = theme.accent.withOpacity(0.3);

    Widget legendColumn(String label, Color color, double percent, CrossAxisAlignment align) {
      return Column(
        crossAxisAlignment: align,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.body.copyWith(color: theme.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Text('${(percent * 100).toStringAsFixed(1)}%', style: AppTypography.title.copyWith(color: theme.textPrimary)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: legendColumn(l10n.scalperLabel, scalperColor, profile.scalperPercent, CrossAxisAlignment.start)),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DonutChart(
                    segments: [
                      DonutSegment(value: profile.scalperPercent, color: scalperColor),
                      DonutSegment(value: profile.dayTraderPercent, color: dayTraderColor),
                      DonutSegment(value: profile.swingPercent, color: swingColor),
                    ],
                  ),
                ),
              ),
              Expanded(child: legendColumn(l10n.swingLabel, swingColor, profile.swingPercent, CrossAxisAlignment.end)),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dayTraderColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              '${l10n.dayTraderLabel}: ${(profile.dayTraderPercent * 100).toStringAsFixed(1)}%',
              style: AppTypography.caption.copyWith(color: theme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
