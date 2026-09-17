import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';

import 'database.dart';

/// Readings in and out of storage.
///
/// **The day key is frozen here, at write time**, from the device's offset and
/// the user's day boundary. Never derived on read: flying to another timezone
/// must not move last March, and a reading at 01:30 belongs to the day that
/// just ended.
final class ObservationRepository {
  ObservationRepository(
    this._db, {
    required this.installId,
    this.dayBoundaryHour = 4,
  });

  final PatternsDatabase _db;
  final String installId;

  /// The local hour a new day starts. 04:00 by default, user-configurable.
  final int dayBoundaryHour;

  /// Records one reading and returns it.
  ///
  /// A marker can take as many of these a day as the day deserves. Nothing is
  /// overwritten and nothing is merged: two readings are two rows.
  Future<Observation> log({
    required String metricId,
    required MetricValue value,
    required DateTime at,
    required int utcOffsetMinutes,
    bool enteredLate = false,
    String? id,
  }) async {
    final utc = at.toUtc();
    final observation = Observation(
      id: id ?? Ids.newId(),
      metricId: metricId,
      dayKey: dayKeyFor(
        utc,
        offsetMinutes: utcOffsetMinutes,
        dayBoundaryHour: dayBoundaryHour,
      ),
      recordedAt: utc,
      utcOffsetMinutes: utcOffsetMinutes,
      value: value,
      enteredLate: enteredLate,
      createdAt: utc,
    );
    await _insert(observation, updatedAt: utc);
    return observation;
  }

  /// Records a reading against a day chosen by hand.
  ///
  /// Retro-filling is normal - last night's mood remembered this morning - and
  /// it is marked rather than hidden, because it is still worth knowing which
  /// numbers were remembered rather than noticed.
  Future<Observation> logForDay({
    required String metricId,
    required MetricValue value,
    required String dayKey,
    required DateTime now,
    required int utcOffsetMinutes,
  }) async {
    final utc = now.toUtc();
    final observation = Observation(
      id: Ids.newId(),
      metricId: metricId,
      dayKey: dayKey,
      recordedAt: utc,
      utcOffsetMinutes: utcOffsetMinutes,
      value: value,
      enteredLate: true,
      createdAt: utc,
    );
    await _insert(observation, updatedAt: utc);
    return observation;
  }

  Future<void> _insert(Observation observation, {required DateTime updatedAt}) {
    return _db.into(_db.observations).insertOnConflictUpdate(
          ObservationsCompanion.insert(
            id: observation.id,
            updatedAt: updatedAt.toUtc().millisecondsSinceEpoch,
            installId: installId,
            dayKey: observation.dayKey,
            tzOffsetMinutes: observation.utcOffsetMinutes,
            metricId: observation.metricId,
            recordedAt: observation.recordedAt.toUtc().millisecondsSinceEpoch,
            valueJson: jsonEncode(observation.value.toWire()),
            enteredLate: Value(observation.enteredLate),
            createdAt: (observation.createdAt ?? observation.recordedAt)
                .toUtc()
                .millisecondsSinceEpoch,
          ),
        );
  }

  /// Changes the value of one reading, keeping its place in the day.
  Future<void> updateValue(
    String observationId,
    MetricValue value, {
    required DateTime now,
  }) async {
    await (_db.update(_db.observations)
          ..where((o) => o.id.equals(observationId)))
        .write(ObservationsCompanion(
      valueJson: Value(jsonEncode(value.toWire())),
      updatedAt: Value(now.toUtc().millisecondsSinceEpoch),
    ));
  }

