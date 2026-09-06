import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

/// Patterns' database.
///
/// **Schema version is the whole game for restore.** An archive written at a
/// higher version is refused outright; a lower one migrates forward through
/// [migration], the same chain the live database uses. One migration path, and
/// the restore path shares it.
///
/// This is the one database in the portfolio holding data its owner cannot
/// recreate: a year of readings, a diary, and photos. Every rule below is
/// written with that in mind.
@DriftDatabase(
  tables: [
    Metrics,
    MetricOptions,
    Observations,
    Photos,
    SavedReports,
    Settings,
    AppMeta,
  ],
)
class PatternsDatabase extends _$PatternsDatabase {
  PatternsDatabase(super.e);

  /// Bumped for every schema change, and written into every archive manifest.
  static const currentSchemaVersion = 2;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          // Migration steps land here as the schema grows. Each one must be
          // additive or explicitly lossy with a note, because this chain also
          // carries a two-year-old backup forward on restore.
          //
          // v1 -> v2: saved reports. Purely additive - a v1 archive restores
          // with no reports, which is exactly what a v1 phone had.
          if (from < 2) await m.createTable(savedReports);
          await _createIndexes();
        },
        beforeOpen: (details) async {
          // Foreign keys are off by default in SQLite and must be enabled per
          // connection, not once at creation.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Indexes for the queries the app actually runs.
  ///
  /// Every report reads observations by marker over a date range, and the home
  /// list reads today across every marker. Both are covered by the composite
  /// index; the day-only index carries the day detail screen, which asks for
  /// everything that happened on one date regardless of marker.
  Future<void> _createIndexes() async {
    const statements = [
      'CREATE INDEX IF NOT EXISTS idx_observations_metric_day '
          'ON observations (metric_id, day_key)',
      'CREATE INDEX IF NOT EXISTS idx_observations_day '
          'ON observations (day_key)',
      'CREATE INDEX IF NOT EXISTS idx_observations_deleted '
          'ON observations (deleted_at)',
      'CREATE INDEX IF NOT EXISTS idx_metric_options_metric '
          'ON metric_options (metric_id)',
      'CREATE INDEX IF NOT EXISTS idx_photos_day ON photos (day_key)',
      'CREATE INDEX IF NOT EXISTS idx_photos_metric ON photos (metric_id)',
    ];
    for (final statement in statements) {
      await customStatement(statement);
    }
  }
}
