import '../domain/fill.dart';

class TraderProfile {
  final double scalperPercent;
  final double dayTraderPercent;
  final double swingPercent;
  final Duration averageDuration;
  final Duration longestDuration;
  final Duration shortestDuration;

  const TraderProfile({
    required this.scalperPercent,
    required this.dayTraderPercent,
    required this.swingPercent,
    required this.averageDuration,
    required this.longestDuration,
    required this.shortestDuration,
  });

  factory TraderProfile.empty() => const TraderProfile(
        scalperPercent: 0,
        dayTraderPercent: 0,
        swingPercent: 0,
        averageDuration: Duration.zero,
        longestDuration: Duration.zero,
        shortestDuration: Duration.zero,
      );
}

class Streak {
  final int length;
  final double netPnl;

  const Streak({required this.length, required this.netPnl});

  factory Streak.empty() => const Streak(length: 0, netPnl: 0);
}

class PairStat {
  final String coin;
  final int tradeCount;
  final double pnl;

  const PairStat({required this.coin, required this.tradeCount, required this.pnl});
}

class SizeBucketStat {
  final String label;
  final int count;
  final double winRate;
  final double avgPnl;

  const SizeBucketStat({
    required this.label,
    required this.count,
    required this.winRate,
    required this.avgPnl,
  });
}

class BehaviorSummary {
  final TraderProfile traderProfile;
  final Streak longestWinStreak;
  final Streak longestLossStreak;
  final double averageWinStreak;
  final double averageLossStreak;
  final double recoveryRate;
  final List<PairStat> mostTraded;
  final List<PairStat> mostProfitable;
  final List<PairStat> leastProfitable;
  final List<SizeBucketStat> sizeCorrelation;

  const BehaviorSummary({
    required this.traderProfile,
    required this.longestWinStreak,
    required this.longestLossStreak,
    required this.averageWinStreak,
    required this.averageLossStreak,
    required this.recoveryRate,
    required this.mostTraded,
    required this.mostProfitable,
    required this.leastProfitable,
    required this.sizeCorrelation,
  });

  factory BehaviorSummary.empty() => BehaviorSummary(
        traderProfile: TraderProfile.empty(),
        longestWinStreak: Streak.empty(),
        longestLossStreak: Streak.empty(),
        averageWinStreak: 0,
        averageLossStreak: 0,
        recoveryRate: 0,
        mostTraded: const [],
        mostProfitable: const [],
        leastProfitable: const [],
        sizeCorrelation: const [],
      );
}

class BehaviorMetrics {
  static BehaviorSummary? _cachedSummary;
  static String? _cachedKey;

  BehaviorSummary compute(List<Fill> fills) {
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

  BehaviorSummary _computeInternal(List<Fill> fills) {
    if (fills.isEmpty) return BehaviorSummary.empty();

    final sorted = [...fills]..sort((a, b) => a.time.compareTo(b.time));
    final closed = sorted.where((f) => f.closedPnl != 0).toList();

    return BehaviorSummary(
      traderProfile: _computeTraderProfile(sorted),
      longestWinStreak: _longestStreak(closed, wins: true),
      longestLossStreak: _longestStreak(closed, wins: false),
      averageWinStreak: _averageStreakLength(closed, wins: true),
      averageLossStreak: _averageStreakLength(closed, wins: false),
      recoveryRate: _recoveryRate(closed),
      mostTraded: _mostTraded(closed),
      mostProfitable: _rankedByPnl(closed, ascending: false),
      leastProfitable: _rankedByPnl(closed, ascending: true),
      sizeCorrelation: _sizeCorrelation(closed),
    );
  }

  List<SizeBucketStat> _sizeCorrelation(List<Fill> closed) {
    if (closed.length < 3) return [];

    final bySize = [...closed]..sort((a, b) => a.size.compareTo(b.size));
    final chunkSize = (bySize.length / 3).ceil();

    final chunks = [
      bySize.take(chunkSize).toList(),
      bySize.skip(chunkSize).take(chunkSize).toList(),
      bySize.skip(chunkSize * 2).toList(),
    ];
    final labels = ['small', 'medium', 'large'];

    final result = <SizeBucketStat>[];
    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      if (chunk.isEmpty) continue;
      final wins = chunk.where((f) => f.closedPnl > 0).length;
      final avgPnl = chunk.fold<double>(0, (sum, f) => sum + f.closedPnl) / chunk.length;
      result.add(SizeBucketStat(
        label: labels[i],
        count: chunk.length,
        winRate: wins / chunk.length,
        avgPnl: avgPnl,
      ));
    }
    return result;
  }

