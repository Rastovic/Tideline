import 'dart:io';

import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:test/test.dart';

final createdAt = DateTime.utc(2026, 8, 19);

void main() {
  final seeds = seedMetrics(createdAt: createdAt);

  test('every seeded marker is valid by the same rules as a hand-made one', () {
    for (final metric in seeds) {
      expect(
        validateMetric(metric),
        isEmpty,
        reason: 'seed "${metric.name}" would be refused by the editor',
      );
    }
  });

  test('every id is a real uuid, so rows stay portable', () {
    for (final metric in seeds) {
      expect(Ids.isValid(metric.id), isTrue, reason: metric.name);
      for (final option in metric.options) {
        expect(Ids.isValid(option.id), isTrue, reason: option.label);
      }
    }
  });

  test('ids are unique, so a re-seed cannot double a marker', () {
    final ids = seeds.map((m) => m.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every marker has a colour from the palette', () {
    for (final metric in seeds) {
      expect(markerPalette, contains(metric.colorHex), reason: metric.name);
    }
  });

  test('bloating and the urge keep their peak, not their median', () {
    final peaked = seeds.where(
      (m) => m.aggregation == DayAggregation.peak,
    ).map((m) => m.id);
    expect(peaked, containsAll([seedIds['bloating'], seedIds['overeating-urge']]));
  });

  test('the cycle domain holds the two taps and no symptom', () {
    final cycle = seeds.where((m) => m.domain == MetricDomain.cycle);
    expect(cycle.map((m) => m.id), [seedIds['period-start'], seedIds['period-end']]);
  });

  test('mood is one plain scale, not a two-axis pad', () {
    final mood = seeds.firstWhere((m) => m.id == seedIds['mood']);
    expect(mood.kind, MetricKind.scale);
    expect(mood.scaleMin, 1);
    expect(mood.scaleMax, 10);
  });

  group('the app records, it never grades', () {
    test('no marker carries a goal, a target, a streak or a direction', () {
      // These four fields are absent from Metric on purpose, and their absence
      // is load-bearing: a target field is how a tracker for weight, appetite
      // and mood quietly becomes a compliance app. Mechanised so the next
      // reasonable-sounding pull request has to argue with a red test.
      final banned = RegExp(
        r'\b(streak|goalValue|targetValue|dailyGoal|direction)\b',
        caseSensitive: false,
      );
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final trimmed = lines[i].trimLeft();
          if (trimmed.startsWith('//')) continue;
          if (banned.hasMatch(lines[i])) offenders.add('${entity.path}:${i + 1}');
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
