import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/app/patterns_app.dart';
import 'package:patterns/data/app_database.dart';
import 'package:patterns/data/evening_reminder.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/l10n/app_language.dart';
import 'package:patterns/l10n/app_strings.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_notify/vitals_notify.dart';

Future<PatternsController> freshController() async {
  final controller = PatternsController(
    db: PatternsDatabase(NativeDatabase.memory()),
    installId: '018f2c00-aaaa-7000-8000-000000000001',
    dayBoundaryHour: 4,
  );
  await controller.seedIfNeeded();
  return controller;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('English unless something says otherwise', () async {
    expect(await AppLanguage.load(), AppLanguage.en);
    await AppLanguage.save(AppLanguage.sr);
    expect(await AppLanguage.load(), AppLanguage.sr);
  });

  test('the seeded markers are the same objects in either language', () async {
    // Names are data, not copy. Switching the language must not rewrite a
    // single row, or the app would be editing her record.
    final controller = await freshController();
    final names = [for (final m in controller.allMarkers) m.name];
    expect(names, contains('mood'));
    expect(names, contains('diary'));
    controller.dispose();
  });

  testWidgets('switching in Settings redraws the app and is remembered',
      (tester) async {
    final controller = await freshController();
    final language = ValueNotifier(AppLanguage.en);
    final reminder = EveningReminder(RecordingNotifier());

    await tester.pumpWidget(PatternsApp(
      controller: controller,
      reminder: reminder,
      settings: ReminderSettings.off,
      language: language,
    ));
    await tester.pumpAndSettle();

    // Home is in English, and the marker names are untouched.
    expect(find.text('MIND'), findsOneWidget);
    expect(find.text('mood'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Srpski'));
    await tester.pumpAndSettle();

    expect(find.text('Podesavanja'), findsOneWidget);
    expect(find.text('PODSJETNIK'), findsOneWidget);
    expect(await AppLanguage.load(), AppLanguage.sr);

    // The screen underneath changed too, not only the one in front.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('UM'), findsOneWidget);
    expect(find.text('mood'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('the evening reminder is re-worded when the language changes',
      (tester) async {
    final controller = await freshController();
    final notifier = RecordingNotifier();
    final reminder = EveningReminder(notifier);
    final language = ValueNotifier(AppLanguage.en);
    await ReminderSettings.off.copyWith(enabled: true).save();

    await tester.pumpWidget(PatternsApp(
      controller: controller,
      reminder: reminder,
      settings: ReminderSettings.off.copyWith(enabled: true),
      language: language,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Srpski'));
    await tester.pumpAndSettle();

    expect(notifier.scheduled.last.body, AppStrings(AppLanguage.sr).reminderBody);
    controller.dispose();
  });
}
