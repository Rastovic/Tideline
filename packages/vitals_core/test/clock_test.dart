import 'package:test/test.dart';
import 'package:vitals_core/vitals_core.dart';

void main() {
  group('FakeClock', () {
    test('starts where it was seeded, normalised to UTC', () {
      final clock = FakeClock(DateTime.utc(2026, 8, 11, 9));
      expect(clock.nowUtc(), DateTime.utc(2026, 8, 11, 9));
      expect(clock.nowUtc().isUtc, isTrue);
    });

    test('advances', () {
      final clock = FakeClock(DateTime.utc(2026, 8, 11, 9));
      clock.advance(const Duration(hours: 2, minutes: 30));
      expect(clock.nowUtc(), DateTime.utc(2026, 8, 11, 11, 30));
    });

    test('refuses to advance backwards', () {
      final clock = FakeClock(DateTime.utc(2026, 8, 11));
      expect(
        () => clock.advance(const Duration(minutes: -1)),
        throwsArgumentError,
      );
    });

    test('setTo models the user moving the device date backwards', () {
      final clock = FakeClock(DateTime.utc(2026, 8, 11));
      clock.setTo(DateTime.utc(2026, 8, 4));
      expect(clock.nowUtc(), DateTime.utc(2026, 8, 4));
    });

    test('setOffsetMinutes models a flight without moving the instant', () {
      final clock = FakeClock(DateTime.utc(2026, 8, 11, 12), offsetMinutes: 60);
      final before = clock.nowUtc();
      clock.setOffsetMinutes(540);
      expect(clock.nowUtc(), before);
      expect(clock.offsetMinutes(), 540);
    });

    test('drives a day boundary crossing', () {
      final clock = FakeClock(
        DateTime.utc(2026, 8, 11, 3, 59),
        offsetMinutes: 0,
      );
      String key() => dayKeyFor(
            clock.nowUtc(),
            offsetMinutes: clock.offsetMinutes(),
            dayBoundaryHour: 4,
          );

      expect(key(), '2026-08-10');
      clock.advance(const Duration(minutes: 1));
      expect(key(), '2026-08-11');
    });
  });

  group('SystemClock', () {
    test('reports UTC', () {
      expect(const SystemClock().nowUtc().isUtc, isTrue);
    });

    test('reports the device offset', () {
      expect(
        const SystemClock().offsetMinutes(),
        DateTime.now().timeZoneOffset.inMinutes,
      );
    });
  });
}
