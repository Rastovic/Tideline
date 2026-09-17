/// Cycle maths.
///
/// The module records two things - a period start and a period end - and
/// derives one: **which day of the cycle a given date is**. That derived number
/// is the entire reason the module exists. It is not a calendar feature; it is
/// a second axis, so any report can be re-sorted from *by date* to *by cycle
/// day* and bloating, irritability or appetite can be read against it without
/// being owned by it.
///
/// **Counting yes, predicting never.** There is no function here that estimates
/// a next period, a fertile window or an ovulation day, in this version or any
/// later one, and `cycle_test.dart` asserts that this file does not contain
/// one. A wrong prediction is a consequence this app cannot carry, and the
/// evidence bar for that is a different product.
library;

import 'package:vitals_core/vitals_core.dart';

/// Days after a recorded start beyond which counting stops.
///
/// Past this, the stretch is treated as unanchored and produces no cycle day at
/// all. Counting to day 97 because a start was never logged is a guess dressed
/// as a fact, and the honest answer is "unknown".
const int maxCountedCycleDay = 60;

/// One recorded period: when bleeding started, and when it stopped.
final class CyclePeriod {
  const CyclePeriod({required this.startDayKey, this.endDayKey});

  final String startDayKey;

  /// Null while it is still going, or when the end was never recorded.
  final String? endDayKey;

  /// Days of bleeding, inclusive of both ends. Null when unfinished.
  int? get lengthDays => endDayKey == null
      ? null
      : daysBetween(startDayKey, endDayKey!) + 1;

  @override
  String toString() => 'CyclePeriod($startDayKey - ${endDayKey ?? '...'})';
}

/// Which day of the cycle [dayKey] is, counting the most recent start as day 1.
///
/// Returns null when there is no start on or before that date, or when the last
/// start is further back than [maxCountedCycleDay]. Null means "not known",
/// never zero and never a guess.
int? cycleDayFor(
  String dayKey,
  List<CyclePeriod> periods, {
  int maxDay = maxCountedCycleDay,
}) {
  String? mostRecentStart;
  for (final period in periods) {
    if (period.startDayKey.compareTo(dayKey) > 0) continue;
    if (mostRecentStart == null ||
        period.startDayKey.compareTo(mostRecentStart) > 0) {
      mostRecentStart = period.startDayKey;
    }
  }
  if (mostRecentStart == null) return null;

  final elapsed = daysBetween(mostRecentStart, dayKey);
  if (elapsed < 0) return null;
  final cycleDay = elapsed + 1;
  if (cycleDay > maxDay) return null;
  return cycleDay;
}

/// Length of each completed cycle, start to start.
///
/// Only fully bracketed cycles appear: the current one has no next start yet,
/// so it has no length, and reporting one would mean predicting where it ends.
List<int> cycleLengths(List<CyclePeriod> periods) {
  final starts = [for (final p in periods) p.startDayKey]..sort();
  return [
    for (var i = 1; i < starts.length; i++) daysBetween(starts[i - 1], starts[i]),
  ];
}

/// Where the cycle stands today, as counted facts and nothing else.
///
/// **Every field is something that was recorded.** There is no expected next
/// date, no "late", no window, and no field that could be mistaken for one.
final class CycleStatus {
  const CycleStatus({
    this.day,
    this.lastStart,
    this.bleedingDays,
    this.bleedingNow = false,
    this.recentLengths = const [],
  });

  /// Today's cycle day, or null when there is nothing to count from - no
  /// start recorded, or the last one further back than [maxCountedCycleDay].
  final int? day;

  final String? lastStart;

  /// Days of bleeding in the most recent period: the recorded length once it
  /// has an end, otherwise the days counted so far.
  final int? bleedingDays;

  /// The most recent period has a start and no end yet.
  final bool bleedingNow;

  /// Completed cycle lengths, start to start, most recent last. The current
  /// stretch is never in here: it has no next start, and guessing where it
  /// ends is the one thing this module refuses to do.
  final List<int> recentLengths;

  bool get isAnchored => day != null;
}

/// Reads [periods] as they stand on [today].
CycleStatus cycleStatusOn(
  String today,
  List<CyclePeriod> periods, {
  int maxDay = maxCountedCycleDay,
  int keepLengths = 3,
}) {
  final past = [
    for (final period in periods)
      if (period.startDayKey.compareTo(today) <= 0) period,
  ]..sort((a, b) => a.startDayKey.compareTo(b.startDayKey));
  if (past.isEmpty) return const CycleStatus();

  final last = past.last;
  final ended = last.endDayKey;
  final lengths = cycleLengths(periods);

  return CycleStatus(
    day: cycleDayFor(today, periods, maxDay: maxDay),
    lastStart: last.startDayKey,
    bleedingDays: ended == null
        ? daysBetween(last.startDayKey, today) + 1
        : last.lengthDays,
    bleedingNow: ended == null,
    recentLengths: lengths.length <= keepLengths
        ? lengths
        : lengths.sublist(lengths.length - keepLengths),
  );
}

/// Buckets day keys by their cycle day, for a report sorted by cycle day rather
/// than by date.
///
/// Days that cannot be anchored are dropped rather than bucketed into a
/// catch-all, because a catch-all bucket in a chart looks like data.
Map<int, List<String>> groupByCycleDay(
  Iterable<String> dayKeys,
  List<CyclePeriod> periods, {
  int maxDay = maxCountedCycleDay,
}) {
  final grouped = <int, List<String>>{};
  for (final dayKey in dayKeys) {
    final day = cycleDayFor(dayKey, periods, maxDay: maxDay);
    if (day == null) continue;
    grouped.putIfAbsent(day, () => []).add(dayKey);
  }
  for (final days in grouped.values) {
    days.sort();
  }
  return grouped;
}

/// Builds periods from recorded start and end days.
///
/// An end with no start before it is discarded rather than paired with the next
/// start, and a start with no end stays open. Both are ordinary situations - a
/// forgotten tap is not a data error - and neither is repaired by guessing.
List<CyclePeriod> buildPeriods({
  required Iterable<String> startDayKeys,
  required Iterable<String> endDayKeys,
}) {
  final starts = startDayKeys.toSet().toList()..sort();
  final ends = endDayKeys.toSet().toList()..sort();

  return [
    for (var i = 0; i < starts.length; i++)
      CyclePeriod(
        startDayKey: starts[i],
        endDayKey: _firstEndBetween(
          ends,
          after: starts[i],
          before: i + 1 < starts.length ? starts[i + 1] : null,
        ),
      ),
  ];
}

String? _firstEndBetween(
  List<String> ends, {
  required String after,
  required String? before,
}) {
  for (final end in ends) {
    if (end.compareTo(after) < 0) continue;
    if (before != null && end.compareTo(before) >= 0) return null;
    return end;
  }
  return null;
}
