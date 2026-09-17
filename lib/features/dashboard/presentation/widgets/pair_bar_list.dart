import 'package:flutter/material.dart';

import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/typography.dart';
import '../../application/behavior_metrics.dart';

class PairBarList extends StatelessWidget {
  final List<PairStat> pairs;
  final bool showPnl;
  final Color barColor;

  const PairBarList({super.key, required this.pairs, required this.barColor, this.showPnl = true});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);

    if (pairs.isEmpty) {
      return Center(child: Text('—', style: AppTypography.caption.copyWith(color: theme.textSecondary)));
    }

    final maxValue = pairs
        .map((p) => showPnl ? p.pnl.abs() : p.tradeCount.toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: pairs.map((p) {
        final value = showPnl ? p.pnl.abs() : p.tradeCount.toDouble();
        final fraction = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.04, 1.0);
        final color = showPnl ? (p.pnl >= 0 ? theme.positive : theme.negative) : barColor;
        final valueText = showPnl ? p.pnl.toStringAsFixed(2) : '${p.tradeCount}';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(p.coin, style: AppTypography.body.copyWith(color: theme.textPrimary)),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 10,
                        width: constraints.maxWidth * fraction,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 76,
                child: Text(
                  valueText,
                  textAlign: TextAlign.right,
                  style: AppTypography.caption.copyWith(color: theme.textSecondary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
