import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/home_screen.dart';
import 'package:patterns/screens/report_view_screen.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
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

Widget wrap(PatternsController controller) => MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: HomeScreen(controller: controller),
    );

void main() {
  testWidgets('home lists the markers, grouped, with nothing logged yet',
      (tester) async {
    final controller = await freshController();
    await tester.pumpWidget(wrap(controller));
    await tester.pumpAndSettle();

    expect(find.text('MIND'), findsOneWidget);
    expect(find.text('BODY'), findsOneWidget);
    expect(find.text('mood'), findsOneWidget);
    expect(find.text('creatine'), findsOneWidget);

    // Every marker starts as a dash. Not a warning, not a red badge, not a
    // count of what is "left" - the home screen never grades a day.
    expect(find.text('—'), findsWidgets);
    expect(find.text('✓'), findsNothing);
    controller.dispose();
  });

  testWidgets('nothing on this screen scores the day', (tester) async {
    final controller = await freshController();
    await tester.pumpWidget(wrap(controller));
    await tester.pumpAndSettle();

    for (final banned in ['%', 'niz', 'propust', '0/']) {
      expect(
        find.textContaining(banned),
        findsNothing,
        reason: 'the home screen must not grade the day',
      );
    }
    controller.dispose();
  });

  testWidgets('logging a rating ticks its row', (tester) async {
    final controller = await freshController();
    await tester.pumpWidget(wrap(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('tiredness'));
    await tester.pumpAndSettle();

    // The sheet opens on the middle of the scale rather than the bottom, so a
    // slider parked on 1 cannot suggest an answer.
    expect(find.text('6'), findsOneWidget);
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();

    expect(find.text('✓'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('a second reading of the same marker shows a count',
      (tester) async {
    final controller = await freshController();
    final bloating = controller.byId(seedIds['bloating']!)!;
    await controller.log(
      bloating.id,
      const NumberValue(3, kind: MetricKind.scale),
    );
    await controller.log(
      bloating.id,
      const NumberValue(7, kind: MetricKind.scale),
    );

    await tester.pumpWidget(wrap(controller));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('2×'), 120);
    expect(find.text('2×'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('"nothing today" is an answer the sheet can record',
      (tester) async {
    final controller = await freshController();
    await tester.pumpWidget(wrap(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('feelings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None of these'));
    await tester.pumpAndSettle();
    // Chosen, not saved: the sheet stays open for a note or a photo.
    expect(await controller.readingsOn(controller.today), isEmpty);
    await tester.ensureVisible(find.text('Log'));
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();

    final readings = await controller.readingsOn(controller.today);
    expect(readings, hasLength(1));
    expect((readings.single.value as TagsValue).isExplicitNone, isTrue);
    controller.dispose();
  });

  group('tapping a marker already logged today', () {
    testWidgets('edits the latest reading instead of adding one',
        (tester) async {
      final controller = await freshController();
      await controller.log(seedIds['feelings']!, TagsValue(const []));
      await tester.pumpWidget(wrap(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('feelings'));
      await tester.pumpAndSettle();
      expect(find.text("Editing today's entry"), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'fine after all');
      await tester.ensureVisible(find.text('Log'));
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();

      final readings = await controller.readingsOn(controller.today);
      expect(readings, hasLength(1));
      expect(readings.single.note, 'fine after all');
      controller.dispose();
    });

    testWidgets('"New entry" records a second reading next to it',
        (tester) async {
      final controller = await freshController();
      await controller.log(seedIds['feelings']!, TagsValue(const []));
      await tester.pumpWidget(wrap(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('feelings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New entry'));
      await tester.pumpAndSettle();
      expect(find.text('Another entry for today'), findsOneWidget);
      await tester.tap(find.text('None of these'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Log'));
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();

      expect(await controller.readingsOn(controller.today), hasLength(2));
      controller.dispose();
    });
  });

  testWidgets('the day detail screen shows the readings with their times',
      (tester) async {
    final controller = await freshController();
    await controller.log(
      seedIds['diary']!,
      const TextValue('bila sam umorna zbog posla'),
    );

    await tester.pumpWidget(wrap(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.today_outlined));
    await tester.pumpAndSettle();

    expect(find.text('bila sam umorna zbog posla'), findsOneWidget);
    expect(find.text('diary'), findsOneWidget);
    controller.dispose();
  });
  group('holding a row', () {
    testWidgets('opens that marker\'s last month and saves nothing',
        (tester) async {
      // Looking at one marker is not a question worth keeping. The saved list
      // is hers, and it would grow by one every time a row was held.
      final controller = await freshController();
      await tester.pumpWidget(wrap(controller));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('tiredness'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportViewScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'tiredness'), findsOneWidget);

      // Changing the axis stays on this screen.
      await tester.tap(find.text('Grid'));
      await tester.pumpAndSettle();
      expect(await controller.savedReports(), isEmpty);
      controller.dispose();
    });

    testWidgets('does nothing on a marker with nothing to chart',
        (tester) async {
      final controller = await freshController();
      await tester.pumpWidget(wrap(controller));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('diary'), 120);
      await tester.longPress(find.text('diary'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportViewScreen), findsNothing);
      controller.dispose();
    });
  });
}
