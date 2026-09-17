import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vitals_archive/vitals_archive.dart';

const reader = ArchiveReader();
const planner = ImportPlanner();

ArchiveManifest manifestWith({int schemaVersion = 3}) => ArchiveManifest(
      app: 'tally',
      appVersion: '1.4.2',
      schemaVersion: schemaVersion,
      installId: '018f2c00-aaaa-7000-8000-000000000001',
      exportedAt: 1786472040000,
      timezone: 'Europe/Dublin',
      dayBoundaryHour: 4,
      device: const {'model': 'Pixel 7a', 'os': 'Android 15'},
      rowCounts: const {'sessions': 2, 'day_ledger': 3},
    );

Map<String, Object?> row(String id, {int updatedAt = 1000, int? deletedAt}) => {
      'id': id,
      'updatedAt': updatedAt,
      'installId': 'install-a',
      'deletedAt': deletedAt,
      'dayKey': '2026-08-11',
    };

Uint8List buildArchive({
  int schemaVersion = 3,
  Map<String, List<Map<String, Object?>>>? tables,
}) {
  final writer = ArchiveWriter(manifest: manifestWith(schemaVersion: schemaVersion));
  (tables ??
          {
            'sessions': [row('a'), row('b')],
            'day_ledger': [
              {'id': 'd1', 'updatedAt': 1, 'installId': 'x', 'dayKey': '2026-08-09'},
              {'id': 'd2', 'updatedAt': 1, 'installId': 'x', 'dayKey': '2026-08-10'},
              {'id': 'd3', 'updatedAt': 1, 'installId': 'x', 'dayKey': '2026-08-11'},
            ],
          })
      .forEach(writer.addTable);
  return writer.build();
}

