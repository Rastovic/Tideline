import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/ads.dart';
import '../data/app_database.dart';
import '../l10n/app_language.dart';
import '../data/app_lock.dart';
import '../data/evening_reminder.dart';
import '../data/patterns_controller.dart';
import '../data/quick_log_widget.dart';
import '../onboarding/onboarding.dart';
import '../onboarding/tour_banner.dart';
import '../screens/app_lock_gate.dart';
import 'tideline_themes.dart';
import '../screens/home_screen.dart';

/// The app shell: language, theme, lock, and home.
class PatternsApp extends StatelessWidget {
  const PatternsApp({
    required this.controller,
    required this.reminder,
    required this.settings,
    this.lock,
    this.quickLog,
    required this.language,
    this.theme,
    this.onboarding,
    this.ads,
    super.key,
  });

  /// Banners under Settings and the marker list. Null shows none, as in tests.
  final AdsController? ads;

  /// The first-run welcome and tour. Null skips it, as in most tests.
  final Onboarding? onboarding;

  /// Null uses Tide, following the system for light and dark.
  final ValueNotifier<ThemeChoice>? theme;

  /// Null leaves the app unlocked, for tests of everything else.
  final AppLock? lock;

  final QuickLogWidget? quickLog;

  /// Held here rather than in a screen, so changing it in Settings redraws
  /// the whole app - including the screens already on the stack.
  final ValueNotifier<AppLanguage> language;

  final PatternsController controller;
  final EveningReminder reminder;
  final ReminderSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? ValueNotifier(const ThemeChoice());
    return ValueListenableBuilder(
      valueListenable: language,
      builder: (context, current, _) => ValueListenableBuilder(
        valueListenable: theme,
        builder: (context, choice, _) => ThemeScope(
          choice: theme,
          child: LanguageScope(
            language: language,
            child: _app(current, choice),
          ),
        ),
      ),
    );
  }

  Widget _app(AppLanguage current, ThemeChoice choice) => MaterialApp(
    title: 'Patterns',
    debugShowCheckedModeBanner: false,
    // The pickers and the system widgets follow the same choice.
    locale: Locale(current.code),
    supportedLocales: const [Locale('en'), Locale('sr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: choice.theme.data(Brightness.light),
    darkTheme: choice.theme.data(Brightness.dark),
    themeMode: choice.mode,
    navigatorKey: onboarding?.navigatorKey,
    builder: (context, child) {
      final framed = switch (onboarding) {
        final onboarding? => TourFrame(onboarding: onboarding, child: child!),
        null => child!,
      };
      final locked = switch (lock) {
        final lock? => AppLockGate(lock: lock, child: framed),
        null => framed,
      };
      return switch (ads) {
        final ads? => AdsScope(ads: ads, child: locked),
        null => locked,
      };
    },
    home: HomeScreen(
      controller: controller,
      reminder: reminder,
      initialSettings: settings,
      lock: lock,
      quickLog: quickLog,
    ),
  );
}
