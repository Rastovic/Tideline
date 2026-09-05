/// Shared primitives for every app in the Vitals portfolio.
///
/// Deliberately free of Flutter and of any plugin, so domain engines that
/// depend on it stay testable on the Dart VM and portable to iOS unchanged.
library;

export 'src/clock.dart';
export 'src/day_key.dart';
export 'src/ids.dart';
export 'src/result.dart';
