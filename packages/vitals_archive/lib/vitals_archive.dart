/// Backup export and restore, shared by every Vitals app.
///
/// Implements `00-foundation/DATA-PORTABILITY.md`. Two things live here that
/// are impossible to retrofit once real users hold real history:
///
/// - [PortableTable], the four columns that make a row mergeable: a UUID id,
///   `updatedAt`, a `deletedAt` tombstone, and the `installId` that wrote it
/// - the archive format, which is deliberately also the wire format a future
///   `POST /sync` would take, so growing a backend is an endpoint rather than
///   a rewrite
///
/// The SAF document-picker wrappers are **not** here. They need Flutter, and
/// keeping this package pure Dart means the whole read path, the conflict rule
/// and the import preview are testable without a device.
library;

export 'src/archive_io.dart';
export 'src/import_plan.dart';
export 'src/manifest.dart';
export 'src/ndjson.dart';
export 'src/portable.dart';
