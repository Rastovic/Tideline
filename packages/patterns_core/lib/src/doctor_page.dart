import 'package:vitals_core/vitals_core.dart';

import 'cycle.dart';
import 'day_summary.dart';
import 'metric.dart';
import 'metric_kind.dart';
import 'metric_value.dart';
import 'observation.dart';

/// The most markers one printed page holds and stays readable.
///
/// Eight small grids and their facts fill an A4 page at a size a clinician can
/// read without a magnifier. A ninth is a second page, and a second page is the
/// one that gets lost.
const doctorPageMaxMarkers = 8;

/// One number with the day it happened, for "highest 9, on 14.8.".
typedef DatedValue = ({num value, String dayKey});

/// How often one option was picked, in days.
typedef OptionCount = ({String label, int days});

/// One marker on the doctor page: its days, and the plain facts about them.
///
/// **No interpretation and no score.** Nothing here says better, worse,
/// improving, concerning or normal. A page that editorialises is a page a
/// clinician stops trusting on sight, and the reading is theirs to do.
final class DoctorEntry {
  const DoctorEntry({
    required this.metric,
    required this.days,
    required this.stats,
    this.highest,
    this.lowest,
    this.daysOn,
    this.optionCounts = const [],
    this.explicitNoneDays = 0,
    this.typicalMinute,
  });

  final Metric metric;

  /// One per day of the period, unlogged days included, for the grid.
  final List<DaySummary> days;

  final PeriodStats stats;

  /// The extremes with their dates. Only for markers that carry a quantity -
  /// a "highest yes" or a "latest bedtime by minute number" means nothing.
  final DatedValue? highest;
  final DatedValue? lowest;

  /// A yes/no marker: the days it was yes. Out of [PeriodStats.daysLogged], not
  /// out of the period, because a day never answered is not a day it was no.
  final int? daysOn;

  /// A tags or choice marker: each option with the days it was picked, most
  /// frequent first. Options never picked in the period are left out.
  final List<OptionCount> optionCounts;

  /// Days answered "none of these", kept apart from unlogged days.
  final int explicitNoneDays;

  /// A time marker: the circular mean of every recorded time.
  final int? typicalMinute;

  /// The range the grid shades against. A rating uses its declared bounds, so
  /// a month that never went below 4 does not redraw 4 as the floor.
  (num, num) get bounds => switch (metric.kind) {
        MetricKind.scale => (metric.scaleMin, metric.scaleMax),
        MetricKind.percent => (0, 100),
        _ => (0, (stats.highest ?? 1) == 0 ? 1 : stats.highest ?? 1),
      };
}

/// Everything one doctor page prints.
final class DoctorPage {
  const DoctorPage({
    required this.from,
    required this.to,
    required this.entries,
    required this.daysWithAnyEntry,
    this.periodStarts = const [],
  });

  final String from;
  final String to;
  final List<DoctorEntry> entries;

  /// Days on which at least one of the printed markers holds a reading. The
  /// coverage line at the top of the page, so every number below it is read
  /// against how much was actually recorded.
  final int daysWithAnyEntry;

  /// Period start dates inside the stretch. Dates only: **counting yes,
  /// predicting never**, so there is no cycle length estimate and no next date.
  final List<String> periodStarts;

  int get daysInPeriod => dayKeyRange(from, to).length;
}

/// Builds the page from stored readings. Pure: nothing here touches storage.
///
/// [metrics] is the order printed. Markers with nothing to chart - a diary, a
/// photo - are dropped here rather than trusted to the caller: **a diary never
/// reaches this page**, private or not, because free text on a clinical page is
/// the entry most likely to be read by the wrong person.
DoctorPage buildDoctorPage({
  required List<Metric> metrics,
  required Iterable<Observation> observations,
  required String from,
  required String to,
  List<CyclePeriod> cyclePeriods = const [],
}) {
  final printable = [
    for (final metric in metrics)
      if (metric.kind != MetricKind.text && metric.kind != MetricKind.photo)
        metric,
  ].take(doctorPageMaxMarkers).toList();

  final loggedDays = <String>{};
  final entries = <DoctorEntry>[];
  for (final metric in printable) {
    final days = summariseDays(metric, observations, from: from, to: to);
    for (final day in days) {
      if (day.isLogged) loggedDays.add(day.dayKey);
    }
    entries.add(_entryFor(metric, days, observations, from: from, to: to));
  }

  return DoctorPage(
    from: from,
    to: to,
    entries: entries,
    daysWithAnyEntry: loggedDays.length,
    periodStarts: [
      for (final period in cyclePeriods)
        if (period.startDayKey.compareTo(from) >= 0 &&
            period.startDayKey.compareTo(to) <= 0)
          period.startDayKey,
    ]..sort(),
  );
}

DoctorEntry _entryFor(
  Metric metric,
  List<DaySummary> days,
  Iterable<Observation> observations, {
  required String from,
  required String to,
}) {
  final stats = statsFor(days);

  switch (metric.kind) {
    case MetricKind.boolean:
      return DoctorEntry(
        metric: metric,
        days: days,
        stats: stats,
        daysOn: days.where((d) => (d.value ?? 0) > 0).length,
      );

    case MetricKind.tags || MetricKind.choice:
      final counts = <String, int>{};
      for (final day in days) {
        for (final id in day.optionIds) {
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
      final labels = {for (final o in metric.options) o.id: o.label};
      final ordered = [
        for (final MapEntry(:key, :value) in counts.entries)
          (label: labels[key] ?? key, days: value),
      ]..sort((a, b) => b.days != a.days
          ? b.days.compareTo(a.days)
          : a.label.compareTo(b.label));
      return DoctorEntry(
        metric: metric,
        days: days,
        stats: stats,
        optionCounts: ordered,
        explicitNoneDays: days.where((d) => d.explicitNone).length,
      );

    case MetricKind.timeOfDay:
      final minutes = [
        for (final o in observations)
          if (!o.isDeleted &&
              o.metricId == metric.id &&
              o.dayKey.compareTo(from) >= 0 &&
              o.dayKey.compareTo(to) <= 0)
            if (o.value case TimeOfDayValue(:final minutesFromMidnight))
              minutesFromMidnight,
      ];
      return DoctorEntry(
        metric: metric,
        days: days,
        stats: stats,
        typicalMinute: circularMeanMinutes(minutes),
      );

    default:
      return DoctorEntry(
        metric: metric,
        days: days,
        stats: stats,
        highest: _extreme(days, highest: true),
        lowest: _extreme(days, highest: false),
      );
  }
}

/// The first day holding the extreme value. First rather than last, so the
/// date printed is the earliest time it happened and stays put as days are
/// added after it.
DatedValue? _extreme(List<DaySummary> days, {required bool highest}) {
  DatedValue? best;
  for (final day in days) {
    final value = day.value;
    if (value == null) continue;
    if (best == null ||
        (highest ? value > best.value : value < best.value)) {
      best = (value: value, dayKey: day.dayKey);
    }
  }
  return best;
}
