import 'package:patterns_core/patterns_core.dart';
import 'package:test/test.dart';

final createdAt = DateTime.utc(2026, 8, 1, 9);

Metric marker(
  String id,
  String name,
  MetricKind kind, {
  DayAggregation? aggregation,
  DisplayStyle? display,
}) {
  final made = Metric.create(
    id: id,
    name: name,
    domain: MetricDomain.body,
    kind: kind,
    createdAt: createdAt,
    unit: kind == MetricKind.amount ? 'g' : null,
    lowLabel: 'nisko',
    highLabel: 'visoko',
  );
  return made.copyWith(aggregation: aggregation, displayStyle: display);
}

Observation reading(String metricId, String dayKey, MetricValue value) =>
    Observation(
      id: 'o-$metricId-$dayKey-${value.hashCode}',
      metricId: metricId,
      dayKey: dayKey,
      recordedAt: DateTime.utc(2026, 9, 1, 12),
      utcOffsetMinutes: 120,
      value: value,
    );

MetricValue scale(int n) => NumberValue(n, kind: MetricKind.scale);
MetricValue grams(num n) => NumberValue(n, kind: MetricKind.amount);

ReportDefinition definition(
  List<ReportSeries> series, {
  ReportPeriod period = const LastDays(7),
  ReportAxis axis = ReportAxis.date,
}) =>
    ReportDefinition(
      id: 'r1',
      name: 'test',
      series: series,
      period: period,
      axis: axis,
      createdAt: createdAt,
    );

