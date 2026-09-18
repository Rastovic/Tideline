import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/app_database.dart';
import 'package:patterns/data/evening_reminder.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/day_detail_screen.dart';
import 'package:patterns/screens/home_screen.dart';
import 'package:patterns/screens/log_sheet.dart';
import 'package:patterns/screens/photo_timeline_screen.dart';
import 'package:patterns/screens/report_chart.dart';
import 'package:patterns/screens/report_view_screen.dart';
import 'package:patterns/screens/settings_screen.dart';
import 'package:patterns/l10n/app_language.dart';
import 'package:patterns/l10n/app_strings.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_core/vitals_core.dart';
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

/// Opens the log sheet for [metric] from a bare button, and hands back what
/// it returned.
Future<List<LoggedEntry?>> openSheet(
  WidgetTester tester,
  Metric metric, {
  MetricValue? initial,
}) async {
  final results = <LoggedEntry?>[];
  await tester.pumpWidget(wrap(Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () async => results.add(
          await showLogSheet(context, metric: metric, initial: initial),
        ),
        child: const Text('open'),
      ),
    ),
  )));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

FilledButton primary(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

void main() {
  group('the log sheet refuses a reading nobody made', () {
    testWidgets('an empty or unreadable amount cannot be saved as zero',
        (tester) async {
      final controller = await freshController();
      final dose = controller.byId(seedIds['creatine-dose']!)!;
      final results = await openSheet(tester, dose);

      expect(primary(tester, 'Log').onPressed, isNull);
      await tester.enterText(find.byType(TextField).first, 'abc');
      await tester.pump();
      expect(primary(tester, 'Log').onPressed, isNull);
      await tester.enterText(find.byType(TextField).first, '-2');
      await tester.pump();
      expect(primary(tester, 'Log').onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, '2,5');
      await tester.pump();
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();
      expect(results.single!.value,
          const NumberValue(2.5, kind: MetricKind.amount));
      controller.dispose();
    });

    testWidgets('editing an amount shows the number being changed',
        (tester) async {
      final controller = await freshController();
      final dose = controller.byId(seedIds['creatine-dose']!)!;
      await openSheet(
        tester,
        dose,
        initial: const NumberValue(5, kind: MetricKind.amount),
      );
      expect(find.widgetWithText(TextField, '5'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('an empty diary entry cannot be saved', (tester) async {
      final controller = await freshController();
      await openSheet(tester, controller.byId(seedIds['diary']!)!);
      expect(primary(tester, 'Save').onPressed, isNull);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(primary(tester, 'Save').onPressed, isNull);
      controller.dispose();
    });

    testWidgets('tags with nothing picked are not "none of these"',
        (tester) async {
      final controller = await freshController();
      final results =
          await openSheet(tester, controller.byId(seedIds['feelings']!)!);
      expect(primary(tester, 'Log').onPressed, isNull);
      // The explicit answer is still one tap away.
      await tester.tap(find.text('None of these'));
      await tester.pumpAndSettle();
      expect((results.single!.value as TagsValue).isExplicitNone, isTrue);
      controller.dispose();
    });
  });

  group('day detail', () {
    testWidgets('moves between days, never past today', (tester) async {
      final controller = await freshController();
      await tester.pumpWidget(wrap(DayDetailScreen(
        controller: controller,
        dayKey: controller.today,
      )));
      await tester.pumpAndSettle();

      final next = find.ancestor(
        of: find.byTooltip('Next day'),
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(next).onPressed, isNull);

      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();
      final yesterday = addDays(controller.today, -1);
      expect(find.textContaining(
          humanDateFor(yesterday)), findsOneWidget);
      expect(tester.widget<IconButton>(next).onPressed, isNotNull);
      controller.dispose();
    });

    testWidgets('a missed day can be filled in, and is marked as late',
        (tester) async {
      final controller = await freshController();
      final yesterday = addDays(controller.today, -1);
      await tester.pumpWidget(wrap(DayDetailScreen(
        controller: controller,
        dayKey: yesterday,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('tiredness'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();

      final readings = await controller.readingsOn(yesterday);
      expect(readings, hasLength(1));
      expect(readings.single.enteredLate, isTrue);
      expect(await controller.readingsOn(controller.today), isEmpty);
      expect(find.text('entered later'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('shows the cycle day when it can be counted', (tester) async {
      final controller = await freshController();
      await controller.logForDay(
        seedIds['period-start']!,
        const BooleanValue(true),
        addDays(controller.today, -2),
      );
      await tester.pumpWidget(wrap(DayDetailScreen(
        controller: controller,
        dayKey: controller.today,
      )));
      await tester.pumpAndSettle();
      expect(find.text('cycle day 3'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('holding a reading asks before deleting it', (tester) async {
      final controller = await freshController();
      await controller.log(
          seedIds['mood']!, const NumberValue(4, kind: MetricKind.scale));
      await tester.pumpWidget(wrap(DayDetailScreen(
        controller: controller,
        dayKey: controller.today,
      )));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('mood'));
      await tester.pumpAndSettle();
      expect(find.text('Delete entry?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await controller.readingsOn(controller.today), hasLength(1));

      await tester.longPress(find.text('mood'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await controller.readingsOn(controller.today), isEmpty);
      controller.dispose();
    });
  });

  testWidgets('a square in a report opens its day', (tester) async {
    final controller = await freshController();
    final mood = controller.byId(seedIds['mood']!)!;
    await tester.pumpWidget(wrap(ReportViewScreen.forMarker(
      controller: controller,
      metric: mood,
    )));
    await tester.pumpAndSettle();

    // The right edge of the row is the last day of the window: today.
    final row = tester.getRect(find.byType(ReportRowChart));
    await tester.tapAt(Offset(row.right - 1, row.center.dy));
    await tester.pumpAndSettle();

    expect(find.byType(DayDetailScreen), findsOneWidget);
    expect(find.textContaining(humanDateFor(controller.today)),
        findsOneWidget);
    controller.dispose();
  });

  testWidgets('holding a photo marker opens its photos by month',
      (tester) async {
    final controller = await freshController();
    final photoMarker = Metric.create(
      id: '018f2c00-dddd-7000-8000-000000000001',
      name: 'koza',
      domain: MetricDomain.body,
      kind: MetricKind.photo,
      createdAt: DateTime.utc(2026),
    );
    await controller.saveMetric(photoMarker);
    for (final day in ['2026-08-03', '2026-09-01', '2026-09-02']) {
      await controller.photos.add(
        dayKey: day,
        utcOffsetMinutes: 0,
        fileName: '$day.jpg',
        thumbFileName: '${day}_t.jpg',
        byteSize: 10,
        capturedAt: DateTime.parse('${day}T10:00:00Z'),
        metricId: photoMarker.id,
      );
    }

    await tester.pumpWidget(wrap(HomeScreen(controller: controller)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('koza'), 120);
    await tester.longPress(find.text('koza'));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoTimelineScreen), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('August 2026'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('returning to the app re-reads the day', (tester) async {
    final controller = await freshController();
    await tester.pumpWidget(wrap(HomeScreen(controller: controller)));
    await tester.pumpAndSettle();

    var notified = 0;
    controller.addListener(() => notified++);
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(notified, greaterThan(0));
    controller.dispose();
  });

  group('the day boundary', () {
    test('moving it files new readings differently and leaves old ones alone',
        () async {
      final controller = await freshController();
      final mood = seedIds['mood']!;
      final halfPastOne = DateTime(2026, 9, 10, 1, 30);

      await controller.log(
          mood, const NumberValue(5, kind: MetricKind.scale), now: halfPastOne);
      expect(await controller.readingsOn('2026-09-09'), hasLength(1));

      await controller.setDayBoundaryHour(0);
      await controller.log(
          mood, const NumberValue(6, kind: MetricKind.scale), now: halfPastOne);

      expect(await controller.readingsOn('2026-09-10'), hasLength(1));
      // The first reading keeps the day it was filed under.
      expect(await controller.readingsOn('2026-09-09'), hasLength(1));
      controller.dispose();
    });

    testWidgets('is set in Settings and remembered', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = await freshController();
      await tester.pumpWidget(wrap(SettingsScreen(
        reminder: EveningReminder(RecordingNotifier()),
        settings: ReminderSettings.off,
        controller: controller,
      )));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('04:00'), 150);
      await tester.tap(find.text('04:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('02:00').last);
      await tester.pumpAndSettle();

      expect(controller.dayBoundaryHour, 2);
      expect(await DayBoundary.load(), 2);
      controller.dispose();
    });
  });

  testWidgets('a screen reader hears every day of a report, logged or not',
      (tester) async {
    final handle = tester.ensureSemantics();
    final controller = await freshController();
    final mood = controller.byId(seedIds['mood']!)!;
    await controller.log(mood.id, const NumberValue(7, kind: MetricKind.scale));

    await tester.pumpWidget(wrap(ReportViewScreen.forMarker(
      controller: controller,
      metric: mood,
    )));
    await tester.pumpAndSettle();

    final labels = <String>[];
    void walk(SemanticsNode node) {
      if (node.label.isNotEmpty) labels.add(node.label);
      node.visitChildren((child) {
        walk(child);
        return true;
      });
    }

    walk(tester.getSemantics(find.byType(ReportViewScreen)));

    final yesterday = addDays(controller.today, -1);
    expect(labels, contains('${humanDateFor(controller.today)}: 7'));
    expect(labels, contains('${humanDateFor(yesterday)}: not logged'));
    // One node per day of the window, in order.
    expect(
      labels.where((l) => l.contains(': 7') || l.contains('not logged')),
      hasLength(30),
    );
    controller.dispose();
    handle.dispose();
  });
}

String humanDateFor(String dayKey) =>
    const AppStrings(AppLanguage.en).humanDate(dayKey, withYear: true);
