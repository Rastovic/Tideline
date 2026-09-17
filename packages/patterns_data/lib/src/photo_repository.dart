import 'package:drift/drift.dart';
import 'package:vitals_core/vitals_core.dart';

import 'database.dart';

/// One stored photo, as the app reads it back.
final class StoredPhoto {
  const StoredPhoto({
    required this.id,
    required this.dayKey,
    required this.fileName,
    required this.thumbFileName,
    required this.byteSize,
    required this.capturedAt,
    this.metricId,
    this.observationId,
    this.caption,
  });

  final String id;
  final String dayKey;
  final String fileName;
  final String thumbFileName;
  final int byteSize;
  final DateTime capturedAt;

  /// Null for a free photo that belongs to the day rather than to a marker.
  final String? metricId;
  final String? observationId;

  final String? caption;

  bool get isFree => metricId == null;
}

/// Photo rows. **The bytes never come through here** - files live in
/// app-private storage and this table only ever holds their names.
///
/// The count cap from the shipped-product plan is gone. What replaces it is a
/// size budget the user can look at, because a cap written for occasional
/// photos hits in thirteen months of daily ones, and **the app never deletes a
/// photo on its own**: it can surface the oldest, and the choice stays with the
/// person whose photo it is.
final class PhotoRepository {
  PhotoRepository(this._db, {required this.installId});

  final PatternsDatabase _db;
  final String installId;

  /// Records a photo that has already been written to disk.
  Future<StoredPhoto> add({
    required String dayKey,
    required int utcOffsetMinutes,
    required String fileName,
    required String thumbFileName,
    required int byteSize,
    required DateTime capturedAt,
    String? metricId,
    String? observationId,
    String? caption,
  }) async {
    final id = Ids.newId();
    final millis = capturedAt.toUtc().millisecondsSinceEpoch;
    await _db.into(_db.photos).insert(
          PhotosCompanion.insert(
            id: id,
            updatedAt: millis,
            installId: installId,
            dayKey: dayKey,
            tzOffsetMinutes: utcOffsetMinutes,
            fileName: fileName,
            thumbFileName: thumbFileName,
            byteSize: byteSize,
            capturedAt: millis,
            metricId: Value(metricId),
            observationId: Value(observationId),
            caption: Value(caption),
          ),
        );
    return StoredPhoto(
      id: id,
      dayKey: dayKey,
      fileName: fileName,
      thumbFileName: thumbFileName,
      byteSize: byteSize,
      capturedAt: capturedAt.toUtc(),
      metricId: metricId,
      observationId: observationId,
      caption: caption,
    );
  }

  /// Every photo of one day, marker photos and free ones alike.
  Future<List<StoredPhoto>> onDay(String dayKey) async {
    final rows = await (_db.select(_db.photos)
          ..where((p) => p.dayKey.equals(dayKey) & p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm(expression: p.capturedAt)]))
        .get();
    return [for (final row in rows) _toDomain(row)];
  }

  /// Every photo of one marker, oldest first. The photo timeline reads this.
  Future<List<StoredPhoto>> forMetric(String metricId) async {
    final rows = await (_db.select(_db.photos)
          ..where((p) => p.metricId.equals(metricId) & p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm(expression: p.capturedAt)]))
        .get();
    return [for (final row in rows) _toDomain(row)];
  }

  /// The shot before this one, for the ghost overlay at capture.
  ///
  /// Worth more than any alignment algorithm: framing the next photo like the
  /// last is what makes a series comparable, and it costs one faded image.
  Future<StoredPhoto?> mostRecentFor(String metricId) async {
    final rows = await (_db.select(_db.photos)
          ..where((p) => p.metricId.equals(metricId) & p.deletedAt.isNull())
          ..orderBy([
            (p) => OrderingTerm(
                  expression: p.capturedAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : _toDomain(rows.single);
  }

  /// Every live photo carrying a caption, newest first. Search reads this.
  Future<List<StoredPhoto>> captioned() async {
    final rows = await (_db.select(_db.photos)
          ..where((p) =>
              p.deletedAt.isNull() &
              p.caption.isNotNull() &
              p.caption.equals('').not())
          ..orderBy([
            (p) => OrderingTerm(
                  expression: p.capturedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return [for (final row in rows) _toDomain(row)];
  }

  /// What every photo occupies, for the size budget in Settings.
  Future<int> totalBytes() async {
    final total = _db.photos.byteSize.sum();
    final query = _db.selectOnly(_db.photos)
      ..addColumns([total])
      ..where(_db.photos.deletedAt.isNull());
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }

  Future<void> setCaption(String photoId, String? caption) async {
    await (_db.update(_db.photos)..where((p) => p.id.equals(photoId)))
        .write(PhotosCompanion(
      caption: Value(caption),
      updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
    ));
  }

  /// Soft-deletes the row. **The file is the caller's to remove**, and only
  /// after the user asked: a background job that reclaims space by deleting
  /// photos is the one behaviour this app must never have.
  Future<void> softDelete(String photoId, {required DateTime now}) async {
    final millis = now.toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.photos)..where((p) => p.id.equals(photoId)))
        .write(PhotosCompanion(
      deletedAt: Value(millis),
      updatedAt: Value(millis),
    ));
  }

  StoredPhoto _toDomain(PhotoRow row) => StoredPhoto(
        id: row.id,
        dayKey: row.dayKey,
        fileName: row.fileName,
        thumbFileName: row.thumbFileName,
        byteSize: row.byteSize,
        capturedAt:
            DateTime.fromMillisecondsSinceEpoch(row.capturedAt, isUtc: true),
        metricId: row.metricId,
        observationId: row.observationId,
        caption: row.caption,
      );
}
