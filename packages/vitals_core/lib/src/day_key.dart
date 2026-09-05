/// Day-key maths.
///
/// Rule 5 of `00-foundation/DATA-PORTABILITY.md`: a day key is frozen at write
/// time and never derived at read time. A user who flies to Tokyo must not see
/// last March's statement change, and a day boundary of 04:00 means a session
/// finished at 02:30 belongs to the day before.
library;

/// The local calendar day an instant belongs to, as `YYYY-MM-DD`.
///
/// [utcInstant] is the moment. [offsetMinutes] is the device's offset from UTC
/// at that moment. [dayBoundaryHour] is the local hour a new day starts, so 4
/// means 03:59 closes yesterday and 04:00 opens today.
String dayKeyFor(
  DateTime utcInstant, {
  required int offsetMinutes,
  int dayBoundaryHour = 0,
}) {
  if (dayBoundaryHour < 0 || dayBoundaryHour > 23) {
    throw ArgumentError.value(
      dayBoundaryHour,
      'dayBoundaryHour',
      'Must be 0-23',
    );
  }
  final local = utcInstant.toUtc().add(Duration(minutes: offsetMinutes));
  final shifted = local.subtract(Duration(hours: dayBoundaryHour));
  return formatDayKey(shifted.year, shifted.month, shifted.day);
}

/// Formats a calendar date as `YYYY-MM-DD`. Zero-padded, never locale-aware.
String formatDayKey(int year, int month, int day) {
  final y = year.toString().padLeft(4, '0');
  final m = month.toString().padLeft(2, '0');
  final d = day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Parses a `YYYY-MM-DD` key into a **UTC** midnight date.
///
/// UTC is not incidental. A day key is a calendar label, not an instant, so all
/// arithmetic on it must happen in a timezone with no DST: in a local zone,
/// 28 to 30 March is 47 hours and `difference().inDays` answers 1.
///
/// Returns null rather than throwing, because keys can arrive from an imported
/// archive written by a future version and a bad row must cost one row.
DateTime? parseDayKey(String key) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime.utc(year, month, day);
  // Rejects 2026-02-30, which DateTime would silently roll into March.
  if (date.month != month || date.day != day) return null;
  return date;
}

/// The day key [days] after [key]. Negative values step backwards.
///
/// Calendar arithmetic in UTC, so it stays correct across a DST change where
/// the equivalent local day is 23 or 25 hours long.
String addDays(String key, int days) {
  final date = parseDayKey(key);
  if (date == null) {
    throw ArgumentError.value(key, 'key', 'Not a YYYY-MM-DD day key');
  }
  final moved = DateTime.utc(date.year, date.month, date.day + days);
  return formatDayKey(moved.year, moved.month, moved.day);
}

/// Whole days from [from] to [to]. Negative when [to] is earlier.
int daysBetween(String from, String to) {
  final a = parseDayKey(from);
  final b = parseDayKey(to);
  if (a == null) throw ArgumentError.value(from, 'from', 'Not a day key');
  if (b == null) throw ArgumentError.value(to, 'to', 'Not a day key');
  return b.difference(a).inDays;
}

/// Every day key from [from] to [to] inclusive, ascending.
///
/// The statement layer walks this rather than scanning raw events, so a day
/// with nothing logged still appears as a zero row instead of a gap.
List<String> dayKeyRange(String from, String to) {
  final span = daysBetween(from, to);
  if (span < 0) return const [];
  return [for (var i = 0; i <= span; i++) addDays(from, i)];
}
