import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/day_detail_screen.dart';
import 'package:patterns/screens/home_screen.dart';
import 'package:patterns/data/app_database.dart';
import 'package:patterns/data/evening_reminder.dart';
import 'package:patterns/screens/search_screen.dart';
import 'package:patterns/screens/settings_screen.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_notify/vitals_notify.dart';
import 'package:vitals_ui/vitals_ui.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';

Future<PatternsController> freshController() async {
  final controller = PatternsController(
    db: PatternsDatabase(NativeDatabase.memory()),
    installId: install,
    dayBoundaryHour: 4,
  );
  await controller.seedIfNeeded();
  return controller;
}

Widget wrap(Widget child) => MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: child,
    );

Future<void> addCaptionedPhoto(
  PatternsController controller,
  String caption,
) =>
    controller.photos.add(
      dayKey: controller.today,
      utcOffsetMinutes: 0,
      fileName: 'a.jpg',
      thumbFileName: 'a_t.jpg',
      byteSize: 1000,
      capturedAt: DateTime.now().toUtc(),
      caption: caption,
    );

void main() {
  group('the controller', () {
    test('finds diary entries and photo captions, ignoring diacritics',
        () async {
      final controller = await freshController();
      await controller.log(
        seedIds['diary']!,
        const TextValue('Bila sam tužna zbog posla'),
      );
      await controller.log(seedIds['diary']!, const TextValue('trening dobar'));
      await addCaptionedPhoto(controller, 'poslije treninga');

      final sad = await controller.search('tuzna');
      expect(sad.map((h) => h.text), ['Bila sam tužna zbog posla']);

      final training = await controller.search('trening');
      expect(training, hasLength(2));
      expect(
        training.map((h) => h.source).toSet(),
        {'dnevnik', 'fotografija'},
      );
      controller.dispose();
    });

    test('a private entry is found only when asked for', () async {
      final controller = await freshController();
      await controller.log(
        seedIds['diary']!,
        const TextValue('samo za mene', isPrivate: true),
      );

      expect(await controller.search('mene'), isEmpty);
      final found = await controller.search('mene', includePrivate: true);
      expect(found.single.isPrivate, isTrue);
      controller.dispose();
    });

    test('a deleted entry is not found', () async {
      final controller = await freshController();
      await controller.log(seedIds['diary']!, const TextValue('obrisano'));
      final reading = (await controller.readingsOn(controller.today)).single;
      await controller.deleteReading(reading.id);

      expect(await controller.search('obrisano'), isEmpty);
      controller.dispose();
    });
  });

  group('the screens', () {
    testWidgets('a diary entry marked private is saved private',
        (tester) async {
      final controller = await freshController();
      await tester.pumpWidget(wrap(HomeScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('dnevnik'), 120);
      await tester.tap(find.text('dnevnik'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'tajna');
      await tester.tap(find.text('Privatno'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sacuvaj'));
      await tester.pumpAndSettle();

      final reading = (await controller.readingsOn(controller.today)).single;
      expect(reading.value, const TextValue('tajna', isPrivate: true));
      controller.dispose();
    });

    testWidgets('a hit opens its day, and private ones wait for the switch',
        (tester) async {
      final controller = await freshController();
      await controller.log(
        seedIds['diary']!,
        const TextValue('konflikt na poslu'),
      );
      await controller.log(
        seedIds['diary']!,
        const TextValue('konflikt kod kuce', isPrivate: true),
      );

      await tester.pumpWidget(wrap(SearchScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'konflikt');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('konflikt na poslu'), findsOneWidget);
      expect(find.text('konflikt kod kuce'), findsNothing);

      await tester.tap(find.text('Ukljuci privatne'));
      await tester.pumpAndSettle();
      expect(find.text('konflikt kod kuce'), findsOneWidget);

      await tester.tap(find.text('konflikt na poslu'));
      await tester.pumpAndSettle();
      expect(find.byType(DayDetailScreen), findsOneWidget);
      controller.dispose();
    });

    testWidgets('nothing found says so', (tester) async {
      final controller = await freshController();
      await tester.pumpWidget(wrap(SearchScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nepostojece');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Nista ne sadrzi te rijeci.'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('the home header fits a 360dp phone', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = await freshController();
      await tester.pumpWidget(wrap(HomeScreen(controller: controller)));
      await tester.pumpAndSettle();

      // An overflowing Row reports through the framework as an exception.
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.search), findsOneWidget);
      controller.dispose();
    });
  });
  testWidgets('Settings shows what the photos take, and offers no cleanup',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = await freshController();
    await addCaptionedPhoto(controller, 'a');
    await addCaptionedPhoto(controller, 'b');

    await tester.pumpWidget(wrap(SettingsScreen(
      reminder: EveningReminder(RecordingNotifier()),
      settings: ReminderSettings.off,
      controller: controller,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Fotografije zauzimaju'), findsOneWidget);
    expect(find.text('2 KB'), findsOneWidget);
    for (final banned in ['obrisi', 'oslobodi', 'previse', 'limit']) {
      expect(find.textContaining(banned), findsNothing, reason: banned);
    }
    controller.dispose();
  });
}
