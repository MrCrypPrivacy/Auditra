import 'package:flutter/material.dart';

import '../../core/l10n/locale_controller.dart';
import '../../core/theme/theme_controller.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final controller = AppLocaleScope.of(context);

    return PopupMenuButton<Locale>(
      tooltip: '',
      color: theme.surface,
      icon: Icon(Icons.language, color: theme.textSecondary),
      onSelected: controller.select,
      itemBuilder: (context) {
        return AppLocales.supported.map((locale) {
          return PopupMenuItem(
            value: locale,
            child: Text(
              AppLocales.nativeNames[locale.languageCode] ?? locale.languageCode,
              style: TextStyle(color: theme.textPrimary),
            ),
          );
        }).toList();
      },
    );
  }
}
