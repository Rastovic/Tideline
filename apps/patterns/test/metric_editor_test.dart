import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/metric_editor_screen.dart';
import 'package:patterns/screens/metrics_screen.dart';
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

Widget wrapEditor(PatternsController controller, {Metric? metric}) =>
    MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: MetricEditorScreen(controller: controller, metric: metric),
    );

Widget wrapList(PatternsController controller) => MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: MetricsScreen(controller: controller),
    );

/// Scrolls the form until [finder] is on screen, then settles.
///
/// The editor is a long form and the test viewport is 800x600, so half of it
/// starts off screen and off the element tree. Scrolling rather than enlarging
/// the window keeps the test honest about a phone.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Back to the top of the form, where the error banner is.
Future<void> scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new marker is created without a code change, which is the '
      'whole point of this screen', (tester) async {
    final controller = await freshController();
    final before = controller.allMarkers.length;
    await tester.pumpWidget(wrapEditor(controller));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'kosa');
    await scrollTo(tester, find.text('Photo'));
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final made = controller.allMarkers.firstWhere((m) => m.name == 'kosa');
    expect(controller.allMarkers, hasLength(before + 1));
    expect(made.kind, MetricKind.photo);
    // A photo is never charted, so it carries no display style and its day is
    // not collapsed. The editor took both from the kind rather than asking.
    expect(made.displayStyle, isNull);
    expect(made.aggregation, DayAggregation.none);
    controller.dispose();
  });

  testWidgets('a marker with no name is refused, and says so', (tester) async {
    final controller = await freshController();
    await tester.pumpWidget(wrapEditor(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Give it a name.'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('every problem is shown at once, not one at a time',
      (tester) async {
    // Fixing a form error by error is how a person gives up on a form.
    final controller = await freshController();
    await tester.pumpWidget(wrapEditor(controller));
    await tester.pumpAndSettle();

    // A scale with no name and no labelled ends: two failures, one tap.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Give it a name.'), findsOneWidget);
    expect(
      find.text('Say what the low end and the high end mean.'),
      findsOneWidget,
    );
    controller.dispose();
  });

  testWidgets('the editor offers only the rules the kind can take',
      (tester) async {
    final controller = await freshController();
    await tester.pumpWidget(wrapEditor(controller));
    await tester.pumpAndSettle();

    // A rating: typical, peak, lowest, last - and never a sum, because adding
    // two moods together is not a number that means anything.
    await scrollTo(tester, find.text('Typical'));
    expect(find.text('Typical'), findsOneWidget);
    expect(find.text('Sum'), findsNothing);

    await scrollToTop(tester);
    await scrollTo(tester, find.text('Amount'));
    await tester.tap(find.text('Amount'));
    await tester.pumpAndSettle();

    // A dose: 3 g and 2 g on one day are 5 g.
    await scrollTo(tester, find.text('Sum'));
    expect(find.text('Sum'), findsOneWidget);
    expect(find.text('Typical'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('nothing on this screen can set a goal, a target or a streak',
      (tester) async {
    // The ban is mechanised here rather than left to discipline: a target
    // field is how grading gets added to a recording app by accident.
    final controller = await freshController();
    await tester.pumpWidget(wrapEditor(controller));
    await tester.pumpAndSettle();

    for (final banned in ['Cilj', 'cilj', 'Niz', 'Meta', 'Uspjeh']) {
      expect(find.textContaining(banned), findsNothing, reason: banned);
    }
    controller.dispose();
  });

  group('a marker that already holds readings', () {
    Future<(PatternsController, Metric)> withReadings() async {
      final controller = await freshController();
      final marker = controller.allMarkers
          .firstWhere((m) => m.kind == MetricKind.scale && m.scaleMin == 1);
      for (final value in [2, 9]) {
        await controller.log(
          marker.id,
          NumberValue(value, kind: MetricKind.scale),
        );
      }
      return (controller, marker);
    }

    testWidgets('cannot be retyped, and the screen says why', (tester) async {
      final (controller, marker) = await withReadings();
      await tester.pumpWidget(wrapEditor(controller, metric: marker));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.textContaining('2 entries'));
      expect(find.textContaining('2 entries'), findsOneWidget);
      expect(find.textContaining('archive this one and make a new one'),
          findsOneWidget);
      // The kinds that would reinterpret those two readings are not offered at
      // all, so the refusal happens before the tap rather than after it.
      expect(find.text('Percent'), findsNothing);
      expect(find.text('Photo'), findsNothing);
      controller.dispose();
    });

    testWidgets('cannot have its scale narrowed under a reading that exists',
        (tester) async {
      final (controller, marker) = await withReadings();
      await tester.pumpWidget(wrapEditor(controller, metric: marker));
      await tester.pumpAndSettle();

      // Bottom from 1 to 4, which would strand the reading of 2.
      await scrollTo(tester, find.text('RANGE'));
      final up = find.widgetWithIcon(IconButton, Icons.add);
      for (var i = 0; i < 3; i++) {
        await tester.tap(up.first);
        await tester.pump();
      }
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // No manual scroll here on purpose: the form scrolls itself back to the
      // banner. Without that, refusing an edit made at the bottom of a long
      // form looks exactly like the Save button doing nothing.
      expect(find.textContaining('below the new bottom'), findsOneWidget);
      expect(
        (await controller.metrics.byId(marker.id))!.scaleMin,
        1,
        reason: 'a refused edit must not reach storage',
      );
      controller.dispose();
    });

    testWidgets('can still be renamed, recoloured and re-summarised',
        (tester) async {
      // The guards are about meaning, not about locking the marker: everything
      // that re-reads the same history rather than reinterpreting it stays
      // editable forever.
      final (controller, marker) = await withReadings();
      await tester.pumpWidget(wrapEditor(controller, metric: marker));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'bloating ujutru',
      );
      await scrollTo(tester, find.text('Highest'));
      await tester.tap(find.text('Highest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved = (await controller.metrics.byId(marker.id))!;
      expect(saved.name, 'bloating ujutru');
      expect(saved.aggregation, DayAggregation.peak);
      controller.dispose();
    });
  });

  testWidgets('archiving keeps the marker and takes it off the home list',
      (tester) async {
    final controller = await freshController();
    final marker = controller.allMarkers.first;
    await tester.pumpWidget(wrapEditor(controller, metric: marker));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Archive'));
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    final archived = (await controller.metrics.byId(marker.id))!;
    expect(archived.isArchived, isTrue);
    expect(archived.isDeleted, isFalse);
    expect(
      controller.sections[marker.domain]?.map((s) => s.metric.id),
      isNot(contains(marker.id)),
    );
    controller.dispose();
  });

  testWidgets('the marker list shows archived markers, which home hides',
      (tester) async {
    // Archiving a finished course of a supplement must not be
    // indistinguishable from losing it.
    final controller = await freshController();
    final marker = controller.allMarkers.first;
    await controller.archiveMarker(marker.id);

    await tester.pumpWidget(wrapList(controller));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('ARCHIVED'));
    expect(find.text('ARCHIVED'), findsOneWidget);
    expect(find.text(marker.name), findsOneWidget);
    controller.dispose();
  });

  testWidgets('deleting a marker leaves its readings on disk', (tester) async {
    final controller = await freshController();
    final marker = controller.allMarkers
        .firstWhere((m) => m.kind == MetricKind.scale);
    await controller.log(marker.id, const NumberValue(5, kind: MetricKind.scale));
    final kinds = controller.kinds;

    await tester.pumpWidget(wrapEditor(controller, metric: marker));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Delete marker'));
    await tester.tap(find.text('Delete marker'));
    await tester.pumpAndSettle();
    // The dialog's own button, not the one on the form behind it.
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Delete'),
    ));
    await tester.pumpAndSettle();

    expect(await controller.metrics.byId(marker.id), isNull);
    final left = await controller.observations.onDay(
      controller.today,
      kinds: kinds,
    );
    expect(
      left.where((o) => o.metricId == marker.id),
      hasLength(1),
      reason: 'deleting a marker by accident must not take a year of numbers',
    );
    controller.dispose();
  });
}
