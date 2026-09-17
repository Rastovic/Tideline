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
  group('where the cycle stands today', () {
    final periods = buildPeriods(
      startDayKeys: const ['2026-07-04', '2026-08-02', '2026-09-01'],
      endDayKeys: const ['2026-07-08', '2026-08-06'],
    );

    test('counts the day, the bleeding so far, and completed cycles', () {
      final status = cycleStatusOn('2026-09-03', periods);
      expect(status.day, 3);
      expect(status.lastStart, '2026-09-01');
      // Still going: counted so far, not a length it does not have yet.
      expect(status.bleedingNow, isTrue);
      expect(status.bleedingDays, 3);
      // 4 July to 2 August is 29, 2 August to 1 September is 30. The current
      // stretch has no next start and is not a length.
      expect(status.recentLengths, [29, 30]);
    });

    test('a finished period reports its recorded length', () {
      final status = cycleStatusOn('2026-08-20', periods);
      expect(status.lastStart, '2026-08-02');
      expect(status.bleedingNow, isFalse);
      expect(status.bleedingDays, 5);
      expect(status.day, 19);
    });

    test('nothing recorded is not anchored, and says so with nulls', () {
      const status = CycleStatus();
      expect(status.isAnchored, isFalse);
      expect(cycleStatusOn('2026-09-03', const []).day, isNull);
    });

    test('a start too far back stops counting rather than guessing', () {
      final stale = buildPeriods(
        startDayKeys: const ['2026-01-01'],
        endDayKeys: const ['2026-01-05'],
      );
      final status = cycleStatusOn('2026-09-03', stale);
      expect(status.isAnchored, isFalse);
      // The facts it does have are still reported.
      expect(status.lastStart, '2026-01-01');
      expect(status.bleedingDays, 5);
    });

    test('a start recorded for a future day is not today\'s anchor', () {
      final status = cycleStatusOn('2026-08-30', periods);
      expect(status.lastStart, '2026-08-02');
    });
  });
}
