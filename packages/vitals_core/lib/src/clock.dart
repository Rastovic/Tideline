/// A source of "now".
///
/// Nothing in any app may call [DateTime.now] directly. Every time-dependent
/// path takes a [Clock], so tests can drive a day boundary, a DST change or a
/// six-month history without waiting for one.
abstract interface class Clock {
  /// The current instant, always in UTC.
  DateTime nowUtc();

  /// The device's current offset from UTC, in minutes.
  ///
  /// Stored alongside timestamps so a statement written in Dublin still reads
  /// as the same day after the user lands in Tokyo.
  int offsetMinutes();
}

/// The real clock. The only implementation that ships in a release build.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  int offsetMinutes() => DateTime.now().timeZoneOffset.inMinutes;
}

/// A clock the test drives by hand.
final class FakeClock implements Clock {
  FakeClock(DateTime start, {int offsetMinutes = 0})
      : _now = start.toUtc(),
        _offsetMinutes = offsetMinutes;

  DateTime _now;
  int _offsetMinutes;

  @override
  DateTime nowUtc() => _now;

  @override
  int offsetMinutes() => _offsetMinutes;

  /// Moves time forward. Negative durations are rejected: a clock that can run
  /// backwards hides ordering bugs instead of surfacing them.
  void advance(Duration by) {
    if (by.isNegative) {
      throw ArgumentError.value(by, 'by', 'Cannot advance a clock backwards');
    }
    _now = _now.add(by);
  }

  /// Jumps to an instant, which may be backwards. Use only to model a user
  /// changing the device date, and assert the app copes.
  void setTo(DateTime instant) => _now = instant.toUtc();

  /// Models a flight: changes the offset without moving the instant.
  void setOffsetMinutes(int minutes) => _offsetMinutes = minutes;
}
