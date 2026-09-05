import 'dart:io';

import 'package:patterns_core/patterns_core.dart';
import 'package:test/test.dart';

void main() {
  group('counting from a recorded start', () {
    final periods = [
      const CyclePeriod(startDayKey: '2026-07-04', endDayKey: '2026-07-08'),
      const CyclePeriod(startDayKey: '2026-08-01', endDayKey: '2026-08-05'),
    ];

    test('the start day is day 1, not day 0', () {
      expect(cycleDayFor('2026-08-01', periods), 1);
    });

    test('counts forward from the most recent start', () {
      expect(cycleDayFor('2026-08-19', periods), 19);
    });

    test('a date before any recorded start has no cycle day', () {
      expect(cycleDayFor('2026-06-30', periods), isNull);
    });

    test('an unanchored stretch produces nothing rather than a guess', () {
      // Nothing was recorded after 1 August, so by November the honest answer
      // is "unknown", not "day 97".
      expect(cycleDayFor('2026-11-05', periods), isNull);
    });

    test('a period length counts both ends', () {
      expect(periods.first.lengthDays, 5);
    });

    test('an unfinished period has no length', () {
      const running = CyclePeriod(startDayKey: '2026-08-01');
      expect(running.lengthDays, isNull);
    });

    test('cycle length is start to start, and only for closed cycles', () {
      expect(cycleLengths(periods), [28]);
    });
  });

  group('building periods from what was tapped', () {
    test('pairs each start with the first end after it', () {
      final periods = buildPeriods(
        startDayKeys: const ['2026-07-04', '2026-08-01'],
        endDayKeys: const ['2026-07-08', '2026-08-05'],
      );
      expect(periods, hasLength(2));
      expect(periods.first.endDayKey, '2026-07-08');
      expect(periods.last.endDayKey, '2026-08-05');
    });

    test('a forgotten end leaves that period open instead of borrowing one',
        () {
      final periods = buildPeriods(
        startDayKeys: const ['2026-07-04', '2026-08-01'],
        endDayKeys: const ['2026-08-05'],
      );
      expect(periods.first.endDayKey, isNull);
      expect(periods.last.endDayKey, '2026-08-05');
    });

    test('an end with no start before it is discarded', () {
      final periods = buildPeriods(
        startDayKeys: const ['2026-08-01'],
        endDayKeys: const ['2026-07-02'],
      );
      expect(periods.single.endDayKey, isNull);
    });
  });

  test('grouping by cycle day drops days that cannot be anchored', () {
    final grouped = groupByCycleDay(
      const ['2026-06-01', '2026-08-01', '2026-08-02', '2026-08-29'],
      const [CyclePeriod(startDayKey: '2026-08-01')],
    );
    expect(grouped[1], ['2026-08-01']);
    expect(grouped[2], ['2026-08-02']);
    expect(grouped[29], ['2026-08-29']);
    expect(grouped.values.expand((d) => d), isNot(contains('2026-06-01')));
  });

  group('the prediction that does not exist', () {
    test('no function in this package estimates a future period', () {
      // Not a style rule. A predicted period, fertile window or ovulation day
      // is a different product with a different evidence bar, and a wrong one
      // is a consequence this app cannot carry. The ban is mechanised here so
      // it survives someone adding "just a small estimate" in two years.
      final banned = RegExp(
        r'\b(predict|forecast|fertile|ovulat|nextPeriod|dueDate)',
        caseSensitive: false,
      );
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final isComment = line.trimLeft().startsWith('//') ||
              line.trimLeft().startsWith('///');
          if (isComment) continue;
          if (banned.hasMatch(line)) offenders.add('${entity.path}:${i + 1}');
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
