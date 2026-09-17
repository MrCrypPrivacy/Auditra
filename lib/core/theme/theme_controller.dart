import 'package:flutter/material.dart';

import 'app_theme.dart';

class ThemeController extends ValueNotifier<AppTheme> {
  ThemeController(super.initial);

  void select(AppTheme theme) => value = theme;

  void cycle() {
    final currentIndex = AppTheme.all.indexOf(value);
    final nextIndex = (currentIndex + 1) % AppTheme.all.length;
    value = AppTheme.all[nextIndex];
  }
}

class AppThemeScope extends InheritedNotifier<ThemeController> {
  const AppThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope not found in context');
    return scope!.notifier!;
  }

  static AppTheme themeOf(BuildContext context) => of(context).value;
}
