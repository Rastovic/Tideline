import 'package:vitals_core/vitals_core.dart';

import 'aggregation.dart';
import 'language.dart';
import 'display.dart';
import 'metric.dart';
import 'metric_kind.dart';
import 'metric_value.dart';

/// Why a marker or a reading was refused.
///
/// A message, not a boolean. The editor shows [message] verbatim, so "a scale
/// needs both ends labelled" is written once here rather than reinvented in
/// three widgets, and a test can assert the exact wording.
final class ValidationFailure {
  const ValidationFailure(this.field, this.message);

  /// The field the user has to fix, for focusing the right input.
  final String field;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is ValidationFailure &&
      other.field == field &&
      other.message == message;

  @override
  int get hashCode => Object.hash(field, message);

  @override
  String toString() => '$field: $message';
}

/// Checks a marker definition before it is saved.
///
/// Returns every problem at once rather than the first, because fixing a form
/// one error at a time is how a person gives up on a form.
List<ValidationFailure> validateMetric(
  Metric metric, [
  TextLanguage language = TextLanguage.en,
]) {
  String t(String en, String sr) => language.pick(en, sr);
  final problems = <ValidationFailure>[];

  if (metric.name.trim().isEmpty) {
    problems.add(ValidationFailure('name', t('Give it a name.', 'Daj mu ime.')));
  }

  if (!DayAggregation.allowedFor(metric.kind).contains(metric.aggregation)) {
    problems.add(ValidationFailure(
      'aggregation',
      t(
        'A ${metric.kind.wireName} marker cannot summarise a day by '
            '${metric.aggregation.wireName}.',
        'Marker tipa ${metric.kind.wireName} ne moze sazeti dan po pravilu '
            '${metric.aggregation.wireName}.',
      ),
    ));
  }

  final allowedStyles = DisplayStyle.allowedFor(metric.kind);
  final style = metric.displayStyle;
  if (style == null) {
    if (allowedStyles.isNotEmpty) {
      problems.add(ValidationFailure(
        'displayStyle',
        t('Choose how this marker is drawn.', 'Izaberi kako se marker crta.'),
      ));
    }
  } else if (!allowedStyles.contains(style)) {
    problems.add(ValidationFailure(
      'displayStyle',
      t(
        'A ${metric.kind.wireName} marker cannot be drawn as '
            '${style.wireName}.',
        'Marker tipa ${metric.kind.wireName} ne moze se crtati kao '
            '${style.wireName}.',
      ),
    ));
  }

  switch (metric.kind) {
    case MetricKind.scale:
      if (metric.scaleMax - metric.scaleMin < 1) {
        problems.add(ValidationFailure(
          'scale',
          t('The top of the scale has to be above the bottom.',
              'Gornja granica mora biti iznad donje.'),
        ));
      }
      if ((metric.lowLabel ?? '').trim().isEmpty ||
          (metric.highLabel ?? '').trim().isEmpty) {
        // Unlabelled ends are the reason old ratings become unreadable: a 3
        // means nothing in March unless you wrote down what 1 and 10 were.
        problems.add(ValidationFailure(
          'labels',
          t('Say what the low end and the high end mean.',
              'Napisi sta znace najniza i najvisa vrijednost.'),
        ));
      }
    case MetricKind.amount:
      if ((metric.unit ?? '').trim().isEmpty) {
        problems.add(ValidationFailure(
          'unit',
          t('An amount needs a unit - g, ml, kg.',
              'Kolicina treba jedinicu - g, ml, kg.'),
        ));
      }
    case MetricKind.choice:
    case MetricKind.tags:
      if (metric.liveOptions.length < 2) {
        problems.add(ValidationFailure(
          'options',
          t('Add at least two options.', 'Dodaj bar dvije opcije.'),
        ));
      }
      final ids = metric.options.map((o) => o.id).toList();
      if (ids.toSet().length != ids.length) {
        problems.add(ValidationFailure(
          'options',
          t('Two options share an id.', 'Dvije opcije dijele isti id.'),
        ));
      }
    case MetricKind.percent:
    case MetricKind.count:
    case MetricKind.duration:
    case MetricKind.boolean:
    case MetricKind.text:
    case MetricKind.photo:
    case MetricKind.timeOfDay:
      break;
  }

  return problems;
}

/// Checks a reading against the marker it claims to belong to.
///
/// The last gate before storage. A value of the wrong kind, an option that does
/// not exist, or a rating outside its own scale is refused here rather than
/// discovered a year later in a chart that cannot be drawn.
Result<MetricValue, ValidationFailure> validateValue(
  Metric metric,
  MetricValue value,
) {
  if (value.kind != metric.kind) {
    return Err(ValidationFailure(
      'value',
      'That is a ${value.kind.wireName} value on a '
          '${metric.kind.wireName} marker.',
    ));
  }

  switch (value) {
    case NumberValue(:final number):
      switch (metric.kind) {
        case MetricKind.scale:
          if (number < metric.scaleMin || number > metric.scaleMax) {
            return Err(ValidationFailure(
              'value',
              'Outside ${metric.scaleMin}-${metric.scaleMax}.',
            ));
          }
        case MetricKind.percent:
          if (number < 0 || number > 100) {
            return const Err(ValidationFailure('value', 'Outside 0-100.'));
          }
        case MetricKind.count:
        case MetricKind.duration:
          if (number < 0) {
            return const Err(
              ValidationFailure('value', 'Cannot be negative.'),
            );
          }
        case MetricKind.amount:
          // A measurement can legitimately be negative - a temperature, a
          // change against a baseline - so nothing is refused here.
          break;
        default:
          break;
      }
    case ChoiceValue(:final optionId):
      if (!metric.options.any((o) => o.id == optionId)) {
        return const Err(
          ValidationFailure('value', 'That option is not on this marker.'),
        );
      }
    case TagsValue(:final optionIds):
      final known = metric.options.map((o) => o.id).toSet();
      final unknown = optionIds.where((id) => !known.contains(id));
      if (unknown.isNotEmpty) {
        return Err(ValidationFailure(
          'value',
          'Unknown option: ${unknown.first}.',
        ));
      }
    case TimeOfDayValue(:final minutesFromMidnight):
      if (minutesFromMidnight < 0 || minutesFromMidnight > 1439) {
        return const Err(
          ValidationFailure('value', 'Not a time of day.'),
        );
      }
    case PhotoValue(:final photoId):
      if (photoId.trim().isEmpty) {
        return const Err(ValidationFailure('value', 'Photo has no file.'));
      }
    case BooleanValue():
    case TextValue():
      break;
  }

  return Ok(value);
}

/// Whether a marker holding readings can be changed to [target] kind.
///
/// Almost always no, and the editor offers "archive this and start a new one"
/// instead. The exception is a widening that cannot lose meaning, and even that
/// is refused when readings exist outside the new bounds - checked by the
/// caller, which has the readings.
bool canRetype(MetricKind from, MetricKind to, {required bool hasReadings}) {
  if (from == to) return true;
  if (!hasReadings) return true;
  return switch ((from, to)) {
    (MetricKind.count, MetricKind.amount) => true,
    (MetricKind.scale, MetricKind.count) => true,
    _ => false,
  };
}
