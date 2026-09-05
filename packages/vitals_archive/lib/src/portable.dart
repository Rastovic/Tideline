import 'package:drift/drift.dart';

/// The four columns every portable table carries.
///
/// Rules 1 to 4 of `00-foundation/DATA-PORTABILITY.md`. They cost nothing on
/// day one and are **unfixable once real users hold real history**, which is
/// why they live in a mixin rather than in a convention someone has to
/// remember.
///
/// ```dart
/// class Tasks extends Table with PortableTable {
///   TextColumn get title => text()();
///   @override
///   Set<Column> get primaryKey => {id};
/// }
/// ```
mixin PortableTable on Table {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  IntColumn get updatedAt => integer()();

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  IntColumn get deletedAt => integer().nullable()();

  /// Which install created this row. Tells a future merge which device said
  /// what.
  TextColumn get installId => text().withLength(min: 36, max: 36)();
}

/// A table whose rows belong to a calendar day.
///
/// Rule 5: the day key is **frozen at write time** and never derived at read
/// time. A user who flies to Tokyo must not see last March's statement change.
mixin DayScopedTable on Table {
  /// `YYYY-MM-DD`, computed once by the app's own day-boundary rule.
  TextColumn get dayKey => text().withLength(min: 10, max: 10)();

  /// Device offset from UTC when the row was written, in minutes.
  ///
  /// Kept so a statement can explain itself later, and so a merge can tell a
  /// genuine duplicate from two rows written in different zones.
  IntColumn get tzOffsetMinutes => integer()();
}

/// Values every portable row needs at insert time.
///
/// Built through this rather than by hand so a caller cannot forget
/// [installId] or leave [updatedAt] at zero.
final class PortableStamp {
  const PortableStamp({
    required this.id,
    required this.updatedAt,
    required this.installId,
    this.deletedAt,
  });

  final String id;
  final int updatedAt;
  final String installId;
  final int? deletedAt;

  /// Marks this row deleted at [millis], leaving the tombstone behind.
  PortableStamp deleted(int millis) => PortableStamp(
        id: id,
        updatedAt: millis,
        installId: installId,
        deletedAt: millis,
      );

  /// Bumps [updatedAt] so a merge sees this as the newer side.
  PortableStamp touched(int millis) => PortableStamp(
        id: id,
        updatedAt: millis,
        installId: installId,
        deletedAt: deletedAt,
      );

  bool get isDeleted => deletedAt != null;
}

/// Resolves two versions of the same row.
///
/// **Last-writer-wins on [PortableStamp.updatedAt], with a tombstone winning a
/// tie.** Identical semantics to the merge import and to a future `POST /sync`,
/// so the product has one conflict rule rather than two.
///
/// A tie broken in favour of the tombstone is deliberate: resurrecting deleted
/// data is worse than losing an edit the user can redo.
PortableStamp resolveConflict(PortableStamp a, PortableStamp b) {
  if (a.updatedAt > b.updatedAt) return a;
  if (b.updatedAt > a.updatedAt) return b;
  if (a.isDeleted) return a;
  if (b.isDeleted) return b;
  // A true tie between two live rows: pick deterministically so two devices
  // merging in opposite order still converge on the same answer.
  return a.installId.compareTo(b.installId) <= 0 ? a : b;
}
