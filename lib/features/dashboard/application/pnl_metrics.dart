import '../domain/fill.dart';

class PnlSummary {
  final double totalPnl;
  final double winRate;
  final double averageWin;
  final double averageLoss;
  final double mathematicalExpectancy;
  final double riskRewardRatio;
  final double maxWin;
  final double maxLoss;
  final double maxDrawdown;
  final double maxDrawdownPercent;
  final List<double> cumulativePnl;
  final List<DateTime> cumulativePnlTimes;

  const PnlSummary({
    required this.totalPnl,
    required this.winRate,
    required this.averageWin,
    required this.averageLoss,
    required this.mathematicalExpectancy,
    required this.riskRewardRatio,
    required this.maxWin,
    required this.maxLoss,
    required this.maxDrawdown,
    required this.maxDrawdownPercent,
    required this.cumulativePnl,
    required this.cumulativePnlTimes,
  });

  factory PnlSummary.empty() => const PnlSummary(
        totalPnl: 0,
        winRate: 0,
        averageWin: 0,
        averageLoss: 0,
        mathematicalExpectancy: 0,
        riskRewardRatio: 0,
        maxWin: 0,
        maxLoss: 0,
        maxDrawdown: 0,
        maxDrawdownPercent: 0,
        cumulativePnl: [],
        cumulativePnlTimes: [],
      );
}

class PnlMetrics {
  static PnlSummary? _cachedSummary;
  static String? _cachedKey;

  PnlSummary compute(List<Fill> fills) {
    final key = _fingerprint(fills);
    if (key == _cachedKey && _cachedSummary != null) return _cachedSummary!;

    final result = _computeInternal(fills);
    _cachedKey = key;
    _cachedSummary = result;
    return result;
  }

  String _fingerprint(List<Fill> fills) {
    if (fills.isEmpty) return '0';
    return '${fills.length}-${fills.first.tid}-${fills.last.tid}';
  }

  PnlSummary _computeInternal(List<Fill> fills) {
    final closed = fills.where((fill) => fill.closedPnl != 0).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    if (closed.isEmpty) return PnlSummary.empty();

    final wins = closed.where((fill) => fill.closedPnl > 0).toList();
    final losses = closed.where((fill) => fill.closedPnl < 0).toList();

    final totalPnl =
        closed.fold<double>(0, (sum, fill) => sum + fill.closedPnl);
    final winRate = wins.length / closed.length;

    final averageWin = wins.isEmpty
        ? 0.0
        : wins.fold<double>(0, (sum, fill) => sum + fill.closedPnl) /
            wins.length;

    final averageLoss = losses.isEmpty
        ? 0.0
        : losses.fold<double>(0, (sum, fill) => sum + fill.closedPnl) /
            losses.length;

    final riskRewardRatio =
        averageLoss == 0 ? 0.0 : (averageWin / averageLoss.abs());

    final mathematicalExpectancy =
        (winRate * averageWin) - ((1 - winRate) * averageLoss.abs());

    final maxWin = wins.isEmpty
        ? 0.0
        : wins.map((fill) => fill.closedPnl).reduce((a, b) => a > b ? a : b);

    final maxLoss = losses.isEmpty
        ? 0.0
        : losses.map((fill) => fill.closedPnl).reduce((a, b) => a < b ? a : b);

    final cumulative = <double>[];
    final cumulativeTimes = <DateTime>[];
    var running = 0.0;
    for (final fill in closed) {
      running += fill.closedPnl;
      cumulative.add(running);
      cumulativeTimes.add(fill.time);
    }

    var peak = 0.0;
    var maxDrawdown = 0.0;
    var maxDrawdownPercent = 0.0;
    for (final point in cumulative) {
      if (point > peak) peak = point;
      final drawdown = peak - point;
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
        maxDrawdownPercent = peak > 0 ? (drawdown / peak) * 100 : 0;
      }
    }

    return PnlSummary(
      totalPnl: totalPnl,
      winRate: winRate,
      averageWin: averageWin,
      averageLoss: averageLoss,
      mathematicalExpectancy: mathematicalExpectancy,
      riskRewardRatio: riskRewardRatio,
      maxWin: maxWin,
      maxLoss: maxLoss,
      maxDrawdown: maxDrawdown,
      maxDrawdownPercent: maxDrawdownPercent,
      cumulativePnl: cumulative,
      cumulativePnlTimes: cumulativeTimes,
    );
  }
}
