import '../domain/fill.dart';

class DailyActivity {
  final DateTime day;
  final int longs;
  final int shorts;
  final double winRate;
  final double pnl;

  const DailyActivity({
    required this.day,
    required this.longs,
    required this.shorts,
    required this.winRate,
    required this.pnl,
  });
}

class HourStat {
  final int hour;
  final int count;
  final double winRate;

  const HourStat({required this.hour, required this.count, required this.winRate});
}

class WeekdayStat {
  final int weekday;
  final int count;
  final double winRate;

  const WeekdayStat({required this.weekday, required this.count, required this.winRate});
}

class DirectionStat {
  final int count;
  final double winRate;
  final double pnl;

  const DirectionStat({required this.count, required this.winRate, required this.pnl});

  factory DirectionStat.empty() => const DirectionStat(count: 0, winRate: 0, pnl: 0);
}

class TimePatternSummary {
  final List<DailyActivity> dailyActivity;
  final List<HourStat> hourlyWinRate;
  final List<WeekdayStat> weekdayWinRate;
  final DirectionStat longStats;
  final DirectionStat shortStats;

  const TimePatternSummary({
    required this.dailyActivity,
    required this.hourlyWinRate,
    required this.weekdayWinRate,
    required this.longStats,
    required this.shortStats,
  });

  factory TimePatternSummary.empty() => TimePatternSummary(
        dailyActivity: const [],
        hourlyWinRate: const [],
        weekdayWinRate: const [],
        longStats: DirectionStat.empty(),
        shortStats: DirectionStat.empty(),
      );
}

class TimePatternMetrics {
  static TimePatternSummary? _cachedSummary;
  static String? _cachedKey;

  TimePatternSummary compute(List<Fill> fills) {
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

  TimePatternSummary _computeInternal(List<Fill> fills) {
    if (fills.isEmpty) return TimePatternSummary.empty();

    final byDay = <DateTime, List<Fill>>{};
    for (final fill in fills) {
      final local = fill.time.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      byDay.putIfAbsent(day, () => []).add(fill);
    }

    final days = byDay.keys.toList()..sort();
    final activity = days.map((day) {
      final dayFills = byDay[day]!;
      final longs = dayFills.where((f) => f.direction.contains('Long')).length;
      final shorts = dayFills.where((f) => f.direction.contains('Short')).length;

      final closed = dayFills.where((f) => f.closedPnl != 0).toList();
      final wins = closed.where((f) => f.closedPnl > 0).length;
      final winRate = closed.isEmpty ? 0.0 : wins / closed.length;

      final pnl = dayFills.fold<double>(0, (sum, f) => sum + f.closedPnl);

      return DailyActivity(day: day, longs: longs, shorts: shorts, winRate: winRate, pnl: pnl);
    }).toList();

    final closedFills = fills.where((f) => f.closedPnl != 0).toList();

    final byHour = <int, List<Fill>>{};
    final byWeekday = <int, List<Fill>>{};
    for (final fill in closedFills) {
      final local = fill.time.toLocal();
      byHour.putIfAbsent(local.hour, () => []).add(fill);
      byWeekday.putIfAbsent(local.weekday, () => []).add(fill);
    }

    final hourly = List.generate(24, (hour) {
      final hourFills = byHour[hour] ?? [];
      final wins = hourFills.where((f) => f.closedPnl > 0).length;
      final winRate = hourFills.isEmpty ? 0.0 : wins / hourFills.length;
      return HourStat(hour: hour, count: hourFills.length, winRate: winRate);
    });

    final weekday = List.generate(7, (index) {
      final day = index + 1;
      final dayFills = byWeekday[day] ?? [];
      final wins = dayFills.where((f) => f.closedPnl > 0).length;
      final winRate = dayFills.isEmpty ? 0.0 : wins / dayFills.length;
      return WeekdayStat(weekday: day, count: dayFills.length, winRate: winRate);
    });

    DirectionStat direction(bool Function(Fill) matcher) {
      final matched = closedFills.where(matcher).toList();
      if (matched.isEmpty) return DirectionStat.empty();
      final wins = matched.where((f) => f.closedPnl > 0).length;
      final pnl = matched.fold<double>(0, (sum, f) => sum + f.closedPnl);
      return DirectionStat(count: matched.length, winRate: wins / matched.length, pnl: pnl);
    }

    return TimePatternSummary(
      dailyActivity: activity,
      hourlyWinRate: hourly,
      weekdayWinRate: weekday,
      longStats: direction((f) => f.direction.contains('Long')),
      shortStats: direction((f) => f.direction.contains('Short')),
    );
  }
}
