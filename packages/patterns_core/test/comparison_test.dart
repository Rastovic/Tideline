import 'dart:io';

import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:test/test.dart';

final createdAt = DateTime.utc(2026, 8, 1);

Metric marker(String id, MetricKind kind, {List<MetricOption>? options}) =>
    Metric.create(
      id: id,
      name: id,
      domain: MetricDomain.body,
      kind: kind,
      createdAt: createdAt,
    ).copyWith(options: options);

var _n = 0;
Observation reading(String metricId, String dayKey, MetricValue value) =>
    Observation(
      id: 'o${_n++}',
      metricId: metricId,
      dayKey: dayKey,
      recordedAt: DateTime.parse('${dayKey}T18:00:00Z'),
      utcOffsetMinutes: 0,
      value: value,
    );

MetricValue scale(int n) => NumberValue(n, kind: MetricKind.scale);

void main() {
  final creatine = marker('creatine', MetricKind.boolean);
  final bloating = marker('bloating', MetricKind.scale);

  test('a yes/no condition splits the days, with a count on each side', () {
    final observations = <Observation>[];
    for (var i = 0; i < 20; i++) {
      final day = addDays('2026-09-01', i);
      final on = i.isEven;
      observations.add(reading('creatine', day, BooleanValue(on)));
      observations.add(reading('bloating', day, scale(on ? 7 : 3)));
    }

    final comparison = buildComparison(
      condition: creatine,
      outcome: bloating,
      observations: observations,
      from: '2026-09-01',
      to: '2026-09-20',
    );

    expect(comparison.pairedDays, 20);
    expect(comparison.buckets.map((b) => b.label), ['yes', 'no']);
    expect(comparison.buckets.first.typical, 7);
    expect(comparison.buckets.first.days, 10);
    expect(comparison.buckets.last.typical, 3);
    expect(comparison.isEmpty, isFalse);
  });

  test('a day missing either marker is not a pair', () {
    final observations = [
      reading('creatine', '2026-09-01', const BooleanValue(true)),
      reading('bloating', '2026-09-01', scale(6)),
      // Bloating alone, creatine alone: neither is a pair.
      reading('bloating', '2026-09-02', scale(9)),
      reading('creatine', '2026-09-03', const BooleanValue(true)),
    ];
    final comparison = buildComparison(
      condition: creatine,
      outcome: bloating,
      observations: observations,
      from: '2026-09-01',
      to: '2026-09-10',
    );
    expect(comparison.pairedDays, 1);
    expect(comparison.buckets.single.typical, 6);
    // One group is not a comparison.
    expect(comparison.isEmpty, isTrue);
  });

  test('the next-day pairing reads the day after the condition', () {
    final sleep = marker('short night', MetricKind.boolean);
    final mood = marker('mood', MetricKind.scale);
    final observations = <Observation>[];
    for (var i = 0; i < 12; i++) {
      final day = addDays('2026-09-01', i);
      final badNight = i % 3 == 0;
      observations.add(reading('short night', day, BooleanValue(badNight)));
      // The mood dip lands on the following day, not the same one.
      observations.add(reading('mood', day, scale(i % 3 == 1 ? 3 : 8)));
    }

    final sameDay = buildComparison(
      condition: sleep,
      outcome: mood,
      observations: observations,
      from: '2026-09-01',
      to: '2026-09-12',
    );
    final nextDay = buildComparison(
      condition: sleep,
      outcome: mood,
      observations: observations,
      from: '2026-09-01',
      to: '2026-09-12',
      pairing: ComparePairing.nextDay,
    );

    expect(sameDay.buckets.firstWhere((b) => b.label == 'yes').typical, 8);
    expect(nextDay.buckets.firstWhere((b) => b.label == 'yes').typical, 3);
  });

  test('a number condition is split into its own thirds, middle dropped', () {
    final dose = marker('dose', MetricKind.amount);
    final observations = <Observation>[];
    for (var i = 0; i < 9; i++) {
      final day = addDays('2026-09-01', i);
      observations
          .add(reading('dose', day, NumberValue(i + 1, kind: MetricKind.amount)));
      observations.add(reading('bloating', day, scale(i + 1)));
    }

    final comparison = buildComparison(
      condition: dose,
      outcome: bloating,
      observations: observations,
      from: '2026-09-01',
      to: '2026-09-10',
    );

    expect(comparison.buckets.map((b) => b.label), ['high', 'low']);
    // Highest third against lowest third, and the middle is in neither.
    expect(comparison.buckets.first.typical, greaterThan(6));
    expect(comparison.buckets.last.typical, lessThan(4));
    expect(
      comparison.buckets.fold<int>(0, (sum, b) => sum + b.days),
      lessThan(comparison.pairedDays),
    );
  });

  test('tags become one group per option, most used first', () {
    final feelings = marker('feelings', MetricKind.tags, options: const [
      MetricOption(id: 't1', label: 'sadness'),
      MetricOption(id: 't2', label: 'anxiety'),
    ]);
    final observations = <Observation>[];
    for (var i = 0; i < 10; i++) {
      final day = addDays('2026-09-01', i);
      observations.add(reading(
        'feelings',
        day,
        TagsValue([if (i < 7) 't1', if (i.isEven) 't2']),
      ));
      observations.add(reading('bloating', day, scale(i < 7 ? 6 : 2)));
    }

    final comparison = buildComparison(
      condition: feelings,
      outcome: bloating,
      observations: observations,
      from: '2026-09-01',
      to: '2026-09-12',
    );
    expect(comparison.buckets.first.label, 'sadness');
    expect(comparison.buckets.first.days, 7);
  });

  test('nothing anywhere in the engine claims a cause', () {
    final source = File('lib/src/comparison.dart').readAsStringSync();
    for (final banned in [
      RegExp(r'\bcauses?\b', caseSensitive: false),
      RegExp(r'\bpredict', caseSensitive: false),
      RegExp(r'\bcorrelat', caseSensitive: false),
      RegExp(r'\bp-?value', caseSensitive: false),
    ]) {
      final lines = source
          .split('\n')
          .where((l) => banned.hasMatch(l) && !l.trimLeft().startsWith('///'));
      expect(lines, isEmpty, reason: banned.pattern);
    }
  });
}
