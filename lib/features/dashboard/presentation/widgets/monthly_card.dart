import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/typography.dart';
import '../../../../l10n/generated/app_localizations.dart';

class MonthlyCard<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final DateTime Function(T item) dateOf;
  final Widget Function(BuildContext context, List<T> monthItems) builder;

  const MonthlyCard({
    super.key,
    required this.title,
    required this.items,
    required this.dateOf,
    required this.builder,
  });

  @override
  State<MonthlyCard<T>> createState() => _MonthlyCardState<T>();
}

class _MonthlyCardState<T> extends State<MonthlyCard<T>> {
  List<DateTime> _months = const [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _computeMonths();
  }

  @override
  void didUpdateWidget(covariant MonthlyCard<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _computeMonths();
    }
  }

  void _computeMonths() {
    final set = <DateTime>{};
    for (final item in widget.items) {
      final d = widget.dateOf(item).toLocal();
      set.add(DateTime(d.year, d.month));
    }
    final months = set.toList()..sort();
    setState(() {
      _months = months;
      _index = months.isEmpty ? 0 : months.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    Widget body;
    String monthLabel = '';
    bool canPrev = false;
    bool canNext = false;

    if (_months.isEmpty) {
      body = Center(
        child: Text(l10n.noDataLabel, style: AppTypography.caption.copyWith(color: theme.textSecondary)),
      );
    } else {
      final month = _months[_index];
      monthLabel = DateFormat.yMMMM(locale).format(month);
      canPrev = _index > 0;
      canNext = _index < _months.length - 1;
      final monthItems = widget.items.where((item) {
        final d = widget.dateOf(item).toLocal();
        return d.year == month.year && d.month == month.month;
      }).toList();
      body = widget.builder(context, monthItems);
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: AppTypography.title.copyWith(color: theme.textPrimary)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    iconSize: 18,
                    color: canPrev ? theme.textPrimary : theme.textSecondary.withOpacity(0.3),
                    onPressed: canPrev ? () => setState(() => _index--) : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(color: theme.textSecondary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    iconSize: 18,
                    color: canNext ? theme.textPrimary : theme.textSecondary.withOpacity(0.3),
                    onPressed: canNext ? () => setState(() => _index++) : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: body),
        ],
      ),
    );
  }
}
