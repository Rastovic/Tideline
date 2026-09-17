import 'package:flutter/material.dart';
import 'package:vitals_notify/vitals_notify.dart';

import 'app/patterns_app.dart';
import 'data/app_database.dart';
import 'data/app_lock.dart';
import 'data/evening_reminder.dart';
import 'data/patterns_controller.dart';
import 'data/quick_log_widget.dart';
import 'l10n/app_language.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = openPatternsDatabase();
  final installId = await InstallId.load();
  final dayBoundaryHour = await DayBoundary.load();

  final controller = PatternsController(
    db: db,
    installId: installId,
    dayBoundaryHour: dayBoundaryHour,
  );
  // Seeding is idempotent and checks for any marker, deleted ones included, so
  // a marker removed on purpose does not reappear after an update.
  await controller.seedIfNeeded();

  // Re-armed on every launch rather than trusted to have survived. Android
  // drops pending alarms on a reboot and on an app update, and the second is
  // the one that would quietly break this for the person who least expects it.
  // A fixed notification id makes the call idempotent.
  final language = ValueNotifier(await AppLanguage.load());
  final settings = await ReminderSettings.load();
  final reminder = EveningReminder(LocalNotifier());
  await reminder.apply(settings, language: language.value);

  // Loaded before the first frame, so the app never flashes its content
  // before the lock covers it.
  final lock = AppLock();
  await lock.load();

  runApp(
    PatternsApp(
      controller: controller,
      lock: lock,
      quickLog: const PlatformQuickLogWidget(),
      language: language,
      reminder: reminder,
      settings: settings,
    ),
  );
}
