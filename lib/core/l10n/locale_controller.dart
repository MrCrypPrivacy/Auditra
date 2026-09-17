import 'package:flutter/material.dart';

class AppLocales {
  static const supported = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('it'),
    Locale('pt'),
    Locale('ru'),
    Locale('ar'),
    Locale('zh'),
    Locale('ja'),
  ];

  static const nativeNames = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'ar': 'العربية',
    'zh': '中文',
    'ja': '日本語',
  };
}

class LocaleController extends ValueNotifier<Locale> {
  LocaleController(super.initial);

  void select(Locale locale) => value = locale;
}

class AppLocaleScope extends InheritedNotifier<LocaleController> {
  const AppLocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope not found in context');
    return scope!.notifier!;
  }
}
