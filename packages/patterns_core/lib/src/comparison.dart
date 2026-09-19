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
    required this.pairedDays,
    required this.pairing,
  });

  /// The marker the days are split by - "on the days creatine was taken".
  final Metric condition;

  /// The marker read on those days - "bloating sat at".
  final Metric outcome;

  final List<CompareBucket> buckets;

  /// Days where both markers were logged (after the lag is applied).
  final int pairedDays;

  final ComparePairing pairing;

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
        if (bucket(labels[entry.key] ?? entry.key, entry.value)
            case final b?) {
          buckets.add(b);
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

  return Comparison(
    condition: condition,
    outcome: outcome,
    buckets: buckets,
    pairedDays: pairs.length,
    pairing: pairing,
  );
}
