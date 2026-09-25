import 'day_summary.dart';
import 'metric.dart';
import 'metric_kind.dart';
import 'observation.dart';
import 'package:vitals_core/vitals_core.dart';

/// Whether the two markers are read on the same day, or one day apart.
///
/// The lag exists because some of what she wants to see is not same-day at
/// all: a short night shows up in the next day's mood, not in that night's.
enum ComparePairing {
  sameDay('sameDay', 0),
  nextDay('nextDay', 1);

  const ComparePairing(this.wireName, this.lagDays);

  final String wireName;

  /// Days added to the condition's date to find the outcome's.
  final int lagDays;

  static ComparePairing? fromWire(String value) {
    for (final p in ComparePairing.values) {
      if (p.wireName == value) return p;
    }
    return null;
  }
}

/// One group of days, and what the outcome marker did on them.
final class CompareBucket {
  const CompareBucket({
    required this.label,
    required this.days,
    this.typical,
    this.lowest,
    this.highest,
  });

  /// What the condition was on those days: `yes`, `no`, an option's label, or
  /// the low and high thirds of a number.
  final String label;

  /// How many paired days the group holds. **Always shown**: a difference
  /// over four days and one over ninety are not the same thing, and a number
  /// without its count is how a tracker starts lying.
  final int days;

  /// The median of the outcome on those days, when it carries a number.
  final num? typical;
  final num? lowest;
  final num? highest;
}

/// One day: what the condition was, and what the outcome did.
///
/// The dots of the dependency chart. Every one is a day that was logged for
/// both; nothing here is filled in, averaged or smoothed.
final class ComparePoint {
  const ComparePoint({
    required this.dayKey,
    required this.outcome,
    this.condition,
    this.bucket,
  });

  /// The condition's day, not the outcome's, which is a day later under
  /// [ComparePairing.nextDay].
  final String dayKey;

  /// The outcome's value that day. Null where the marker carries no number.
  final num? outcome;

  /// The condition's value, for a condition that carries a number.
  final num? condition;

  /// The group this day falls in, for a condition that does not: `yes`, `no`,
  /// or an option's label.
  final String? bucket;
}

/// One day of the window, both markers side by side, for the chart over time.
///
/// **Every day of the window is here**, logged or not, so the chart can leave
/// a gap where nothing was recorded instead of drawing a line across it as if
/// something had been.
final class TimelineDay {
  const TimelineDay({
    required this.dayKey,
    this.condition,
    this.conditionOn,
    this.outcome,
  });

  /// The condition's day. The outcome beside it is read [ComparePairing]
  /// days later, so "creatine today, bloating tomorrow" sits in one column.
  final String dayKey;

  /// The condition's number, for a condition that carries one.
  final num? condition;

  /// For a yes/no or tags condition: whether it happened (yes, or any option
  /// picked). Null when the condition was not logged that day.
  final bool? conditionOn;

  /// The outcome's number, or null when it was not logged.
  final num? outcome;
}

/// Two markers read against each other, in counted groups.
///
/// **It compares and never concludes.** There is no correlation coefficient,
/// no p-value, no "because", and nothing here decides whether a difference is
/// real: it splits the days by what the condition was and reports the
/// outcome's median in each group, with the day count beside it. The reading
/// is hers, exactly as with every other screen in this app.
final class Comparison {
  const Comparison({
    required this.condition,
    required this.outcome,
    required this.buckets,
    required this.points,
    required this.pairedDays,
    required this.pairing,
    this.timeline = const [],
  });

  /// The marker the days are split by - "on the days creatine was taken".
  final Metric condition;

  /// The marker read on those days - "bloating sat at".
  final Metric outcome;

  final List<CompareBucket> buckets;

  /// One per paired day, for the chart. Oldest first.
  final List<ComparePoint> points;

  /// Days where both markers were logged (after the lag is applied).
  final int pairedDays;

  final ComparePairing pairing;

  /// Every day of the window, oldest first, for the chart over time.
  final List<TimelineDay> timeline;

  /// Nothing to show: one of the two was barely logged, or the condition
  /// never varied. Two groups are the minimum a comparison can be made of.
  bool get isEmpty => buckets.length < 2 || pairedDays == 0;
}

