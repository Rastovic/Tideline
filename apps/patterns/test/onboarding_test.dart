import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/app/patterns_app.dart';
import 'package:patterns/data/app_database.dart';
import 'package:patterns/data/evening_reminder.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/l10n/app_language.dart';
import 'package:patterns/onboarding/onboarding.dart';
import 'package:patterns/onboarding/suggested_markers.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_notify/vitals_notify.dart';

/// A fresh install the way main.dart makes one: onboarding decided first,
/// then seeding without markers while it is pending.
Future<(PatternsController, Onboarding)> firstRun(
  ValueNotifier<AppLanguage> language,
) async {
  final controller = PatternsController(
    db: PatternsDatabase(NativeDatabase.memory()),
    installId: '018f2c00-aaaa-7000-8000-000000000001',
    dayBoundaryHour: 4,
  );
  final onboarding = await Onboarding.load(
    controller: controller,
    language: language,
    isFreshInstall: () async => (await controller.metrics.all()).isEmpty,
  );
  await controller.seedIfNeeded(markers: !onboarding.isPending);
  return (controller, onboarding);
}

Future<void> pumpApp(
  WidgetTester tester,
  PatternsController controller,
  Onboarding onboarding,
  ValueNotifier<AppLanguage> language,
) async {
  await tester.pumpWidget(
    PatternsApp(
      controller: controller,
      reminder: EveningReminder(RecordingNotifier()),
      settings: ReminderSettings.off,
      language: language,
      onboarding: onboarding,
    ),
  );
  await tester.pumpAndSettle();
  onboarding.showWelcomeIfPending();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a fresh install is pending and starts with no markers', () async {
    final (controller, onboarding) = await firstRun(
      ValueNotifier(AppLanguage.en),
    );
    expect(onboarding.isPending, isTrue);
    expect(controller.allMarkers, isEmpty);
    controller.dispose();
  });

  test('an install that already has markers never sees the welcome', () async {
    final controller = PatternsController(
      db: PatternsDatabase(NativeDatabase.memory()),
      installId: '018f2c00-aaaa-7000-8000-000000000001',
      dayBoundaryHour: 4,
    );
    await controller.seedIfNeeded();
    final onboarding = await Onboarding.load(
      controller: controller,
      language: ValueNotifier(AppLanguage.en),
      isFreshInstall: () async => (await controller.metrics.all()).isEmpty,
    );
    expect(onboarding.isPending, isFalse);
    controller.dispose();
  });

  test('the demo profile is the short set, not the whole seed', () async {
    final (controller, onboarding) = await firstRun(
      ValueNotifier(AppLanguage.en),
    );
    await onboarding.controller.createDemoProfile(
      name: 'Demo',
      reportNames: (
        moodAndTiredness: 'a',
        trainingAndMood: 'b',
        byCycleDay: 'c',
        weeklyRhythm: 'd',
      ),
      days: 30,
    );
    final names = {
      for (final m in controller.allMarkers)
        if (m.domain != MetricDomain.cycle) m.name,
    };
    expect(names, {
      'mood',
      'tiredness',
      'feelings',
      'bloating',
      'training',
      'bedtime',
      'diary',
    });
    controller.dispose();
  });

  test('suggestions are named in the language picked', () {
    for (final marker in suggestedMarkers) {
      expect(marker.nameIn(AppLanguage.en), isNotEmpty);
      expect(marker.nameIn(AppLanguage.sr), isNotEmpty);
    }
    final mood = suggestedMarkers.firstWhere((m) => m.key == 'mood');
    expect(mood.nameIn(AppLanguage.sr), 'raspolozenje');
    expect(
      suggestedMarkers.map((m) => m.key).toSet(),
      hasLength(suggestedMarkers.length),
    );
  });

  testWidgets('welcome, the whole tour, then her own markers in Serbian', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final language = ValueNotifier(AppLanguage.en);
    final (controller, onboarding) =
        await tester.runAsync(() => firstRun(language))
            as (PatternsController, Onboarding);
    await pumpApp(tester, controller, onboarding, language);

    expect(find.text('Welcome to Tideline'), findsOneWidget);
    await tester.tap(find.text('Srpski'));
    await tester.pumpAndSettle();
    expect(find.text('Dobro dosli u Tideline'), findsOneWidget);

    await tester.runAsync(onboarding.startTour);
    await tester.pumpAndSettle();
    expect(onboarding.step, TourStep.home);
    expect(controller.activeProfile.name, 'Demo');
    expect(find.text('Demo profil'), findsOneWidget);

    // Every stop opens without throwing, and the last one leads to setup.
    for (var i = 1; i < TourStep.values.length; i++) {
      await tester.runAsync(onboarding.next);
      await tester.pumpAndSettle();
      expect(onboarding.step, TourStep.values[i]);
      expect(tester.takeException(), isNull, reason: '${onboarding.step}');
    }
    await tester.tap(find.text('Napravi moje markere'));
    await tester.pumpAndSettle();
    expect(find.text('Sta ces pratiti?'), findsOneWidget);

    await tester.runAsync(
      () => onboarding.finish(
        picked: {'mood', 'water'},
        cycle: true,
        keepDemo: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(onboarding.isPending, isFalse);
    expect(onboarding.step, isNull);
    expect(controller.profileList, hasLength(1));
    expect(controller.activeProfile.name, 'Ja');
    expect(
      {for (final m in controller.allMarkers) m.name},
      {'raspolozenje', 'voda', 'pocetak menstruacije', 'kraj menstruacije'},
    );
    // Her own period pair, not the seed's, which a fresh install never made.
    final profile = controller.activeProfile;
    expect(
      controller.byId(profile.periodStartMetricId!)!.name,
      'pocetak menstruacije',
    );
    expect(
      controller.byId(profile.periodEndMetricId!)!.name,
      'kraj menstruacije',
    );
    expect(controller.cycleEnabled, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('patterns.onboarding'), 'done');
    controller.dispose();
  });

  testWidgets('skipping straight to setup keeps no demo', (tester) async {
    final language = ValueNotifier(AppLanguage.en);
    final (controller, onboarding) =
        await tester.runAsync(() => firstRun(language))
            as (PatternsController, Onboarding);
    await pumpApp(tester, controller, onboarding, language);

    await tester.tap(find.text('Skip, I will set it up myself'));
    await tester.pumpAndSettle();
    expect(find.text('What will you track?'), findsOneWidget);
    expect(find.text('Keep the demo profile'), findsNothing);

    await tester.runAsync(
      () => onboarding.finish(picked: {'mood'}, cycle: false, keepDemo: false),
    );
    await tester.pumpAndSettle();
    expect([for (final m in controller.allMarkers) m.name], ['mood']);
    expect(controller.activeProfileId, defaultProfileId);
    controller.dispose();
  });

  testWidgets('the tour taken again from Settings ends back on her profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final language = ValueNotifier(AppLanguage.en);
    final controller = PatternsController(
      db: PatternsDatabase(NativeDatabase.memory()),
      installId: '018f2c00-aaaa-7000-8000-000000000001',
      dayBoundaryHour: 4,
    );
    final onboarding =
        await tester.runAsync(() async {
              await controller.seedIfNeeded();
              return Onboarding.load(
                controller: controller,
                language: language,
                isFreshInstall: () async =>
                    (await controller.metrics.all()).isEmpty,
              );
            })
            as Onboarding;
    await pumpApp(tester, controller, onboarding, language);
    expect(onboarding.isPending, isFalse);
    final before = controller.allMarkers.length;

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Take the tour again'), 200);
    expect(find.text('Take the tour again'), findsOneWidget);

    await tester.runAsync(onboarding.replay);
    await tester.pumpAndSettle();
    expect(onboarding.isReplay, isTrue);
    expect(controller.activeProfile.name, 'Demo');
    expect(controller.profileList, hasLength(2));

    await tester.runAsync(onboarding.skip);
    await tester.pumpAndSettle();
    expect(onboarding.step, isNull);
    expect(onboarding.isReplay, isFalse);
    expect(controller.activeProfileId, defaultProfileId);
    expect(controller.profileList, hasLength(1));
    expect(controller.allMarkers, hasLength(before));
    controller.dispose();
  });
}
