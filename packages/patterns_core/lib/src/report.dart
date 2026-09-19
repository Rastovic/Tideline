import 'package:vitals_core/vitals_core.dart';

import 'aggregation.dart';
import 'comparison.dart';
import 'cycle.dart';
import 'day_summary.dart';
import 'display.dart';
import 'metric.dart';
import 'observation.dart';

/// What the x axis of a report counts along.
///
/// [cycleDay] is the entire reason the cycle module exists. It is not a
/// calendar view: it re-sorts the same readings so irritability, bloating or
/// appetite can be read against the cycle **without being owned by it**.
enum ReportAxis {
  date('date'),
  cycleDay('cycleDay'),

  /// The same dated days, laid out seven wide.
  ///
  /// A different question rather than a different picture, which is why it is
  /// saved with the report: a linear row answers "how did this move", and a
  /// grid answers **"does this repeat weekly"** - in seven columns a run of low
  /// Sundays is a visible column, and in a scroll it is smeared across the
  /// whole strip.
  ///
  /// The cells are identical to [date]; only the layout differs. Everything
  /// that builds a report treats the two the same, and the grid lives entirely
  /// in the painter.
  grid('grid');

  const ReportAxis(this.wireName);

  final String wireName;

  static ReportAxis? fromWire(String value) {
    for (final axis in ReportAxis.values) {
      if (axis.wireName == value) return axis;
    }
    return null;
  }
}

/// The stretch of days a report covers.
///
/// Two shapes, because a saved report needs both: a rolling window that means
/// the same thing next month, and a fixed stretch for the fortnight worth
/// looking at again.
sealed class ReportPeriod {
  const ReportPeriod();

  /// The first and last day the report draws, inclusive.
  (String from, String to) resolve(String today);

  String get wire;

  static ReportPeriod? fromWire(String value) {
    if (value.startsWith('last:')) {
      final days = int.tryParse(value.substring(5));
      return days == null ? null : LastDays(days);
    }
    final parts = value.split('..');
    if (parts.length == 2) return FixedPeriod(from: parts[0], to: parts[1]);
    return null;
  }
}

/// A rolling window ending today, today included.
final class LastDays extends ReportPeriod {
  const LastDays(this.days);

  final int days;

  @override
  (String, String) resolve(String today) =>
      (addDays(today, -(days - 1)), today);

  @override
  String get wire => 'last:$days';
}

/// A fixed stretch that does not move.
final class FixedPeriod extends ReportPeriod {
  const FixedPeriod({required this.from, required this.to});

  final String from;
  final String to;

  @override
  (String, String) resolve(String today) => (from, to);

  @override
  String get wire => '$from..$to';
}

/// One marker inside a report, with the shape it takes **here**.
///
/// The display is an override rather than a copy of the marker's own: the same
/// dose can be bars in one report and dots in another, and changing it here
/// must not reach back and change the marker.
final class ReportSeries {
  const ReportSeries({
    required this.metricId,
    this.displayStyle,
    this.bandBehindMetricId,
  });

  final String metricId;

  /// Null means "whatever the marker itself says".
  final DisplayStyle? displayStyle;

  /// Draws this series as a pale band **behind** that marker's row instead of
  /// as a row of its own.
  ///
  /// The only overlay the app permits, and the reason it is safe: a band has no
  /// scale, so it cannot be stretched until it agrees with the series in front
  /// of it. Two y axes in one frame are banned for exactly the opposite reason,
  /// and nothing here can produce one - a row draws one marker.
  final String? bandBehindMetricId;

  bool get isBand => bandBehindMetricId != null;
}

