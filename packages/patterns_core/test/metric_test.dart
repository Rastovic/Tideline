import 'package:patterns_core/patterns_core.dart';
import 'package:test/test.dart';

final createdAt = DateTime.utc(2026, 8, 19, 9);

Metric marker(
  MetricKind kind, {
  String name = 'test',
  List<MetricOption> options = const [],
  String? unit,
  String? lowLabel = 'nisko',
  String? highLabel = 'visoko',
}) =>
    Metric.create(
      id: 'm1',
      name: name,
      domain: MetricDomain.body,
      kind: kind,
      createdAt: createdAt,
      options: options,
      unit: unit,
      lowLabel: lowLabel,
      highLabel: highLabel,
    );

void main() {
  group('defaults by kind', () {
    test('a dose sums its day and draws as bars', () {
      final dose = marker(MetricKind.amount, unit: 'g');
      expect(dose.aggregation, DayAggregation.sum);
      expect(dose.displayStyle, DisplayStyle.bars);
    });

    test('a rating takes its typical value and draws as squares', () {
      final rating = marker(MetricKind.scale);
      expect(rating.aggregation, DayAggregation.typical);
      expect(rating.displayStyle, DisplayStyle.squares);
    });

    test('a boolean is a presence strip that is true if any reading was', () {
      final took = marker(MetricKind.boolean);
      expect(took.aggregation, DayAggregation.anyTrue);
      expect(took.displayStyle, DisplayStyle.presenceStrip);
    });

    test('photos and the diary are never charted', () {
      expect(DisplayStyle.defaultFor(MetricKind.photo), isNull);
      expect(DisplayStyle.defaultFor(MetricKind.text), isNull);
    });

    test('peak is offered for a rating, because bloating is about its worst',
        () {
      expect(
        DayAggregation.allowedFor(MetricKind.scale),
        contains(DayAggregation.peak),
      );
    });
  });

  group('validation', () {
    test('a scale with unlabelled ends is refused', () {
      final problems = validateMetric(
        marker(MetricKind.scale, lowLabel: null, highLabel: null),
      );
      expect(problems.map((p) => p.field), contains('labels'));
    });

    test('an amount with no unit is refused', () {
      final problems = validateMetric(marker(MetricKind.amount));
      expect(problems.map((p) => p.field), contains('unit'));
    });

    test('tags need at least two options', () {
      final problems = validateMetric(marker(MetricKind.tags, options: const [
        MetricOption(id: 'a', label: 'tuga'),
      ]));
      expect(problems.map((p) => p.field), contains('options'));
    });

    test('every problem is reported at once, not one at a time', () {
      final problems = validateMetric(Metric.create(
        id: 'm',
        name: '  ',
        domain: MetricDomain.mind,
        kind: MetricKind.scale,
        createdAt: createdAt,
      ));
      expect(problems.length, greaterThan(1));
    });

    test('a valid marker reports nothing', () {
      expect(validateMetric(marker(MetricKind.scale)), isEmpty);
    });
  });

  group('values against their marker', () {
    test('a rating outside its own scale is refused', () {
      final result = validateValue(
        marker(MetricKind.scale),
        const NumberValue(11, kind: MetricKind.scale),
      );
      expect(result.isErr, isTrue);
    });

    test('a tag that is not on the marker is refused', () {
      final feelings = marker(MetricKind.tags, options: const [
        MetricOption(id: 'tuga', label: 'tuga'),
        MetricOption(id: 'ljutnja', label: 'ljutnja'),
      ]);
      expect(validateValue(feelings, TagsValue(const ['sram'])).isErr, isTrue);
      expect(validateValue(feelings, TagsValue(const ['tuga'])).isOk, isTrue);
    });

    test('an empty tag set is a real answer, not an error', () {
      final feelings = marker(MetricKind.tags, options: const [
        MetricOption(id: 'tuga', label: 'tuga'),
        MetricOption(id: 'ljutnja', label: 'ljutnja'),
      ]);
      final result = validateValue(feelings, TagsValue(const []));
      expect(result.isOk, isTrue);
      expect((result.valueOrNull! as TagsValue).isExplicitNone, isTrue);
    });

    test('a value of the wrong kind never reaches storage', () {
      final result = validateValue(
        marker(MetricKind.scale),
        const BooleanValue(true),
      );
      expect(result.isErr, isTrue);
    });

    test('a negative amount is allowed, a negative count is not', () {
      expect(
        validateValue(
          marker(MetricKind.amount, unit: 'kg'),
          const NumberValue(-1.2, kind: MetricKind.amount),
        ).isOk,
        isTrue,
      );
      expect(
        validateValue(
          marker(MetricKind.count),
          const NumberValue(-1, kind: MetricKind.count),
        ).isErr,
        isTrue,
      );
    });
  });

  group('retyping a marker that already holds readings', () {
    test('is refused where the values cannot survive it', () {
      expect(
        canRetype(MetricKind.scale, MetricKind.percent, hasReadings: true),
        isFalse,
      );
    });

    test('is free while it is still empty', () {
      expect(
        canRetype(MetricKind.scale, MetricKind.percent, hasReadings: false),
        isTrue,
      );
    });
  });

  test('archiving keeps the marker out of the home list, not out of history',
      () {
    final finished = marker(MetricKind.boolean).copyWith(
      archivedAt: DateTime.utc(2026, 9),
    );
    expect(finished.isActive, isFalse);
    expect(finished.isDeleted, isFalse);
  });
}
