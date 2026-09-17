import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/report_builder_screen.dart';
import 'package:patterns/screens/day_grid_chart.dart';
import 'package:patterns/screens/report_chart.dart';
import 'package:patterns/screens/report_view_screen.dart';
import 'package:patterns/screens/reports_screen.dart';
import 'package:patterns/l10n/app_language.dart';
import 'package:patterns/l10n/app_strings.dart';
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

Widget wrap(Widget child) => MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: child,
    );

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

ReportDefinition definitionFor(
  List<ReportSeries> series, {
  String name = 'creatine and bloating',
  ReportAxis axis = ReportAxis.date,
}) =>
    ReportDefinition(
      id: '018f2c00-cccc-7000-8000-000000000001',
      name: name,
      series: series,
      period: const LastDays(30),
      axis: axis,
      createdAt: DateTime.utc(2026, 9, 1),
    );

void main() {
  testWidgets('the saved list starts empty and suggests nothing',
      (tester) async {
    // The app never offers a comparison. The whole point is that the
    // connections are hers, made afterwards, which is the same rule that keeps
    // markers from owning each other in the model.
    final controller = await freshController();
    await tester.pumpWidget(wrap(ReportsScreen(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.textContaining('None yet'), findsOneWidget);
    for (final banned in ['preporu', 'predlaz', 'korelac', 'otkri', 'suggest', 'recommend', 'correlat', 'discover']) {
      expect(find.textContaining(banned), findsNothing, reason: banned);
    }
    controller.dispose();
  });

  testWidgets('a saved report opens and draws one row per marker',
      (tester) async {
    final controller = await freshController();
    final mood = controller.allMarkers
        .firstWhere((m) => m.kind == MetricKind.scale);
    final dose = controller.allMarkers
        .firstWhere((m) => m.kind == MetricKind.amount);
    await controller.log(mood.id, const NumberValue(6, kind: MetricKind.scale));
    await controller.log(dose.id, const NumberValue(3, kind: MetricKind.amount));

    final definition = definitionFor([
      ReportSeries(metricId: mood.id),
      ReportSeries(metricId: dose.id),
    ]);
    await controller.saveReport(definition);

    await tester.pumpWidget(wrap(ReportViewScreen(
      controller: controller,
      definition: definition,
    )));
    await tester.pumpAndSettle();

    expect(find.byType(ReportRowChart), findsNWidgets(2));
    expect(find.text(mood.name), findsOneWidget);
    expect(find.text(dose.name), findsOneWidget);
    controller.dispose();
  });

  testWidgets('the facts under a row are counts and ranges, never a grade',
      (tester) async {
    final controller = await freshController();
    final mood = controller.allMarkers
        .firstWhere((m) => m.kind == MetricKind.scale);
    await controller.log(mood.id, const NumberValue(6, kind: MetricKind.scale));

    final definition = definitionFor([ReportSeries(metricId: mood.id)]);
    await tester.pumpWidget(wrap(ReportViewScreen(
      controller: controller,
      definition: definition,
    )));
    await tester.pumpAndSettle();

    // Coverage travels with the number: one day of thirty is a different
    // statement from twenty-eight, and hiding that is how a tracker lies.
    expect(find.textContaining('1/30 days'), findsOneWidget);
    expect(find.textContaining('typical 6'), findsOneWidget);
    for (final banned in ['dobro', 'lose', 'bolje', 'gore', 'ocjena', '%']) {
      expect(find.textContaining(banned), findsNothing, reason: banned);
    }
    controller.dispose();
  });

  testWidgets('a boolean set as a band is not a row of its own',
      (tester) async {
    // The one overlay the app permits, and safe because a band has no scale to
    // stretch until it agrees with the series in front of it.
    final controller = await freshController();
    final bloating = controller.allMarkers
        .firstWhere((m) => m.name == 'bloating');
    final creatine = controller.allMarkers
        .firstWhere((m) => m.name == 'creatine');
    await controller.log(creatine.id, const BooleanValue(true));

    final definition = definitionFor([
      ReportSeries(metricId: bloating.id),
      ReportSeries(metricId: creatine.id, bandBehindMetricId: bloating.id),
    ]);

    await tester.pumpWidget(wrap(ReportViewScreen(
      controller: controller,
      definition: definition,
    )));
    await tester.pumpAndSettle();

    expect(find.byType(ReportRowChart), findsOneWidget);
    expect(find.text('behind: creatine'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('re-sorting by cycle day is a view, not a second report',
      (tester) async {
    final controller = await freshController();
    final irritability = controller.allMarkers
        .firstWhere((m) => m.name == 'irritability');
    final definition = definitionFor([ReportSeries(metricId: irritability.id)]);
    await controller.saveReport(definition);

    await tester.pumpWidget(wrap(ReportViewScreen(
      controller: controller,
      definition: definition,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('By cycle day'));
    await tester.pumpAndSettle();

    final saved = await controller.savedReports();
    expect(saved.single.axis, ReportAxis.cycleDay);
    expect(saved, hasLength(1), reason: 'the same report, re-sorted');
    controller.dispose();
  });

  testWidgets('deleting a report cannot cost a reading', (tester) async {
    final controller = await freshController();
    final mood = controller.allMarkers
        .firstWhere((m) => m.kind == MetricKind.scale);
    await controller.log(mood.id, const NumberValue(6, kind: MetricKind.scale));
    await controller.saveReport(
      definitionFor([ReportSeries(metricId: mood.id)]),
    );

    await tester.pumpWidget(wrap(ReportsScreen(controller: controller)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No entry is touched'),
      findsOneWidget,
      reason: 'the one delete in the app that cannot cost data says so',
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(await controller.savedReports(), isEmpty);
    final left = await controller.readingsOn(controller.today);
    expect(left.where((o) => o.metricId == mood.id), hasLength(1));
    controller.dispose();
  });

  testWidgets('a report whose markers were all deleted says so rather than '
      'showing an empty frame', (tester) async {
    final controller = await freshController();
    final definition = definitionFor([
      const ReportSeries(metricId: 'gone'),
    ]);

    await tester.pumpWidget(wrap(ReportViewScreen(
      controller: controller,
      definition: definition,
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('exist any more'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('every display style draws without help', (tester) async {
    // A structural sweep rather than a golden: each painter has to survive a
    // row that is mostly unlogged, which is what a real month looks like.
    final controller = await freshController();
    final byKind = {
      for (final metric in controller.allMarkers) metric.kind: metric,
    };

    for (final kind in MetricKind.values) {
      final metric = byKind[kind];
      if (metric == null) continue;
      for (final style in DisplayStyle.allowedFor(kind)) {
        final definition = definitionFor(
          [ReportSeries(metricId: metric.id, displayStyle: style)],
          name: '${kind.wireName}/${style.wireName}',
        );
        await tester.pumpWidget(wrap(ReportViewScreen(
          controller: controller,
          definition: definition,
        )));
        await tester.pumpAndSettle();
        expect(
          find.byType(ReportRowChart),
          findsOneWidget,
          reason: '${kind.wireName} as ${style.wireName}',
        );
      }
    }
    controller.dispose();
  });

  group('building one', () {
    testWidgets('a report is named, given markers, and saved', (tester) async {
      final controller = await freshController();
      await tester.pumpWidget(
        wrap(ReportBuilderScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'creatine and bloating',
      );
      await scrollTo(tester, find.text('bloating'));
      await tester.tap(find.text('bloating'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved = await controller.savedReports();
      expect(saved, hasLength(1));
      expect(saved.single.name, 'creatine and bloating');
      expect(saved.single.series, hasLength(1));
      expect(saved.single.period.wire, 'last:30');
      controller.dispose();
    });

    testWidgets('a report with no markers is refused, and says why',
        (tester) async {
      final controller = await freshController();
      await tester.pumpWidget(
        wrap(ReportBuilderScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'prazno');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Pick at least one marker.'), findsOneWidget);
      expect(await controller.savedReports(), isEmpty);
      controller.dispose();
    });

    testWidgets('the markers that are never charted are not offered',
        (tester) async {
      // A diary and a photo have no display style, so there is nothing for a
      // row to draw. They live on the day detail screen, which is where a
      // photo belongs: next to what else happened that day.
      final controller = await freshController();
      await tester.pumpWidget(
        wrap(ReportBuilderScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      final diary = controller.allMarkers
          .firstWhere((m) => m.kind == MetricKind.text);
      expect(find.text(diary.name), findsNothing);
      controller.dispose();
    });
  });

  group('row order', () {
    testWidgets('a dragged row saves in its new place, and the band follows it',
        (tester) async {
      final controller = await freshController();
      final scales = controller.allMarkers
          .where((m) => m.kind == MetricKind.scale)
          .take(3)
          .toList();
      final flag = controller.allMarkers
          .firstWhere((m) => m.kind == MetricKind.boolean);
      final definition = definitionFor([
        for (final m in scales) ReportSeries(metricId: m.id),
        ReportSeries(metricId: flag.id, bandBehindMetricId: scales.last.id),
      ]);

      await tester.pumpWidget(wrap(ReportBuilderScreen(
        controller: controller,
        definition: definition,
      )));
      await tester.pumpAndSettle();

      // A band has no place of its own in the stack, so only rows are offered.
      final handles = find.byIcon(Icons.drag_handle);
      expect(handles, findsNWidgets(3));

      final rowHeight = tester.getSize(find.byType(ListTile).first).height;
      final gesture =
          await tester.startGesture(tester.getCenter(handles.last));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(0, -rowHeight * 2.5 / 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved = (await controller.savedReports()).single;
      expect(
        [for (final s in saved.series) s.metricId],
        [scales[2].id, scales[0].id, scales[1].id, flag.id],
      );
      expect(saved.series.last.bandBehindMetricId, scales[2].id);

      // The report draws in the order it was saved in.
      final report = await controller.buildSavedReport(saved);
      expect(
        [for (final row in report.rows) row.metric.id],
        [scales[2].id, scales[0].id, scales[1].id],
      );
      controller.dispose();
    });

    testWidgets('one row has nothing to order, so there is no section',
        (tester) async {
      final controller = await freshController();
      final mood = controller.allMarkers
          .firstWhere((m) => m.kind == MetricKind.scale);
      await tester.pumpWidget(wrap(ReportBuilderScreen(
        controller: controller,
        definition: definitionFor([ReportSeries(metricId: mood.id)]),
      )));
      await tester.pumpAndSettle();

      expect(find.text('REDOSLIJED'), findsNothing);
      expect(find.byIcon(Icons.drag_handle), findsNothing);
      controller.dispose();
    });
  });

  group('the day grid', () {
    testWidgets('is a layout of the same cells, not a different reading',
        (tester) async {
      final controller = await freshController();
      final mood = controller.allMarkers
          .firstWhere((m) => m.kind == MetricKind.scale);
      await controller.log(
        mood.id,
        const NumberValue(6, kind: MetricKind.scale),
      );

      await tester.pumpWidget(wrap(ReportViewScreen(
        controller: controller,
        definition: definitionFor(
          [ReportSeries(metricId: mood.id)],
          axis: ReportAxis.grid,
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.byType(DayGridChart), findsOneWidget);
      expect(find.byType(ReportRowChart), findsNothing);
      // The facts line is unchanged: the grid answers a different question
      // about the same numbers, so it must not report different ones.
      expect(find.textContaining('1/30 days'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('labels every weekday, because two of them share an initial',
        (tester) async {
      final controller = await freshController();
      final mood = controller.allMarkers
          .firstWhere((m) => m.kind == MetricKind.scale);

      await tester.pumpWidget(wrap(ReportViewScreen(
        controller: controller,
        definition: definitionFor(
          [ReportSeries(metricId: mood.id)],
          axis: ReportAxis.grid,
        ),
      )));
      await tester.pumpAndSettle();

      for (final label in const AppStrings(AppLanguage.en).weekdays) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      controller.dispose();
    });

    testWidgets('switching to the grid keeps one report, not two',
        (tester) async {
      final controller = await freshController();
      final mood = controller.allMarkers
          .firstWhere((m) => m.kind == MetricKind.scale);
      final definition = definitionFor([ReportSeries(metricId: mood.id)]);
      await controller.saveReport(definition);

      await tester.pumpWidget(wrap(ReportViewScreen(
        controller: controller,
        definition: definition,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grid'));
      await tester.pumpAndSettle();

      final saved = await controller.savedReports();
      expect(saved, hasLength(1));
      expect(saved.single.axis, ReportAxis.grid);
      expect(find.byType(DayGridChart), findsOneWidget);
      controller.dispose();
    });

    test('a grid report round trips through storage', () async {
      // `axis` is a wire string, so adding a third value needed no migration -
      // and an older build reads an unknown axis as null and skips the report
      // rather than crashing on it.
      expect(ReportAxis.fromWire('grid'), ReportAxis.grid);
      expect(ReportAxis.fromWire('byMoonPhase'), isNull);
    });
  });

  group('a fixed date range', () {
    testWidgets('is picked from the builder and saved as a fixed period',
        (tester) async {
      final controller = await freshController();
      await tester.pumpWidget(
        wrap(ReportBuilderScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'avgust');

      // The range first, then the marker: `scrollUntilVisible` only walks one
      // way, and Period sits above Markeri on this form.
      await scrollTo(tester, find.text('Date range'));
      await tester.tap(find.text('Date range'));
      await tester.pumpAndSettle();

      // The picker opens on today, which is the only date guaranteed to be on
      // screen and inside the bounds.
      final today = DateTime.now();
      await tester.tap(find.text('${today.day}').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('${today.day}').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('bloating'));
      await tester.tap(find.text('bloating'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved = await controller.savedReports();
      expect(saved.single.period, isA<FixedPeriod>());
      final period = saved.single.period as FixedPeriod;
      expect(period.from, period.to, reason: 'one day picked twice');
      expect(period.from, contains('-'));
      controller.dispose();
    });

    testWidgets('backing out of the picker leaves the period alone',
        (tester) async {
      final controller = await freshController();
      await tester.pumpWidget(
        wrap(ReportBuilderScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Date range'));
      await tester.tap(find.text('Date range'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Date range'), findsOneWidget);
      expect(find.text('month'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('an existing fixed period shows on the chip and reopens',
        (tester) async {
      // Reachable rather than stuck: before this, a saved fixed period drew a
      // chip that could be looked at and not changed.
      final controller = await freshController();
      final mood = controller.allMarkers
          .firstWhere((m) => m.kind == MetricKind.scale);
      final year = DateTime.now().year;
      final definition = ReportDefinition(
        id: '018f2c00-cccc-7000-8000-000000000007',
        name: 'avgust',
        series: [ReportSeries(metricId: mood.id)],
        period: FixedPeriod(from: '$year-08-01', to: '$year-08-31'),
        createdAt: DateTime.utc(2026, 9, 1),
      );

      await tester.pumpWidget(wrap(ReportBuilderScreen(
        controller: controller,
        definition: definition,
      )));
      await tester.pumpAndSettle();

      // The year is dropped when it is this one: a chip is a few characters
      // wide and two ISO dates do not fit.
      expect(find.text('1.8. - 31.8.'), findsOneWidget);
      controller.dispose();
    });

    test('a fixed period does not move, and a rolling one does', () {
      const fixed = FixedPeriod(from: '2026-08-01', to: '2026-08-31');
      expect(fixed.resolve('2026-09-07'), ('2026-08-01', '2026-08-31'));
      expect(fixed.resolve('2027-01-01'), ('2026-08-01', '2026-08-31'));
      expect(const LastDays(7).resolve('2027-01-01'),
          ('2026-12-26', '2027-01-01'));
    });
  });
}
