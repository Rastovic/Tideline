import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vitals_ads/vitals_ads.dart';
import 'package:vitals_notify/vitals_notify.dart';

import 'app/patterns_app.dart';
import 'app/tideline_themes.dart';
import 'data/ads.dart';
import 'data/app_database.dart';
import 'data/app_lock.dart';
import 'data/evening_reminder.dart';
import 'data/patterns_controller.dart';
import 'data/quick_log_widget.dart';
import 'package:patterns_core/patterns_core.dart' show defaultProfileId;

import 'l10n/app_language.dart';
import 'onboarding/onboarding.dart';
import 'l10n/app_strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = openPatternsDatabase();
  final installId = await InstallId.load();
  final dayBoundaryHour = await DayBoundary.load();

  final language = ValueNotifier(await AppLanguage.load());
  final controller = PatternsController(
    db: db,
    installId: installId,
    dayBoundaryHour: dayBoundaryHour,
    activeProfileId: await ActiveProfile.load() ?? defaultProfileId,
  );
  // Decided before seeding: an empty database is a fresh install, and a fresh
  // install picks its own markers at the end of the welcome instead of
  // inheriting the whole starting set.
  final onboarding = await Onboarding.load(
    controller: controller,
    language: language,
    isFreshInstall: () async => (await controller.metrics.all()).isEmpty,
  );

  // Seeding is idempotent and checks for any marker, deleted ones included, so
  // a marker removed on purpose does not reappear after an update.
  await controller.seedIfNeeded(
    defaultProfileName: AppStrings(language.value).defaultProfileName,
    markers: !onboarding.isPending,
  );

  // Re-armed on every launch rather than trusted to have survived. Android
  // drops pending alarms on a reboot and on an app update, and the second is
  // the one that would quietly break this for the person who least expects it.
  // A fixed notification id makes the call idempotent.
  final settings = await ReminderSettings.load();
  final reminder = EveningReminder(LocalNotifier());
  await reminder.apply(settings, language: language.value);

  // Loaded before the first frame, so the app never flashes its content
  // before the lock covers it.
  final theme = ValueNotifier(await ThemeChoice.load());
  final lock = AppLock();
  await lock.load();

  // Not awaited: the first frame must not wait on an ad, and everything the
  // ads layer is asked before it finishes answers "no ad" anyway.
  final ads = AdsController(gateway: AdMobGateway());
  unawaited(ads.start());

  runApp(
    PatternsApp(
      controller: controller,
      lock: lock,
      quickLog: const PlatformQuickLogWidget(),
      language: language,
      theme: theme,
      reminder: reminder,
      settings: settings,
      onboarding: onboarding,
      ads: ads,
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => onboarding.showWelcomeIfPending(),
  );
}
