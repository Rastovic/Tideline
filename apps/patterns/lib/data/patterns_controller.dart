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
        photos = PhotoRepository(db, installId: installId),
        reports = ReportRepository(db, installId: installId);

  final PatternsDatabase _db;
  final int _dayBoundaryHour;

  /// Null in tests and on a device where the directory could not be opened.
  /// Every photo path checks it rather than assuming.
  final PhotoStore? _photoStore;

  final MetricRepository metrics;
  final ObservationRepository observations;
  final PhotoRepository photos;
  final ReportRepository reports;

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

  /// Saved reports, newest question first.
  Future<List<ReportDefinition>> savedReports() => reports.all();

  Future<void> saveReport(ReportDefinition definition) async {
    await reports.save(definition, now: DateTime.now().toUtc());
    notifyListeners();
  }

  /// Soft-deletes a report. **No reading is touched**, because a report is a
  /// lens over flat data rather than something the readings hang off.
  Future<void> deleteReport(String id) async {
    await reports.softDelete(id, now: DateTime.now().toUtc());
    notifyListeners();
  }

  /// Rebuilds a report from the readings, every time.
  ///
  /// Nothing is cached. Changing a marker's day rule from "typical" to "peak"
  /// re-reads history rather than leaving a saved report showing yesterday's
  /// numbers, which is the whole reason the stored row holds the question and
  /// not the answer.
  Future<Report> buildSavedReport(ReportDefinition definition) async {
    final (from, to) = definition.period.resolve(_today);
    final all = await metrics.all();
    final wanted = definition.metricIds.toSet();
    final readings = await observations.range(
      metricIds: wanted,
      from: from,
      to: to,
      kinds: {for (final m in all) m.id: m.kind},
    );

    return buildReport(
      definition,
      metrics: all,
      observations: readings,
      today: _today,
      cyclePeriods: await cyclePeriods(),
    );
  }

  /// The recorded periods, derived from the two cycle markers.
  ///
  /// Counting, never predicting: an unanchored stretch produces no cycle day
  /// rather than a guessed one, and there is no function anywhere that
  /// estimates a next period.
  Future<List<CyclePeriod>> cyclePeriods() async {
    final startId = seedIds['period-start'];
    final endId = seedIds['period-end'];
    if (startId == null || endId == null) return const [];
    return buildPeriods(
      startDayKeys: await observations.trueDays(startId),
      endDayKeys: await observations.trueDays(endId),
    );
  }

  /// Every marker including the archived ones, for the marker editor.
  ///
  /// The home list drops archived markers; the editor must not, or a finished
  /// course of a supplement becomes unreachable the moment it is archived.
  List<Metric> get allMarkers => List.unmodifiable(_all);

  /// The next free position in a section, so a new marker lands at the bottom
  /// of its own list rather than in the middle of another one.
  int nextSortOrder(MetricDomain domain) {
    var highest = -1;
    for (final metric in _all) {
      if (metric.domain != domain) continue;
      if (metric.sortOrder > highest) highest = metric.sortOrder;
    }
    return highest + 1;
  }

  /// What is already recorded against a marker, for the editor's guards.
  Future<MetricReadingFacts> factsFor(Metric metric) =>
      observations.factsFor(metric.id, kind: metric.kind);

  /// Writes a marker, new or edited.
  ///
  /// Validation is the caller's job and happens in the editor, where the
  /// failures can be shown against the fields that caused them.
  Future<void> saveMetric(Metric metric) async {
    await metrics.save(metric, now: DateTime.now().toUtc());
    await refresh();
  }

  /// Takes a marker off the home list and keeps every reading it holds.
  Future<void> archiveMarker(String metricId) async {
    await metrics.archive(metricId, now: DateTime.now().toUtc());
    await refresh();
  }

  Future<void> unarchiveMarker(String metricId) async {
    await metrics.unarchive(metricId, now: DateTime.now().toUtc());
    await refresh();
  }

  /// Soft-deletes a marker. **Its readings stay on disk**, so deleting one by
  /// accident does not take a year of numbers with it.
  Future<void> deleteMarker(String metricId) async {
    await metrics.softDelete(metricId, now: DateTime.now().toUtc());
    await refresh();
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
