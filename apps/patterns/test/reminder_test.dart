import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/app_database.dart';
import 'package:patterns/data/evening_reminder.dart';
import 'package:patterns/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_notify/vitals_notify.dart';
import 'package:vitals_ui/vitals_ui.dart';

Widget wrapSettings(
  EveningReminder reminder, {
  ReminderSettings settings = ReminderSettings.off,
}) =>
    MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: SettingsScreen(reminder: reminder, settings: settings),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('when the reminder next fires', () {
    test('today, when the time has not passed yet', () {
      final at = nextReminderAt(DateTime(2026, 9, 6, 18, 30), 21 * 60);
      expect(at, DateTime(2026, 9, 6, 21));
    });

    test('tomorrow, when it has', () {
      final at = nextReminderAt(DateTime(2026, 9, 6, 22, 15), 21 * 60);
      expect(at, DateTime(2026, 9, 7, 21));
    });

    test('exactly now counts as passed', () {
      // Otherwise setting the reminder to the current minute fires it
      // instantly, which reads as the app shouting at you for opening
      // Settings.
      final at = nextReminderAt(DateTime(2026, 9, 6, 21), 21 * 60);
      expect(at, DateTime(2026, 9, 7, 21));
    });

    test('crosses the month end without help', () {
      final at = nextReminderAt(DateTime(2026, 9, 30, 23), 21 * 60);
      expect(at, DateTime(2026, 10, 1, 21));
    });
  });

  group('applying the settings to the OS', () {
    test('an enabled reminder is scheduled to repeat, once', () async {
      final notifier = RecordingNotifier();
      await EveningReminder(notifier).apply(
        const ReminderSettings(enabled: true, minute: 21 * 60),
        now: DateTime(2026, 9, 6, 18),
      );

      expect(notifier.scheduled, hasLength(1));
      expect(notifier.daily, [EveningReminder.notificationId]);
      expect(notifier.scheduled.single.at, DateTime(2026, 9, 6, 21));
    });

    test('changing the time replaces rather than adding a second alarm',
        () async {
      // One fixed id is what makes this true. Without it, every visit to
      // Settings leaves another alarm behind and the phone goes off twice.
      final notifier = RecordingNotifier();
      final reminder = EveningReminder(notifier);
      await reminder.apply(
        const ReminderSettings(enabled: true, minute: 21 * 60),
        now: DateTime(2026, 9, 6, 18),
      );
      await reminder.apply(
        const ReminderSettings(enabled: true, minute: 22 * 60),
        now: DateTime(2026, 9, 6, 18),
      );

      expect(
        notifier.scheduled.map((n) => n.id).toSet(),
        {EveningReminder.notificationId},
      );
    });

    test('turning it off cancels it and changes nothing else', () async {
      final notifier = RecordingNotifier();
      final reminder = EveningReminder(notifier);
      await reminder.apply(
        const ReminderSettings(enabled: true, minute: 21 * 60),
        now: DateTime(2026, 9, 6, 18),
      );
      await reminder.apply(ReminderSettings.off, now: DateTime(2026, 9, 6, 18));

      expect(notifier.cancelled, contains(EveningReminder.notificationId));
      expect(notifier.scheduled, isEmpty);
    });

    test('it says the same thing every night, and never grades the day', () {
      // The reminder has no way to know whether anything was logged: `apply`
      // takes the settings and the clock, and nothing else. The wording is
      // pinned here so a later "helpful" version has to argue with a test.
      final text = '${EveningReminder.title} ${EveningReminder.body}';
      for (final banned in [
        'propust',
        'nisi',
        'niz',
        'dana zaredom',
        '%',
        'bravo',
      ]) {
        expect(text.toLowerCase(), isNot(contains(banned)), reason: banned);
      }
    });
  });

  group('the settings screen', () {
    testWidgets('starts off, because nothing asked for it yet',
        (tester) async {
      final notifier = RecordingNotifier();
      await tester.pumpWidget(wrapSettings(EveningReminder(notifier)));
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isFalse);
      expect(notifier.scheduled, isEmpty);
    });

    testWidgets('turning it on asks for permission, then schedules it',
        (tester) async {
      final notifier = RecordingNotifier();
      await tester.pumpWidget(wrapSettings(EveningReminder(notifier)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(notifier.daily, [EveningReminder.notificationId]);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isTrue);
    });

    testWidgets('a refused permission leaves the switch off and says why',
        (tester) async {
      // Never on-but-silent. An app that says a reminder is set when the OS
      // will never deliver it is lying, and the discovery comes weeks later.
      final notifier = RecordingNotifier()
        ..permissionState = NotificationPermission.denied;
      await tester.pumpWidget(wrapSettings(EveningReminder(notifier)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(notifier.scheduled, isEmpty);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isFalse);
      expect(find.textContaining('iskljucena u postavkama telefona'),
          findsOneWidget);
      expect(find.textContaining('Sve ostalo radi normalno'), findsOneWidget);
    });

    testWidgets('the promise about what it says is on the screen',
        (tester) async {
      final notifier = RecordingNotifier();
      await tester.pumpWidget(wrapSettings(EveningReminder(notifier)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ne zna da li si nesto upisala'),
          findsOneWidget);
    });

    testWidgets('the chosen time survives a restart', (tester) async {
      final notifier = RecordingNotifier();
      await tester.pumpWidget(wrapSettings(EveningReminder(notifier)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final reloaded = await ReminderSettings.load();

      expect(reloaded.enabled, isTrue);
      expect(reloaded.minute, ReminderSettings.defaultMinute);
    });
  });
}
