import 'package:auditra/features/dashboard/application/pnl_metrics.dart';
import 'package:auditra/features/dashboard/domain/fill.dart';
import 'package:flutter_test/flutter_test.dart';

Fill _closedFill({required String tid, required double pnl, required DateTime time}) {
  return Fill(
    coin: 'BTC',
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

void main() {
  group('PnlMetrics', () {
    test('computes totals, win rate, expectancy and risk/reward', () {
      final fills = [
        _closedFill(tid: 'pnl-1', pnl: 100, time: DateTime(2026, 1, 1)),
        _closedFill(tid: 'pnl-2', pnl: -50, time: DateTime(2026, 1, 2)),
        _closedFill(tid: 'pnl-3', pnl: 50, time: DateTime(2026, 1, 3)),
      ];

      final summary = PnlMetrics().compute(fills);

      expect(summary.totalPnl, 100);
      expect(summary.winRate, closeTo(2 / 3, 1e-9));
      expect(summary.averageWin, 75);
      expect(summary.averageLoss, -50);
      expect(summary.maxWin, 100);
      expect(summary.maxLoss, -50);
      expect(summary.riskRewardRatio, closeTo(1.5, 1e-9));
      expect(summary.mathematicalExpectancy, closeTo(33.333, 0.01));
    });

    test('computes max drawdown from the peak of the cumulative curve', () {
      final fills = [
        _closedFill(tid: 'dd-1', pnl: 100, time: DateTime(2026, 2, 1)),
        _closedFill(tid: 'dd-2', pnl: -50, time: DateTime(2026, 2, 2)),
        _closedFill(tid: 'dd-3', pnl: 50, time: DateTime(2026, 2, 3)),
      ];

      final summary = PnlMetrics().compute(fills);

      expect(summary.maxDrawdown, 50);
      expect(summary.maxDrawdownPercent, closeTo(50, 1e-9));
    });

    test('ignores fills with zero closedPnl (order-opening fills)', () {
      final fills = [
        Fill(
          coin: 'ETH',
          price: 3000,
          size: 1,
          side: 'B',
          direction: 'Open Long',
          time: DateTime(2026, 3, 1),
          closedPnl: 0,
          fee: 0.1,
          feeToken: 'USDC',
          tid: 'open-1',
          startPosition: 0,
        ),
        _closedFill(tid: 'close-1', pnl: 20, time: DateTime(2026, 3, 2)),
      ];

      final summary = PnlMetrics().compute(fills);

      expect(summary.totalPnl, 20);
      expect(summary.winRate, 1);
    });

    test('returns an empty summary for an empty fill list', () {
      final summary = PnlMetrics().compute(const []);

      expect(summary.totalPnl, 0);
      expect(summary.winRate, 0);
      expect(summary.cumulativePnl, isEmpty);
    });
  });
}
