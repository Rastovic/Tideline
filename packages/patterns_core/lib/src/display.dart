import 'metric_kind.dart';

/// How a marker draws itself in a report.
///
/// **A per-marker setting, not an app-wide rule.** The whole point of a report
/// here is stacking a rising dose against a symptom against a training day, and
/// those three want three different shapes. The user sets a default when the
/// marker is created and can override it inside any single report.
enum DisplayStyle {
  /// One square per day, colour intensity from the value, an empty outline for
  /// a day with nothing logged.
  ///
  /// The honest default for ratings: an unlogged day looks unlogged.
  squares('squares'),

  /// A column per day. Reads growth better than anything else, which is what a
  /// dose climbing over a month needs.
  bars('bars'),

  /// One dot per reading, unconnected.
  ///
  /// The only style that shows several readings in one day without collapsing
  /// them, and the required style for a clock time.
  dots('dots'),

  /// A broken line: segments join **only** consecutive logged days, and a gap
  /// stays a gap.
  ///
  /// The old plan banned lines outright. The real target of that ban was
  /// interpolation - a line drawn straight through days you never logged
  /// invents them - and breaking at gaps removes exactly that, so the shape is
  /// allowed and the lie is not.
  brokenLine('brokenLine'),

  /// A thin strip, filled on days something was true.
  presenceStrip('presenceStrip'),

  /// The same strip, drawn **behind** another marker's chart as a pale band.
  ///
  /// The one overlay the app permits, and the reason it is safe: a band has no
  /// scale of its own, so it cannot be stretched to agree with the series in
  /// front of it. Two y axes in one frame are banned for the opposite reason.
  backgroundBand('backgroundBand'),

  /// One row per option, marked where that option was picked. How named
  /// feelings are read: eight sparse rows, and the dark cells line up or they
  /// do not.
  tagRows('tagRows');

  const DisplayStyle(this.wireName);

  final String wireName;

  static DisplayStyle? fromWire(String value) {
    for (final style in DisplayStyle.values) {
      if (style.wireName == value) return style;
    }
    return null;
  }

  /// The styles offered for [kind], first one being the default.
  static List<DisplayStyle> allowedFor(MetricKind kind) => switch (kind) {
        MetricKind.scale || MetricKind.percent =>
          const [squares, bars, dots, brokenLine],
        MetricKind.count || MetricKind.duration || MetricKind.amount =>
          const [bars, squares, dots, brokenLine],
        MetricKind.boolean =>
          const [presenceStrip, backgroundBand, squares, dots],
        MetricKind.choice => const [tagRows, dots],
        MetricKind.tags => const [tagRows],
        MetricKind.timeOfDay => const [dots],
        // Neither is charted. They are read on the day detail screen, which is
        // where a photo belongs: next to what else happened that day.
        MetricKind.text || MetricKind.photo => const [],
      };

  static DisplayStyle? defaultFor(MetricKind kind) {
    final allowed = allowedFor(kind);
    return allowed.isEmpty ? null : allowed.first;
  }
}
