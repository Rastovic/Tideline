import 'archive_io.dart';
import 'manifest.dart';
import 'portable.dart';

/// How an import treats what is already on the device.
enum ImportMode {
  /// Wipe local, load the archive.
  ///
  /// The correct default on a fresh install and the only mode most users ever
  /// want.
  replace,

  /// Row-level last-writer-wins, tombstone wins a tie.
  ///
  /// Needed only when someone has genuinely used two devices. **If v1 does not
  /// ship this, the UI says so rather than silently replacing.**
  merge,
}

/// What the user is shown before anything is written.
///
/// The dry run exists so a restore is never a surprise. Overwriting six months
/// of a baby's feeds, or a year of solvency history, by accident is
/// unforgivable and entirely preventable.
final class ImportPreview {
  const ImportPreview({
    required this.mode,
    required this.manifest,
    required this.rowCounts,
    required this.skipped,
    required this.mediaCount,
    this.earliestDay,
    this.latestDay,
  });

  final ImportMode mode;
  final ArchiveManifest manifest;
  final Map<String, int> rowCounts;
  final List<String> skipped;
  final int mediaCount;
  final String? earliestDay;
  final String? latestDay;

  int get totalRows => rowCounts.values.fold(0, (a, b) => a + b);

  /// The sentence the confirmation sheet shows.
  ///
  /// Plain and factual, and it always states what is being replaced. No
  /// exclamation marks: this app's voice is a friend with a spreadsheet.
  String get summary {
    final parts = <String>[];
    final sessions = rowCounts['sessions'];
    if (sessions != null && sessions > 0) parts.add('$sessions sessions');
    final days = rowCounts['day_ledger'];
    if (days != null && days > 0) parts.add('$days days');
    if (parts.isEmpty) parts.add('$totalRows rows');

    final range = earliestDay != null && latestDay != null
        ? ', $earliestDay to $latestDay'
        : '';
    final tail = mode == ImportMode.replace
        ? 'This replaces everything currently in the app.'
        : 'This merges with what is already here.';
    return '${parts.join(', ')}$range. $tail';
  }

  bool get hadLosses => skipped.isNotEmpty;
}

/// Builds the preview, and nothing else.
///
/// Deliberately separate from anything that writes: the read path can be tested
/// exhaustively without a database, and a bug here cannot corrupt data.
final class ImportPlanner {
  const ImportPlanner();

  /// Column names a day key can arrive under.
  ///
  /// Drift writes `day_key`; a hand-built archive or a future JSON producer may
  /// write `dayKey`. Accepting both is not politeness: the date range is the
  /// load-bearing sentence on the confirmation sheet, and looking for the wrong
  /// name loses it **silently**, leaving the user to confirm a wipe with no
  /// idea what period they are about to replace.
  static const dayKeyColumns = ['day_key', 'dayKey'];

  ImportPreview preview(
    ArchiveContents contents, {
    ImportMode mode = ImportMode.replace,
    List<String> dayKeyColumnNames = dayKeyColumns,
  }) {
    final counts = {
      for (final entry in contents.tables.entries)
        entry.key: entry.value.rows.length,
    };

    String? earliest;
    String? latest;
    for (final table in contents.tables.values) {
      for (final row in table.rows) {
        for (final column in dayKeyColumnNames) {
          final day = row[column];
          if (day is! String || day.length != 10) continue;
          if (earliest == null || day.compareTo(earliest) < 0) earliest = day;
          if (latest == null || day.compareTo(latest) > 0) latest = day;
          break;
        }
      }
    }

    return ImportPreview(
      mode: mode,
      manifest: contents.manifest,
      rowCounts: counts,
      skipped: [for (final row in contents.skipped) row.toString()],
      mediaCount: contents.mediaPaths.length,
      earliestDay: earliest,
      latestDay: latest,
    );
  }

  /// Merges incoming rows against local ones by id.
  ///
  /// Last-writer-wins on `updatedAt`, tombstone wins a tie, and a true tie
  /// between two live rows breaks on `installId` so two devices merging in
  /// opposite order still converge.
  List<Map<String, Object?>> mergeRows({
    required List<Map<String, Object?>> local,
    required List<Map<String, Object?>> incoming,
  }) {
    final byId = <String, Map<String, Object?>>{};

    void consider(Map<String, Object?> row) {
      final id = row['id'];
      if (id is! String || id.isEmpty) return;
      final existing = byId[id];
      if (existing == null) {
        byId[id] = row;
        return;
      }
      // Stamps are built once and compared by identity, so the winner maps
      // straight back to the row it came from.
      final existingStamp = _stampOf(existing);
      final winner = resolveConflict(existingStamp, _stampOf(row));
      byId[id] = identical(winner, existingStamp) ? existing : row;
    }

    local.forEach(consider);
    incoming.forEach(consider);

    return byId.values.toList()
      ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  }

  PortableStamp _stampOf(Map<String, Object?> row) => PortableStamp(
        id: row['id'] as String? ?? '',
        updatedAt: row['updatedAt'] as int? ?? 0,
        installId: row['installId'] as String? ?? '',
        deletedAt: row['deletedAt'] as int?,
      );
}

/// The outcome of verifying an import by recomputation.
///
/// Named `ImportVerification` rather than `VerificationResult` because drift
/// exports a type of that name and every app here uses drift.
///
/// After import, the engine is re-run over the imported raw inputs and compared
/// against the imported derived rows. A mismatch **warns, imports the
/// recomputed values, and logs** rather than refusing: the recomputed number is
/// by definition the correct one.
///
/// In an app with a ledger this check is free, and it tests the exporter, the
/// importer and the engine at once, on real user data.
final class ImportVerification {
  const ImportVerification({
    required this.checkedDays,
    required this.mismatchedDays,
  });

  final int checkedDays;
  final List<String> mismatchedDays;

  bool get isClean => mismatchedDays.isEmpty;

  /// What the warning says when it is not clean.
  String get message => isClean
      ? 'Restored. Every day checked out.'
      : '${mismatchedDays.length} of $checkedDays days did not match and were '
          'recalculated from your sessions.';
}
