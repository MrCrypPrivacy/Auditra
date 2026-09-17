import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/filters/period_filter.dart';
import '../../../core/storage/wallet_profile.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/behavior_metrics.dart';
import '../application/fee_metrics.dart';
import '../application/pnl_metrics.dart';
import '../application/time_pattern_metrics.dart';
import '../domain/fill.dart';
import 'widgets/activity_chart.dart';
import 'widgets/calendar_heatmap.dart';
import 'widgets/daily_pnl_chart.dart';
import 'widgets/direction_card.dart';
import 'widgets/monthly_card.dart';
import 'widgets/pair_bar_list.dart';
import 'widgets/pnl_chart.dart';
import 'widgets/stats_panel.dart';
import 'widgets/trader_profile_donut.dart';
import 'widgets/win_rate_bar_chart.dart';

class OverviewScreen extends StatefulWidget {
  final List<Fill> fills;
  final Period period;
  final ValueChanged<Period> onPeriodChanged;
  final List<WalletProfile> wallets;
  final String? origin;
  final ValueChanged<String?> onOriginChanged;
  final int breachCount;
  final VoidCallback onViewRules;

  const OverviewScreen({
    super.key,
    required this.fills,
    required this.period,
    required this.onPeriodChanged,
    required this.wallets,
    required this.origin,
    required this.onOriginChanged,
    required this.breachCount,
    required this.onViewRules,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  static const _cardHeight = 340.0;

  final _scrollController = ScrollController();
  final _resumenKey = GlobalKey();
  final _rendimientoKey = GlobalKey();
  final _comportamientoKey = GlobalKey();
  final _rachasKey = GlobalKey();
  final _paresKey = GlobalKey();
  final _comisionesKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.02,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final filtered = PeriodFilter.apply(widget.fills, widget.period);
    final summary = PnlMetrics().compute(filtered);
    final timePatterns = TimePatternMetrics().compute(filtered);
    final behavior = BehaviorMetrics().compute(filtered);
    final fees = FeeMetrics().compute(filtered);

    final periodLabels = {
      Period.all: l10n.periodAll,
      Period.today: l10n.periodToday,
      Period.week: l10n.periodWeek,
      Period.month: l10n.periodMonth,
      Period.year: l10n.periodYear,
    };

    Widget selectorBox({required String label, required Widget dropdown}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.body.copyWith(color: theme.textSecondary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border),
            ),
            child: dropdown,
          ),
        ],
      );
    }

    Widget navPill(String label, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.border),
          ),
          child: Text(label, style: AppTypography.body.copyWith(color: theme.textSecondary)),
        ),
      );
    }

    Widget legendDot(Color color) {
      return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
    }

    Widget panel(String title, Widget child) {
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
            Expanded(child: child),
          ],
        ),
      );
    }

    Widget bigStat(String label, String value, {Color? color}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTypography.caption.copyWith(color: theme.textSecondary)),
            const SizedBox(height: 8),
            Text(value, style: AppTypography.display.copyWith(color: color ?? theme.textPrimary)),
          ],
        ),
      );
    }

    Widget twoColRow(Widget left, Widget right, {double breakpoint = 760}) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < breakpoint;
          final leftBox = SizedBox(height: _cardHeight, child: left);
          final rightBox = SizedBox(height: _cardHeight, child: right);

          if (isNarrow) {
            return Column(children: [leftBox, const SizedBox(height: 16), rightBox]);
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftBox),
              const SizedBox(width: 16),
              Expanded(child: rightBox),
            ],
          );
        },
      );
    }

    Widget threeColRow(Widget a, Widget b, Widget c, {double breakpoint = 900}) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < breakpoint;
          final aBox = SizedBox(height: _cardHeight, child: a);
          final bBox = SizedBox(height: _cardHeight, child: b);
          final cBox = SizedBox(height: _cardHeight, child: c);

          if (isNarrow) {
            return Column(children: [
              aBox,
              const SizedBox(height: 16),
              bBox,
              const SizedBox(height: 16),
              cBox,
            ]);
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: aBox),
              const SizedBox(width: 16),
              Expanded(child: bBox),
              const SizedBox(width: 16),
              Expanded(child: cBox),
            ],
          );
        },
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.breachCount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.negative.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.negative.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: theme.negative, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.breachCount} ${l10n.ruleAlertBanner}',
                      style: AppTypography.body.copyWith(color: theme.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onViewRules,
                    child: Text(l10n.viewButton, style: TextStyle(color: theme.negative)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(l10n.overviewTitle, style: AppTypography.display.copyWith(color: theme.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              selectorBox(
                label: l10n.periodLabel,
                dropdown: DropdownButtonHideUnderline(
                  child: DropdownButton<Period>(
                    value: widget.period,
                    isDense: true,
                    dropdownColor: theme.surface,
                    style: AppTypography.body.copyWith(color: theme.textPrimary),
                    icon: Icon(Icons.keyboard_arrow_down, color: theme.textSecondary, size: 16),
                    items: Period.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(periodLabels[p]!)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) widget.onPeriodChanged(value);
                    },
                  ),
                ),
              ),
              selectorBox(
                label: l10n.originLabel,
                dropdown: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: widget.origin,
                    isDense: true,
                    dropdownColor: theme.surface,
                    style: AppTypography.body.copyWith(color: theme.textPrimary),
                    icon: Icon(Icons.keyboard_arrow_down, color: theme.textSecondary, size: 16),
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text(l10n.originAll)),
                      ...widget.wallets.map((w) => DropdownMenuItem<String?>(value: w.address, child: Text(w.name))),
                    ],
                    onChanged: widget.onOriginChanged,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              navPill(l10n.navAllLabel, _scrollToTop),
              navPill(l10n.navSummaryLabel, () => _scrollToKey(_resumenKey)),
              navPill(l10n.navPerformanceLabel, () => _scrollToKey(_rendimientoKey)),
              navPill(l10n.traderProfileTitle, () => _scrollToKey(_comportamientoKey)),
              navPill(l10n.winningStreaksTitle, () => _scrollToKey(_rachasKey)),
              navPill(l10n.pairsTitle, () => _scrollToKey(_paresKey)),
              navPill(l10n.cumulativeFeesTitle, () => _scrollToKey(_comisionesKey)),
            ],
          ),
          const SizedBox(height: 24),

          // Row 1: Stats + PnL chart (narrow/wide asymmetric, same height as the rest)
          KeyedSubtree(
            key: _resumenKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 760;
                final statsPanel = SizedBox(height: _cardHeight, child: StatsPanel(summary: summary));
                final chartPanel = SizedBox(
                  height: _cardHeight,
                  child: panel(l10n.chartPanelTitle, PnlChart(cumulativePnl: summary.cumulativePnl, times: summary.cumulativePnlTimes)),
                );

                if (isNarrow) {
                  return Column(children: [statsPanel, const SizedBox(height: 16), chartPanel]);
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 360, child: statsPanel),
                      const SizedBox(width: 16),
                      Expanded(child: chartPanel),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Row 2: Actividad + PnL por Día (con navegación mes a mes)
          KeyedSubtree(
            key: _rendimientoKey,
            child: twoColRow(
              MonthlyCard<DailyActivity>(
                title: l10n.activityPanelTitle,
                items: timePatterns.dailyActivity,
                dateOf: (d) => d.day,
                builder: (context, monthItems) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          legendDot(theme.positive),
                          const SizedBox(width: 4),
                          Text(l10n.longsLegendLabel, style: TextStyle(fontSize: 11, color: theme.textSecondary)),
                          const SizedBox(width: 12),
                          legendDot(theme.negative),
                          const SizedBox(width: 4),
                          Text(l10n.shortsLegendLabel, style: TextStyle(fontSize: 11, color: theme.textSecondary)),
                          const SizedBox(width: 12),
                          Container(width: 10, height: 2, color: theme.textPrimary),
                          const SizedBox(width: 4),
                          Text(l10n.winRateLegendLabel, style: TextStyle(fontSize: 11, color: theme.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: ActivityChart(daily: monthItems)),
                    ],
                  );
                },
              ),
              MonthlyCard<DailyActivity>(
                title: l10n.dailyPnlPanelTitle,
                items: timePatterns.dailyActivity,
                dateOf: (d) => d.day,
                builder: (context, monthItems) => DailyPnlChart(daily: monthItems),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Row 3: Win Rate por Hora + Win Rate por Día
          Builder(builder: (context) {
            final weekdayLabels = [
              l10n.weekdayMon, l10n.weekdayTue, l10n.weekdayWed, l10n.weekdayThu,
              l10n.weekdayFri, l10n.weekdaySat, l10n.weekdaySun,
            ].map((name) => name.substring(0, name.length < 3 ? name.length : 3)).toList();

            return twoColRow(
              panel(
                l10n.hourlyWinRateTitle,
                WinRateBarChart(
                  labels: List.generate(24, (h) => h % 3 == 0 ? '$h' : ''),
                  winRates: timePatterns.hourlyWinRate.map((h) => h.winRate).toList(),
                  counts: timePatterns.hourlyWinRate.map((h) => h.count).toList(),
                  labelColor: theme.textSecondary,
                ),
              ),
              panel(
                l10n.weekdayWinRateTitle,
                WinRateBarChart(
                  labels: weekdayLabels,
                  winRates: timePatterns.weekdayWinRate.map((w) => w.winRate).toList(),
                  counts: timePatterns.weekdayWinRate.map((w) => w.count).toList(),
                  labelColor: theme.textSecondary,
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Row 4: Dirección de trade + Perfil de trader (donuts)
          KeyedSubtree(
            key: _comportamientoKey,
            child: twoColRow(
              panel(
                l10n.directionTitle,
                DirectionCard(longStats: timePatterns.longStats, shortStats: timePatterns.shortStats),
              ),
              panel(
                l10n.traderProfileTitle,
                TraderProfileDonut(profile: behavior.traderProfile),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Row 5: Rachas Ganadoras + Rachas Perdedoras + Recuperación
          KeyedSubtree(
            key: _rachasKey,
            child: threeColRow(
              panel(
                l10n.winningStreaksTitle,
                Row(
                  children: [
                    bigStat(l10n.avgWinStreakLabel, behavior.averageWinStreak.toStringAsFixed(1)),
                    bigStat(
                      l10n.streakNetPnlLabel,
                      behavior.longestWinStreak.netPnl.toStringAsFixed(2),
                      color: theme.positive,
                    ),
                  ],
                ),
              ),
              panel(
                l10n.losingStreaksTitle,
                Row(
                  children: [
                    bigStat(l10n.avgLossStreakLabel, behavior.averageLossStreak.toStringAsFixed(1)),
                    bigStat(
                      l10n.streakNetPnlLabel,
                      behavior.longestLossStreak.netPnl.toStringAsFixed(2),
                      color: theme.negative,
                    ),
                  ],
                ),
              ),
              panel(
                l10n.recoveryTitle,
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${(behavior.recoveryRate * 100).toStringAsFixed(0)}%',
                        style: AppTypography.display.copyWith(color: theme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.recoveryRateLabel,
                        style: AppTypography.caption.copyWith(color: theme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Row 6: Calendario + Pares Más Tradeados
          KeyedSubtree(
            key: _paresKey,
            child: twoColRow(
              MonthlyCard<DailyActivity>(
                title: l10n.calendarTitle,
                items: timePatterns.dailyActivity,
                dateOf: (d) => d.day,
                builder: (context, monthItems) => Center(
                  child: CalendarHeatmap(daily: monthItems, showMonthLabel: false),
                ),
              ),
              panel(
                l10n.mostTradedLabel,
                PairBarList(pairs: behavior.mostTraded, showPnl: false, barColor: theme.accent),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Row 7: Pares Más Rentables + Pares Menos Rentables
          twoColRow(
            panel(
              l10n.mostProfitableLabel,
              PairBarList(pairs: behavior.mostProfitable, barColor: theme.positive),
            ),
            panel(
              l10n.leastProfitableLabel,
              PairBarList(pairs: behavior.leastProfitable, barColor: theme.negative),
            ),
          ),
          const SizedBox(height: 16),

          // Row 8: Comisiones (diarias, con navegación mensual) + Comisiones acumuladas
          KeyedSubtree(
            key: _comisionesKey,
            child: twoColRow(
              MonthlyCard<DailyFeeStat>(
                title: l10n.dailyFeesTitle,
                items: fees.dailyFees,
                dateOf: (d) => d.day,
                builder: (context, monthItems) => DailyPnlChart(
                  daily: monthItems
                      .map((d) => DailyActivity(day: d.day, longs: 0, shorts: 0, winRate: 0, pnl: -d.fee))
                      .toList(),
                ),
              ),
              panel(
                l10n.cumulativeFeesTitle,
                PnlChart(cumulativePnl: fees.cumulativeFees, times: fees.cumulativeFeeTimes),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Row 9: Ratio Comisiones (con navegación mensual) + Resumen mensual
          twoColRow(
            MonthlyCard<DailyFeeRatioStat>(
              title: l10n.feeRatioChartTitle,
              items: fees.dailyFeeRatio,
              dateOf: (d) => d.day,
              builder: (context, monthItems) => DailyPnlChart(
                daily: monthItems
                    .map((d) => DailyActivity(day: d.day, longs: 0, shorts: 0, winRate: 0, pnl: d.ratio))
                    .toList(),
              ),
            ),
            panel(
              l10n.monthlySummaryTitle,
              SingleChildScrollView(
                child: Column(
                  children: fees.monthly.map((m) {
                    final label = DateFormat.yMMMM(locale).format(DateTime(m.year, m.month));
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(label, style: AppTypography.body.copyWith(color: theme.textPrimary))),
                          SizedBox(
                            width: 100,
                            child: Text(
                              m.pnl.toStringAsFixed(2),
                              style: AppTypography.body.copyWith(color: m.pnl >= 0 ? theme.positive : theme.negative),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              '${(m.winRate * 100).toStringAsFixed(0)}%',
                              style: AppTypography.body.copyWith(color: theme.textSecondary),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
