import 'package:flutter/material.dart';

import '../../../core/rules/trade_rule.dart';
import '../../../core/storage/rules_local_store.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/fill.dart';

class RulesScreen extends StatefulWidget {
  final String address;
  final List<Fill> fills;

  const RulesScreen({super.key, required this.address, required this.fills});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  late final RulesLocalStore _store = RulesLocalStore(widget.address);
  List<TradeRule> _rules = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rules = await _store.loadAll();
    if (mounted) setState(() => _rules = rules);
  }

  Future<void> _addRule(BuildContext context) async {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;
    RuleType selectedType = RuleType.noTradingWeekday;
    int weekday = 6;
    int maxTrades = 5;
    int startHour = 0;
    int endHour = 6;

    final weekdayItems = [
      MapEntry(1, l10n.weekdayMon),
      MapEntry(2, l10n.weekdayTue),
      MapEntry(3, l10n.weekdayWed),
      MapEntry(4, l10n.weekdayThu),
      MapEntry(5, l10n.weekdayFri),
      MapEntry(6, l10n.weekdaySat),
      MapEntry(7, l10n.weekdaySun),
    ];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.surface,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<RuleType>(
                    value: selectedType,
                    dropdownColor: theme.surface,
                    isExpanded: true,
                    style: TextStyle(color: theme.textPrimary),
                    items: [
                      DropdownMenuItem(value: RuleType.noTradingWeekday, child: Text(l10n.ruleTypeWeekday)),
                      DropdownMenuItem(value: RuleType.maxTradesPerDay, child: Text(l10n.ruleTypeMaxTrades)),
                      DropdownMenuItem(value: RuleType.noTradingHourRange, child: Text(l10n.ruleTypeHourRange)),
                    ],
                    onChanged: (value) => setDialogState(() => selectedType = value!),
                  ),
                  const SizedBox(height: 16),
                  if (selectedType == RuleType.noTradingWeekday)
                    DropdownButton<int>(
                      value: weekday,
                      dropdownColor: theme.surface,
                      isExpanded: true,
                      style: TextStyle(color: theme.textPrimary),
                      items: weekdayItems
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => weekday = value!),
                    ),
                  if (selectedType == RuleType.maxTradesPerDay)
                    TextField(
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.textPrimary),
                      decoration: InputDecoration(labelText: l10n.maxTradesFieldLabel),
                      onChanged: (value) => maxTrades = int.tryParse(value) ?? maxTrades,
                    ),
                  if (selectedType == RuleType.noTradingHourRange)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: theme.textPrimary),
                            decoration: InputDecoration(labelText: l10n.startHourFieldLabel),
                            onChanged: (value) => startHour = int.tryParse(value) ?? startHour,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: theme.textPrimary),
                            decoration: InputDecoration(labelText: l10n.endHourFieldLabel),
                            onChanged: (value) => endHour = int.tryParse(value) ?? endHour,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final params = switch (selectedType) {
                      RuleType.noTradingWeekday => {'weekday': weekday},
                      RuleType.maxTradesPerDay => {'max': maxTrades},
                      RuleType.noTradingHourRange => {'startHour': startHour, 'endHour': endHour},
                    };
                    await _store.add(TradeRule(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      type: selectedType,
                      params: params,
                    ));
                    await _load();
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  child: Text(l10n.saveButton, style: TextStyle(color: theme.accent)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;
    final breaches = RuleEvaluator().evaluate(_rules, widget.fills);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.rulesTitle, style: AppTypography.display.copyWith(color: theme.textPrimary)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addRule(context),
                icon: Icon(Icons.add, color: theme.accent),
                label: Text(l10n.addRuleButton, style: TextStyle(color: theme.accent)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_rules.isEmpty)
            Text(l10n.noRulesYet, style: AppTypography.body.copyWith(color: theme.textSecondary))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _rules.map((rule) {
                return Chip(
                  backgroundColor: theme.surface,
                  label: Text(rule.describe(l10n), style: TextStyle(color: theme.textPrimary)),
                  deleteIcon: Icon(Icons.close, size: 16, color: theme.textSecondary),
                  onDeleted: () async {
                    await _store.remove(rule.id);
                    await _load();
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          Text(
            '${l10n.ruleBreachesLabel} (${breaches.length})',
            style: AppTypography.title.copyWith(color: theme.textPrimary),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: breaches.length,
              separatorBuilder: (_, __) => Divider(color: theme.border, height: 1),
              itemBuilder: (context, index) {
                final breach = breaches[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.warning_amber_rounded, color: theme.negative, size: 18),
                  title: Text(breach.rule.describe(l10n), style: AppTypography.body.copyWith(color: theme.textPrimary)),
                  subtitle: Text(breach.detail, style: AppTypography.caption.copyWith(color: theme.textSecondary)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
