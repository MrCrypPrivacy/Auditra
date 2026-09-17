import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final controller = AppThemeScope.of(context);

    return IconButton(
      icon: Icon(Icons.palette_outlined, color: theme.textSecondary),
      tooltip: theme.name,
      onPressed: controller.cycle,
    );
  }
}
