import 'package:auditra/features/dashboard/application/behavior_metrics.dart';
import 'package:auditra/features/dashboard/domain/fill.dart';
import 'package:flutter_test/flutter_test.dart';

Fill _closedFill({
  required String tid,
  required double pnl,
  required DateTime time,
  String coin = 'BTC',
}) {
  return Fill(
    coin: coin,
    price: 60000,
    size: 0.1,
    side: 'A',
    direction: 'Close Long',
    time: time,
    closedPnl: pnl,
    fee: 0.5,
    feeToken: 'USDC',
    tid: tid,
    startPosition: 0.1,
  );
}

Fill _positionFill({
  required String tid,
  required String coin,
  required String side,
  required double size,
  required double startPosition,
  required DateTime time,
}) {
  return Fill(
    coin: coin,
    price: 100,
    size: size,
    side: side,
    direction: side == 'B' ? 'Open Long' : 'Close Long',
    time: time,
    closedPnl: 0,
    fee: 0,
    feeToken: 'USDC',
    tid: tid,
    startPosition: startPosition,
  );
}

void main() {
  group('BehaviorMetrics trader profile', () {
    test(
      'detects a closed position even when floating point leaves residue '
      'near zero (regression for the exact-equality flat-position bug)',
      () {
        // 0.1 + 0.2 famously does not equal exactly 0.3 in double precision.
        // Opening with two partial fills (0.1, then 0.2) and closing with a
        // clean 0.3 leaves startPosition/positionAfter a hair off zero —
        // this must still be detected as fully closed.
        final fills = [
          _positionFill(
            tid: 'open-1',
            coin: 'ETH',
            side: 'B',
            size: 0.1,
            startPosition: 0,
            time: DateTime(2026, 1, 1, 10, 0),
          ),
          _positionFill(
            tid: 'open-2',
            coin: 'ETH',
            side: 'B',
            size: 0.2,
            startPosition: 0.1,
            time: DateTime(2026, 1, 1, 10, 5),
          ),
          _positionFill(
            tid: 'close-1',
            coin: 'ETH',
            side: 'A',
            size: 0.3,
            startPosition: 0.1 + 0.2,
            time: DateTime(2026, 1, 1, 11, 0),
          ),
        ];

        final summary = BehaviorMetrics().compute(fills);

        expect(summary.traderProfile.longestDuration, isNot(Duration.zero));
        expect(summary.traderProfile.longestDuration, const Duration(hours: 1));
      },
    );
  });

  group('BehaviorMetrics streaks', () {
    test('finds the longest win and loss streaks with their net PnL', () {
      // win, win, loss, win, win, win, loss, loss
      final fills = [
        _closedFill(tid: 's1', pnl: 10, time: DateTime(2026, 1, 1)),
        _closedFill(tid: 's2', pnl: 10, time: DateTime(2026, 1, 2)),
        _closedFill(tid: 's3', pnl: -5, time: DateTime(2026, 1, 3)),
        _closedFill(tid: 's4', pnl: 20, time: DateTime(2026, 1, 4)),
        _closedFill(tid: 's5', pnl: 20, time: DateTime(2026, 1, 5)),
        _closedFill(tid: 's6', pnl: 20, time: DateTime(2026, 1, 6)),
        _closedFill(tid: 's7', pnl: -5, time: DateTime(2026, 1, 7)),
        _closedFill(tid: 's8', pnl: -5, time: DateTime(2026, 1, 8)),
      ];

      final summary = BehaviorMetrics().compute(fills);

      expect(summary.longestWinStreak.length, 3);
      expect(summary.longestWinStreak.netPnl, 60);
      expect(summary.longestLossStreak.length, 2);
      expect(summary.longestLossStreak.netPnl, -10);
      expect(summary.averageWinStreak, closeTo(2.5, 1e-9));
      expect(summary.averageLossStreak, closeTo(1.5, 1e-9));
    });

    test('ranks pairs by trade count and by PnL', () {
      final fills = [
        _closedFill(tid: 'p1', pnl: 10, time: DateTime(2026, 1, 1), coin: 'BTC'),
        _closedFill(tid: 'p2', pnl: -30, time: DateTime(2026, 1, 2), coin: 'BTC'),
        _closedFill(tid: 'p3', pnl: 100, time: DateTime(2026, 1, 3), coin: 'ETH'),
      ];

      final summary = BehaviorMetrics().compute(fills);

      expect(summary.mostTraded.first.coin, 'BTC');
      expect(summary.mostTraded.first.tradeCount, 2);
      expect(summary.mostProfitable.first.coin, 'ETH');
      expect(summary.leastProfitable.first.coin, 'BTC');
      expect(summary.leastProfitable.first.pnl, -20);
    });

    test('returns an empty summary for an empty fill list', () {
      final summary = BehaviorMetrics().compute(const []);

      expect(summary.longestWinStreak.length, 0);
      expect(summary.mostTraded, isEmpty);
    });
  });
}
