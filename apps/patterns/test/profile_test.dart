import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/app_database.dart';
import 'package:patterns/data/evening_reminder.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/home_screen.dart';
import 'package:patterns/screens/report_builder_screen.dart';
import 'package:patterns/screens/settings_screen.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_notify/vitals_notify.dart';
import 'package:vitals_ui/vitals_ui.dart';

Future<PatternsController> freshController() async {
  final controller = PatternsController(
    db: PatternsDatabase(NativeDatabase.memory()),
    installId: '018f2c00-aaaa-7000-8000-000000000001',
    dayBoundaryHour: 4,
  );
  await controller.seedIfNeeded();
  return controller;
}

Widget wrap(Widget child) => MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: child,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the controller', () {
    test('starts with one profile, which tracks the cycle', () async {
      final controller = await freshController();
      expect(controller.profileList, hasLength(1));
      expect(controller.activeProfile.name, 'Me');
      expect(controller.cycleEnabled, isTrue);
      controller.dispose();
    });

    test('a new profile has its own markers and none of the readings',
        () async {
      final controller = await freshController();
      await controller.log(
          seedIds['mood']!, const NumberValue(8, kind: MetricKind.scale));

      final kid = await controller.createProfile(
        name: 'Luka',
        start: ProfileStart.starter,
      );

      expect(controller.activeProfileId, kid.id);
      final names = controller.allMarkers.map((m) => m.name).toList();
      expect(names, contains('mood'));
      // Its own marker, not the parent's.
      expect(controller.allMarkers.any((m) => m.id == seedIds['mood']), isFalse);
      // Nothing logged in this profile, whatever the parent logged.
      expect(await controller.readingsOn(controller.today), isEmpty);
      // New profiles start without the cycle.
      expect(controller.cycleEnabled, isFalse);
      expect(
        controller.allMarkers.any((m) => m.domain == MetricDomain.cycle),
        isFalse,
      );

      await controller.switchProfile(defaultProfileId);
      expect(await controller.readingsOn(controller.today), hasLength(1));
      controller.dispose();
    });

    test('an empty profile has no markers, a copy has the markers only',
        () async {
      final controller = await freshController();
      await controller.log(
          seedIds['mood']!, const NumberValue(8, kind: MetricKind.scale));

      await controller.createProfile(name: 'Prazan', start: ProfileStart.empty);
      expect(controller.allMarkers, isEmpty);

      await controller.createProfile(
        name: 'Kopija',
        start: ProfileStart.copy,
        copyFrom: defaultProfileId,
      );
      expect(controller.allMarkers.map((m) => m.name), contains('mood'));
      expect(await controller.readingsOn(controller.today), isEmpty);
      // The source's period pair is its own and does not come along.
      expect(
        controller.allMarkers.any((m) => m.domain == MetricDomain.cycle),
        isFalse,
      );
      controller.dispose();
    });

    test('turning the cycle on makes a pair; off hides it and keeps it',
        () async {
      final controller = await freshController();
      await controller.createProfile(name: 'Ana', start: ProfileStart.empty);

      await controller.setCycleEnabled(true);
      expect(controller.cycleEnabled, isTrue);
      await controller.logPeriod(
        start: true,
        dayKey: addDays(controller.today, -2),
      );
      expect((await controller.cycleStatus()).day, 3);

      await controller.setCycleEnabled(false);
      expect((await controller.cycleStatus()).day, isNull);
      expect(await controller.cyclePeriods(), isEmpty);

      // Back on: the same period, not a fresh start.
      await controller.setCycleEnabled(true);
      expect((await controller.cycleStatus()).day, 3);
      controller.dispose();
    });

    test('the last profile cannot be deleted; another one can', () async {
      final controller = await freshController();
      expect(await controller.deleteProfile(defaultProfileId), isFalse);

      final kid = await controller.createProfile(
        name: 'Luka',
        start: ProfileStart.starter,
      );
      expect(await controller.deleteProfile(kid.id), isTrue);
      expect(controller.profileList, hasLength(1));
      expect(controller.activeProfileId, defaultProfileId);
      // The parent's markers are untouched.
      expect(controller.allMarkers.any((m) => m.id == seedIds['mood']), isTrue);
      controller.dispose();
    });

    test('reports and photos belong to the profile they were made in',
        () async {
      final controller = await freshController();
      await controller.saveReport(ReportDefinition(
        id: '018f2c00-cccc-7000-8000-000000000001',
        name: 'mine',
        series: [ReportSeries(metricId: seedIds['mood']!)],
        period: const LastDays(30),
        createdAt: DateTime.utc(2026, 9, 1),
      ));
      await controller.createProfile(name: 'Luka', start: ProfileStart.empty);
      expect(await controller.savedReports(), isEmpty);

      await controller.switchProfile(defaultProfileId);
      expect((await controller.savedReports()).single.name, 'mine');
      controller.dispose();
    });
  });

  group('the screens', () {
    testWidgets('home shows whose record it is, and switches from there',
        (tester) async {
      final controller = await freshController();
      await controller.createProfile(name: 'Luka', start: ProfileStart.starter);
      await controller.switchProfile(defaultProfileId);

      await tester.pumpWidget(wrap(HomeScreen(controller: controller)));
      await tester.pumpAndSettle();
      expect(find.text('Me'), findsOneWidget);

      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Luka'));
      await tester.pumpAndSettle();

      expect(controller.activeProfile.name, 'Luka');
      expect(find.text('Luka'), findsOneWidget);
      // No cycle on a profile that does not track one.
      expect(find.text('CYCLE'), findsNothing);
      expect(await ActiveProfile.load(), controller.activeProfileId);
      controller.dispose();
    });

    testWidgets('a new profile is made from the picker', (tester) async {
      final controller = await freshController();
      await tester.pumpWidget(wrap(HomeScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Luka');
      await tester.pump();
      await tester.tap(find.text('Empty'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(controller.activeProfile.name, 'Luka');
      expect(controller.allMarkers, isEmpty);
      controller.dispose();
    });

    testWidgets('the cycle switch in Settings hides the card on home',
        (tester) async {
      final controller = await freshController();
      await tester.pumpWidget(wrap(SettingsScreen(
        reminder: EveningReminder(RecordingNotifier()),
        settings: ReminderSettings.off,
        controller: controller,
      )));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Track the cycle'), 150);
      await tester.tap(find.text('Track the cycle'));
      await tester.pumpAndSettle();
      expect(controller.cycleEnabled, isFalse);

      await tester.pumpWidget(wrap(HomeScreen(controller: controller)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('appetite'), 150);
      expect(find.text('CYCLE'), findsNothing);
      expect(find.text('Period started'), findsNothing);
      controller.dispose();
    });

    testWidgets('no cycle axis in a report for a profile without a cycle',
        (tester) async {
      final controller = await freshController();
      await controller.createProfile(name: 'Luka', start: ProfileStart.starter);
      await tester.pumpWidget(
          wrap(ReportBuilderScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('By date'), findsOneWidget);
      expect(find.text('By cycle day'), findsNothing);
      controller.dispose();
    });
  });
}
