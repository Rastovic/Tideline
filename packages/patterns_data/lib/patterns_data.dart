/// Patterns' storage: the drift schema and the repositories over it.
///
/// The engine in `patterns_core` knows nothing about this package, which is
/// what keeps it testable on the Dart VM. Everything here is the boring half:
/// rows in, domain objects out, and no maths.
library;

export 'src/backup.dart';
export 'src/database.dart';
export 'src/metric_repository.dart';
export 'src/observation_repository.dart';
export 'src/photo_repository.dart';
export 'src/tables.dart';