void main() {
  group('round trip', () {
    test('every row survives export and import unchanged', () {
      final result = reader.read(buildArchive(), appSchemaVersion: 3);
      expect(result.error, isNull);

      final contents = result.contents!;
      expect(contents.tables['sessions']!.rows, hasLength(2));
      expect(contents.tables['day_ledger']!.rows, hasLength(3));
      expect(contents.tables['sessions']!.rows.first['id'], 'a');
      expect(contents.skipped, isEmpty);
    });

    test('the manifest survives intact', () {
      final contents = reader.read(buildArchive(), appSchemaVersion: 3).contents!;
      final m = contents.manifest;
      expect(m.app, 'tally');
      expect(m.schemaVersion, 3);
      expect(m.dayBoundaryHour, 4);
      expect(m.timezone, 'Europe/Dublin');
      expect(m.device['model'], 'Pixel 7a');
      expect(m.totalRows, 5);
    });

    test('media round-trips with relative paths', () {
      final writer = ArchiveWriter(manifest: manifestWith());
      writer.addTable('sessions', [row('a')]);
      writer.addMedia('photos/plant.jpg', utf8.encode('jpeg-bytes'));
      final contents =
          reader.read(writer.build(), appSchemaVersion: 3).contents!;
      expect(contents.mediaPaths, ['photos/plant.jpg']);
    });

    test('an absolute or escaping media path is refused at write time', () {
      // An absolute path from the old phone is a guaranteed broken image, and
      // it fails silently. Catch it while writing, not while reading.
      final writer = ArchiveWriter(manifest: manifestWith());
      expect(
        () => writer.addMedia('/Users/me/photo.jpg', const [1]),
        throwsArgumentError,
      );
      expect(
        () => writer.addMedia('../../etc/passwd', const [1]),
        throwsArgumentError,
      );
    });
  });

  group('refusals', () {
    test('an archive from a newer app is refused outright', () {
      final result = reader.read(buildArchive(schemaVersion: 9), appSchemaVersion: 3);
      expect(result.contents, isNull);
      expect(result.error!.reason, ArchiveRejection.futureSchema);
      // The message must tell the user what to do, not name a schema version.
      expect(result.error!.message, contains('Update the app'));
    });

    test('an older archive is accepted, because migrations carry it forward', () {
      // One migration path, shared by the live database and the restore path.
      final result = reader.read(buildArchive(schemaVersion: 1), appSchemaVersion: 3);
      expect(result.error, isNull);
      expect(result.contents!.manifest.schemaVersion, 1);
    });

    test('a truncated zip fails cleanly', () {
      final full = buildArchive();
      final truncated = Uint8List.sublistView(full, 0, full.length ~/ 2);
      final result = reader.read(truncated, appSchemaVersion: 3);
      expect(result.contents, isNull);
      expect(result.error, isNotNull);
    });

    test('random bytes are not mistaken for a backup', () {
      final result = reader.read(
        Uint8List.fromList(List.generate(500, (i) => i % 256)),
        appSchemaVersion: 3,
      );
      expect(result.contents, isNull);
      expect(result.error!.reason, ArchiveRejection.malformed);
    });

    test('a damaged byte anywhere is a refusal, never a throw', () {
      // The zip directory can survive damage that an entry's compressed
      // stream or the manifest text does not, and those used to throw from
      // inflating or decoding instead of being refused. A throw here is a
      // restore screen that stops with no explanation.
      final bytes = buildArchive();
      final threw = <int>[];
      for (var i = 0; i < bytes.length; i++) {
        final damaged = Uint8List.fromList(bytes);
        damaged[i] ^= 0xFF;
        try {
          reader.read(damaged, appSchemaVersion: 3);
        } on Object {
          threw.add(i);
        }
      }
      expect(threw, isEmpty, reason: '${threw.length} positions threw');
    });

    test('a tampered file is caught by its checksum', () {
      // Flip a byte inside the zip payload and the sha256 no longer matches.
      final bytes = buildArchive();
      var flipped = false;
      for (var i = bytes.length ~/ 3; i < bytes.length - 1 && !flipped; i++) {
        if (bytes[i] != 0) {
          bytes[i] = bytes[i] ^ 0xFF;
          flipped = true;
        }
      }
      final result = reader.read(bytes, appSchemaVersion: 3);
      // Either the zip itself no longer decodes, or the checksum catches it.
      // Both are correct refusals; what must never happen is a silent import.
      expect(result.contents, isNull);
      expect(result.error, isNotNull);
    });

    test('a manifest that is not JSON is refused with plain words', () {
      final parsed = ArchiveManifest.parse('this is not json');
      expect(parsed.manifest, isNull);
      expect(parsed.error!.reason, ArchiveRejection.malformed);
      expect(parsed.error!.message, isNot(contains('FormatException')));
    });

    test('a manifest missing its schema version is refused', () {
      final parsed = ArchiveManifest.parse('{"format":"app-archive/1"}');
      expect(parsed.manifest, isNull);
      expect(parsed.error!.reason, ArchiveRejection.malformed);
    });
  });

  group('a corrupted line costs one row, not the archive', () {
    test('bad lines are skipped and reported', () {
      // The entire reason the format is NDJSON rather than one JSON document.
      final decoded = Ndjson.decode(
        'sessions',
        '${jsonEncode(row('a'))}\n'
        'not json at all\n'
        '${jsonEncode(row('b'))}\n'
        '["an array, not an object"]\n'
        '${jsonEncode(row('c'))}\n',
      );
      expect(decoded.rows.map((r) => r['id']), ['a', 'b', 'c']);
      expect(decoded.skipped, hasLength(2));
      expect(decoded.skipped.first.lineNumber, 2);
      expect(decoded.hadLosses, isTrue);
    });

    test('blank lines are not losses', () {
      final decoded = Ndjson.decode('t', '\n${jsonEncode(row('a'))}\n\n');
      expect(decoded.rows, hasLength(1));
      expect(decoded.skipped, isEmpty);
    });

    test('encode and decode are inverse', () {
      final rows = [row('a'), row('b'), row('c')];
      final decoded = Ndjson.decode('t', Ndjson.encode(rows));
      expect(decoded.rows, rows);
    });
  });

  group('the dry run', () {
    test('states what is being replaced, in plain words', () {
      final contents = reader.read(buildArchive(), appSchemaVersion: 3).contents!;
      final preview = planner.preview(contents);
      expect(preview.summary, contains('2 sessions'));
      expect(preview.summary, contains('3 days'));
      expect(preview.summary, contains('2026-08-09 to 2026-08-11'));
      expect(preview.summary, contains('replaces everything'));
      // Plain and factual. No cheering, no alarm.
      expect(preview.summary, isNot(contains('!')));
    });

    test('merge mode says merge, not replace', () {
      final contents = reader.read(buildArchive(), appSchemaVersion: 3).contents!;
      final preview = planner.preview(contents, mode: ImportMode.merge);
      expect(preview.summary, contains('merges'));
      expect(preview.summary, isNot(contains('replaces')));
    });

    test('reports the day range from the rows, not from the manifest', () {
      final contents = reader.read(buildArchive(), appSchemaVersion: 3).contents!;
      final preview = planner.preview(contents);
      expect(preview.earliestDay, '2026-08-09');
      expect(preview.latestDay, '2026-08-11');
    });

    test('an archive with no day-scoped rows still previews', () {
      final archive = buildArchive(
        tables: {
          'settings': [
            {'id': 's', 'updatedAt': 1, 'installId': 'x'},
          ],
        },
      );
      final contents = reader.read(archive, appSchemaVersion: 3).contents!;
      final preview = planner.preview(contents);
      expect(preview.earliestDay, isNull);
      expect(preview.summary, contains('1 rows'));
    });
  });

  group('the conflict rule', () {
    test('last writer wins', () {
      final older = PortableStamp(id: 'a', updatedAt: 100, installId: 'x');
      final newer = PortableStamp(id: 'a', updatedAt: 200, installId: 'y');
      expect(resolveConflict(older, newer), newer);
      expect(resolveConflict(newer, older), newer);
    });

    test('a tombstone wins a tie', () {
      // Resurrecting deleted data is worse than losing an edit the user can
      // redo.
      final live = PortableStamp(id: 'a', updatedAt: 100, installId: 'x');
      final dead = PortableStamp(
        id: 'a',
        updatedAt: 100,
        installId: 'y',
        deletedAt: 100,
      );
      expect(resolveConflict(live, dead), dead);
      expect(resolveConflict(dead, live), dead);
    });

    test('a newer edit beats an older tombstone', () {
      final dead = PortableStamp(
        id: 'a',
        updatedAt: 100,
        installId: 'x',
        deletedAt: 100,
      );
      final revived = PortableStamp(id: 'a', updatedAt: 200, installId: 'y');
      expect(resolveConflict(dead, revived), revived);
    });

    test('a true tie converges whichever order the devices merge in', () {
      final a = PortableStamp(id: 'r', updatedAt: 100, installId: 'aaa');
      final b = PortableStamp(id: 'r', updatedAt: 100, installId: 'bbb');
      expect(resolveConflict(a, b).installId, resolveConflict(b, a).installId);
    });

    test('deleted() leaves a tombstone rather than dropping the row', () {
      final stamp = PortableStamp(id: 'a', updatedAt: 100, installId: 'x');
      final gone = stamp.deleted(500);
      expect(gone.isDeleted, isTrue);
      expect(gone.deletedAt, 500);
      expect(gone.updatedAt, 500, reason: 'a delete is also an edit');
      expect(gone.id, 'a');
    });
  });

  group('merge', () {
    test('keeps the newer of two versions of a row', () {
      final merged = planner.mergeRows(
        local: [row('a', updatedAt: 100), row('b', updatedAt: 100)],
        incoming: [row('a', updatedAt: 200)],
      );
      expect(merged, hasLength(2));
      expect(
        merged.firstWhere((r) => r['id'] == 'a')['updatedAt'],
        200,
      );
    });

    test('a tombstone on either side removes the row from the live set', () {
      final merged = planner.mergeRows(
        local: [row('a', updatedAt: 100)],
        incoming: [row('a', updatedAt: 200, deletedAt: 200)],
      );
      expect(merged.single['deletedAt'], 200);
    });

    test('is order independent', () {
      final forward = planner.mergeRows(
        local: [row('a', updatedAt: 100)],
        incoming: [row('a', updatedAt: 200)],
      );
      final backward = planner.mergeRows(
        local: [row('a', updatedAt: 200)],
        incoming: [row('a', updatedAt: 100)],
      );
      expect(forward.single['updatedAt'], backward.single['updatedAt']);
    });

    test('rows with no usable id are dropped rather than corrupting the set', () {
      final merged = planner.mergeRows(
        local: const [],
        incoming: [
          {'updatedAt': 1},
          {'id': '', 'updatedAt': 1},
          row('good'),
        ],
      );
      expect(merged.map((r) => r['id']), ['good']);
    });
  });

  group('verification by recomputation', () {
    test('a clean result says so plainly', () {
      const result = ImportVerification(checkedDays: 366, mismatchedDays: []);
      expect(result.isClean, isTrue);
      expect(result.message, 'Restored. Every day checked out.');
    });

    test('a mismatch reports the count and what was done about it', () {
      // Warns, imports the recomputed values, logs. The recomputed number is
      // by definition the correct one, so refusing the import would be wrong.
      const result = ImportVerification(
        checkedDays: 366,
        mismatchedDays: ['2026-03-29', '2026-10-25'],
      );
      expect(result.isClean, isFalse);
      expect(result.message, contains('2 of 366'));
      expect(result.message, contains('recalculated'));
    });
  });

  group('the file name', () {
    test('sorts chronologically and is distinguishable at a glance', () {
      final name = ArchiveManifest.fileNameFor(
        appSlug: 'scroll-allowance',
        exportedAtLocal: DateTime(2026, 8, 10, 19, 34),
      );
      expect(name, 'scroll-allowance-backup-2026-08-10-1934.zip');
    });

    test('zero-pads so a directory listing sorts correctly', () {
      final name = ArchiveManifest.fileNameFor(
        appSlug: 'tally',
        exportedAtLocal: DateTime(2026, 1, 2, 3, 4),
      );
      expect(name, 'tally-backup-2026-01-02-0304.zip');
    });
  });
}
