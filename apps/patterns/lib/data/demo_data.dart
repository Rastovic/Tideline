import 'dart:math';

import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';

/// One made-up reading for the demo profile.
typedef DemoReading = ({
  String metricId,
  MetricValue value,
  String dayKey,
  int minuteOfDay,
  String? note,
});

/// Invents a plausible few months for the demo profile, so reports have
/// something to show before months of real logging exist.
///
/// **Only ever written into its own profile**, which the person deletes when
/// done looking. It is deterministic for a given [seed], so the demo looks the
/// same every time it is made and a screenshot can be compared to another.
///
/// The patterns are deliberate and easy to spot, because the point is to show
/// what a report can reveal: lower mood on Sundays (a stripe in the grid),
/// bloating and irritability late in the cycle (a hump on the cycle axis),
/// better mood on training days (a band that lines up), and creatine starting
/// part-way through (a band that begins). Markers missing from [markers] are
/// skipped, so the compact demo set gets only its own share of these.
List<DemoReading> demoReadings({
  required List<Metric> markers,
  required String today,
  required String? periodStartId,
  required String? periodEndId,
  int days = 120,
  int seed = 7,
}) {
  final random = Random(seed);
  final byName = {for (final m in markers) m.name: m};
  Metric? m(String name) => byName[name];
  String? option(Metric? metric, String label) {
    for (final o in metric?.options ?? const <MetricOption>[]) {
      if (o.label == label) return o.id;
    }
    return null;
  }

  double noise(double spread) => (random.nextDouble() * 2 - 1) * spread;
  int clamp10(double v) => v.round().clamp(1, 10);

  final readings = <DemoReading>[];
  void add(
    Metric? metric,
    MetricValue value,
    String day,
    int minute, [
    String? note,
  ]) {
    if (metric == null) return;
    readings.add((
      metricId: metric.id,
      value: value,
      dayKey: day,
      minuteOfDay: minute,
      note: note,
    ));
  }

  final start = addDays(today, -(days - 1));

  // The cycle: a start every 27-31 days, bleeding for 4-6 days.
  final cycleStarts = <String>[];
  var next = addDays(start, 3);
  while (next.compareTo(today) <= 0) {
    cycleStarts.add(next);
    next = addDays(next, 27 + random.nextInt(5));
  }
  int? cycleDayOf(String day) {
    String? last;
    for (final s in cycleStarts) {
      if (s.compareTo(day) <= 0) last = s;
    }
    return last == null ? null : daysBetween(last, day) + 1;
  }

  for (final s in cycleStarts) {
    if (periodStartId != null) {
      readings.add((
        metricId: periodStartId,
        value: const BooleanValue(true),
        dayKey: s,
        minuteOfDay: 8 * 60,
        note: null,
      ));
    }
    final end = addDays(s, 3 + random.nextInt(3));
    if (periodEndId != null && end.compareTo(today) <= 0) {
      readings.add((
        metricId: periodEndId,
        value: const BooleanValue(true),
        dayKey: end,
        minuteOfDay: 21 * 60,
        note: null,
      ));
    }
  }

  const diaryLines = [
    'Long day at work, but the walk home helped.',
    'Slept badly, everything felt heavier.',
    'Good talk with a friend tonight.',
    'Too much screen time, restless.',
    'Quiet Sunday, a bit flat.',
    'Productive morning, tired afternoon.',
    'Headache most of the day.',
  ];
  const notes = [
    'after the pizza',
    'late dinner',
    'busy day',
    'after a long walk',
    'stressful meeting',
  ];

  final creatineFrom = addDays(start, 40);

  for (var i = 0; i < days; i++) {
    final day = addDays(start, i);
    // An unlogged day now and then, because real records have gaps and the
    // reports are built to show them honestly.
    if (random.nextDouble() < 0.08) continue;

    final weekday = parseDayKey(day)!.weekday;
    final cycleDay = cycleDayOf(day);
    final late = cycleDay != null && cycleDay >= 23;
    final sunday = weekday == DateTime.sunday;

    final trains =
        (weekday == DateTime.monday ||
            weekday == DateTime.wednesday ||
            weekday == DateTime.friday) &&
        random.nextDouble() < 0.82;

    final bed = 22 * 60 + 50 + noise(55).round() + (weekday >= 5 ? 35 : 0);
    final sleptBadly = bed > 23 * 60 + 40;

    final mood = clamp10(
      6.6 +
          noise(1.2) +
          (trains ? 0.9 : 0) -
          (sunday ? 1.6 : 0) -
          (late ? 1.3 : 0) -
          (sleptBadly ? 0.8 : 0),
    );
    add(m('mood'), NumberValue(mood, kind: MetricKind.scale), day, 21 * 60);

    add(
      m('tiredness'),
      NumberValue(
        clamp10(6.2 + noise(1.3) - (sleptBadly ? 2 : 0)),
        kind: MetricKind.scale,
      ),
      day,
      21 * 60 + 2,
      sleptBadly && random.nextDouble() < 0.3 ? 'went to bed late' : null,
    );
    add(
      m('motivation'),
      NumberValue(clamp10(mood + noise(1.2)), kind: MetricKind.scale),
      day,
      21 * 60 + 3,
    );
    add(
      m('irritability'),
      NumberValue(
        clamp10(3.2 + noise(1.2) + (late ? 3.2 : 0)),
        kind: MetricKind.scale,
      ),
      day,
      21 * 60 + 4,
    );

    final feelings = m('feelings');
    final picked = <String>[
      if (mood <= 4) ?option(feelings, 'sadness'),
      if (random.nextDouble() < 0.18) ?option(feelings, 'anxiety'),
      if (random.nextDouble() < 0.22) ?option(feelings, 'overthinking'),
      if (late && random.nextDouble() < 0.4) ?option(feelings, 'overwhelm'),
    ];
    add(feelings, TagsValue(picked), day, 21 * 60 + 5);

    final context = m('context');
    add(
      context,
      TagsValue([
        if (weekday <= 5 && random.nextDouble() < 0.6) ?option(context, 'work'),
        if (sleptBadly) ?option(context, 'bad sleep'),
        if (random.nextDouble() < 0.07) ?option(context, 'conflict'),
      ]),
      day,
      21 * 60 + 6,
    );

    if (random.nextDouble() < 0.3) {
      add(
        m('diary'),
        TextValue(diaryLines[random.nextInt(diaryLines.length)]),
        day,
        22 * 60,
      );
    }

    final onCreatine =
        day.compareTo(creatineFrom) >= 0 && random.nextDouble() < 0.88;
    if (day.compareTo(creatineFrom) >= 0) {
      add(m('creatine'), BooleanValue(onCreatine), day, 9 * 60);
      if (onCreatine) {
        add(
          m('creatine dose'),
          NumberValue(3 + random.nextInt(3), kind: MetricKind.amount),
          day,
          9 * 60 + 1,
        );
      }
    }

    final bloating = clamp10(
      2.4 +
          noise(1.1) +
          (late ? 3.6 : 0) +
          (cycleDay != null && cycleDay <= 2 ? 2 : 0) +
          (onCreatine ? 0.6 : 0),
    );
    add(
      m('bloating'),
      NumberValue(bloating, kind: MetricKind.scale),
      day,
      20 * 60,
      bloating >= 7 && random.nextDouble() < 0.5
          ? notes[random.nextInt(notes.length)]
          : null,
    );

    add(m('training'), BooleanValue(trains), day, 19 * 60);
    if (trains) {
      add(
        m('training quality'),
        NumberValue(
          clamp10(6.8 + noise(1.5) - (late ? 1 : 0)),
          kind: MetricKind.scale,
        ),
        day,
        19 * 60 + 1,
      );
    }

    add(
      m('appetite'),
      NumberValue(
        clamp10(5.5 + noise(1.2) + (late ? 2 : 0)),
        kind: MetricKind.scale,
      ),
      day,
      20 * 60 + 1,
    );
    add(
      m('urge to overeat'),
      NumberValue(
        clamp10(2.5 + noise(1.3) + (late ? 3 : 0) + (sunday ? 1 : 0)),
        kind: MetricKind.scale,
      ),
      day,
      20 * 60 + 2,
    );

    add(m('bedtime'), TimeOfDayValue(bed % 1440), day, 21 * 60 + 10);
    add(
      m('wake-up'),
      TimeOfDayValue(
        (6 * 60 + 55 + noise(30).round() + (weekday >= 6 ? 60 : 0)).clamp(
          0,
          1439,
        ),
      ),
      day,
      9 * 60 + 2,
    );
  }

  return readings;
}