void main() {
  group('the period', () {
    test('a rolling window counts back from today, today included', () {
      expect(const LastDays(7).resolve('2026-09-07'), ('2026-09-01', '2026-09-07'));
    });

    test('a fixed stretch does not move', () {
      const period = FixedPeriod(from: '2026-08-01', to: '2026-08-31');
      expect(period.resolve('2026-09-07'), ('2026-08-01', '2026-08-31'));
    });

    test('both survive a round trip through storage', () {
      for (final period in [
        const LastDays(30),
        const FixedPeriod(from: '2026-08-01', to: '2026-08-31'),
      ]) {
        expect(ReportPeriod.fromWire(period.wire)!.wire, period.wire);
      }
    });
  });

  group('the shared axis', () {
    test('every row has one cell per day, in the same order', () {
      // This is what makes stacked rows readable at all: cell 4 of every row
      // is the same date.
      final mood = marker('m1', 'raspolozenje', MetricKind.scale);
      final dose = marker('m2', 'kreatin doza', MetricKind.amount);
      final report = buildReport(
        definition([
          const ReportSeries(metricId: 'm1'),
          const ReportSeries(metricId: 'm2'),
        ]),
        metrics: [mood, dose],
        observations: [reading('m1', '2026-09-03', scale(7))],
        today: '2026-09-07',
      );

      expect(report.labels, hasLength(7));
      for (final row in report.rows) {
        expect(row.cells, hasLength(7));
        expect(row.cells.map((c) => c.dayKey), report.labels);
      }
    });

    test('an unlogged day is a cell, never a gap in the list', () {
      final mood = marker('m1', 'raspolozenje', MetricKind.scale);
      final report = buildReport(
        definition([const ReportSeries(metricId: 'm1')]),
        metrics: [mood],
        observations: [reading('m1', '2026-09-03', scale(7))],
        today: '2026-09-07',
      );

      final cells = report.rows.single.cells;
      expect(cells.where((c) => c.isLogged), hasLength(1));
      expect(cells.where((c) => c.value == null), hasLength(6));
      // Nothing between 3 September and 7 September was invented.
      expect(cells.last.value, isNull);
    });

    test('a marker deleted after the report was saved costs its row only', () {
      final mood = marker('m1', 'raspolozenje', MetricKind.scale);
      final report = buildReport(
        definition([
          const ReportSeries(metricId: 'm1'),
          const ReportSeries(metricId: 'gone'),
        ]),
        metrics: [mood],
        observations: const [],
        today: '2026-09-07',
      );

      expect(report.rows, hasLength(1));
      expect(report.rows.single.metric.id, 'm1');
    });
  });

  group('the display style', () {
    test('the report overrides the marker without changing it', () {
      final dose = marker('m1', 'kreatin doza', MetricKind.amount);
      expect(dose.displayStyle, DisplayStyle.bars);

      final report = buildReport(
        definition([
          const ReportSeries(metricId: 'm1', displayStyle: DisplayStyle.dots),
        ]),
        metrics: [dose],
        observations: const [],
        today: '2026-09-07',
      );

      expect(report.rows.single.displayStyle, DisplayStyle.dots);
      expect(dose.displayStyle, DisplayStyle.bars, reason: 'marker untouched');
    });

    test('no override falls back to the marker itself', () {
      final dose = marker('m1', 'kreatin doza', MetricKind.amount);
      final report = buildReport(
        definition([const ReportSeries(metricId: 'm1')]),
        metrics: [dose],
        observations: const [],
        today: '2026-09-07',
      );

      expect(report.rows.single.displayStyle, DisplayStyle.bars);
    });
  });

  group('the one permitted overlay', () {
    test('a boolean band is not a row, it rides behind one', () {
      // The only overlay the app allows, and safe because a band has no scale
      // of its own to stretch until it agrees with the series in front.
      final bloating = marker('m1', 'nadutost', MetricKind.scale);
      final creatine = marker('m2', 'kreatin', MetricKind.boolean);
      final report = buildReport(
        definition([
          const ReportSeries(metricId: 'm1'),
          const ReportSeries(metricId: 'm2', bandBehindMetricId: 'm1'),
        ]),
        metrics: [bloating, creatine],
        observations: [
          reading('m2', '2026-09-02', const BooleanValue(true)),
          reading('m2', '2026-09-03', const BooleanValue(false)),
        ],
        today: '2026-09-07',
      );

      expect(report.rows, hasLength(1), reason: 'the band is not its own row');
      final row = report.rows.single;
      expect(row.bandMetric?.id, 'm2');
      expect(row.bandOn, hasLength(7));
      expect(row.bandOn[1], isTrue);
      expect(row.bandOn[2], isFalse);
    });

    test('one row draws one marker, so two y axes cannot be built', () {
      // Structural rather than checked: a row holds a single metric and a
      // single list of cells. There is nowhere to put a second series.
      final report = buildReport(
        definition([
          const ReportSeries(metricId: 'm1'),
          const ReportSeries(metricId: 'm2'),
        ]),
        metrics: [
          marker('m1', 'a', MetricKind.scale),
          marker('m2', 'b', MetricKind.amount),
        ],
        observations: const [],
        today: '2026-09-07',
      );

      expect(report.rows, hasLength(2));
      expect(report.rows.map((r) => r.metric.id), ['m1', 'm2']);
    });
  });

  group('the typical week', () {
    test('a dose is summed within the week, because five 3 g days are 15 g',
        () {
      final dose = marker('m1', 'kreatin doza', MetricKind.amount);
      expect(dose.aggregation, DayAggregation.sum);

      final report = buildReport(
        definition([const ReportSeries(metricId: 'm1')],
            period: const FixedPeriod(from: '2026-09-01', to: '2026-09-14')),
        metrics: [dose],
        observations: [
          for (final day in ['01', '02', '03'])
            reading('m1', '2026-09-$day', grams(3)),
          for (final day in ['08', '09'])
            reading('m1', '2026-09-$day', grams(5)),
        ],
        today: '2026-09-14',
      );

      // Week one is 9 g, week two is 10 g, so the typical week is 9.5.
      expect(report.rows.single.weeklyTypical, 9.5);
    });

    test('a rating is not summed within the week', () {
      final mood = marker('m1', 'raspolozenje', MetricKind.scale);
      final report = buildReport(
        definition([const ReportSeries(metricId: 'm1')],
            period: const FixedPeriod(from: '2026-09-01', to: '2026-09-07')),
        metrics: [mood],
        observations: [
          reading('m1', '2026-09-01', scale(4)),
          reading('m1', '2026-09-02', scale(6)),
        ],
        today: '2026-09-07',
      );

      expect(report.rows.single.weeklyTypical, 5);
    });

    test('a period shorter than a week has no typical week', () {
      // A week's authority on four days' evidence.
      final mood = marker('m1', 'raspolozenje', MetricKind.scale);
      final report = buildReport(
        definition([const ReportSeries(metricId: 'm1')],
            period: const LastDays(4)),
        metrics: [mood],
        observations: [reading('m1', '2026-09-07', scale(4))],
        today: '2026-09-07',
      );

      expect(report.rows.single.weeklyTypical, isNull);
    });
  });

  group('re-sorted by cycle day', () {
    final periods = [
      const CyclePeriod(startDayKey: '2026-08-01', endDayKey: '2026-08-05'),
      const CyclePeriod(startDayKey: '2026-08-29', endDayKey: '2026-09-02'),
    ];

    test('the axis becomes cycle days, and cycles stack on each other', () {
      final irritability = marker('m1', 'razdrazljivost', MetricKind.scale);
      final report = buildReport(
        definition(
          [const ReportSeries(metricId: 'm1')],
          period: const FixedPeriod(from: '2026-08-01', to: '2026-09-05'),
          axis: ReportAxis.cycleDay,
        ),
        metrics: [irritability],
        observations: [
          // Cycle day 3 in both cycles: 4 and 8, so the cell is 6.
          reading('m1', '2026-08-03', scale(4)),
          reading('m1', '2026-08-31', scale(8)),
        ],
        cyclePeriods: periods,
        today: '2026-09-05',
      );

      expect(report.labels.first, '1');
      expect(report.rows.single.cells[2].value, 6);
      expect(report.rows.single.cells[2].readingCount, 2);
    });

    test('a cycle day with nothing behind it stays unlogged', () {
      final irritability = marker('m1', 'razdrazljivost', MetricKind.scale);
      final report = buildReport(
        definition(
          [const ReportSeries(metricId: 'm1')],
          period: const FixedPeriod(from: '2026-08-01', to: '2026-09-05'),
          axis: ReportAxis.cycleDay,
        ),
        metrics: [irritability],
        observations: [reading('m1', '2026-08-03', scale(4))],
        cyclePeriods: periods,
        today: '2026-09-05',
      );

      expect(report.rows.single.cells[0].isLogged, isFalse);
      expect(report.rows.single.cells[0].value, isNull);
    });

    test('a dated axis still reports the cycle day of each date', () {
      final mood = marker('m1', 'raspolozenje', MetricKind.scale);
      final report = buildReport(
        definition([const ReportSeries(metricId: 'm1')],
            period: const FixedPeriod(from: '2026-08-01', to: '2026-08-03')),
        metrics: [mood],
        observations: const [],
        cyclePeriods: periods,
        today: '2026-08-03',
      );

      expect(report.cycleDays, [1, 2, 3]);
    });

    test('an unanchored stretch has no cycle day rather than a guess', () {
      final mood = marker('m1', 'raspolozenje', MetricKind.scale);
      final report = buildReport(
        definition([const ReportSeries(metricId: 'm1')],
            period: const FixedPeriod(from: '2026-07-01', to: '2026-07-02')),
        metrics: [mood],
        observations: const [],
        cyclePeriods: periods,
        today: '2026-09-05',
      );

      expect(report.cycleDays, [null, null]);
    });
  });

  test('the facts on a row are counts and ranges, never a grade', () {
    final mood = marker('m1', 'raspolozenje', MetricKind.scale);
    final report = buildReport(
      definition([const ReportSeries(metricId: 'm1')]),
      metrics: [mood],
      observations: [
        reading('m1', '2026-09-05', scale(3)),
        reading('m1', '2026-09-06', scale(7)),
      ],
      today: '2026-09-07',
    );

    final stats = report.rows.single.stats;
    expect(stats.typical, 5);
    expect(stats.lowest, 3);
    expect(stats.highest, 7);
    expect(stats.daysLogged, 2);
    expect(stats.daysInPeriod, 7);
    // Coverage travels with every number derived from it: a typical over two
    // days of seven is a different statement from one over seven.
    expect(stats.coverage, closeTo(2 / 7, 0.001));
  });
}