/// Splits the days by [condition] and reports what [outcome] did on them.
///
/// A yes/no condition splits into yes and no. A tags or choice condition makes
/// one group per option that was picked, plus the days it was not. A number
/// splits into its own lowest and highest thirds, and **the middle third is
/// dropped rather than squeezed into one side**, because the point of the two
/// groups is that they are far apart.
Comparison buildComparison({
  required Metric condition,
  required Metric outcome,
  required Iterable<Observation> observations,
  required String from,
  required String to,
  ComparePairing pairing = ComparePairing.sameDay,
}) {
  final conditionDays = {
    for (final day in summariseDays(condition, observations, from: from, to: to))
      day.dayKey: day,
  };
  final outcomeDays = {
    for (final day in summariseDays(outcome, observations, from: from, to: to))
      day.dayKey: day,
  };

  // Pairs of (condition day, outcome day), both logged.
  final pairs = <(DaySummary, DaySummary)>[];
  for (final entry in conditionDays.entries) {
    if (!entry.value.isLogged) continue;
    final outcomeDay = outcomeDays[addDays(entry.key, pairing.lagDays)];
    if (outcomeDay == null || !outcomeDay.isLogged) continue;
    pairs.add((entry.value, outcomeDay));
  }

  CompareBucket? bucket(String label, Iterable<DaySummary> days) {
    final list = days.toList();
    if (list.isEmpty) return null;
    final values = [
      for (final day in list)
        if (day.value case final v?) v,
    ]..sort();
    return CompareBucket(
      label: label,
      days: list.length,
      typical: median(values),
      lowest: values.isEmpty ? null : values.first,
      highest: values.isEmpty ? null : values.last,
    );
  }

  final buckets = <CompareBucket>[];
  final points = <ComparePoint>[];
  final numericCondition = condition.kind != MetricKind.boolean &&
      condition.kind != MetricKind.tags &&
      condition.kind != MetricKind.choice;

  switch (condition.kind) {
    case MetricKind.boolean:
      final yes = [
        for (final (c, o) in pairs)
          if ((c.value ?? 0) > 0) o,
      ];
      final no = [
        for (final (c, o) in pairs)
          if ((c.value ?? 0) <= 0) o,
      ];
      if (bucket('yes', yes) case final b?) buckets.add(b);
      if (bucket('no', no) case final b?) buckets.add(b);
      for (final (c, o) in pairs) {
        points.add(ComparePoint(
          dayKey: c.dayKey,
          outcome: o.value,
          bucket: (c.value ?? 0) > 0 ? 'yes' : 'no',
        ));
      }

    case MetricKind.tags || MetricKind.choice:
      final labels = {for (final o in condition.options) o.id: o.label};
      final counts = <String, List<DaySummary>>{};
      for (final (c, o) in pairs) {
        for (final id in c.optionIds) {
          counts.putIfAbsent(id, () => []).add(o);
        }
      }
      final ordered = counts.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));
      for (final entry in ordered.take(5)) {
        final label = labels[entry.key] ?? entry.key;
        if (bucket(label, entry.value) case final b?) buckets.add(b);
        for (final (c, o) in pairs) {
          if (c.optionIds.contains(entry.key)) {
            points.add(ComparePoint(
              dayKey: c.dayKey,
              outcome: o.value,
              bucket: label,
            ));
          }
        }
      }

    default:
      final values = [
        for (final (c, _) in pairs)
          if (c.value case final v?) v,
      ]..sort();
      if (values.length >= 6) {
        final lowEdge = values[(values.length / 3).floor()];
        final highEdge = values[(values.length * 2 / 3).floor()];
        final low = [
          for (final (c, o) in pairs)
            if (c.value != null && c.value! <= lowEdge) o,
        ];
        final high = [
          for (final (c, o) in pairs)
            if (c.value != null && c.value! >= highEdge) o,
        ];
        if (bucket('high', high) case final b?) buckets.add(b);
        if (bucket('low', low) case final b?) buckets.add(b);
      }
  }

  if (numericCondition) {
    for (final (c, o) in pairs) {
      points.add(ComparePoint(
        dayKey: c.dayKey,
        outcome: o.value,
        condition: c.value,
      ));
    }
  }
  points.sort((a, b) => a.dayKey.compareTo(b.dayKey));

  final timeline = [
    for (final c in conditionDays.values)
      TimelineDay(
        dayKey: c.dayKey,
        condition: numericCondition && c.isLogged ? c.value : null,
        conditionOn: numericCondition || !c.isLogged
            ? null
            : condition.kind == MetricKind.boolean
            ? (c.value ?? 0) > 0
            : c.optionIds.isNotEmpty,
        outcome: switch (outcomeDays[addDays(c.dayKey, pairing.lagDays)]) {
          final o? when o.isLogged => o.value,
          _ => null,
        },
      ),
  ]..sort((a, b) => a.dayKey.compareTo(b.dayKey));

  return Comparison(
    condition: condition,
    outcome: outcome,
    buckets: buckets,
    points: points,
    pairedDays: pairs.length,
    pairing: pairing,
    timeline: timeline,
  );
}
