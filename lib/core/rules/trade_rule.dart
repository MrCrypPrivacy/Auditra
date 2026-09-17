import '../../features/dashboard/domain/fill.dart';
import '../../l10n/generated/app_localizations.dart';

enum RuleType { noTradingWeekday, maxTradesPerDay, noTradingHourRange }

class TradeRule {
  final String id;
  final RuleType type;
  final Map<String, dynamic> params;

  const TradeRule({required this.id, required this.type, required this.params});

  factory TradeRule.fromJson(Map<String, dynamic> json) {
    return TradeRule(
      id: json['id'] as String,
      type: RuleType.values.firstWhere((t) => t.name == json['type']),
      params: Map<String, dynamic>.from(json['params'] as Map),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'params': params,
      };

  String describe(AppLocalizations l10n) {
    switch (type) {
      case RuleType.noTradingWeekday:
        final weekdayNames = [
          l10n.weekdayMon, l10n.weekdayTue, l10n.weekdayWed, l10n.weekdayThu,
          l10n.weekdayFri, l10n.weekdaySat, l10n.weekdaySun,
        ];
        final weekday = params['weekday'] as int;
        return '${l10n.noTradingOnPrefix} ${weekdayNames[weekday - 1]}';
      case RuleType.maxTradesPerDay:
        return '${l10n.maxTradesPrefix} ${params['max']} ${l10n.tradesPerDaySuffix}';
      case RuleType.noTradingHourRange:
        return '${l10n.noTradingHourPrefix} ${params['startHour']}:00-${params['endHour']}:00';
    }
  }
}

class RuleBreach {
  final TradeRule rule;
  final DateTime date;
  final String detail;

  const RuleBreach({required this.rule, required this.date, required this.detail});
}

class RuleEvaluator {
  List<RuleBreach> evaluate(List<TradeRule> rules, List<Fill> fills) {
    final breaches = <RuleBreach>[];

    for (final rule in rules) {
      switch (rule.type) {
        case RuleType.noTradingWeekday:
          final weekday = rule.params['weekday'] as int;
          for (final fill in fills) {
            final local = fill.time.toLocal();
            if (local.weekday == weekday) {
              breaches.add(RuleBreach(
                rule: rule,
                date: local,
                detail: '${fill.coin} at ${local.hour}:${local.minute.toString().padLeft(2, '0')}',
              ));
            }
          }
          break;

        case RuleType.maxTradesPerDay:
          final max = rule.params['max'] as int;
          final byDay = <String, List<Fill>>{};
          for (final fill in fills) {
            final local = fill.time.toLocal();
            final key = '${local.year}-${local.month}-${local.day}';
            byDay.putIfAbsent(key, () => []).add(fill);
          }
          byDay.forEach((day, dayFills) {
            if (dayFills.length > max) {
              breaches.add(RuleBreach(
                rule: rule,
                date: dayFills.first.time.toLocal(),
                detail: '${dayFills.length} trades on $day',
              ));
            }
          });
          break;

        case RuleType.noTradingHourRange:
          final start = rule.params['startHour'] as int;
          final end = rule.params['endHour'] as int;
          for (final fill in fills) {
            final local = fill.time.toLocal();
            final inRange = start <= end
                ? (local.hour >= start && local.hour < end)
                : (local.hour >= start || local.hour < end);
            if (inRange) {
              breaches.add(RuleBreach(
                rule: rule,
                date: local,
                detail: '${fill.coin} at ${local.hour}:${local.minute.toString().padLeft(2, '0')}',
              ));
            }
          }
          break;
      }
    }

    breaches.sort((a, b) => b.date.compareTo(a.date));
    return breaches;
  }
}
