/// Patterns' schema v1.
///
/// Every table carries [PortableTable], so every row has a UUID id, an
/// `updatedAt` merge key, a `deletedAt` tombstone and the `installId` that
/// wrote it. Enums are stored as **strings, never ordinals** (rule 6).
///
/// **The observations table is long, not wide.** One row per reading, never a
/// column per marker. A wide table cannot survive user-created markers - every
/// new marker would be a migration - and it is the one schema decision here
/// with no way back.
library;

import 'package:drift/drift.dart';
import 'package:vitals_archive/vitals_archive.dart';

/// A thing being tracked. Seeded markers and invented ones are the same row.
@DataClassName('MetricRow')
class Metrics extends Table with PortableTable {
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// `mind` / `body` / `cycle`. Decides which section of the home list it sits
  /// in, and nothing else.
  TextColumn get domain => text()();

  /// One of the eleven kinds, as its wire name.
  TextColumn get kind => text()();

  /// How a day holding several readings collapses in a report: `sum`,
  /// `typical`, `peak`, `lowest`, `last`, `anyTrue`, `union`, `none`.
  ///
  /// **Applied at read time, never at write time.** Changing it re-reads the
  /// same history instead of rewriting it, which is why no aggregate is stored.
  TextColumn get aggregation => text()();

  /// How it draws. Null for the kinds that are never charted.
  TextColumn get displayStyle => text().nullable()();

  /// `#RRGGBB`, from the fixed palette.
  TextColumn get colorHex => text().nullable()();

  TextColumn get unit => text().nullable()();

  IntColumn get scaleMin => integer().withDefault(const Constant(1))();
  IntColumn get scaleMax => integer().withDefault(const Constant(10))();

  TextColumn get lowLabel => text().nullable()();
  TextColumn get highLabel => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();

  /// Archived keeps every reading and stops being offered. Finishing a course
  /// of a supplement is archiving, not deleting.
  IntColumn get archivedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One option of a choice or tags marker.
///
/// A row of its own rather than a JSON blob on the marker, so renaming
/// "overthink" is one UPDATE and four months of readings keep pointing at the
/// same [id].
@DataClassName('MetricOptionRow')
class MetricOptions extends Table with PortableTable {
  TextColumn get metricId => text()();

  TextColumn get label => text().withLength(min: 1, max: 120)();

  TextColumn get colorHex => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Archived options keep their history and stop being offered.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One reading of one marker, at one moment.
///
/// A day holds as many of these per marker as it needs: appetite at 11:00 and
/// again at 22:00 are two rows, not a correction.
@DataClassName('ObservationRow')
class Observations extends Table with PortableTable, DayScopedTable {
  TextColumn get metricId => text()();

  /// UTC epoch millis. Orders readings inside a day.
  IntColumn get recordedAt => integer()();

  /// The reading itself, as the JSON its kind serialises to.
  ///
  /// One column rather than five typed ones because the kind already says how
  /// to read it, and five columns means four are null on every row. **No
  /// numeric copy is stored alongside it**: a second source of truth for the
  /// same number is how a value and its projection drift apart. Reports load a
  /// date range and do the maths in Dart, which at one person's volume is a
  /// few thousand rows a year.
  TextColumn get valueJson => text()();

  /// A sentence about this reading: "7, after the pizza".
  ///
  /// Free text, so it follows the diary's rules wherever anything leaves the
  /// app: never on the doctor page, and in an export only when the diary is
  /// ticked. Null is the normal case - a note is offered, never asked for.
  TextColumn get note => text().nullable()();

  /// Filled in after the fact rather than as it happened. Marked, not hidden.
  BoolColumn get enteredLate => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A photo, stored as a file reference. The bytes never enter the database.
///
/// Attaches **either** to an observation of a photo marker, or to a day on its
/// own - "ovo je poslije treninga" needs no marker to belong to.
@DataClassName('PhotoRow')
class Photos extends Table with PortableTable, DayScopedTable {
  /// Null for a free photo that belongs to the day rather than to a marker.
  TextColumn get metricId => text().nullable()();

  /// Null for a free photo.
  TextColumn get observationId => text().nullable()();

  /// File name inside the app-private photo directory, not a full path: an
  /// absolute path from an old install is wrong after a restore.
  TextColumn get fileName => text()();

  TextColumn get thumbFileName => text()();

  /// Searchable alongside the diary. The caption is what makes a photo mean
  /// anything six months later.
  TextColumn get caption => text().nullable()();

  /// Bytes on disk, so Settings can show a size budget without walking the
  /// directory. **The app never deletes a photo on its own** - it surfaces the
  /// oldest and the choice stays with the user.
  IntColumn get byteSize => integer()();

  IntColumn get capturedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Key-value settings. Day boundary, reminder time, theme, app lock.
class Settings extends Table with PortableTable {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Install identity. Exactly one row.
///
/// Named `AppMeta` rather than `Meta` because drift resolves table classes by
/// name and `Meta` collides with the annotation class in `package:meta`.
@DataClassName('AppMetaRow')
class AppMeta extends Table with PortableTable {
  TextColumn get deviceInstallId => text()();

  IntColumn get installedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A saved report: which markers, over what stretch, drawn how.
///
/// **It stores the question, never the answer.** No aggregate, no cached row,
/// no rendered image - a report is rebuilt from the readings every time it is
/// opened, so changing a marker's day rule re-reads history rather than
/// leaving a saved report showing the old numbers forever.
///
/// Named `SavedReportRow` rather than `Report`, which is the built object in
/// `patterns_core`. Same rule as `AppMeta`: drift generates a data class per
/// table, and a persistence row is not a domain object.
@DataClassName('SavedReportRow')
class SavedReports extends Table with PortableTable {
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// The series, as JSON: marker id, display override, and which row a boolean
  /// band rides behind. JSON rather than a second table because a series has no
  /// identity of its own - it exists only inside its report, and is always read
  /// and written whole.
  TextColumn get seriesJson => text()();

  /// `last:30` or `2026-08-01..2026-08-31`. A rolling window and a fixed
  /// stretch in one column, both round-tripped by `ReportPeriod`.
  TextColumn get period => text()();

  /// `date` or `cycleDay`, as a string. Never an ordinal.
  TextColumn get axis => text()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
