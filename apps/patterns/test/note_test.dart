import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/archive_transfer.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/day_detail_screen.dart';
import 'package:patterns/screens/export_screen.dart';
import 'package:patterns/screens/home_screen.dart';
import 'package:patterns/screens/search_screen.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_ui/vitals_ui.dart';

final class FakeTransfer implements ArchiveTransfer {
  Uint8List? sent;

  @override
  Future<Uint8List?> pick() async => null;

  @override
  Future<void> send(Uint8List bytes, String fileName) async => sent = bytes;
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

void main() {
  testWidgets('a note is written with the reading and shown under it',
      (tester) async {
    final controller = await freshController();
    await tester.pumpWidget(wrap(HomeScreen(controller: controller)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('tiredness'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Note'), '  after the pizza  ');
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();

    final reading = (await controller.readingsOn(controller.today)).single;
    // Trimmed, because trailing spaces are not part of a sentence.
    expect(reading.note, 'after the pizza');

    await tester.tap(find.byTooltip('Day detail'));
    await tester.pumpAndSettle();
    expect(find.text('after the pizza'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('an empty note stays null, and editing can clear one',
      (tester) async {
    final controller = await freshController();
    await controller.log(
      seedIds['tiredness']!,
      const NumberValue(6, kind: MetricKind.scale),
      note: 'first thought',
    );

    await tester.pumpWidget(wrap(DayDetailScreen(
      controller: controller,
      dayKey: controller.today,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('tiredness'));
    await tester.pumpAndSettle();
    // The note it is changing is in the field, not a blank one.
    expect(find.widgetWithText(TextField, 'first thought'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'first thought'), '   ');
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();

    final reading = (await controller.readingsOn(controller.today)).single;
    expect(reading.note, isNull);
    controller.dispose();
  });

  testWidgets('the diary and a photo are not offered a note of their own',
      (tester) async {
    final controller = await freshController();
    await tester.pumpWidget(wrap(HomeScreen(controller: controller)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('diary'), 120);
    await tester.tap(find.text('diary'));
    await tester.pumpAndSettle();
    // A diary entry is already the note.
    expect(find.widgetWithText(TextField, 'Note'), findsNothing);
    controller.dispose();
  });

  test('search finds notes, named by their marker', () async {
    final controller = await freshController();
    await controller.log(
      seedIds['bloating']!,
      const NumberValue(7, kind: MetricKind.scale),
      note: 'after the pizza',
    );

    final hits = await controller.search('pizza');
    expect(hits.single.text, 'after the pizza');
    expect(hits.single.markerName, 'bloating');
    expect(hits.single.isNote, isTrue);
    controller.dispose();
  });

  testWidgets('a note leaves the phone only with the diary', (tester) async {
    final controller = await freshController();
    await controller.log(
      seedIds['bloating']!,
      const NumberValue(7, kind: MetricKind.scale),
      note: 'after the pizza',
    );
    final transfer = FakeTransfer();

    await tester.pumpWidget(
        wrap(ExportScreen(controller: controller, transfer: transfer)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Share file'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Share file'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Notes on readings left out: 1.'),
        findsOneWidget);
    await tester.tap(find.text('Share file'));
    await tester.pumpAndSettle();
    expect(utf8.decode(transfer.sent!), isNot(contains('pizza')));
    controller.dispose();
  });

  testWidgets('a hit on a note opens its day', (tester) async {
    final controller = await freshController();
    await controller.log(
      seedIds['bloating']!,
      const NumberValue(7, kind: MetricKind.scale),
      note: 'after the pizza',
    );

    await tester.pumpWidget(wrap(SearchScreen(controller: controller)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('after the pizza'), findsOneWidget);
    expect(find.textContaining('bloating'), findsOneWidget);
    await tester.tap(find.text('after the pizza'));
    await tester.pumpAndSettle();
    expect(find.byType(DayDetailScreen), findsOneWidget);
    controller.dispose();
  });
}
