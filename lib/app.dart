import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/locale_controller.dart';
import 'core/storage/app_prefs_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/onboarding/presentation/launch_decider.dart';
import 'l10n/generated/app_localizations.dart';
import 'shared/widgets/app_title_bar.dart';

class AuditraApp extends StatefulWidget {
  const AuditraApp({super.key});

  @override
  State<AuditraApp> createState() => _AuditraAppState();
}

class _AuditraAppState extends State<AuditraApp> {
  final _themeController = ThemeController(AppTheme.brand);
  final _localeController = LocaleController(const Locale('en'));
  final _prefsStore = AppPrefsStore();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _themeController.addListener(_savePrefs);
    _localeController.addListener(_savePrefs);
  }

  Future<void> _loadPrefs() async {
    final prefs = await _prefsStore.load();

    final themeName = prefs['theme'] as String?;
    if (themeName != null) {
      final match = AppTheme.all.where((t) => t.name == themeName);
      if (match.isNotEmpty) _themeController.select(match.first);
    }

    final localeCode = prefs['locale'] as String?;
    if (localeCode != null) {
      _localeController.select(Locale(localeCode));
    }
  }

  void _savePrefs() {
    _prefsStore.save({
      'theme': _themeController.value.name,
      'locale': _localeController.value.languageCode,
    });
  }

  @override
  void dispose() {
    _themeController.removeListener(_savePrefs);
    _localeController.removeListener(_savePrefs);
    _themeController.dispose();
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      controller: _themeController,
      child: AppLocaleScope(
        controller: _localeController,
        child: AnimatedBuilder(
          animation: Listenable.merge([_themeController, _localeController]),
          builder: (context, _) {
            final theme = _themeController.value;
            return MaterialApp(
              title: 'Auditra',
              debugShowCheckedModeBanner: false,
              theme: ThemeData.dark().copyWith(
                scaffoldBackgroundColor: theme.background,
              ),
              locale: _localeController.value,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocales.supported,
              builder: (context, child) {
                return Column(
                  children: [
                    const AppTitleBar(),
                    Expanded(child: child ?? const SizedBox.shrink()),
                  ],
                );
              },
              home: const LaunchDecider(),
            );
          },
        ),
      ),
    );
  }
}