  /// Soft-deletes a reading. The tombstone stays, so a restore cannot bring it
  /// back from an older copy.
  Future<void> softDelete(String observationId, {required DateTime now}) async {
    final millis = now.toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.observations)
          ..where((o) => o.id.equals(observationId)))
        .write(ObservationsCompanion(
      deletedAt: Value(millis),
      updatedAt: Value(millis),
    ));
  }

  /// Every live reading of [metricIds] between [from] and [to] inclusive.
  ///
  /// One query for the whole report rather than one per marker: a stacked
  /// report of eight markers over a year is eight thousand rows, and eight
  /// round trips through the isolate boundary is where that gets slow.
  Future<List<Observation>> range({
    required Iterable<String> metricIds,
    required String from,
    required String to,
    required Map<String, MetricKind> kinds,
  }) async {
    final ids = metricIds.toList();
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(_db.observations)
          ..where((o) =>
              o.metricId.isIn(ids) &
              o.deletedAt.isNull() &
              o.dayKey.isBiggerOrEqualValue(from) &
              o.dayKey.isSmallerOrEqualValue(to))
          ..orderBy([(o) => OrderingTerm(expression: o.recordedAt)]))
        .get();
    return _toDomain(rows, kinds);
  }

  /// Every live reading of [metricIds], whatever the day, newest first.
  ///
  /// For search, which has no period: an entry is looked for by what it says,
  /// and "sometime last spring" is not a range anyone can type. Only ever asked
  /// for the diary, which is one row a day at most people's pace.
  Future<List<Observation>> allOf({
    required Iterable<String> metricIds,
    required Map<String, MetricKind> kinds,
  }) async {
    final ids = metricIds.toList();
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(_db.observations)
          ..where((o) => o.metricId.isIn(ids) & o.deletedAt.isNull())
          ..orderBy([
            (o) => OrderingTerm(
                  expression: o.recordedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return _toDomain(rows, kinds);
  }

  /// Everything recorded on one day, for the day detail screen.
  Future<List<Observation>> onDay(
    String dayKey, {
    required Map<String, MetricKind> kinds,
  }) async {
    final rows = await (_db.select(_db.observations)
          ..where((o) => o.dayKey.equals(dayKey) & o.deletedAt.isNull())
          ..orderBy([(o) => OrderingTerm(expression: o.recordedAt)]))
        .get();
    return _toDomain(rows, kinds);
  }

  /// How many readings each marker holds on [dayKey], for the home list.
  ///
  /// A count rather than the readings themselves: the home list shows a tick
  /// and a `3x`, and loading a day of values to render a tick is work nobody
  /// asked for.
  Future<Map<String, int>> countsOnDay(String dayKey) async {
    final count = _db.observations.id.count();
    final query = _db.selectOnly(_db.observations)
      ..addColumns([_db.observations.metricId, count])
      ..where(_db.observations.dayKey.equals(dayKey) &
          _db.observations.deletedAt.isNull())
      ..groupBy([_db.observations.metricId]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(_db.observations.metricId)!: row.read(count)!,
    };
  }

  /// What one marker already holds, for the editor's data-loss guards.
  ///
  /// Read before an edit is saved, and only then: narrowing a scale or removing
  /// an option is safe on a marker answered twice and destroys meaning on one
  /// answered for a year, and nothing else in the app needs to know which.
  ///
  /// The count is of rows, so a reading this build cannot decode still counts -
  /// an unreadable row is history too, and the guard has to be pessimistic
  /// about it. The extremes and the picked options come only from rows that did
  /// decode, since an undecodable one cannot argue either way.
  Future<MetricReadingFacts> factsFor(
    String metricId, {
    required MetricKind kind,
  }) async {
    final rows = await (_db.select(_db.observations)
          ..where((o) => o.metricId.equals(metricId) & o.deletedAt.isNull()))
        .get();
    if (rows.isEmpty) return MetricReadingFacts.none;

    num? lowest;
    num? highest;
    final used = <String>{};
    for (final row in rows) {
      final value = decodeValue(kind, jsonDecode(row.valueJson));
      switch (value) {
        case NumberValue(:final number):
          if (lowest == null || number < lowest) lowest = number;
          if (highest == null || number > highest) highest = number;
        case ChoiceValue(:final optionId):
          used.add(optionId);
        case TagsValue(:final optionIds):
          used.addAll(optionIds);
        default:
          break;
      }
    }

    return MetricReadingFacts(
      count: rows.length,
      lowestNumber: lowest,
      highestNumber: highest,
      usedOptionIds: used,
    );
  }

  /// The days a boolean marker was recorded true, for the cycle module and for
  /// a background band.
  Future<List<String>> trueDays(String metricId) async {
    final rows = await (_db.select(_db.observations)
          ..where((o) => o.metricId.equals(metricId) & o.deletedAt.isNull())
          ..orderBy([(o) => OrderingTerm(expression: o.dayKey)]))
        .get();
    return [
      for (final row in rows)
        if (decodeValue(MetricKind.boolean, jsonDecode(row.valueJson))
            case BooleanValue(value: true))
          row.dayKey,
    ];
  }

  List<Observation> _toDomain(
    List<ObservationRow> rows,
    Map<String, MetricKind> kinds,
  ) {
    final observations = <Observation>[];
    for (final row in rows) {
      final kind = kinds[row.metricId];
      if (kind == null) continue;
      final value = decodeValue(kind, jsonDecode(row.valueJson));
      // A row this build cannot read costs that row, never the screen. It stays
      // on disk untouched and a later version may well understand it.
      if (value == null) continue;
      observations.add(
        Observation(
          id: row.id,
          metricId: row.metricId,
          dayKey: row.dayKey,
          recordedAt:
              DateTime.fromMillisecondsSinceEpoch(row.recordedAt, isUtc: true),
          utcOffsetMinutes: row.tzOffsetMinutes,
          value: value,
          enteredLate: row.enteredLate,
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
          updatedAt:
              DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
          deletedAt: row.deletedAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
        ),
      );
    }
    return observations;
  }
}
