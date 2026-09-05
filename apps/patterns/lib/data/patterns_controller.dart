import 'package:flutter/foundation.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_core/vitals_core.dart';

import 'photo_store.dart';

/// What the home list shows for one marker.
///
/// A tick and a count, never a score. There is no completion percentage here
/// and no "you missed" state, because a day with nothing logged is a day, not
/// a failure.
final class MarkerStatus {
  const MarkerStatus({required this.metric, required this.count});

  final Metric metric;

  /// Readings recorded today. Zero renders as a dash.
  final int count;

  bool get isLoggedToday => count > 0;
}

/// Everything the screens read, and the only thing that writes.
///
/// A plain [ChangeNotifier] rather than a state-management package: one person,
/// one screen at a time, and a dependency here would outlive whatever is
/// fashionable when it was added.
final class PatternsController extends ChangeNotifier {
  PatternsController({
    required PatternsDatabase db,
    required String installId,
    required int dayBoundaryHour,
    PhotoStore? photoStore,
  })  : _db = db,
        _dayBoundaryHour = dayBoundaryHour,
        // ignore: prefer_initializing_formals
        _photoStore = photoStore,
        metrics = MetricRepository(db, installId: installId),
        observations = ObservationRepository(
          db,
          installId: installId,
          dayBoundaryHour: dayBoundaryHour,
        ),
        photos = PhotoRepository(db, installId: installId);

  final PatternsDatabase _db;
  final int _dayBoundaryHour;

  /// Null in tests and on a device where the directory could not be opened.
  /// Every photo path checks it rather than assuming.
  final PhotoStore? _photoStore;

  final MetricRepository metrics;
  final ObservationRepository observations;
  final PhotoRepository photos;

  PhotoStore? get photoStore => _photoStore;

  List<Metric> _all = const [];
  Map<String, int> _todayCounts = const {};
  String _today = '';
  bool _loading = true;

  bool get isLoading => _loading;

  /// The day key the app is currently calling "today", frozen by the same rule
  /// every reading is written with.
  String get today => _today;

  /// Live markers, grouped for the home list, in the user's own order.
  Map<MetricDomain, List<MarkerStatus>> get sections {
    final grouped = <MetricDomain, List<MarkerStatus>>{};
    for (final metric in _all) {
      if (!metric.isActive) continue;
      grouped.putIfAbsent(metric.domain, () => []).add(
            MarkerStatus(metric: metric, count: _todayCounts[metric.id] ?? 0),
          );
    }
    return grouped;
  }

  Map<String, MetricKind> get kinds => {
        for (final metric in _all) metric.id: metric.kind,
      };

  Metric? byId(String id) {
    for (final metric in _all) {
      if (metric.id == id) return metric;
    }
    return null;
  }

  /// Loads markers and today's counts. Called on start and after every write.
  Future<void> refresh({DateTime? now}) async {
    final at = (now ?? DateTime.now()).toUtc();
    _today = dayKeyFor(
      at,
      offsetMinutes: (now ?? DateTime.now()).timeZoneOffset.inMinutes,
      dayBoundaryHour: _dayBoundaryHour,
    );
    _all = await metrics.all();
    _todayCounts = await observations.countsOnDay(_today);
    _loading = false;
    notifyListeners();
  }

  /// Writes the starting markers on a fresh install.
  Future<void> seedIfNeeded() async {
    await metrics.seedIfEmpty(now: DateTime.now().toUtc());
    await refresh();
  }

  /// Records one reading, now.
  Future<void> log(String metricId, MetricValue value, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    await observations.log(
      metricId: metricId,
      value: value,
      at: at.toUtc(),
      utcOffsetMinutes: at.timeZoneOffset.inMinutes,
    );
    await refresh(now: at);
  }

  /// Records one reading against a day chosen by hand.
  Future<void> logForDay(
    String metricId,
    MetricValue value,
    String dayKey,
  ) async {
    final now = DateTime.now();
    await observations.logForDay(
      metricId: metricId,
      value: value,
      dayKey: dayKey,
      now: now.toUtc(),
      utcOffsetMinutes: now.timeZoneOffset.inMinutes,
    );
    await refresh();
  }

  Future<void> updateValue(String observationId, MetricValue value) async {
    await observations.updateValue(
      observationId,
      value,
      now: DateTime.now().toUtc(),
    );
    await refresh();
  }

  Future<void> deleteReading(String observationId) async {
    await observations.softDelete(observationId, now: DateTime.now().toUtc());
    await refresh();
  }

  /// Everything recorded on one day, for the day detail screen.
  Future<List<Observation>> readingsOn(String dayKey) =>
      observations.onDay(dayKey, kinds: kinds);

  /// Every photo of one day, marker photos and free ones alike.
  Future<List<StoredPhoto>> photosOn(String dayKey) => photos.onDay(dayKey);

  /// Saves a captured image and records it.
  ///
  /// Two rows, in this order: the photo row first, then - for a marker photo -
  /// an observation pointing at it. If the app dies between them the photo is
  /// still on the day, which is the failure worth having: an orphaned photo is
  /// visible and recoverable, an observation pointing at nothing is neither.
  ///
  /// [metricId] null records a free photo that belongs to the day alone.
  Future<StoredPhoto?> capturePhoto(
    Uint8List bytes, {
    String? metricId,
    String? dayKey,
    String? caption,
  }) async {
    final store = _photoStore;
    if (store == null) return null;
    final saved = await store.save(bytes);
    if (saved == null) return null;

    final now = DateTime.now();
    final day = dayKey ?? _today;
    final photo = await photos.add(
      dayKey: day,
      utcOffsetMinutes: now.timeZoneOffset.inMinutes,
      fileName: saved.fileName,
      thumbFileName: saved.thumbFileName,
      byteSize: saved.byteSize,
      capturedAt: now.toUtc(),
      metricId: metricId,
      caption: caption,
    );

    if (metricId != null) {
      await observations.logForDay(
        metricId: metricId,
        value: PhotoValue(photoId: photo.id, caption: caption),
        dayKey: day,
        now: now.toUtc(),
        utcOffsetMinutes: now.timeZoneOffset.inMinutes,
      );
    }

    await refresh();
    return photo;
  }

  /// Deletes a photo: the row first, then the files.
  ///
  /// Only ever from an explicit tap. Nothing here runs on a timer or on low
  /// storage, because an app that quietly deletes your photos to save space is
  /// worse than an app that runs out of it.
  Future<void> deletePhoto(StoredPhoto photo) async {
    await photos.softDelete(photo.id, now: DateTime.now().toUtc());
    await _photoStore?.deleteFiles(photo.fileName, photo.thumbFileName);
    await refresh();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }
}
