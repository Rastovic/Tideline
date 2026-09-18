import 'metric_value.dart';

/// One reading of one marker, at one moment.
///
/// **The table is long, not wide**: one row per reading, never a column per
/// marker. The wide shape cannot survive user-created markers, and it is the
/// single schema decision with no way back.
///
/// **A day holds as many of these per marker as it needs.** Appetite at 11:00
/// and appetite at 22:00 are two readings, not a correction, and collapsing
/// them is a read-time job governed by the marker's own aggregation rule.
final class Observation {
  const Observation({
    required this.id,
    required this.metricId,
    required this.dayKey,
    required this.recordedAt,
    required this.utcOffsetMinutes,
    required this.value,
    this.note,
    this.enteredLate = false,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String metricId;

  /// The local day this belongs to, `YYYY-MM-DD`, **frozen at write time**.
  ///
  /// Never derived when read. The day boundary is 04:00 by default, so a
  /// reading at 01:30 belongs to the day that just ended, and flying to another
  /// timezone must not silently move last March.
  final String dayKey;

  /// The moment, in UTC. What orders readings inside a day and what a "last of
  /// the day" rule reads.
  final DateTime recordedAt;

  /// The device's offset from UTC at [recordedAt], so a local clock time can be
  /// reconstructed exactly, years later, without guessing the zone.
  final int utcOffsetMinutes;

  final MetricValue value;

  /// A sentence about this one reading, or null. Free text, so it travels
  /// under the diary's rules: never on the doctor page, and out of an export
  /// unless the diary is ticked.
  final String? note;

  /// Filled in after the fact rather than as it happened.
  ///
  /// Marked rather than hidden: retro-filling is allowed and normal, and it is
  /// still worth knowing that last Tuesday's mood was remembered on Thursday.
  final bool enteredLate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Tombstone. Never hard-deleted.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// The local wall-clock minute this was recorded at, 0-1439.
  int get localMinuteOfDay {
    final local = recordedAt.toUtc().add(Duration(minutes: utcOffsetMinutes));
    return local.hour * 60 + local.minute;
  }

  Observation copyWith({
    String? dayKey,
    DateTime? recordedAt,
    int? utcOffsetMinutes,
    MetricValue? value,
    String? note,
    bool? enteredLate,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      Observation(
        id: id,
        metricId: metricId,
        dayKey: dayKey ?? this.dayKey,
        recordedAt: recordedAt ?? this.recordedAt,
        utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
        value: value ?? this.value,
        note: note ?? this.note,
        enteredLate: enteredLate ?? this.enteredLate,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  @override
  String toString() => 'Observation($metricId, $dayKey, $value)';
}
