import 'package:flutter/material.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/app_database.dart';
import '../data/evening_reminder.dart';
import '../data/patterns_controller.dart';
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
    super.key,
  });

  final PatternsController controller;
  final EveningReminder reminder;
  final ReminderSettings settings;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Patterns',
        debugShowCheckedModeBanner: false,
        theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
        darkTheme: VitalsTheme.dark(accent: AppAccent.patternsCobalt),
        home: HomeScreen(
          controller: controller,
          reminder: reminder,
          initialSettings: settings,
        ),
      );
}
