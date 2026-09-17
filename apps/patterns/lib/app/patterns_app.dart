import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/app_database.dart';
import '../l10n/app_language.dart';
import '../data/app_lock.dart';
import '../data/evening_reminder.dart';
import '../data/patterns_controller.dart';
import '../data/quick_log_widget.dart';
import '../screens/app_lock_gate.dart';
import '../screens/home_screen.dart';

/// The app shell.
///
/// One theme for now - `Tide` light, with dark following the system. The second
/// theme in the shipped-product plan was store differentiation, which a
/// personal build does not need.
class PatternsApp extends StatelessWidget {
  const PatternsApp({
    required this.controller,
    required this.reminder,
    required this.settings,
    this.lock,
    this.quickLog,
    required this.language,
    super.key,
  });

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
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: language,
        builder: (context, current, _) => LanguageScope(
          language: language,
          child: _app(current),
        ),
      );

  Widget _app(AppLanguage current) => MaterialApp(
        title: 'Patterns',
        debugShowCheckedModeBanner: false,
        // The pickers and the system widgets follow the same choice.
        locale: Locale(current.code),
        supportedLocales: const [Locale('en'), Locale('sr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
        darkTheme: VitalsTheme.dark(accent: AppAccent.patternsCobalt),
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
