import '../../features/dashboard/domain/fill.dart';

enum Period { all, today, week, month, year }

class PeriodFilter {
  static List<Fill> apply(List<Fill> fills, Period period) {
    if (period == Period.all) return fills;

    final now = DateTime.now();
    late DateTime cutoff;

    switch (period) {
      case Period.today:
        cutoff = DateTime(now.year, now.month, now.day);
        break;
      case Period.week:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case Period.month:
        cutoff = DateTime(now.year, now.month - 1, now.day);
        break;
      case Period.year:
        cutoff = DateTime(now.year - 1, now.month, now.day);
        break;
      case Period.all:
        return fills;
    }

    return fills.where((fill) => fill.time.toLocal().isAfter(cutoff)).toList();
  }
}
