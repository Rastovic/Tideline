import 'metric_kind.dart';

/// How a day with several readings becomes one value in a report.
///
/// A marker can be answered as many times a day as the day deserves - appetite
/// at 11:00 and again at 22:00 are two facts. A report still has to draw one
/// square per day, so every marker carries the rule for collapsing its own day,
/// and **the rule is a property of the marker, not of the chart**: bloating
/// wants its peak, a dose wants its total, and no single default is right for
/// both.
///
/// Stored as [wireName]. The raw readings are never overwritten - this is only
/// ever applied at read time, so changing the rule re-reads history rather than
/// rewriting it.
enum DayAggregation {
  /// Everything added up. Doses, glasses of water, minutes trained.
  sum('sum'),

  /// The median, shown to the user as "typical".
  ///
  /// Median rather than mean because self-report is skewed and a mean over a
  /// 1-10 scale reads as precision the data does not have.
  typical('typical'),

  /// The highest reading of the day. The right rule for anything whose peak is
  /// what you noticed - bloating, pain, an urge.
  peak('peak'),

  /// The lowest reading of the day.
  lowest('lowest'),

  /// The last reading of the day, by time.
  last('last'),

  /// True when any reading that day was true.
  anyTrue('anyTrue'),

  /// Every option picked that day, from every reading, merged.
  union('union'),

  /// No collapsing. Each reading stays its own point, which is what a clock
  /// time and a photo need - averaging two bedtimes into one loses the day.
  none('none');

  const DayAggregation(this.wireName);

  final String wireName;

  static DayAggregation? fromWire(String value) {
    for (final rule in DayAggregation.values) {
      if (rule.wireName == value) return rule;
    }
    return null;
  }

  /// The rules that make sense for [kind], first one being the default.
  ///
  /// The editor offers exactly this list, so a marker cannot be configured into
  /// a combination the summary layer would have to guess its way out of.
  static List<DayAggregation> allowedFor(MetricKind kind) => switch (kind) {
        MetricKind.scale ||
        MetricKind.percent =>
          const [typical, peak, lowest, last],
        MetricKind.count ||
        MetricKind.duration ||
        MetricKind.amount =>
          const [sum, typical, peak, lowest, last],
        MetricKind.boolean => const [anyTrue, sum],
        MetricKind.choice => const [last, union],
        MetricKind.tags => const [union],
        MetricKind.text || MetricKind.photo || MetricKind.timeOfDay =>
          const [none],
      };

  /// The rule a newly created marker of [kind] starts with.
  static DayAggregation defaultFor(MetricKind kind) => allowedFor(kind).first;
}
