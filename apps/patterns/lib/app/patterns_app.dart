import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/app_database.dart';
import '../l10n/app_language.dart';
import '../data/app_lock.dart';
import '../data/evening_reminder.dart';
import '../data/patterns_controller.dart';
import '../data/quick_log_widget.dart';
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
    super.key,
  });

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
        builder: (context, child) => switch (lock) {
          final lock? => AppLockGate(lock: lock, child: child!),
          null => child!,
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
