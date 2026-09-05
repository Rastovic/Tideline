import 'package:patterns_core/patterns_core.dart';
import 'package:test/test.dart';

final createdAt = DateTime.utc(2026, 8, 1);

Metric marker(MetricKind kind, DayAggregation rule) => Metric(
      id: 'm1',
      name: 'test',
      domain: MetricDomain.body,
      kind: kind,
      aggregation: rule,
      displayStyle: DisplayStyle.defaultFor(kind),
      createdAt: createdAt,
      unit: 'g',
      lowLabel: 'nisko',
      highLabel: 'visoko',
    );

var _seq = 0;

Observation reading(
  String dayKey,
  MetricValue value, {
  int hour = 12,
}) =>
    Observation(
      id: 'o${_seq++}',
      metricId: 'm1',
      dayKey: dayKey,
      recordedAt: DateTime.utc(2026, 8, int.parse(dayKey.split('-').last), hour),
      utcOffsetMinutes: 120,
      value: value,
    );

MetricValue scale(num n) => NumberValue(n, kind: MetricKind.scale);
MetricValue grams(num n) => NumberValue(n, kind: MetricKind.amount);

void main() {
  group('a day holding several readings', () {
    test('a dose is the total of the day', () {
      final summaries = summariseDays(
        marker(MetricKind.amount, DayAggregation.sum),
        [
          reading('2026-08-02', grams(3), hour: 9),
          reading('2026-08-02', grams(2), hour: 21),
        ],
        from: '2026-08-02',
        to: '2026-08-02',
      );
      expect(summaries.single.value, 5);
      expect(summaries.single.readingCount, 2);
    });

    test('bloating keeps its peak, because the peak is what you noticed', () {
      final summaries = summariseDays(
        marker(MetricKind.scale, DayAggregation.peak),
        [
          reading('2026-08-02', scale(2), hour: 8),
          reading('2026-08-02', scale(7), hour: 15),
          reading('2026-08-02', scale(3), hour: 22),
        ],
        from: '2026-08-02',
        to: '2026-08-02',
      );
      expect(summaries.single.value, 7);
    });

    test('a rating takes the typical value, not the mean', () {
      // Mean would be 5.25 and would be dragged by the one bad reading.
      final summaries = summariseDays(
        marker(MetricKind.scale, DayAggregation.typical),
        [
          reading('2026-08-02', scale(6), hour: 8),
          reading('2026-08-02', scale(7), hour: 12),
          reading('2026-08-02', scale(7), hour: 16),
          reading('2026-08-02', scale(1), hour: 23),
        ],
        from: '2026-08-02',
        to: '2026-08-02',
      );
      expect(summaries.single.value, 6.5);
    });

    test('"last" reads the clock, not the order the rows arrived in', () {
      final summaries = summariseDays(
        marker(MetricKind.scale, DayAggregation.last),
        [
          reading('2026-08-02', scale(9), hour: 22),
          reading('2026-08-02', scale(4), hour: 7),
        ],
        from: '2026-08-02',
        to: '2026-08-02',
      );
      expect(summaries.single.value, 9);
    });
  });

  group('days with nothing in them', () {
    test('are present, empty, and never interpolated', () {
      final summaries = summariseDays(
        marker(MetricKind.scale, DayAggregation.typical),
        [
          reading('2026-08-01', scale(2)),
          reading('2026-08-05', scale(8)),
        ],
        from: '2026-08-01',
        to: '2026-08-05',
      );
      expect(summaries, hasLength(5));
      expect(summaries[0].value, 2);
      // The three days between hold no invented value between 2 and 8.
      expect(summaries[1].value, isNull);
      expect(summaries[2].value, isNull);
      expect(summaries[3].value, isNull);
      expect(summaries.every((s) => s.isLogged), isFalse);
      expect(summaries[4].value, 8);
    });

    test('are not the same thing as "none of these"', () {
      final feelings = Metric(
        id: 'm1',
        name: 'osjecanja',
        domain: MetricDomain.mind,
        kind: MetricKind.tags,
        aggregation: DayAggregation.union,
        displayStyle: DisplayStyle.tagRows,
        createdAt: createdAt,
        options: const [
          MetricOption(id: 'tuga', label: 'tuga'),
          MetricOption(id: 'ljutnja', label: 'ljutnja'),
        ],
      );
      final summaries = summariseDays(
        feelings,
        [reading('2026-08-02', TagsValue(const []))],
        from: '2026-08-01',
        to: '2026-08-02',
      );
      final unlogged = summaries[0];
      final answeredNone = summaries[1];
      expect(unlogged.isLogged, isFalse);
      expect(unlogged.explicitNone, isFalse);
      expect(answeredNone.isLogged, isTrue);
      expect(answeredNone.explicitNone, isTrue);
    });
  });

  test('tags merge every pick of the day', () {
    final feelings = Metric(
      id: 'm1',
      name: 'osjecanja',
      domain: MetricDomain.mind,
      kind: MetricKind.tags,
      aggregation: DayAggregation.union,
      displayStyle: DisplayStyle.tagRows,
      createdAt: createdAt,
      options: const [
        MetricOption(id: 'tuga', label: 'tuga'),
        MetricOption(id: 'overthink', label: 'overthink'),
      ],
    );
    final summaries = summariseDays(
      feelings,
      [
        reading('2026-08-02', TagsValue(const ['tuga']), hour: 9),
        reading('2026-08-02', TagsValue(const ['overthink', 'tuga']), hour: 23),
      ],
      from: '2026-08-02',
      to: '2026-08-02',
    );
    expect(summaries.single.optionIds, ['overthink', 'tuga']);
  });

  group('the facts about a period', () {
    test('coverage counts logged days against the whole period', () {
      final summaries = summariseDays(
        marker(MetricKind.scale, DayAggregation.typical),
        [
          reading('2026-08-01', scale(4)),
          reading('2026-08-03', scale(6)),
        ],
        from: '2026-08-01',
        to: '2026-08-04',
      );
      final stats = statsFor(summaries);
      expect(stats.daysInPeriod, 4);
      expect(stats.daysLogged, 2);
      expect(stats.coverage, 0.5);
      expect(stats.typical, 5);
      expect(stats.lowest, 4);
      expect(stats.highest, 6);
    });

    test('an empty period states nothing rather than zero', () {
      final stats = statsFor(summariseDays(
        marker(MetricKind.scale, DayAggregation.typical),
        const [],
        from: '2026-08-01',
        to: '2026-08-07',
      ));
      expect(stats.typical, isNull);
      expect(stats.coverage, 0);
    });
  });

  group('clock times are circular', () {
    test('23:40 and 00:20 average to midnight, not to noon', () {
      expect(circularMeanMinutes([23 * 60 + 40, 20]), 0);
    });

    test('two ordinary evening times average between them', () {
      expect(circularMeanMinutes([22 * 60, 23 * 60]), 22 * 60 + 30);
    });

    test('times spread evenly round the clock have no average', () {
      expect(circularMeanMinutes([0, 360, 720, 1080]), isNull);
    });
  });

  test('a deleted reading is not counted', () {
    final summaries = summariseDays(
      marker(MetricKind.scale, DayAggregation.typical),
      [
        reading('2026-08-02', scale(5)).copyWith(
          deletedAt: DateTime.utc(2026, 8, 3),
        ),
      ],
      from: '2026-08-02',
      to: '2026-08-02',
    );
    expect(summaries.single.isLogged, isFalse);
  });
}
