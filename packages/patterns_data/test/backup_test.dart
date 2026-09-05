import 'dart:convert';
import 'package:archive/archive.dart';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:test/test.dart';
import 'package:vitals_archive/vitals_archive.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';
final now = DateTime.utc(2026, 8, 19, 10);

/// Stands in for app-private photo storage.
final class FakePhotoStore {
  final files = <String, List<int>>{};

  Future<List<int>?> read(String name) async => files[name];

  Future<void> write(String name, List<int> bytes) async =>
      files[name] = bytes;
}

void main() {
  late PatternsDatabase db;
  late MetricRepository metrics;
  late ObservationRepository readings;
  late FakePhotoStore photos;

  Future<Uint8List> exportAll({bool includePhotos = true}) async {
    final result = await PatternsBackup(db).export(
      appVersion: '0.1.0',
      installId: install,
      exportedAtMillis: now.millisecondsSinceEpoch,
      timezone: 'Europe/Belgrade',
      dayBoundaryHour: 4,
      readPhoto: photos.read,
      includePhotos: includePhotos,
    );
    return result.bytes;
  }

  setUp(() async {
    db = PatternsDatabase(NativeDatabase.memory());
    metrics = MetricRepository(db, installId: install);
    readings = ObservationRepository(db, installId: install);
    photos = FakePhotoStore();
    await metrics.seedIfEmpty(now: now);
    await readings.log(
      metricId: seedIds['mood']!,
      value: const NumberValue(7, kind: MetricKind.scale),
      at: DateTime.utc(2026, 8, 19, 20),
      utcOffsetMinutes: 120,
    );
    await readings.log(
      metricId: seedIds['diary']!,
      value: const TextValue('bila sam umorna zbog posla'),
      at: DateTime.utc(2026, 8, 19, 21),
      utcOffsetMinutes: 120,
    );
  });
  tearDown(() => db.close());

  Future<void> addPhoto({required bool withFile}) async {
    photos.files['p1.jpg'] = utf8.encode('full-size bytes');
    photos.files['p1-thumb.jpg'] = utf8.encode('thumb bytes');
    if (!withFile) photos.files.remove('p1.jpg');
    await db.into(db.photos).insert(
          PhotosCompanion.insert(
            id: '0198aa02-0000-7000-8000-000000000001',
            updatedAt: now.millisecondsSinceEpoch,
            installId: install,
            dayKey: '2026-08-19',
            tzOffsetMinutes: 120,
            fileName: 'p1.jpg',
            thumbFileName: 'p1-thumb.jpg',
            byteSize: 15,
            capturedAt: now.millisecondsSinceEpoch,
          ),
        );
  }

  group('a backup is the whole thing, photos included', () {
    test('every row and every photo comes back', () async {
      await addPhoto(withFile: true);
      final bytes = await exportAll();

      final restoredDb = PatternsDatabase(NativeDatabase.memory());
      final restoredPhotos = FakePhotoStore();
      final result = await PatternsBackup(restoredDb).import(
        bytes,
        writePhoto: restoredPhotos.write,
      );

      expect(result.error, isNull);
      expect(result.report!.isComplete, isTrue);
      expect(result.report!.photosRestored, 2);

      final restoredMetrics =
          MetricRepository(restoredDb, installId: install);
      final restoredReadings =
          ObservationRepository(restoredDb, installId: install);
      final all = await restoredMetrics.all();
      expect(all, hasLength(18));

      final kinds = {for (final m in all) m.id: m.kind};
      final day = await restoredReadings.onDay('2026-08-19', kinds: kinds);
      expect(day, hasLength(2));
      expect(
        day.firstWhere((o) => o.metricId == seedIds['diary']).value,
        const TextValue('bila sam umorna zbog posla'),
      );
      expect(restoredPhotos.files['p1.jpg'], utf8.encode('full-size bytes'));
      await restoredDb.close();
    });

    test('options keep their ids, so old readings still point at them',
        () async {
      final bytes = await exportAll();
      final restoredDb = PatternsDatabase(NativeDatabase.memory());
      await PatternsBackup(restoredDb).import(
        bytes,
        writePhoto: photos.write,
      );
      final feelings = await MetricRepository(restoredDb, installId: install)
          .byId(seedIds['feelings']!);
      expect(
        feelings!.options.map((o) => o.id),
        contains(seedOptionIds['feelings.overthink']),
      );
      await restoredDb.close();
    });
  });

  group('what did not come back is stated, with a count', () {
    test('a photo whose file was already gone is reported, not hidden',
        () async {
      await addPhoto(withFile: false);
      final bytes = await exportAll();

      final restoredDb = PatternsDatabase(NativeDatabase.memory());
      final result = await PatternsBackup(restoredDb).import(
        bytes,
        writePhoto: FakePhotoStore().write,
      );

      expect(result.report!.isComplete, isFalse);
      expect(result.report!.photosMissing, ['p1.jpg']);
      // The row survives, so the day still shows a photo existed and the
      // caption is not lost as well.
      expect(await restoredDb.select(restoredDb.photos).get(), hasLength(1));
      await restoredDb.close();
    });

    test('an export without photos says so by omitting them', () async {
      await addPhoto(withFile: true);
      final result = await PatternsBackup(db).export(
        appVersion: '0.1.0',
        installId: install,
        exportedAtMillis: now.millisecondsSinceEpoch,
        timezone: 'Europe/Belgrade',
        dayBoundaryHour: 4,
        readPhoto: photos.read,
        includePhotos: false,
      );
      expect(result.photosIncluded, 0);

      final restoredDb = PatternsDatabase(NativeDatabase.memory());
      final imported = await PatternsBackup(restoredDb).import(
        result.bytes,
        writePhoto: FakePhotoStore().write,
      );
      expect(imported.report!.photosMissing, hasLength(2));
      await restoredDb.close();
    });
  });

  group('nothing touches the live data until the archive is trusted', () {
    test('a file that is not a backup is refused and changes nothing',
        () async {
      final before = await db.select(db.observations).get();
      final result = await PatternsBackup(db).import(
        Uint8List.fromList(utf8.encode('this is a photo, not a backup')),
        writePhoto: photos.write,
      );
      expect(result.error, isNotNull);
      expect(result.report, isNull);
      expect(await db.select(db.observations).get(), hasLength(before.length));
    });

    test('an archive from a newer schema is refused outright', () async {
      final writer = ArchiveWriter(
        manifest: ArchiveManifest(
          app: 'patterns',
          appVersion: '9.9.9',
          schemaVersion: PatternsDatabase.currentSchemaVersion + 1,
          installId: install,
          exportedAt: now.millisecondsSinceEpoch,
          timezone: 'Europe/Belgrade',
          dayBoundaryHour: 4,
          rowCounts: const {},
        ),
      )..addTable('metrics', const []);

      final result = await PatternsBackup(db).import(
        writer.build(),
        writePhoto: photos.write,
      );
      expect(result.error, isNotNull);
      // Downgrading is the case where a silent partial import would corrupt
      // real history, so it stops before the transaction opens.
      expect(await db.select(db.metrics).get(), hasLength(18));
    });

    test('a tampered archive fails its checksum', () async {
      // One row edited inside the zip, checksums left as they were. This is
      // what a half-written file or a helpful cloud "repair" looks like, and
      // it is the case where importing anyway would quietly corrupt a year of
      // readings.
      final original = ZipDecoder().decodeBytes(await exportAll());
      final rebuilt = Archive();
      for (final file in original.files) {
        if (!file.isFile) continue;
        final bytes = file.name == 'data/observations.ndjson'
            ? utf8.encode(utf8.decode(file.readBytes()!).replaceFirst('7', '2'))
            : file.readBytes()!;
        rebuilt.addFile(ArchiveFile(file.name, bytes.length, bytes));
      }

      final result = await PatternsBackup(db).import(
        Uint8List.fromList(ZipEncoder().encode(rebuilt)),
        writePhoto: photos.write,
      );
      expect(result.error, isNotNull);
    });
  });
}
