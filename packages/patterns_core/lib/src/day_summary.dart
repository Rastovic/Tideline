import 'dart:math' as math;

import 'package:vitals_core/vitals_core.dart';

import 'aggregation.dart';
import 'metric.dart';
import 'metric_value.dart';
import 'observation.dart';

/// One day of one marker, after the day's readings have been collapsed.
///
/// **An unlogged day is a real object with a null [value]**, not a missing map
/// entry. Charts draw it as an empty square, and nothing anywhere is allowed to
/// fill the gap by interpolating between its neighbours.
final class DaySummary {
  const DaySummary({
    required this.dayKey,
    required this.readingCount,
    this.value,
    this.optionIds = const [],
    this.explicitNone = false,
  });

  final String dayKey;

  /// How many readings the day held before collapsing. Shown as `3x` on the
  /// home list, and it is why the count is kept rather than thrown away.
  final int readingCount;

  /// The collapsed number, or null when the day holds no readings or the kind
  /// carries no number.
  final num? value;

  /// Every option picked that day, for a tag or choice marker.
  final List<String> optionIds;

  /// The day was answered "none of these".
  ///
  /// Distinct from an unlogged day, and the distinction is the whole point:
  /// without it, patterns are computed only over the days someone felt well
  /// enough to log, which is the bias that makes self-tracking lie.
  final bool explicitNone;

  bool get isLogged => readingCount > 0;

  @override
  String toString() => 'DaySummary($dayKey, $value, n=$readingCount)';
}

/// Collapses [observations] of one marker into one row per day from [from] to
/// [to] inclusive, following that marker's own aggregation rule.
///
/// Readings are never rewritten: this runs at read time, so changing a marker
/// from "typical" to "peak" re-reads the same history rather than losing it.
List<DaySummary> summariseDays(
  Metric metric,
  Iterable<Observation> observations, {
  required String from,
  required String to,
}) {
  final byDay = <String, List<Observation>>{};
  for (final observation in observations) {
    if (observation.isDeleted) continue;
    if (observation.metricId != metric.id) continue;
    if (observation.dayKey.compareTo(from) < 0) continue;
    if (observation.dayKey.compareTo(to) > 0) continue;
    byDay.putIfAbsent(observation.dayKey, () => []).add(observation);
  }

  return [
    for (final dayKey in dayKeyRange(from, to))
      _collapseDay(metric, dayKey, byDay[dayKey] ?? const []),
  ];
}

DaySummary _collapseDay(
  Metric metric,
  String dayKey,
  List<Observation> readings,
) {
  if (readings.isEmpty) {
    return DaySummary(dayKey: dayKey, readingCount: 0);
  }

  final ordered = [...readings]
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  final optionIds = <String>{};
  var sawTagsValue = false;
  for (final reading in ordered) {
    switch (reading.value) {
      case TagsValue(optionIds: final picked):
        sawTagsValue = true;
        optionIds.addAll(picked);
      case ChoiceValue(:final optionId):
        optionIds.add(optionId);
      default:
        break;
    }
  }

  final numbers = [
    for (final reading in ordered)
      if (reading.value.asNumber case final n?) n,
  ];

  final value = switch (metric.aggregation) {
    DayAggregation.sum => numbers.isEmpty ? null : numbers.reduce((a, b) => a + b),
    DayAggregation.typical => median(numbers),
    DayAggregation.peak =>
      numbers.isEmpty ? null : numbers.reduce((a, b) => a > b ? a : b),
    DayAggregation.lowest =>
      numbers.isEmpty ? null : numbers.reduce((a, b) => a < b ? a : b),
    DayAggregation.last => ordered.last.value.asNumber,
    DayAggregation.anyTrue => numbers.isEmpty
        ? null
        : (numbers.any((n) => n > 0) ? 1 : 0),
    DayAggregation.union => null,
    DayAggregation.none => null,
  };

  return DaySummary(
    dayKey: dayKey,
    readingCount: ordered.length,
    value: value,
    optionIds: optionIds.toList()..sort(),
    // Only a tags marker can say "none of these", and only by being answered
    // with an empty set. A day with no reading at all is never this.
    explicitNone: sawTagsValue && optionIds.isEmpty,
  );
}

/// The median, or null for an empty list.
///
/// Median rather than mean everywhere in this app: self-report is skewed, one
/// terrible Tuesday drags a mean, and a mean over a 1-10 scale reads as
/// precision the data does not have. Shown to the user as "typical", never as
/// "median".
num? median(List<num> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  return (sorted[middle - 1] + sorted[middle]) / 2;
}

/// The plain facts about one marker over one period. No claims, no ranking, no
/// grade - the app states what was recorded and the reading is the user's.
final class PeriodStats {
  const PeriodStats({
    required this.daysInPeriod,
    required this.daysLogged,
    required this.readingCount,
    this.typical,
    this.lowest,
    this.highest,
  });

  final int daysInPeriod;
  final int daysLogged;
  final int readingCount;

  /// The median of the collapsed daily values.
  final num? typical;
  final num? lowest;
  final num? highest;

  /// Share of days in the period that hold at least one reading, 0-1.
  ///
  /// Always shown next to any number derived from them. A typical value over
  /// nine days of a month is a different statement from one over twenty-eight,
  /// and hiding that is how a tracker quietly lies.
  double get coverage => daysInPeriod == 0 ? 0 : daysLogged / daysInPeriod;
}

/// Facts for one marker over the days in [summaries].
PeriodStats statsFor(List<DaySummary> summaries) {
  final logged = summaries.where((s) => s.isLogged).toList();
  final values = [
    for (final summary in summaries)
      if (summary.value case final v?) v,
  ];
  final sorted = [...values]..sort();
  return PeriodStats(
    daysInPeriod: summaries.length,
    daysLogged: logged.length,
    readingCount: logged.fold(0, (sum, s) => sum + s.readingCount),
    typical: median(values),
    lowest: sorted.isEmpty ? null : sorted.first,
    highest: sorted.isEmpty ? null : sorted.last,
  );
}

/// The average of clock times, in minutes from midnight.
///
/// Times are **circular**: the mean of 23:40 and 00:20 is midnight, not noon.
/// Averaging the raw minute numbers gives 12:00, which is not merely wrong but
/// wrong in the most misleading direction for the exact marker people care
/// about - bedtime. Vectors on a circle, then back to an angle.
int? circularMeanMinutes(List<int> minutes) {
  if (minutes.isEmpty) return null;
  var x = 0.0;
  var y = 0.0;
  for (final minute in minutes) {
    final angle = 2 * math.pi * (minute / 1440);
    x += math.cos(angle);
    y += math.sin(angle);
  }
  // Times spread evenly around the clock have no meaningful average, and
  // inventing one would be the same lie as interpolating a missing day.
  if (x.abs() < 1e-12 && y.abs() < 1e-12) return null;
  final mean = math.atan2(y, x);
  final normalised = mean < 0 ? mean + 2 * math.pi : mean;
  return ((normalised / (2 * math.pi)) * 1440).round() % 1440;
}
