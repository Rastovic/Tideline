import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/archive_transfer.dart';
import 'package:patterns/data/doctor_pdf.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/doctor_page_screen.dart';
import 'package:patterns/screens/export_screen.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:pdf/widgets.dart' as pw;
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

Future<({pw.Font regular, pw.Font bold})?> noFonts() async => null;

/// Page objects in an uncompressed PDF, `/Pages` excluded.
int pageCount(Uint8List bytes) =>
    RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length;

void main() {
  group('the rendered file', () {
    test('is one page, whatever eight markers hold, on both papers',
        () async {
      final controller = await freshController();
      final charted = controller.allMarkers
          .where((m) => m.displayStyle != null)
          .take(doctorPageMaxMarkers)
          .toList();
      for (final m in charted) {
        if (m.kind == MetricKind.scale) {
          await controller.log(
              m.id, const NumberValue(7, kind: MetricKind.scale));
        }
      }
      final page = await controller.doctorPage(
        [for (final m in charted) m.id],
        const LastDays(180),
      );
      expect(page.entries, hasLength(charted.length));

      for (final paper in DoctorPaper.values) {
        final bytes = await renderDoctorPdf(
          page,
          generatedAt: DateTime(2026, 9, 17),
          paper: paper,
          compress: false,
        );
        expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
        expect(pageCount(bytes), 1, reason: paper.label);
      }
      controller.dispose();
    });

    test('the facts are counts and ranges, never a verdict', () {
      final mood = Metric.create(
        id: 'm',
        name: 'mood',
        domain: MetricDomain.mind,
        kind: MetricKind.scale,
        createdAt: DateTime.utc(2026),
      );
      final page = buildDoctorPage(
        metrics: [mood],
        observations: [
          for (final (day, n) in [('2026-09-01', 2), ('2026-09-03', 9)])
            Observation(
              id: day,
              metricId: 'm',
              dayKey: day,
              recordedAt: DateTime.utc(2026, 9, 1),
              utcOffsetMinutes: 0,
              value: NumberValue(n, kind: MetricKind.scale),
            ),
        ],
        from: '2026-09-01',
        to: '2026-09-30',
      );
      final lines = doctorFacts(page.entries.single).join(' ');
      expect(lines, contains('lowest 2 (1.9.)'));
      expect(lines, contains('highest 9 (3.9.)'));
      expect(lines, contains('2/30 days logged'));
      for (final banned in [
        'bolje', 'gore', 'normal', 'zabrinj', 'poboljs', 'pogors', 'trend',
      ]) {
        expect(lines, isNot(contains(banned)), reason: banned);
      }
    });
  });

  group('the screen', () {
    Widget wrap(Widget child) => MaterialApp(
          theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
          home: child,
        );

    testWidgets('picks markers and shares one PDF', (tester) async {
      final controller = await freshController();
      final transfer = FakeTransfer();
      await tester.pumpWidget(wrap(DoctorPageScreen(
        controller: controller,
        transfer: transfer,
        fonts: noFonts,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('tiredness'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Make PDF'), 200);
      await tester.runAsync(() async {
        await tester.tap(find.text('Make PDF'));
        // Rendering runs real async work the fake clock does not advance.
        for (var i = 0; i < 50 && transfer.sent == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();

      expect(transfer.sent, isNotNull);
      expect(transfer.sentName, endsWith('.pdf'));
      controller.dispose();
    });

    testWidgets('nothing picked is refused, and says why', (tester) async {
      final controller = await freshController();
      final transfer = FakeTransfer();
      await tester.pumpWidget(wrap(DoctorPageScreen(
        controller: controller,
        transfer: transfer,
        fonts: noFonts,
      )));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Make PDF'), 200);
      await tester.tap(find.text('Make PDF'));
      await tester.pumpAndSettle();

      expect(transfer.sent, isNull);
      await tester.scrollUntilVisible(
          find.text('Pick at least one marker.'), -200);
      expect(find.text('Pick at least one marker.'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('a diary is never offered', (tester) async {
      final controller = await freshController();
      await tester.pumpWidget(wrap(DoctorPageScreen(
        controller: controller,
        transfer: FakeTransfer(),
        fonts: noFonts,
      )));
      await tester.pumpAndSettle();
      expect(find.text('diary'), findsNothing);
      controller.dispose();
    });
  });
  group('the export screen', () {
    Widget wrap(Widget child) => MaterialApp(
          theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
          home: child,
        );

    testWidgets('says what is held back, then shares text without it',
        (tester) async {
      final controller = await freshController();
      await controller.log(
          seedIds['mood']!, const NumberValue(6, kind: MetricKind.scale));
      await controller.log(
          seedIds['diary']!, const TextValue('tajna', isPrivate: true));
      await controller.log(seedIds['diary']!, const TextValue('obicno'));
      final transfer = FakeTransfer();

      await tester.pumpWidget(wrap(
        ExportScreen(controller: controller, transfer: transfer),
      ));
      await tester.pumpAndSettle();

      // Lazily built, so scroll it into existence, then fully on screen.
      await tester.scrollUntilVisible(
        find.text('Share file'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Share file'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Private diary entries left out: 1.'),
          findsOneWidget);
      expect(find.textContaining('Diary not ticked, left out: 1.'),
          findsOneWidget);

      await tester.tap(find.text('Share file'));
      await tester.pumpAndSettle();

      final text = utf8.decode(transfer.sent!);
      expect(transfer.sentName, endsWith('.md'));
      expect(text, contains('mood'));
      expect(text, isNot(contains('tajna')));
      expect(text, isNot(contains('obicno')));
      controller.dispose();
    });

    testWidgets('CSV is one tap away and is plain CSV', (tester) async {
      final controller = await freshController();
      await controller.log(
          seedIds['mood']!, const NumberValue(6, kind: MetricKind.scale));
      final transfer = FakeTransfer();
      await tester.pumpWidget(wrap(
        ExportScreen(controller: controller, transfer: transfer),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spreadsheet (CSV)'));
      await tester.pumpAndSettle();
      // Lazily built, so scroll it into existence, then fully on screen.
      await tester.scrollUntilVisible(
        find.text('Share file'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Share file'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share file'));
      await tester.pumpAndSettle();

      expect(transfer.sentName, endsWith('.csv'));
      expect(utf8.decode(transfer.sent!),
          startsWith('date,time,marker,kind,value,unit,note,entered_late'));
      controller.dispose();
    });
  });
}
