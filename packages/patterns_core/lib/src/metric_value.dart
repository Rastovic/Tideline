import 'metric_kind.dart';

/// One recorded reading.
///
/// A sealed family rather than a `dynamic` column, so a switch over a value is
/// exhaustive at compile time and a new kind cannot be added without every
/// consumer being told about it.
sealed class MetricValue {
  const MetricValue();

  /// The kind this value belongs to. Used to reject a value written against a
  /// marker of a different kind before it ever reaches storage.
  MetricKind get kind;

  /// The value as a number, for charts and summaries, or null when this kind
  /// carries no number ([ChoiceValue], [TagsValue], [TextValue], [PhotoValue]).
  ///
  /// [BooleanValue] projects to 0 and 1 so "days trained" is a sum and a
  /// presence strip is a chart like any other. [TimeOfDayValue] projects to
  /// minutes from midnight, which is **not** safe to average directly - see
  /// the circular path in the summary layer.
  num? get asNumber;

  /// The value as it goes to storage and to an export.
  Object? toWire();
}

/// A rating, a percentage, a tally, minutes, or a quantity with a unit.
///
/// One class for six kinds because the storage and the maths are identical and
/// only the input widget and the formatting differ. Splitting them would buy a
/// stricter type and cost a switch in every consumer.
final class NumberValue extends MetricValue {
  const NumberValue(this.number, {required this.kind});

  final num number;

  @override
  final MetricKind kind;

  @override
  num? get asNumber => number;

  @override
  Object? toWire() => number;

  @override
  bool operator ==(Object other) =>
      other is NumberValue && other.number == number && other.kind == kind;

  @override
  int get hashCode => Object.hash(kind, number);

  @override
  String toString() => 'NumberValue($number, ${kind.wireName})';
}

/// Did or did not.
final class BooleanValue extends MetricValue {
  const BooleanValue(this.value);

  final bool value;

  @override
  MetricKind get kind => MetricKind.boolean;

  @override
  num? get asNumber => value ? 1 : 0;

  @override
  Object? toWire() => value;

  @override
  bool operator ==(Object other) => other is BooleanValue && other.value == value;

  @override
  int get hashCode => Object.hash('bool', value);

  @override
  String toString() => 'BooleanValue($value)';
}

/// Exactly one option, held by its stable id rather than its label, so renaming
/// an option does not rewrite history.
final class ChoiceValue extends MetricValue {
  const ChoiceValue(this.optionId);

  final String optionId;

  @override
  MetricKind get kind => MetricKind.choice;

  @override
  num? get asNumber => null;

  @override
  Object? toWire() => optionId;

  @override
  bool operator ==(Object other) =>
      other is ChoiceValue && other.optionId == optionId;

  @override
  int get hashCode => Object.hash('choice', optionId);

  @override
  String toString() => 'ChoiceValue($optionId)';
}

/// Any number of options, including none.
///
/// **An empty set is a real answer**, not a missing one: it is how "none of
/// these today" is recorded. Without it there is no difference between a day
/// with no sadness and a day never filled in, and that difference is the whole
/// reason skips are stored at all.
final class TagsValue extends MetricValue {
  TagsValue(Iterable<String> optionIds)
      : optionIds = List.unmodifiable(optionIds.toSet().toList()..sort());

  final List<String> optionIds;

  /// True when the user explicitly answered "none of these".
  bool get isExplicitNone => optionIds.isEmpty;

  @override
  MetricKind get kind => MetricKind.tags;

  @override
  num? get asNumber => null;

  @override
  Object? toWire() => optionIds;

  @override
  bool operator ==(Object other) =>
      other is TagsValue &&
      other.optionIds.length == optionIds.length &&
      _sameOrder(other.optionIds, optionIds);

  static bool _sameOrder(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(['tags', ...optionIds]);

  @override
  String toString() => 'TagsValue(${optionIds.join(', ')})';
}

/// Free text.
final class TextValue extends MetricValue {
  const TextValue(this.text);

  final String text;

  @override
  MetricKind get kind => MetricKind.text;

  @override
  num? get asNumber => null;

  @override
  Object? toWire() => text;

  @override
  bool operator ==(Object other) => other is TextValue && other.text == text;

  @override
  int get hashCode => Object.hash('text', text);

  @override
  String toString() => 'TextValue(${text.length} chars)';
}

/// One photo, held by id rather than by path, with an optional caption.
///
/// The bytes live in app-private files and never in the database. The caption
/// is searchable alongside the diary, because "poslije treninga" is the part
/// that makes the photo mean anything six months later.
final class PhotoValue extends MetricValue {
  const PhotoValue({required this.photoId, this.caption});

  final String photoId;
  final String? caption;

  @override
  MetricKind get kind => MetricKind.photo;

  @override
  num? get asNumber => null;

  @override
  Object? toWire() => {
        'photoId': photoId,
        if (caption != null) 'caption': caption,
      };

  @override
  bool operator ==(Object other) =>
      other is PhotoValue &&
      other.photoId == photoId &&
      other.caption == caption;

  @override
  int get hashCode => Object.hash('photo', photoId, caption);

  @override
  String toString() => 'PhotoValue($photoId)';
}

/// A clock time, stored as minutes from local midnight.
///
/// Stored this way rather than as an instant because "I went to bed at 23:40"
/// is a fact about the clock, not about a moment in UTC, and it must not move
/// when the phone crosses a timezone.
final class TimeOfDayValue extends MetricValue {
  const TimeOfDayValue(this.minutesFromMidnight);

  final int minutesFromMidnight;

  int get hour => minutesFromMidnight ~/ 60;
  int get minute => minutesFromMidnight % 60;

  @override
  MetricKind get kind => MetricKind.timeOfDay;

  @override
  num? get asNumber => minutesFromMidnight;

  @override
  Object? toWire() => minutesFromMidnight;

  @override
  bool operator ==(Object other) =>
      other is TimeOfDayValue &&
      other.minutesFromMidnight == minutesFromMidnight;

  @override
  int get hashCode => Object.hash('timeOfDay', minutesFromMidnight);

  @override
  String toString() =>
      'TimeOfDayValue(${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')})';
}