  // Duration is computed by tracking, per coin, the exact net position size
  // after each fill (using Hyperliquid's own `startPosition` field). A
  // position "opens" when it moves away from zero and "closes" when it
  // returns to zero — compared with a small epsilon rather than exact
  // equality, since decimal parsing can leave tiny floating-point residue
  // (e.g. 0.00000000003 instead of exactly 0.0).
  static const _flatThreshold = 1e-6;

  TraderProfile _computeTraderProfile(List<Fill> sorted) {
    final openTime = <String, DateTime>{};
    final durations = <Duration>[];

    for (final fill in sorted) {
      final wasFlat = fill.startPosition.abs() < _flatThreshold;
      final isFlatAfter = fill.positionAfter.abs() < _flatThreshold;

      if (wasFlat && !isFlatAfter) {
        openTime.putIfAbsent(fill.coin, () => fill.time);
      }

      if (!wasFlat && isFlatAfter) {
        final start = openTime[fill.coin];
        if (start != null) {
          durations.add(fill.time.difference(start));
          openTime.remove(fill.coin);
        }
      }
    }

    if (durations.isEmpty) return TraderProfile.empty();

    final scalper = durations.where((d) => d.inMinutes < 5).length;
    final dayTrader = durations.where((d) => d.inMinutes >= 5 && d.inHours < 4).length;
    final swing = durations.where((d) => d.inHours >= 4).length;
    final total = durations.length;

    final totalMicroseconds = durations.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
    final average = Duration(microseconds: totalMicroseconds ~/ total);
    final longest = durations.reduce((a, b) => a > b ? a : b);
    final shortest = durations.reduce((a, b) => a < b ? a : b);

    return TraderProfile(
      scalperPercent: scalper / total,
      dayTraderPercent: dayTrader / total,
      swingPercent: swing / total,
      averageDuration: average,
      longestDuration: longest,
      shortestDuration: shortest,
    );
  }

  Streak _longestStreak(List<Fill> closed, {required bool wins}) {
    var bestLength = 0;
    var bestPnl = 0.0;
    var currentLength = 0;
    var currentPnl = 0.0;

    for (final fill in closed) {
      final isMatch = wins ? fill.closedPnl > 0 : fill.closedPnl < 0;
      if (isMatch) {
        currentLength++;
        currentPnl += fill.closedPnl;
        if (currentLength > bestLength) {
          bestLength = currentLength;
          bestPnl = currentPnl;
        }
      } else {
        currentLength = 0;
        currentPnl = 0;
      }
    }

    return Streak(length: bestLength, netPnl: bestPnl);
  }

  double _averageStreakLength(List<Fill> closed, {required bool wins}) {
    final streakLengths = <int>[];
    var currentLength = 0;

    for (final fill in closed) {
      final isMatch = wins ? fill.closedPnl > 0 : fill.closedPnl < 0;
      if (isMatch) {
        currentLength++;
      } else {
        if (currentLength > 0) streakLengths.add(currentLength);
        currentLength = 0;
      }
    }
    if (currentLength > 0) streakLengths.add(currentLength);

    if (streakLengths.isEmpty) return 0;
    return streakLengths.reduce((a, b) => a + b) / streakLengths.length;
  }

  // Percentage of trades that come right after a loss and turn out to be
  // winners — how often the trader "bounces back" from a losing trade.
  double _recoveryRate(List<Fill> closed) {
    var afterLoss = 0;
    var recovered = 0;

    for (var i = 1; i < closed.length; i++) {
      if (closed[i - 1].closedPnl < 0) {
        afterLoss++;
        if (closed[i].closedPnl > 0) recovered++;
      }
    }

    if (afterLoss == 0) return 0;
    return recovered / afterLoss;
  }

  Map<String, PairStat> _groupByCoin(List<Fill> closed) {
    final counts = <String, int>{};
    final pnls = <String, double>{};

    for (final fill in closed) {
      counts[fill.coin] = (counts[fill.coin] ?? 0) + 1;
      pnls[fill.coin] = (pnls[fill.coin] ?? 0) + fill.closedPnl;
    }

    return {
      for (final coin in counts.keys)
        coin: PairStat(coin: coin, tradeCount: counts[coin]!, pnl: pnls[coin]!),
    };
  }

  List<PairStat> _mostTraded(List<Fill> closed) {
    final grouped = _groupByCoin(closed).values.toList()
      ..sort((a, b) => b.tradeCount.compareTo(a.tradeCount));
    return grouped.take(5).toList();
  }

  List<PairStat> _rankedByPnl(List<Fill> closed, {required bool ascending}) {
    final grouped = _groupByCoin(closed).values.toList()
      ..sort((a, b) => ascending ? a.pnl.compareTo(b.pnl) : b.pnl.compareTo(a.pnl));
    return grouped.take(5).toList();
  }
}
