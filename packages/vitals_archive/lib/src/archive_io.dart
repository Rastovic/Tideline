import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'manifest.dart';
import 'ndjson.dart';

/// Builds the backup zip.
///
/// Layout, fixed:
/// ```
/// manifest.json
/// data/<table>.ndjson
/// media/...            relative paths only
/// CHECKSUMS.txt        sha256 per file
/// ```
final class ArchiveWriter {
  ArchiveWriter({required this.manifest});

  final ArchiveManifest manifest;

  final _files = <String, List<int>>{};

  /// Adds one table.
  void addTable(String table, Iterable<Map<String, Object?>> rows) {
    _files['data/$table.ndjson'] = utf8.encode(Ndjson.encode(rows));
  }

  /// Adds a media file. [relativePath] is relative to `media/`.
  ///
  /// **Relative only.** An absolute path from the old phone is a guaranteed
  /// broken image on the new one, and it fails silently.
  void addMedia(String relativePath, List<int> bytes) {
    if (relativePath.startsWith('/') || relativePath.contains('..')) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Media paths must be relative and must not escape media/',
      );
    }
    _files['media/$relativePath'] = bytes;
  }

  /// Serialises the zip.
  ///
  /// Checksums are computed over exactly the bytes written, so a tampered or
  /// truncated file is caught on import rather than half-loaded.
  Uint8List build() {
    final archive = Archive();
    final manifestBytes = utf8.encode(manifest.toJson());
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    final checksums = StringBuffer();
    final names = _files.keys.toList()..sort();
    for (final name in names) {
      final bytes = _files[name]!;
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
      checksums.writeln('${sha256.convert(bytes)}  $name');
    }
    checksums.writeln('${sha256.convert(manifestBytes)}  manifest.json');

    final checksumBytes = utf8.encode(checksums.toString());
    archive.addFile(
      ArchiveFile('CHECKSUMS.txt', checksumBytes.length, checksumBytes),
    );

    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }
}

/// What a successfully-read archive contains.
final class ArchiveContents {
  const ArchiveContents({
    required this.manifest,
    required this.tables,
    required this.mediaPaths,
    Map<String, List<int>> media = const {},
  }) : _media = media;

  final ArchiveManifest manifest;
  final Map<String, TableRows> tables;
  final List<String> mediaPaths;

  /// Media bytes, keyed by the same relative path [mediaPaths] lists.
  ///
  /// Held rather than streamed because an archive is already fully in memory
  /// by the time it is read: the checksum pass has to see every byte, so there
  /// is nothing to be saved by pretending otherwise.
  final Map<String, List<int>> _media;

  /// The bytes of one media file, or null when the archive does not carry it.
  ///
  /// An app restoring photos calls this per row and counts the nulls, so the
  /// restore screen can say with a number what did not come back.
  List<int>? mediaBytes(String relativePath) => _media[relativePath];

  /// Rows dropped because their line would not parse.
  List<SkippedRow> get skipped =>
      [for (final table in tables.values) ...table.skipped];

  int get totalRows =>
      tables.values.fold(0, (sum, table) => sum + table.rows.length);
}

/// Reads and validates a backup zip.
///
/// Order matters and is not negotiable: manifest, then compatibility, then
/// checksums, then rows. **Nothing touches the live database until all four
/// pass.**
final class ArchiveReader {
  const ArchiveReader();

  ({ArchiveContents? contents, ArchiveError? error}) read(
    Uint8List zipBytes, {
    required int appSchemaVersion,
    bool verifyChecksums = true,
  }) {
    // Everything, not only the zip directory. The directory can survive
    // damage that the compressed entries or the manifest text do not, and
    // those throw later - from `readBytes`, from `utf8.decode` - when an
    // entry is actually inflated. A throw from any of them is the same fact
    // for the person restoring: this file cannot be trusted.
    try {
      return _read(
        zipBytes,
        appSchemaVersion: appSchemaVersion,
        verifyChecksums: verifyChecksums,
      );
    } on Object {
      return (
        contents: null,
        error: const ArchiveError(
          ArchiveRejection.malformed,
          'This file is not readable as a backup. It may be incomplete.',
        ),
      );
    }
  }

  ({ArchiveContents? contents, ArchiveError? error}) _read(
    Uint8List zipBytes, {
    required int appSchemaVersion,
    required bool verifyChecksums,
  }) {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final byName = {
      for (final file in archive.files)
        if (file.isFile) file.name: file.readBytes() ?? const <int>[],
    };

    // ZipDecoder does not throw on arbitrary bytes; it returns an empty
    // archive. Without this, a user who picked a photo by mistake would be
    // told their backup was missing its manifest, which reads as data loss
    // rather than as the wrong file.
    //
    // The message names no app. This package is shared by every app in the
    // portfolio and it used to say "not a lockIn backup", which was wrong in
    // any of the others the moment they copied it. Callers that want to name
    // themselves have `ArchiveRejection` to switch on.
    if (byName.isEmpty) {
      return (
        contents: null,
        error: const ArchiveError(
          ArchiveRejection.malformed,
          'This file is not a backup from this app.',
        ),
      );
    }

    final manifestBytes = byName['manifest.json'];
    if (manifestBytes == null) {
      return (
        contents: null,
        error: const ArchiveError(
          ArchiveRejection.missingFile,
          'This backup has no manifest, so the app cannot tell what is in it.',
        ),
      );
    }

    final parsed = ArchiveManifest.parse(utf8.decode(manifestBytes));
    if (parsed.error != null) return (contents: null, error: parsed.error);
    final manifest = parsed.manifest!;

    // Before anything else is trusted: refuse a future schema outright.
    final incompatible =
        manifest.checkCompatibility(appSchemaVersion: appSchemaVersion);
    if (incompatible != null) return (contents: null, error: incompatible);

    if (verifyChecksums) {
      final checksumBytes = byName['CHECKSUMS.txt'];
      if (checksumBytes == null) {
        return (
          contents: null,
          error: const ArchiveError(
            ArchiveRejection.missingFile,
            'This backup has no checksums, so the app cannot verify it.',
          ),
        );
      }
      final failure = _verify(utf8.decode(checksumBytes), byName);
      if (failure != null) return (contents: null, error: failure);
    }

    final tables = <String, TableRows>{};
    final media = <String, List<int>>{};
    for (final entry in byName.entries) {
      final name = entry.key;
      if (name.startsWith('data/') && name.endsWith('.ndjson')) {
        final table = name.substring(5, name.length - 7);
        tables[table] = Ndjson.decode(table, utf8.decode(entry.value));
      } else if (name.startsWith('media/')) {
        media[name.substring(6)] = entry.value;
      }
    }

    return (
      contents: ArchiveContents(
        manifest: manifest,
        tables: tables,
        mediaPaths: media.keys.toList()..sort(),
        media: media,
      ),
      error: null,
    );
  }

  ArchiveError? _verify(String checksums, Map<String, List<int>> files) {
    for (final line in const LineSplitter().convert(checksums)) {
      if (line.trim().isEmpty) continue;
      final split = line.indexOf('  ');
      if (split < 0) continue;
      final expected = line.substring(0, split);
      final name = line.substring(split + 2);

      final bytes = files[name];
      if (bytes == null) {
        return ArchiveError(
          ArchiveRejection.missingFile,
          'This backup is missing $name. It may not have finished saving.',
        );
      }
      if (sha256.convert(bytes).toString() != expected) {
        return ArchiveError(
          ArchiveRejection.checksumMismatch,
          'Part of this backup ($name) is damaged, so it was not restored.',
        );
      }
    }
    return null;
  }
}
