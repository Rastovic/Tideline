import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/report_builder_screen.dart';
import 'package:patterns/screens/report_chart.dart';
import 'package:patterns/screens/report_view_screen.dart';
import 'package:patterns/screens/reports_screen.dart';
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
  String name = 'kreatin i nadutost',
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

    expect(find.textContaining('Jos nijedan'), findsOneWidget);
    for (final banned in ['preporu', 'predlaz', 'korelac', 'otkri']) {
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
    expect(find.textContaining('1/30 dana'), findsOneWidget);
    expect(find.textContaining('tipicno 6'), findsOneWidget);
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
        .firstWhere((m) => m.name == 'nadutost');
    final creatine = controller.allMarkers
        .firstWhere((m) => m.name == 'kreatin');
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
    expect(find.text('iza: kreatin'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('re-sorting by cycle day is a view, not a second report',
      (tester) async {
    final controller = await freshController();
    final irritability = controller.allMarkers
        .firstWhere((m) => m.name == 'razdrazljivost');
    final definition = definitionFor([ReportSeries(metricId: irritability.id)]);
    await controller.saveReport(definition);

    await tester.pumpWidget(wrap(ReportViewScreen(
      controller: controller,
      definition: definition,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Po danu ciklusa'));
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
      find.textContaining('Nijedan unos se ne dira'),
      findsOneWidget,
      reason: 'the one delete in the app that cannot cost data says so',
    );
    await tester.tap(find.text('Obrisi'));
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

    expect(find.textContaining('vise ne postoji'), findsOneWidget);
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
        find.widgetWithText(TextField, 'Ime'),
        'kreatin i nadutost',
      );
      await scrollTo(tester, find.text('nadutost'));
      await tester.tap(find.text('nadutost'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sacuvaj'));
      await tester.pumpAndSettle();

      final saved = await controller.savedReports();
      expect(saved, hasLength(1));
      expect(saved.single.name, 'kreatin i nadutost');
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

      await tester.enterText(find.widgetWithText(TextField, 'Ime'), 'prazno');
      await tester.tap(find.text('Sacuvaj'));
      await tester.pumpAndSettle();

      expect(find.text('Izaberi bar jedan marker.'), findsOneWidget);
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
}
