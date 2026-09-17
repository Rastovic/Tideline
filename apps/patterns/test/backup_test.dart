import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/archive_transfer.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/backup_screen.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_ui/vitals_ui.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';

/// Holds the archive instead of touching the file system.
///
/// The whole reason `ArchiveTransfer` is an interface: restore is the one path
/// where a bug costs data that cannot be typed again, so it has to be drivable
/// end to end in a test rather than only on a phone.
final class FakeTransfer implements ArchiveTransfer {
  Uint8List? sent;
  String? sentName;

  /// What `pick` hands back. Null means the user backed out.
  Uint8List? toPick;

  @override
  Future<Uint8List?> pick() async => toPick;

  @override
  Future<void> send(Uint8List bytes, String fileName) async {
    sent = bytes;
    sentName = fileName;
  }
}

Future<PatternsController> freshController() async {
  final controller = PatternsController(
    db: PatternsDatabase(NativeDatabase.memory()),
    installId: install,
    dayBoundaryHour: 4,
  );
  await controller.seedIfNeeded();
  return controller;
}

Widget wrap(PatternsController controller, FakeTransfer transfer) =>
    MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: BackupScreen(controller: controller, transfer: transfer),
    );

Future<int> readingCount(PatternsController controller) async {
  final readings = await controller.observations.range(
    metricIds: controller.allMarkers.map((m) => m.id),
    from: '2000-01-01',
    to: '2100-01-01',
    kinds: controller.kinds,
  );
  return readings.length;
}

