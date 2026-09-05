import 'package:test/test.dart';
import 'package:vitals_core/vitals_core.dart';

void main() {
  group('dayKeyFor', () {
    test('uses the local date, not the UTC date', () {
      // 23:30 UTC is already the next day in Dublin summer time (+60).
      final instant = DateTime.utc(2026, 8, 10, 23, 30);
      expect(dayKeyFor(instant, offsetMinutes: 60), '2026-08-11');
      expect(dayKeyFor(instant, offsetMinutes: 0), '2026-08-10');
    });

    test('a 4am boundary puts 02:30 on the previous day', () {
      final lateNight = DateTime.utc(2026, 8, 11, 2, 30);
      expect(
        dayKeyFor(lateNight, offsetMinutes: 0, dayBoundaryHour: 4),
        '2026-08-10',
      );
    });

    test('a 4am boundary opens the new day at exactly 04:00', () {
      final justBefore = DateTime.utc(2026, 8, 11, 3, 59);
      final justAfter = DateTime.utc(2026, 8, 11, 4, 0);
      expect(
        dayKeyFor(justBefore, offsetMinutes: 0, dayBoundaryHour: 4),
        '2026-08-10',
      );
      expect(
        dayKeyFor(justAfter, offsetMinutes: 0, dayBoundaryHour: 4),
        '2026-08-11',
      );
    });

    test('a negative offset can pull the key back a day', () {
      // 00:30 UTC is still the previous evening in Los Angeles (-420).
      final instant = DateTime.utc(2026, 8, 11, 0, 30);
      expect(dayKeyFor(instant, offsetMinutes: -420), '2026-08-10');
    });

    test('rejects an out-of-range boundary hour', () {
      final instant = DateTime.utc(2026, 8, 11);
      expect(
        () => dayKeyFor(instant, offsetMinutes: 0, dayBoundaryHour: 24),
        throwsArgumentError,
      );
    });

    test('a key frozen in one timezone does not change in another', () {
      // The portability rule that matters: write in Dublin, read in Tokyo.
      final sessionEnd = DateTime.utc(2026, 3, 14, 21, 0);
      final writtenInDublin = dayKeyFor(sessionEnd, offsetMinutes: 0);
      final readInTokyo = writtenInDublin; // frozen at write time, never redone
      expect(readInTokyo, '2026-03-14');
      // Deriving it again on the new device would have produced a different day.
      expect(dayKeyFor(sessionEnd, offsetMinutes: 540), '2026-03-15');
    });
  });

  group('parseDayKey', () {
    test('round-trips a valid key', () {
      final date = parseDayKey('2026-08-11')!;
      expect(formatDayKey(date.year, date.month, date.day), '2026-08-11');
    });

    test('returns null for malformed input rather than throwing', () {
      for (final bad in ['', 'today', '2026-8-11', '20260811', '2026-08-11T00']) {
        expect(parseDayKey(bad), isNull, reason: bad);
      }
    });

    test('rejects a date that does not exist', () {
      expect(parseDayKey('2026-02-30'), isNull);
      expect(parseDayKey('2026-13-01'), isNull);
    });

    test('accepts a real leap day', () {
      expect(parseDayKey('2028-02-29'), isNotNull);
    });
  });

  group('addDays and daysBetween', () {
    test('crosses a month boundary', () {
      expect(addDays('2026-08-31', 1), '2026-09-01');
      expect(addDays('2026-09-01', -1), '2026-08-31');
    });

    test('crosses a year boundary', () {
      expect(addDays('2026-12-31', 1), '2027-01-01');
    });

    test('crosses a leap day', () {
      expect(addDays('2028-02-28', 1), '2028-02-29');
      expect(addDays('2029-02-28', 1), '2029-03-01');
    });

    test('stays correct across a DST change', () {
      // Late March in Europe: the local day is 23 hours long. Calendar
      // arithmetic must not lose or gain a day the way duration maths would.
      expect(addDays('2026-03-28', 1), '2026-03-29');
      expect(daysBetween('2026-03-28', '2026-03-30'), 2);
    });

    test('daysBetween is signed', () {
      expect(daysBetween('2026-08-10', '2026-08-11'), 1);
      expect(daysBetween('2026-08-11', '2026-08-10'), -1);
      expect(daysBetween('2026-08-10', '2026-08-10'), 0);
    });
  });

  group('dayKeyRange', () {
    test('is inclusive at both ends', () {
      expect(dayKeyRange('2026-08-10', '2026-08-12'), [
        '2026-08-10',
        '2026-08-11',
        '2026-08-12',
      ]);
    });

    test('a single day yields one key', () {
      expect(dayKeyRange('2026-08-10', '2026-08-10'), ['2026-08-10']);
    });

    test('a reversed range yields nothing rather than looping', () {
      expect(dayKeyRange('2026-08-12', '2026-08-10'), isEmpty);
    });

    test('a full non-leap year is 365 days', () {
      expect(dayKeyRange('2026-01-01', '2026-12-31').length, 365);
    });

    test('a full leap year is 366 days', () {
      expect(dayKeyRange('2028-01-01', '2028-12-31').length, 366);
    });
  });
}
