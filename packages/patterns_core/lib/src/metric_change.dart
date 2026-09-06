import 'metric.dart';
import 'metric_kind.dart';
import 'validation.dart';

/// What a marker already holds, as far as an edit needs to know.
///
/// The editor cannot decide on its own whether a change is safe: narrowing a
/// scale is harmless on a marker answered twice and destroys meaning on one
/// answered for a year. So the rules live here and the facts are supplied by
/// whoever can read the readings, which keeps this package free of storage.
final class MetricReadingFacts {
  const MetricReadingFacts({
    required this.count,
    this.lowestNumber,
    this.highestNumber,
    this.usedOptionIds = const {},
  });

  /// Readings recorded against the marker, deleted ones excluded.
  final int count;

  /// The extremes actually recorded, for the kinds that store a number.
  /// Null when nothing numeric was ever written.
  final num? lowestNumber;
  final num? highestNumber;

  /// Options that have been picked at least once.
  ///
  /// An option added by mistake a minute ago can be removed outright; one that
  /// carries history can only be archived, because every reading that picked it
  /// points at its id.
  final Set<String> usedOptionIds;

  bool get hasReadings => count > 0;

  /// A marker nothing has been written to yet, which is every marker the
  /// editor has just created.
  static const none = MetricReadingFacts(count: 0);
}

/// Checks an edit before it is saved: [before] as stored, [after] as the editor
/// would write it.
///
/// Runs [validateMetric] on the result first, then the three things that are
/// only wrong in the light of what is already recorded. Like [validateMetric]
/// it returns every problem at once.
///
/// **All three refusals here are data-loss guards, not preferences.** Each one
/// is a change that leaves readings on disk meaning something other than what
/// they meant when they were written, which is the one bug class this app
/// cannot recover from - a year of entries cannot be re-answered.
List<ValidationFailure> validateMetricChange(
  Metric before,
  Metric after, {
  required MetricReadingFacts facts,
}) {
  final problems = validateMetric(after);

  if (after.kind != before.kind &&
      !canRetype(before.kind, after.kind, hasReadings: facts.hasReadings)) {
    // Reinterpreting a year of 1-10 ratings as percentages is a data-loss bug
    // wearing a feature's clothes. The editor offers the honest alternative.
    problems.add(ValidationFailure(
      'kind',
      'Vec ima ${facts.count} unosa, pa vise ne moze promijeniti tip. '
          'Arhiviraj ovaj i napravi novi.',
    ));
  }

  if (after.kind == MetricKind.scale && before.kind == MetricKind.scale) {
    final lowest = facts.lowestNumber;
    final highest = facts.highestNumber;
    if (lowest != null && lowest < after.scaleMin) {
      problems.add(ValidationFailure(
        'scale',
        'Vec postoji unos $lowest, ispod nove donje granice '
            '${after.scaleMin}.',
      ));
    }
    if (highest != null && highest > after.scaleMax) {
      problems.add(ValidationFailure(
        'scale',
        'Vec postoji unos $highest, iznad nove gornje granice '
            '${after.scaleMax}.',
      ));
    }
  }

  final keptIds = after.options.map((o) => o.id).toSet();
  for (final option in before.options) {
    if (keptIds.contains(option.id)) continue;
    if (!facts.usedOptionIds.contains(option.id)) continue;
    problems.add(ValidationFailure(
      'options',
      '"${option.label}" je vec biran. Arhiviraj ga umjesto da ga brises.',
    ));
  }

  return problems;
}
