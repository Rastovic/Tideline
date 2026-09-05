/// What sort of thing a marker records.
///
/// **This list is closed.** Every marker in the app - the ones seeded on first
/// run and the ones the user invents later - is one of these, and there is no
/// code path that only a built-in can take. The moment "mood" is a column and
/// "hair thickness" is a row in a generic side table, the custom side is
/// permanently second class, which is the one thing this app cannot afford.
///
/// Stored as [wireName], never as an ordinal. Reordering this enum must not
/// silently reinterpret a year of history.
enum MetricKind {
  /// A rating between two bounds the user sets, both ends labelled.
  /// Mood, tiredness, bloating, how a workout went.
  scale('scale'),

  /// 0-100 in steps of five. "How much of my usual self".
  percent('percent'),

  /// A tally. Glasses of water, cigarettes, times woken.
  count('count'),

  /// Minutes, entered as hours and minutes. A workout, time outdoors.
  duration('duration'),

  /// A number with a unit. A dose, a weight, a measurement.
  amount('amount'),

  /// Did or did not. Took the supplement, trained, went outside.
  boolean('boolean'),

  /// Exactly one option from a list the user owns.
  /// Which part of the day, which medication.
  choice('choice'),

  /// Any number of options from a list the user owns.
  /// Named feelings, contexts, symptoms.
  tags('tags'),

  /// Free text of any length. The diary.
  text('text'),

  /// One image with an optional caption.
  photo('photo'),

  /// A clock time. Bedtime, waking, first coffee.
  ///
  /// **Circular**, and that is not a detail: the mean of 23:40 and 00:20 is
  /// midnight, not noon, so this kind gets its own averaging path and its own
  /// named test.
  timeOfDay('timeOfDay');

  const MetricKind(this.wireName);

  /// The stable string written to storage and to an export.
  final String wireName;

  /// Parses a stored name, or null when a future version wrote something this
  /// build does not know. A bad row must cost one row, never the import.
  static MetricKind? fromWire(String value) {
    for (final kind in MetricKind.values) {
      if (kind.wireName == value) return kind;
    }
    return null;
  }

  /// Whether a day can hold more than one of these and still make sense.
  ///
  /// Every kind except [text] can: appetite at 11:00 and again at 22:00 are two
  /// facts, not a correction. The diary is the exception because a second entry
  /// on the same day is a continuation of the first, not a second reading.
  bool get allowsManyPerDay => this != MetricKind.text;

  /// Whether values of this kind can be reduced to a number for a chart.
  ///
  /// [choice], [tags], [text] and [photo] cannot, so they are drawn as rows and
  /// strips rather than as bars, and they never enter a numeric summary.
  bool get isNumeric => switch (this) {
        MetricKind.scale ||
        MetricKind.percent ||
        MetricKind.count ||
        MetricKind.duration ||
        MetricKind.amount ||
        MetricKind.boolean ||
        MetricKind.timeOfDay =>
          true,
        MetricKind.choice ||
        MetricKind.tags ||
        MetricKind.text ||
        MetricKind.photo =>
          false,
      };
}
