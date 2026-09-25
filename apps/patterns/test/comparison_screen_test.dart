import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/archive_transfer.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/comparison_chart.dart';
import 'package:patterns/screens/comparison_timeline.dart';
import 'package:patterns/screens/report_builder_screen.dart';
import 'package:patterns/screens/report_view_screen.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

final class FakeTransfer implements ArchiveTransfer {
  Uint8List? sent;
  String? sentName;

  @override
  Future<Uint8List?> pick() async => null;

  @override
  Future<void> send(Uint8List bytes, String fileName) async {
    sent = bytes;
    sentName = fileName;
  }
}

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

/// Twenty days: creatine every other day, bloating high on those days.
Future<void> seedPairs(PatternsController controller) async {
  for (var i = 0; i < 20; i++) {
    final day = addDays(controller.today, -i);
    final on = i.isEven;
    await controller.logForDay(seedIds['creatine']!, BooleanValue(on), day);
    await controller.logForDay(
      seedIds['bloating']!,
      NumberValue(on ? 7 : 3, kind: MetricKind.scale),
      day,
    );
  }
}

void main() {
  testWidgets('the name field offers no example to mistake for a name',
      (tester) async {
    final controller = await freshController();
    await tester.pumpWidget(wrap(ReportBuilderScreen(controller: controller)));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Name'),
    );
    expect(field.decoration!.hintText, isNull);
    controller.dispose();
  });

  testWidgets('a comparison is built from the builder and shown in the report',
      (tester) async {
    final controller = await freshController();
    await seedPairs(controller);

    // Pushed rather than made the home screen: saving pops the builder, and
    // a popped last route takes the navigator with it.
    await tester.pumpWidget(wrap(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReportBuilderScreen(controller: controller),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Name'), 'creatine and bloating');
    // The condition first, then what is read on those days.
    await tester.scrollUntilVisible(find.text('creatine'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('creatine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('creatine'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('bloating'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('bloating'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bloating'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Same day'), -120,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Same day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = (await controller.savedReports()).single;
    expect(saved.compare, ComparePairing.sameDay);

    await tester.pumpWidget(wrap(ReportViewScreen(
      controller: controller,
      definition: saved,
    )));
    await tester.pumpAndSettle();

    expect(find.text('BLOATING BY CREATINE'), findsOneWidget);
    // Over time first: both markers stacked on one date axis, each on its
    // own scale, never two y axes in one frame.
    expect(find.byType(ComparisonTimeline), findsOneWidget);
    expect(find.byType(ComparisonChart), findsNothing);
    expect(find.textContaining('each on its own scale'), findsOneWidget);

    // The dependency chart one tap away: one dot per day, nothing fitted.
    await tester.tap(find.text('Dependency'));
    await tester.pumpAndSettle();
    expect(find.byType(ComparisonTimeline), findsNothing);
    expect(find.byType(ComparisonChart), findsOneWidget);
    expect(find.textContaining('No line is fitted'), findsOneWidget);
    expect(find.text('yes'), findsOneWidget);
    expect(find.text('no'), findsOneWidget);
    // The two medians, and the days behind each.
    expect(find.text('7'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.textContaining('20 days with both'), findsOneWidget);
    // It never explains itself as a cause.
    expect(find.textContaining('makes no claim'), findsOneWidget);
    for (final banned in ['caus', 'because', 'proves']) {
      expect(find.textContaining(banned), findsNothing, reason: banned);
    }
    controller.dispose();
  });

  testWidgets('too few shared days says so instead of drawing a difference',
      (tester) async {
    final controller = await freshController();
    await controller.log(seedIds['creatine']!, const BooleanValue(true));

    final definition = ReportDefinition(
      id: '018f2c00-cccc-7000-8000-000000000011',
      name: 'thin',
      series: [
        ReportSeries(metricId: seedIds['creatine']!),
        ReportSeries(metricId: seedIds['bloating']!),
      ],
      period: const LastDays(30),
      compare: ComparePairing.sameDay,
      createdAt: DateTime.utc(2026, 9, 1),
    );
    await tester.pumpWidget(wrap(ReportViewScreen(
      controller: controller,
      definition: definition,
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('Not enough days'), findsOneWidget);
    controller.dispose();
  });
  testWidgets('one report shares as text, on its own', (tester) async {
    final controller = await freshController();
    await seedPairs(controller);
    await controller.log(seedIds['diary']!, const TextValue('private thought'));
    final transfer = FakeTransfer();

    final definition = ReportDefinition(
      id: '018f2c00-cccc-7000-8000-000000000021',
      name: 'Creatine and bloating',
      series: [
        ReportSeries(metricId: seedIds['creatine']!),
        ReportSeries(metricId: seedIds['bloating']!),
      ],
      period: const LastDays(30),
      compare: ComparePairing.sameDay,
      createdAt: DateTime.utc(2026, 9, 1),
    );
    await controller.saveReport(definition);

    await tester.pumpWidget(wrap(ReportViewScreen(
      controller: controller,
      definition: definition,
      transfer: transfer,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Share this report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('For AI (text)'));
    await tester.pumpAndSettle();

    final text = utf8.decode(transfer.sent!);
    // This report's markers, and nothing else's.
    expect(text, contains('creatine'));
    expect(text, contains('bloating'));
    expect(text, isNot(contains('private thought')));
    // The comparison travels as numbers with their counts.
    expect(text, contains('bloating by creatine'));
    expect(text, contains('10'));
    expect(text, contains('makes no claim'));
    expect(transfer.sentName, endsWith('.md'));
    expect(transfer.sentName, startsWith('creatine-and-bloating'));
    controller.dispose();
  });
}
