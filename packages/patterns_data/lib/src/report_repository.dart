import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:patterns_core/patterns_core.dart';

import 'database.dart';

/// Saved reports in and out of storage.
///
/// **A report stores the question, never the answer.** Nothing here caches a
/// value, a median or a rendered row: opening a report rebuilds it from the
/// readings, so changing a marker's day rule from "typical" to "peak" re-reads
/// history instead of leaving an old number frozen in a saved report.
final class ReportRepository {
  ReportRepository(this._db, {required this.installId});

  final PatternsDatabase _db;
  final String installId;

  Future<List<ReportDefinition>> all({
    String profileId = defaultProfileId,
  }) async {
    final rows = await (_db.select(_db.savedReports)
          ..where((r) => r.deletedAt.isNull() & r.profileId.equals(profileId))
          ..orderBy([(r) => OrderingTerm(expression: r.sortOrder)]))
        .get();
    return [
      for (final row in rows)
        if (_toDomain(row) case final definition?) definition,
    ];
  }

  Future<ReportDefinition?> byId(String id) async {
    final rows = await (_db.select(_db.savedReports)
          ..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
        .get();
    return rows.isEmpty ? null : _toDomain(rows.first);
  }

  /// [profileId] is only written when the report is first saved; an edit
  /// never moves a report to another profile.
  Future<void> save(
    ReportDefinition definition, {
    required DateTime now,
    String profileId = defaultProfileId,
  }) async {
    final millis = now.toUtc().millisecondsSinceEpoch;
    await _db.into(_db.savedReports).insertOnConflictUpdate(
          SavedReportsCompanion.insert(
            id: definition.id,
            updatedAt: millis,
            installId: installId,
            name: definition.name,
            profileId: Value(profileId),
            seriesJson: jsonEncode([
              for (final series in definition.series)
                {
                  'metricId': series.metricId,
                  if (series.displayStyle case final style?)
                    'display': style.wireName,
                  if (series.bandBehindMetricId case final behind?)
                    'bandBehind': behind,
                },
            ]),
            period: definition.period.wire,
            axis: definition.axis.wireName,
            compare: Value(definition.compare?.wireName),
            createdAt: definition.createdAt.toUtc().millisecondsSinceEpoch,
            deletedAt: Value(
              definition.deletedAt?.toUtc().millisecondsSinceEpoch,
            ),
          ),
        );
  }

  /// Soft-deletes a report. **No reading is touched.**
  ///
  /// A report is a lens over flat data, so deleting one loses a question and
  /// never an observation. That is the whole reason protocols became saved
  /// reports rather than a structure the readings hang off.
  Future<void> softDelete(String id, {required DateTime now}) async {
    final millis = now.toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.savedReports)..where((r) => r.id.equals(id)))
        .write(SavedReportsCompanion(
      deletedAt: Value(millis),
      updatedAt: Value(millis),
    ));
  }

  /// Null when the row is unreadable by this build.
  ///
  /// A row costs itself, never the list. A future version may write an axis or
  /// a display style this one has never heard of, and the honest response is to
  /// leave that report alone on disk rather than to crash the screen or to
  /// guess at what it meant.
  ReportDefinition? _toDomain(SavedReportRow row) {
    final period = ReportPeriod.fromWire(row.period);
    final axis = ReportAxis.fromWire(row.axis);
    if (period == null || axis == null) return null;

    final decoded = jsonDecode(row.seriesJson);
    if (decoded is! List) return null;

    final series = <ReportSeries>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final metricId = entry['metricId'];
      if (metricId is! String) continue;
      final display = entry['display'];
      series.add(ReportSeries(
        metricId: metricId,
        displayStyle: display is String ? DisplayStyle.fromWire(display) : null,
        bandBehindMetricId:
            entry['bandBehind'] is String ? entry['bandBehind'] as String : null,
      ));
    }

    return ReportDefinition(
      id: row.id,
      name: row.name,
      series: series,
      period: period,
      axis: axis,
      compare: row.compare == null
          ? null
          : ComparePairing.fromWire(row.compare!),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }
}
