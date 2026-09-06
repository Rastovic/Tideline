/// The Patterns engine: markers, readings, and the maths that turns a pile of
/// readings into rows a person can read.
///
/// Pure Dart. No Flutter, no plugins, no storage, no platform - so it runs on
/// the Dart VM in tests and moves to iOS unchanged.
///
/// Three rules hold this package together and none of them is a detail:
///
/// 1. **Every marker is one object.** Seeded and user-invented markers are the
///    same class in the same table. No built-in flag, no privileged path.
/// 2. **No marker owns another.** Readings are independent streams sharing a
///    date axis; connections are made by the user in a report, afterwards.
/// 3. **The app records and displays. It does not conclude.** There is no
///    scoring, no grading, no goal, no streak, and no function anywhere that
///    predicts anything.
library;

export 'src/aggregation.dart';
export 'src/cycle.dart';
export 'src/day_summary.dart';
export 'src/display.dart';
export 'src/metric.dart';
export 'src/metric_change.dart';
export 'src/metric_kind.dart';
export 'src/metric_value.dart';
export 'src/observation.dart';
export 'src/seed.dart';
export 'src/validation.dart';
export 'src/wire.dart';
