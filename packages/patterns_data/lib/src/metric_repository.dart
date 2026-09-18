import 'package:drift/drift.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';

import 'database.dart';

/// Markers in and out of storage.
///
/// Rows here, domain objects out. No maths, no rules - anything that decides
/// something lives in `patterns_core`, where it can be tested without a
/// database.
final class MetricRepository {
  MetricRepository(this._db, {required this.installId});

  final PatternsDatabase _db;

  /// Stamped onto every row this device writes.
  final String installId;

  /// Every marker, options attached, in home-list order.
  ///
  /// Archived markers are included by default because reports draw the months
  /// they were live: a supplement finished in May is still on the chart.
  /// [profileId] null reads every profile's markers, which only backup-side
  /// and cross-profile checks want; every screen passes one.
  Future<List<Metric>> all({
    bool includeArchived = true,
    String? profileId,
  }) async {
    final metricRows = await (_db.select(_db.metrics)
          ..where((m) => profileId == null
              ? m.deletedAt.isNull()
              : m.deletedAt.isNull() & m.profileId.equals(profileId))
          ..orderBy([(m) => OrderingTerm(expression: m.sortOrder)]))
        .get();
    final optionRows = await (_db.select(_db.metricOptions)
          ..where((o) => o.deletedAt.isNull()))
        .get();

    final optionsByMetric = <String, List<MetricOption>>{};
    for (final row in optionRows) {
      optionsByMetric.putIfAbsent(row.metricId, () => []).add(
            MetricOption(
              id: row.id,
              label: row.label,
              colorHex: row.colorHex,
              sortOrder: row.sortOrder,
              archived: row.archived,
            ),
          );
    }

    final metrics = [
      for (final row in metricRows)
        _toDomain(row, optionsByMetric[row.id] ?? const []),
    ];
    if (includeArchived) return metrics;
    return metrics.where((m) => m.isActive).toList();
  }

  Future<Metric?> byId(String id) async {
    final all = await this.all();
    for (final metric in all) {
      if (metric.id == id) return metric;
    }
    return null;
  }

  /// Writes a marker and its options, replacing what was there.
  ///
  /// Options are diffed rather than deleted and re-inserted: an option keeps
  /// its id for the life of the marker, because every reading that ever picked
  /// it points at that id.
  Future<void> save(Metric metric, {required DateTime now}) async {
    final millis = now.toUtc().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await _db.into(_db.metrics).insertOnConflictUpdate(
            MetricsCompanion.insert(
              id: metric.id,
              updatedAt: millis,
              installId: installId,
              profileId: Value(metric.profileId),
              name: metric.name,
              domain: metric.domain.wireName,
              kind: metric.kind.wireName,
              aggregation: metric.aggregation.wireName,
              displayStyle: Value(metric.displayStyle?.wireName),
              colorHex: Value(metric.colorHex),
              unit: Value(metric.unit),
              scaleMin: Value(metric.scaleMin),
              scaleMax: Value(metric.scaleMax),
              lowLabel: Value(metric.lowLabel),
              highLabel: Value(metric.highLabel),
              sortOrder: Value(metric.sortOrder),
              createdAt: metric.createdAt.toUtc().millisecondsSinceEpoch,
              archivedAt: Value(
                metric.archivedAt?.toUtc().millisecondsSinceEpoch,
              ),
              deletedAt: Value(
                metric.deletedAt?.toUtc().millisecondsSinceEpoch,
              ),
            ),
          );

      for (final option in metric.options) {
        await _db.into(_db.metricOptions).insertOnConflictUpdate(
              MetricOptionsCompanion.insert(
                id: option.id,
                updatedAt: millis,
                installId: installId,
                metricId: metric.id,
                label: option.label,
                colorHex: Value(option.colorHex),
                sortOrder: Value(option.sortOrder),
                archived: Value(option.archived),
              ),
            );
      }

      // An option the editor dropped is gone from the marker, so its row has to
      // go too - otherwise the next read hands it straight back and removing an
      // option looks broken. A tombstone rather than a delete, per
      // `DATA-PORTABILITY.md` rule 3, so a sync can carry the removal.
      //
      // Only ever reached for an option nothing ever picked: an option with
      // history is refused by `validateMetricChange` and archived instead, and
      // an archived option is still in `metric.options` above.
      final keptIds = metric.options.map((o) => o.id).toList();
      await (_db.update(_db.metricOptions)
            ..where((o) =>
                o.metricId.equals(metric.id) &
                o.deletedAt.isNull() &
                o.id.isNotIn(keptIds)))
          .write(MetricOptionsCompanion(
        deletedAt: Value(millis),
        updatedAt: Value(millis),
      ));
    });
  }

  /// Archives a marker: it leaves the home list and keeps every reading.
  Future<void> archive(String metricId, {required DateTime now}) async {
    final millis = now.toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.metrics)..where((m) => m.id.equals(metricId)))
        .write(MetricsCompanion(
      archivedAt: Value(millis),
      updatedAt: Value(millis),
    ));
  }

  Future<void> unarchive(String metricId, {required DateTime now}) async {
    await (_db.update(_db.metrics)..where((m) => m.id.equals(metricId)))
        .write(MetricsCompanion(
      archivedAt: const Value(null),
      updatedAt: Value(now.toUtc().millisecondsSinceEpoch),
    ));
  }

  /// Soft-deletes a marker. **Its readings are left alone.**
  ///
  /// Deliberate: deleting a marker by accident must not take a year of numbers
  /// with it, and an orphaned reading is recoverable while a deleted one is
  /// not. The editor offers archiving first for exactly this reason.
  Future<void> softDelete(String metricId, {required DateTime now}) async {
    final millis = now.toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.metrics)..where((m) => m.id.equals(metricId)))
        .write(MetricsCompanion(
      deletedAt: Value(millis),
      updatedAt: Value(millis),
    ));
  }

  /// Writes the starting markers, once, on an empty database.
  ///
  /// Does nothing if any marker already exists, including a deleted one, so a
  /// marker deleted on purpose does not reappear after an update.
  Future<bool> seedIfEmpty({required DateTime now}) async {
    final existing = await _db.select(_db.metrics).get();
    if (existing.isNotEmpty) return false;
    for (final metric in seedMetrics(createdAt: now)) {
      await save(metric, now: now);
    }
    return true;
  }

  Metric _toDomain(MetricRow row, List<MetricOption> options) => Metric(
        id: row.id,
        profileId: row.profileId,
        name: row.name,
        // A row written by a later version can carry a domain or kind this
        // build has never heard of. It reads as the nearest safe thing rather
        // than crashing the list, and is written back untouched.
        domain: MetricDomain.fromWire(row.domain) ?? MetricDomain.body,
        kind: MetricKind.fromWire(row.kind) ?? MetricKind.text,
        aggregation:
            DayAggregation.fromWire(row.aggregation) ?? DayAggregation.none,
        displayStyle: row.displayStyle == null
            ? null
            : DisplayStyle.fromWire(row.displayStyle!),
        colorHex: row.colorHex,
        unit: row.unit,
        scaleMin: row.scaleMin,
        scaleMax: row.scaleMax,
        lowLabel: row.lowLabel,
        highLabel: row.highLabel,
        options: [...options]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        sortOrder: row.sortOrder,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
        archivedAt: row.archivedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!, isUtc: true),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
        deletedAt: row.deletedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
      );

  /// A fresh id for a marker or an option the user creates.
  static String newId() => Ids.newId();
}
