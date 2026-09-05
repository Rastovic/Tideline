import 'package:drift/drift.dart';
import 'package:vitals_archive/vitals_archive.dart';

import 'database.dart';

/// Bytes of one stored photo, or null when the file is gone.
typedef PhotoReader = Future<List<int>?> Function(String fileName);

/// Writes one photo back to app-private storage during a restore.
typedef PhotoWriter = Future<void> Function(String fileName, List<int> bytes);

/// What a restore could not bring back.
///
/// Surfaced with a count on the restore screen rather than logged quietly.
/// Discovering in March that the photos never came back is the failure this
/// exists to prevent.
final class RestoreReport {
  const RestoreReport({
    required this.rowsWritten,
    required this.photosRestored,
    required this.photosMissing,
  });

  final int rowsWritten;
  final int photosRestored;

  /// Photo rows whose file was not in the archive. The row is kept, so the day
  /// still shows that a photo existed, and the caption survives.
  final List<String> photosMissing;

  bool get isComplete => photosMissing.isEmpty;
}

/// Exports and restores the whole database, photos included.
///
/// **Photos are inside the archive**, not beside it. The shipped-product plan
/// kept them out to keep the file small, which is the right call for a stranger
/// with a 2GB library and the wrong one here: this is a personal backup, the
/// photos are data, and a backup that silently omits half of what you would cry
/// over is not a backup. The export states its size before it is written.
///
/// Import is **atomic**: everything lands inside one transaction, so a crash, a
/// cancel or a low-memory kill leaves the existing data exactly as it was.
final class PatternsBackup {
  const PatternsBackup(this.db);

  final PatternsDatabase db;

  /// Tables that travel, in a fixed order, so two exports of the same data
  /// produce comparable archives.
  static const exportedTables = [
    'metrics',
    'metric_options',
    'observations',
    'photos',
    'settings',
    'meta',
  ];

  /// Nothing is device-local in this app. Every row means the same thing on
  /// another phone, which is why the list is empty rather than absent.
  static const deviceLocalTables = <String>[];

  List<TableInfo<Table, dynamic>> get _tables => [
        for (final table in db.allTables)
          if (!deviceLocalTables.contains(table.actualTableName)) table,
      ];

  /// Builds the archive.
  ///
  /// [readPhoto] is called once per photo row. A photo whose file has vanished
  /// is skipped rather than failing the export - a missing file is already a
  /// loss, and refusing to back up everything else would make it worse.
  Future<({Uint8List bytes, int photosIncluded, int photosMissing})> export({
    required String appVersion,
    required String installId,
    required int exportedAtMillis,
    required String timezone,
    required int dayBoundaryHour,
    required PhotoReader readPhoto,
    bool includePhotos = true,
    Map<String, String> device = const {},
  }) async {
    final data = <String, List<Map<String, Object?>>>{};
    for (final table in _tables) {
      final rows = await db
          .customSelect('SELECT * FROM ${table.actualTableName}')
          .get();
      data[table.actualTableName] = [for (final row in rows) row.data];
    }

    final writer = ArchiveWriter(
      manifest: ArchiveManifest(
        app: 'patterns',
        appVersion: appVersion,
        schemaVersion: db.schemaVersion,
        installId: installId,
        exportedAt: exportedAtMillis,
        timezone: timezone,
        dayBoundaryHour: dayBoundaryHour,
        device: device,
        rowCounts: {
          for (final entry in data.entries) entry.key: entry.value.length,
        },
      ),
    );
    for (final name in data.keys.toList()..sort()) {
      writer.addTable(name, data[name]!);
    }

    var included = 0;
    var missing = 0;
    if (includePhotos) {
      for (final row in data['photos'] ?? const <Map<String, Object?>>[]) {
        for (final key in ['file_name', 'thumb_file_name']) {
          final fileName = row[key];
          if (fileName is! String || fileName.isEmpty) continue;
          final bytes = await readPhoto(fileName);
          if (bytes == null) {
            missing++;
            continue;
          }
          writer.addMedia(fileName, bytes);
          included++;
        }
      }
    }

    return (
      bytes: writer.build(),
      photosIncluded: included,
      photosMissing: missing,
    );
  }

  /// Reads an archive and writes it in, atomically.
  ///
  /// The caller is expected to have shown a preview and taken a confirmation
  /// first: a restore must never be a surprise, because it replaces data that
  /// cannot be typed again.
  Future<({RestoreReport? report, ArchiveError? error})> import(
    Uint8List zipBytes, {
    required PhotoWriter writePhoto,
    ImportMode mode = ImportMode.replace,
  }) async {
    final read = const ArchiveReader().read(
      zipBytes,
      appSchemaVersion: db.schemaVersion,
    );
    if (read.error != null) return (report: null, error: read.error);

    final contents = read.contents!;
    final media = contents.mediaPaths.toSet();
    var rowsWritten = 0;

    await db.transaction(() async {
      if (mode == ImportMode.replace) {
        for (final table in _tables) {
          await db.customStatement('DELETE FROM ${table.actualTableName}');
        }
      }

      for (final table in _tables) {
        final name = table.actualTableName;
        final rows = contents.tables[name]?.rows;
        if (rows == null || rows.isEmpty) continue;

        final columns = {for (final c in table.$columns) c.name};
        for (final row in rows) {
          // Unknown columns from an older archive are dropped rather than
          // failing the row: a schema that gained a column must still read a
          // backup written before that column existed.
          final kept = <String, Object?>{
            for (final entry in row.entries)
              if (columns.contains(entry.key)) entry.key: entry.value,
          };
          if (kept.isEmpty) continue;

          final placeholders = List.filled(kept.length, '?').join(', ');
          await db.customStatement(
            'INSERT OR REPLACE INTO $name (${kept.keys.join(', ')}) '
            'VALUES ($placeholders)',
            kept.values.toList(),
          );
          rowsWritten++;
        }
      }
    });

    // Photos are written after the transaction commits. A half-written file on
    // disk is recoverable - the row still points at it and the next export
    // reports it missing - while a half-written database is not.
    var restored = 0;
    final missing = <String>[];
    for (final row in contents.tables['photos']?.rows ?? const []) {
      for (final key in ['file_name', 'thumb_file_name']) {
        final fileName = row[key];
        if (fileName is! String || fileName.isEmpty) continue;
        if (!media.contains(fileName)) {
          missing.add(fileName);
          continue;
        }
        final bytes = contents.mediaBytes(fileName);
        if (bytes == null) {
          missing.add(fileName);
          continue;
        }
        await writePhoto(fileName, bytes);
        restored++;
      }
    }

    return (
      report: RestoreReport(
        rowsWritten: rowsWritten,
        photosRestored: restored,
        photosMissing: missing,
      ),
      error: null,
    );
  }
}