void main() {
  testWidgets('an archive round trips through the screen, which is the only '
      'way to know restore works at all', (tester) async {
    // The plan's one surviving kill criterion is a restore data-loss bug that
    // is not fully understood. It cannot even be looked for until the whole
    // path - export, hand off, pick, preview, confirm, write - runs in a test.
    final controller = await freshController();
    final transfer = FakeTransfer();
    final mood = controller.allMarkers
        .firstWhere((m) => m.kind == MetricKind.scale);
    await controller.log(mood.id, const NumberValue(6, kind: MetricKind.scale));

    await tester.pumpWidget(wrap(controller, transfer));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make a backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(transfer.sent, isNotNull);
    expect(transfer.sentName, contains('tideline-backup-'));

    // Life carries on after the backup: a second reading lands.
    await controller.log(mood.id, const NumberValue(2, kind: MetricKind.scale));
    expect(await readingCount(controller), 2);

    transfer.toPick = transfer.sent;
    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(
      await readingCount(controller),
      1,
      reason: 'the archive replaced what was here, exactly as it warned',
    );
    controller.dispose();
  });

  testWidgets('the export states its size and its photo count before it goes '
      'anywhere', (tester) async {
    final controller = await freshController();
    final transfer = FakeTransfer();

    await tester.pumpWidget(wrap(controller, transfer));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make a backup'));
    await tester.pumpAndSettle();

    expect(find.text('Backup is ready'), findsOneWidget);
    expect(find.textContaining('KB'), findsOneWidget);
    expect(find.textContaining('0 photo'), findsOneWidget);
    expect(transfer.sent, isNull, reason: 'nothing sent before she said so');
    controller.dispose();
  });

  testWidgets('backing out of the export sends nothing', (tester) async {
    final controller = await freshController();
    final transfer = FakeTransfer();

    await tester.pumpWidget(wrap(controller, transfer));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make a backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(transfer.sent, isNull);
    expect(find.textContaining('was not sent anywhere'), findsOneWidget);
    controller.dispose();
  });

  group('restore', () {
    Future<(PatternsController, FakeTransfer, Uint8List)> withArchive() async {
      final controller = await freshController();
      final transfer = FakeTransfer();
      final mood = controller.allMarkers
          .firstWhere((m) => m.kind == MetricKind.scale);
      await controller.log(
        mood.id,
        const NumberValue(6, kind: MetricKind.scale),
      );
      final archive = await controller.exportArchive(appVersion: 'test');
      return (controller, transfer, archive.bytes);
    }

    testWidgets('says what is in the file and what it replaces, before it '
        'writes a byte', (tester) async {
      final (controller, transfer, bytes) = await withArchive();
      transfer.toPick = bytes;
      await controller.log(
        controller.allMarkers.firstWhere((m) => m.kind == MetricKind.scale).id,
        const NumberValue(2, kind: MetricKind.scale),
      );

      await tester.pumpWidget(wrap(controller, transfer));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore from backup'));
      await tester.pumpAndSettle();

      expect(find.text('Restore this backup?'), findsOneWidget);
      expect(find.textContaining('1 entries'), findsOneWidget);
      // Scoped to the dialog: the screen itself carries the same warning as a
      // standing caption, and the point here is that the confirmation repeats
      // it at the moment it matters.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching:
              find.textContaining('replaces everything now in the app'),
        ),
        findsOneWidget,
      );
      expect(
        await readingCount(controller),
        2,
        reason: 'the preview must not have written anything',
      );
      controller.dispose();
    });

    testWidgets('cancelling changes nothing', (tester) async {
      final (controller, transfer, bytes) = await withArchive();
      transfer.toPick = bytes;
      await controller.log(
        controller.allMarkers.firstWhere((m) => m.kind == MetricKind.scale).id,
        const NumberValue(2, kind: MetricKind.scale),
      );

      await tester.pumpWidget(wrap(controller, transfer));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore from backup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await readingCount(controller), 2);
      expect(find.textContaining('Nothing was changed'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('backing out of the file picker changes nothing',
        (tester) async {
      final (controller, transfer, _) = await withArchive();
      transfer.toPick = null;

      await tester.pumpWidget(wrap(controller, transfer));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore from backup'));
      await tester.pumpAndSettle();

      expect(find.text('Restore this backup?'), findsNothing);
      expect(await readingCount(controller), 1);
      controller.dispose();
    });

    testWidgets('a file that is not an archive is refused in plain words',
        (tester) async {
      // Never a stack trace and never an error code. And nothing is touched:
      // the read path cannot reach the database at all.
      final (controller, transfer, _) = await withArchive();
      transfer.toPick = Uint8List.fromList([1, 2, 3, 4, 5]);

      await tester.pumpWidget(wrap(controller, transfer));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore from backup'));
      await tester.pumpAndSettle();

      expect(find.text('Restore this backup?'), findsNothing);
      // In this app's own words, not the shared package's English, and it says
      // what state the data is in rather than only what went wrong.
      expect(
        find.textContaining('not a backup from this app'),
        findsOneWidget,
      );
      expect(find.textContaining('Nothing was changed'), findsOneWidget);
      expect(await readingCount(controller), 1);
      controller.dispose();
    });

    testWidgets('a tampered archive is refused before anything is written',
        (tester) async {
      final (controller, transfer, bytes) = await withArchive();
      // One byte changed in the middle, leaving the zip readable and the
      // checksum wrong - the failure a truncated download actually produces.
      final tampered = Uint8List.fromList(bytes);
      tampered[tampered.length ~/ 2] ^= 0xFF;
      transfer.toPick = tampered;

      await tester.pumpWidget(wrap(controller, transfer));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore from backup'));
      await tester.pumpAndSettle();

      expect(find.text('Restore this backup?'), findsNothing);
      expect(await readingCount(controller), 1);
      controller.dispose();
    });

    testWidgets('the result says how much came back', (tester) async {
      final (controller, transfer, bytes) = await withArchive();
      transfer.toPick = bytes;

      await tester.pumpWidget(wrap(controller, transfer));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore from backup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(find.textContaining('rows restored'), findsOneWidget);
      expect(find.textContaining('photo'), findsWidgets);
      controller.dispose();
    });
  });
}
