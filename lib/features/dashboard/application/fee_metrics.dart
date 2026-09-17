import '../domain/fill.dart';

class MonthlyStat {
  final int year;
  final int month;
  final double pnl;
  final double winRate;

  const MonthlyStat({
    required this.year,
    required this.month,
    required this.pnl,
    required this.winRate,
  });
}

class DailyFeeStat {
  final DateTime day;
  final double fee;

  const DailyFeeStat({required this.day, required this.fee});
}

class DailyFeeRatioStat {
  final DateTime day;
  final double ratio;

  const DailyFeeRatioStat({required this.day, required this.ratio});
}

class FeeSummary {
  final double totalFees;
  final double feeRatio;
  final List<double> cumulativeFees;
  final List<DateTime> cumulativeFeeTimes;
  final List<DailyFeeStat> dailyFees;
  final List<DailyFeeRatioStat> dailyFeeRatio;
  final List<MonthlyStat> monthly;

  const FeeSummary({
    required this.totalFees,
    required this.feeRatio,
    required this.cumulativeFees,
    required this.cumulativeFeeTimes,
    required this.dailyFees,
    required this.dailyFeeRatio,
    required this.monthly,
  });

  factory FeeSummary.empty() => const FeeSummary(
        totalFees: 0,
        feeRatio: 0,
        cumulativeFees: [],
        cumulativeFeeTimes: [],
        dailyFees: [],
        dailyFeeRatio: [],
        monthly: [],
      );
}

class FeeMetrics {
  static FeeSummary? _cachedSummary;
  static String? _cachedKey;

  FeeSummary compute(List<Fill> fills) {
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

  FeeSummary _computeInternal(List<Fill> fills) {
    if (fills.isEmpty) return FeeSummary.empty();

    final sorted = [...fills]..sort((a, b) => a.time.compareTo(b.time));
    final totalFees = sorted.fold<double>(0, (sum, f) => sum + f.fee);

    final closed = sorted.where((f) => f.closedPnl != 0).toList();
    final totalPnl = closed.fold<double>(0, (sum, f) => sum + f.closedPnl);
    final feeRatio = totalFees == 0 ? 0.0 : totalPnl / totalFees;

    final cumulative = <double>[];
    final cumulativeTimes = <DateTime>[];
    var running = 0.0;
    for (final f in sorted) {
      running += f.fee;
      cumulative.add(running);
      cumulativeTimes.add(f.time);
    }

    final byDay = <DateTime, double>{};
    for (final f in sorted) {
      final local = f.time.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      byDay[day] = (byDay[day] ?? 0) + f.fee;
    }
    final dailyDays = byDay.keys.toList()..sort();
    final dailyFees = dailyDays.map((d) => DailyFeeStat(day: d, fee: byDay[d]!)).toList();

    final pnlByDay = <DateTime, double>{};
    for (final f in closed) {
      final local = f.time.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      pnlByDay[day] = (pnlByDay[day] ?? 0) + f.closedPnl;
    }
    final dailyFeeRatio = dailyDays.map((d) {
      final fee = byDay[d]!;
      final pnl = pnlByDay[d] ?? 0;
      return DailyFeeRatioStat(day: d, ratio: fee == 0 ? 0.0 : pnl / fee);
    }).toList();

    final byMonth = <String, List<Fill>>{};
    for (final f in closed) {
      final local = f.time.toLocal();
      final key = '${local.year}-${local.month}';
      byMonth.putIfAbsent(key, () => []).add(f);
    }

    final monthly = byMonth.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final monthFills = entry.value;
      final pnl = monthFills.fold<double>(0, (sum, f) => sum + f.closedPnl);
      final wins = monthFills.where((f) => f.closedPnl > 0).length;
      final winRate = monthFills.isEmpty ? 0.0 : wins / monthFills.length;
      return MonthlyStat(year: year, month: month, pnl: pnl, winRate: winRate);
    }).toList()
      ..sort((a, b) {
        if (a.year != b.year) return b.year.compareTo(a.year);
        return b.month.compareTo(a.month);
      });

    return FeeSummary(
      totalFees: totalFees,
      feeRatio: feeRatio,
      cumulativeFees: cumulative,
      cumulativeFeeTimes: cumulativeTimes,
      dailyFees: dailyFees,
      dailyFeeRatio: dailyFeeRatio,
      monthly: monthly,
    );
  }
}
