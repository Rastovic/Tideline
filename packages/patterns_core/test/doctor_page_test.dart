import 'package:patterns_core/patterns_core.dart';
import 'package:test/test.dart';

final createdAt = DateTime.utc(2026, 8, 1, 9);

Metric marker(String id, MetricKind kind, {List<MetricOption>? options}) {
  final made = Metric.create(
    id: id,
    name: id,
    domain: MetricDomain.body,
    kind: kind,
    createdAt: createdAt,
  );
  return options == null ? made : made.copyWith(options: options);
}

var _n = 0;
Observation reading(String metricId, String dayKey, MetricValue value) =>
    Observation(
      id: 'o${_n++}',
      metricId: metricId,
      dayKey: dayKey,
      recordedAt: DateTime.utc(2026, 9, 1, 12),
      utcOffsetMinutes: 120,
      value: value,
    );

void main() {
  const from = '2026-09-01';
  const to = '2026-09-10';

  test('a rating gets its range with the dates of both ends', () {
    final mood = marker('mood', MetricKind.scale);
    final page = buildDoctorPage(
      metrics: [mood],
      observations: [
        reading('mood', '2026-09-02', const NumberValue(3, kind: MetricKind.scale)),
        reading('mood', '2026-09-05', const NumberValue(8, kind: MetricKind.scale)),
        reading('mood', '2026-09-07', const NumberValue(8, kind: MetricKind.scale)),
      ],
      from: from,
      to: to,
    );

    final entry = page.entries.single;
    expect(entry.days, hasLength(10));
    expect(entry.lowest, (value: 3, dayKey: '2026-09-02'));
    // The first day it happened, so the printed date does not move later.
    expect(entry.highest, (value: 8, dayKey: '2026-09-05'));
    expect(entry.stats.daysLogged, 3);
    expect(entry.bounds, (1, 10));
    expect(page.daysWithAnyEntry, 3);
    expect(page.daysInPeriod, 10);
  });

  test('a yes/no marker counts yes days out of answered days', () {
    final creatine = marker('kreatin', MetricKind.boolean);
    final page = buildDoctorPage(
      metrics: [creatine],
      observations: [
        reading('kreatin', '2026-09-01', const BooleanValue(true)),
        reading('kreatin', '2026-09-02', const BooleanValue(false)),
        reading('kreatin', '2026-09-03', const BooleanValue(true)),
      ],
      from: from,
      to: to,
    );
    final entry = page.entries.single;
    expect(entry.daysOn, 2);
    expect(entry.stats.daysLogged, 3);
    expect(entry.highest, isNull);
  });

  test('tags are counted in days, most frequent first, none kept apart', () {
    final feelings = marker('osjecanja', MetricKind.tags, options: const [
      MetricOption(id: 't1', label: 'tuga'),
      MetricOption(id: 't2', label: 'anksioznost'),
    ]);
    final page = buildDoctorPage(
      metrics: [feelings],
      observations: [
        reading('osjecanja', '2026-09-01', TagsValue(const ['t1'])),
        reading('osjecanja', '2026-09-02', TagsValue(const ['t1', 't2'])),
        reading('osjecanja', '2026-09-03', TagsValue(const ['t1'])),
        reading('osjecanja', '2026-09-04', TagsValue(const [])),
      ],
      from: from,
      to: to,
    );
    final entry = page.entries.single;
    expect(entry.optionCounts, [
      (label: 'tuga', days: 3),
      (label: 'anksioznost', days: 1),
    ]);
    expect(entry.explicitNoneDays, 1);
  });

  test('a bedtime is averaged on the clock, not on the number line', () {
    final bed = marker('lijeganje', MetricKind.timeOfDay);
    final page = buildDoctorPage(
      metrics: [bed],
      observations: [
        reading('lijeganje', '2026-09-01', const TimeOfDayValue(23 * 60 + 40)),
        reading('lijeganje', '2026-09-02', const TimeOfDayValue(20)),
      ],
      from: from,
      to: to,
    );
    expect(page.entries.single.typicalMinute, 0);
  });

  test('a diary never reaches the page, private or not', () {
    final diary = marker('dnevnik', MetricKind.text);
    final photo = marker('foto', MetricKind.photo);
    final mood = marker('mood', MetricKind.scale);
    final page = buildDoctorPage(
      metrics: [diary, photo, mood],
      observations: [
        reading('dnevnik', '2026-09-01', const TextValue('javno')),
        reading('dnevnik', '2026-09-02',
            const TextValue('tajno', isPrivate: true)),
      ],
      from: from,
      to: to,
    );
    expect(page.entries.map((e) => e.metric.id), ['mood']);
    // Coverage counts only what is printed.
    expect(page.daysWithAnyEntry, 0);
  });

  test('one page holds eight markers, in the order given', () {
    final markers = [
      for (var i = 0; i < 11; i++) marker('m$i', MetricKind.scale),
    ];
    final page = buildDoctorPage(
      metrics: markers,
      observations: const [],
      from: from,
      to: to,
    );
    expect(page.entries.map((e) => e.metric.id),
        [for (var i = 0; i < doctorPageMaxMarkers; i++) 'm$i']);
  });

  test('period starts are dates inside the stretch, and nothing predicted',
      () {
    final page = buildDoctorPage(
      metrics: const [],
      observations: const [],
      from: from,
      to: to,
      cyclePeriods: const [
        CyclePeriod(startDayKey: '2026-08-05', endDayKey: '2026-08-09'),
        CyclePeriod(startDayKey: '2026-09-03'),
      ],
    );
    expect(page.periodStarts, ['2026-09-03']);
  });
}