/// A report someone built and named.
final class ReportDefinition {
  const ReportDefinition({
    required this.id,
    required this.name,
    required this.series,
    required this.period,
    required this.createdAt,
    this.axis = ReportAxis.date,
    this.compare,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final List<ReportSeries> series;
  final ReportPeriod period;
  final ReportAxis axis;

  /// Set when the report also reads its first two markers against each other:
  /// the first splits the days, the second is read on them. Null is the
  /// ordinary stacked report.
  final ComparePairing? compare;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// The markers this report reads, bands included.
  List<String> get metricIds => [for (final s in series) s.metricId];

  ReportDefinition copyWith({
    String? name,
    List<ReportSeries>? series,
    ReportPeriod? period,
    ReportAxis? axis,
    ComparePairing? compare,
    bool clearCompare = false,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      ReportDefinition(
        id: id,
        name: name ?? this.name,
        series: series ?? this.series,
        period: period ?? this.period,
        axis: axis ?? this.axis,
        compare: clearCompare ? null : (compare ?? this.compare),
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}

/// One drawn row: a marker, its cells along the shared axis, and its facts.
final class ReportRow {
  const ReportRow({
    required this.metric,
    required this.cells,
    required this.stats,
    this.displayStyle,
    this.weeklyTypical,
    this.bandMetric,
    this.bandOn = const [],
  });

  final Metric metric;

  /// One per position on the shared axis, in the same order for every row -
  /// which is what makes the rows readable stacked.
  final List<DaySummary> cells;

  final PeriodStats stats;

  /// Resolved: the report's override, or the marker's own.
  final DisplayStyle? displayStyle;

  /// The typical week, or null when the period is shorter than a week or the
  /// marker carries no number. See [weeklyTypicalFor].
  final num? weeklyTypical;

  /// The boolean marker drawn as a pale band behind this row, if any.
  final Metric? bandMetric;

  /// Parallel to [cells]: whether the band is on at that position.
  final List<bool> bandOn;
}

/// A built report: the shared axis, and one row per marker.
final class Report {
  const Report({
    required this.definition,
    required this.from,
    required this.to,
    required this.labels,
    required this.rows,
    this.dayKeys = const [],
    this.cycleDays = const [],
  });

  final ReportDefinition definition;
  final String from;
  final String to;

  /// What each position on the axis is called - a day key, or a cycle day.
  final List<String> labels;

  final List<ReportRow> rows;

  /// The day keys behind the axis. Empty on a cycle-day axis, where one
  /// position is many dates.
  final List<String> dayKeys;

  /// Parallel to [dayKeys] on a date axis: which cycle day each date was, or
  /// null where the stretch is unanchored.
  final List<int?> cycleDays;

  bool get isEmpty => rows.isEmpty;
}

/// Builds a report from stored readings. Pure: nothing here touches storage.
///
/// **Nothing is ever interpolated.** An unlogged day is a cell with a null
/// value, all the way to the painter, and no code path fills a gap from its
/// neighbours. That rule is why the display styles are what they are: bars and
/// squares cannot invent a day, and a line is only allowed because it breaks at
/// one.
Report buildReport(
  ReportDefinition definition, {
  required List<Metric> metrics,
  required Iterable<Observation> observations,
  required String today,
  List<CyclePeriod> cyclePeriods = const [],
}) {
  final (from, to) = definition.period.resolve(today);
  final byId = {for (final metric in metrics) metric.id: metric};

  final bands = <String, ReportSeries>{};
  for (final series in definition.series) {
    if (series.isBand) bands[series.bandBehindMetricId!] = series;
  }

  final rows = <ReportRow>[];
  for (final series in definition.series) {
    if (series.isBand) continue;
    final metric = byId[series.metricId];
    // A marker deleted after the report was saved costs its row, never the
    // report. Losing the whole screen because one marker went is the sort of
    // failure that makes saved reports not worth saving.
    if (metric == null) continue;

    final days = summariseDays(metric, observations, from: from, to: to);
    final band = bands[metric.id];
    final bandMetric = band == null ? null : byId[band.metricId];
    final bandDays = bandMetric == null
        ? const <DaySummary>[]
        : summariseDays(bandMetric, observations, from: from, to: to);

    if (definition.axis == ReportAxis.cycleDay) {
      final folded = _foldOntoCycle(days, cyclePeriods);
      rows.add(ReportRow(
        metric: metric,
        cells: folded,
        stats: statsFor(folded),
        displayStyle: series.displayStyle ?? metric.displayStyle,
        weeklyTypical: null,
        bandMetric: bandMetric,
        bandOn: bandMetric == null
            ? const []
            : _bandOn(_foldOntoCycle(bandDays, cyclePeriods)),
      ));
    } else {
      rows.add(ReportRow(
        metric: metric,
        cells: days,
        stats: statsFor(days),
        displayStyle: series.displayStyle ?? metric.displayStyle,
        weeklyTypical: weeklyTypicalFor(metric, days),
        bandMetric: bandMetric,
        bandOn: bandMetric == null ? const [] : _bandOn(bandDays),
      ));
    }
  }

  if (definition.axis == ReportAxis.cycleDay) {
    final length = rows.isEmpty ? 0 : rows.first.cells.length;
    return Report(
      definition: definition,
      from: from,
      to: to,
      labels: [for (var day = 1; day <= length; day++) '$day'],
      rows: rows,
    );
  }

  final dayKeys = dayKeyRange(from, to);
  return Report(
    definition: definition,
    from: from,
    to: to,
    labels: dayKeys,
    rows: rows,
    dayKeys: dayKeys,
    cycleDays: [
      for (final dayKey in dayKeys) cycleDayFor(dayKey, cyclePeriods),
    ],
  );
}

/// Folds dated days onto cycle day 1..n, one cell per cycle day.
///
/// **Across cycles the rule is always the median, whatever the marker's own day
/// rule is.** Summing a dose across six cycles produces a number that means
/// nothing, and a peak across six cycles is one bad Tuesday reported as a
/// pattern. A cycle day with no dated day behind it stays unlogged rather than
/// being borrowed from its neighbours.
List<DaySummary> _foldOntoCycle(
  List<DaySummary> days,
  List<CyclePeriod> periods,
) {
  final byCycleDay = <int, List<DaySummary>>{};
  var highest = 0;
  for (final day in days) {
    final cycleDay = cycleDayFor(day.dayKey, periods);
    if (cycleDay == null) continue;
    if (cycleDay > highest) highest = cycleDay;
    byCycleDay.putIfAbsent(cycleDay, () => []).add(day);
  }

  return [
    for (var cycleDay = 1; cycleDay <= highest; cycleDay++)
      _foldOne(cycleDay, byCycleDay[cycleDay] ?? const []),
  ];
}

DaySummary _foldOne(int cycleDay, List<DaySummary> days) {
  final logged = days.where((d) => d.isLogged).toList();
  final values = [
    for (final day in days)
      if (day.value case final v?) v,
  ];
  final options = <String>{};
  for (final day in logged) {
    options.addAll(day.optionIds);
  }
  return DaySummary(
    dayKey: '$cycleDay',
    readingCount: logged.fold(0, (sum, d) => sum + d.readingCount),
    value: median(values),
    optionIds: options.toList()..sort(),
    explicitNone: logged.isNotEmpty && options.isEmpty &&
        logged.every((d) => d.explicitNone),
  );
}

List<bool> _bandOn(List<DaySummary> days) => [
      for (final day in days) (day.value ?? 0) > 0,
    ];

/// The typical week for a marker over [days].
///
/// **A dose is summed within a week and a rating is not**, because five doses
/// of 3 g is a 15 g week and five ratings of 3 is not a 15 rating. Weeks are
/// taken in sevens from the start of the period rather than from Monday: the
/// period is what was chosen, and shifting its edge to the nearest Monday
/// silently reports days nobody asked about.
///
/// Null when the period holds less than one full week, since a "typical week"
/// computed from four days is a number with a week's authority and four days'
/// evidence.
num? weeklyTypicalFor(Metric metric, List<DaySummary> days) {
  if (days.length < 7) return null;
  if (!metric.kind.isNumeric) return null;

  final weekly = <num>[];
  for (var start = 0; start + 7 <= days.length; start += 7) {
    final week = days.sublist(start, start + 7);
    final values = [
      for (final day in week)
        if (day.value case final v?) v,
    ];
    if (values.isEmpty) continue;
    weekly.add(
      metric.aggregation == DayAggregation.sum
          ? values.reduce((a, b) => a + b)
          : median(values)!,
    );
  }
  return median(weekly);
}
