import 'dart:convert';

/// One row that failed to parse, kept rather than thrown.
///
/// **A corrupted line costs one row, not the archive.** That is the entire
/// reason the format is NDJSON rather than one big JSON document.
final class SkippedRow {
  const SkippedRow({
    required this.table,
    required this.lineNumber,
    required this.reason,
  });

  final String table;
  final int lineNumber;
  final String reason;

  @override
  String toString() => '$table line $lineNumber: $reason';
}

/// What one table's file decoded to.
final class TableRows {
  const TableRows({
    required this.table,
    required this.rows,
    required this.skipped,
  });

  final String table;
  final List<Map<String, Object?>> rows;
  final List<SkippedRow> skipped;

  bool get hadLosses => skipped.isNotEmpty;
}

/// Newline-delimited JSON: one row per line.
///
/// Chosen over a single JSON document because it streams in and out, so a
/// 50k-row export never holds the whole database in memory; because one bad
/// line costs one row; and because diffing two backups is a text diff.
final class Ndjson {
  const Ndjson._();

  /// Encodes rows lazily, so a caller can write straight to a sink without
  /// materialising the table.
  static Iterable<String> encodeRows(
    Iterable<Map<String, Object?>> rows,
  ) sync* {
    for (final row in rows) {
      yield jsonEncode(row);
    }
  }

  static String encode(Iterable<Map<String, Object?>> rows) =>
      '${encodeRows(rows).join('\n')}\n';

  /// Decodes a table file, collecting bad lines instead of failing.
  static TableRows decode(String table, String source) {
    final rows = <Map<String, Object?>>[];
    final skipped = <SkippedRow>[];
    final lines = const LineSplitter().convert(source);

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      Object? decoded;
      try {
        decoded = jsonDecode(line);
      } on FormatException catch (e) {
        skipped.add(
          SkippedRow(table: table, lineNumber: i + 1, reason: e.message),
        );
        continue;
      }
      if (decoded is! Map<String, dynamic>) {
        skipped.add(
          SkippedRow(
            table: table,
            lineNumber: i + 1,
            reason: 'Expected an object, found ${decoded.runtimeType}',
          ),
        );
        continue;
      }
      rows.add(decoded);
    }

    return TableRows(table: table, rows: rows, skipped: skipped);
  }
}
