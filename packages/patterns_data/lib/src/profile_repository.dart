import 'package:drift/drift.dart';
import 'package:patterns_core/patterns_core.dart';

import 'database.dart';

/// Profiles in and out of storage.
final class ProfileRepository {
  ProfileRepository(this._db, {required this.installId});

  final PatternsDatabase _db;
  final String installId;

  /// Live profiles, in the order they were made.
  Future<List<Profile>> all() async {
    final rows = await (_db.select(_db.profiles)
          ..where((p) => p.deletedAt.isNull())
          ..orderBy([
            (p) => OrderingTerm(expression: p.sortOrder),
            (p) => OrderingTerm(expression: p.createdAt),
          ]))
        .get();
    return [for (final row in rows) _toDomain(row)];
  }

  Future<void> save(Profile profile, {required DateTime now}) async {
    final millis = now.toUtc().millisecondsSinceEpoch;
    await _db.into(_db.profiles).insertOnConflictUpdate(
          ProfilesCompanion.insert(
            id: profile.id,
            updatedAt: millis,
            installId: installId,
            name: profile.name,
            cycleEnabled: Value(profile.cycleEnabled),
            periodStartMetricId: Value(profile.periodStartMetricId),
            periodEndMetricId: Value(profile.periodEndMetricId),
            sortOrder: Value(profile.sortOrder),
            createdAt: profile.createdAt.toUtc().millisecondsSinceEpoch,
            deletedAt: Value(profile.deletedAt?.toUtc().millisecondsSinceEpoch),
          ),
        );
  }

  /// Makes sure the first profile exists, and writes it if it does not.
  ///
  /// Called on every start and after every restore: a database made before
  /// profiles, or restored from a backup made before them, has markers that
  /// already belong to [defaultProfileId] through the column default, but no
  /// profile row to show for it. The cycle is on for it, and pointed at the
  /// seeded period markers, because that is how the app behaved until now.
  Future<void> ensureDefault({
    required String name,
    required DateTime now,
  }) async {
    final existing = await (_db.select(_db.profiles)
          ..where((p) => p.id.equals(defaultProfileId)))
        .get();
    if (existing.isNotEmpty) return;
    await save(
      Profile(
        id: defaultProfileId,
        name: name,
        createdAt: now.toUtc(),
        cycleEnabled: true,
        periodStartMetricId: seedIds['period-start'],
        periodEndMetricId: seedIds['period-end'],
      ),
      now: now,
    );
  }

  /// Soft-deletes the profile **and its markers, photos and reports**, which
  /// all stop being shown. The rows stay on disk as tombstones, the way every
  /// delete in this app works, so the backup still carries the removal.
  Future<void> softDelete(String profileId, {required DateTime now}) async {
    final millis = now.toUtc().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await (_db.update(_db.profiles)..where((p) => p.id.equals(profileId)))
          .write(ProfilesCompanion(
        deletedAt: Value(millis),
        updatedAt: Value(millis),
      ));
      await (_db.update(_db.metrics)
            ..where((m) => m.profileId.equals(profileId) & m.deletedAt.isNull()))
          .write(MetricsCompanion(
        deletedAt: Value(millis),
        updatedAt: Value(millis),
      ));
      await (_db.update(_db.photos)
            ..where((p) => p.profileId.equals(profileId) & p.deletedAt.isNull()))
          .write(PhotosCompanion(
        deletedAt: Value(millis),
        updatedAt: Value(millis),
      ));
      await (_db.update(_db.savedReports)
            ..where((r) => r.profileId.equals(profileId) & r.deletedAt.isNull()))
          .write(SavedReportsCompanion(
        deletedAt: Value(millis),
        updatedAt: Value(millis),
      ));
    });
  }

  Profile _toDomain(ProfileRow row) => Profile(
        id: row.id,
        name: row.name,
        cycleEnabled: row.cycleEnabled,
        periodStartMetricId: row.periodStartMetricId,
        periodEndMetricId: row.periodEndMetricId,
        sortOrder: row.sortOrder,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
        deletedAt: row.deletedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
      );
}
