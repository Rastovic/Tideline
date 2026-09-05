import 'dart:convert';

/// Why an archive was refused.
enum ArchiveRejection {
  /// The manifest is absent, unreadable, or not this format.
  malformed,

  /// Written by a newer version of the app.
  ///
  /// **Refused outright, with no partial write.** The running app cannot know
  /// what a future schema means, and a half-import is worse than no import.
  futureSchema,

  /// A file's sha256 does not match `CHECKSUMS.txt`.
  checksumMismatch,

  /// An expected file is missing from the zip.
  missingFile,
}

/// The refusal, with something the UI can actually say.
final class ArchiveError {
  const ArchiveError(this.reason, this.message);

  final ArchiveRejection reason;

  /// Plain words for the user. Never a stack trace, never an error code.
  final String message;

  @override
  String toString() => '${reason.name}: $message';
}

/// The header of an archive: what it is, who wrote it, and how much is inside.
final class ArchiveManifest {
  const ArchiveManifest({
    required this.app,
    required this.appVersion,
    required this.schemaVersion,
    required this.installId,
    required this.exportedAt,
    required this.timezone,
    required this.rowCounts,
    this.dayBoundaryHour = 0,
    this.device = const {},
    this.encrypted = false,
    this.format = currentFormat,
  });

  /// Parses a manifest, returning an [ArchiveError] rather than throwing.
  ///
  /// A corrupt manifest is a thing users hand us, not a programming error.
  static ({ArchiveManifest? manifest, ArchiveError? error}) parse(
    String source,
  ) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return (
        manifest: null,
        error: const ArchiveError(
          ArchiveRejection.malformed,
          'This file is not a lockIn backup.',
        ),
      );
    }
    if (decoded is! Map<String, dynamic>) {
      return (
        manifest: null,
        error: const ArchiveError(
          ArchiveRejection.malformed,
          'This file is not a lockIn backup.',
        ),
      );
    }

    final format = decoded['format'];
    final schemaVersion = decoded['schemaVersion'];
    if (format is! String ||
        !format.startsWith('app-archive/') ||
        schemaVersion is! int) {
      return (
        manifest: null,
        error: const ArchiveError(
          ArchiveRejection.malformed,
          'This backup is missing information the app needs to read it.',
        ),
      );
    }

    return (
      manifest: ArchiveManifest(
        format: format,
        app: decoded['app'] as String? ?? 'unknown',
        appVersion: decoded['appVersion'] as String? ?? '0.0.0',
        schemaVersion: schemaVersion,
        installId: decoded['installId'] as String? ?? '',
        exportedAt: decoded['exportedAt'] as int? ?? 0,
        timezone: decoded['timezone'] as String? ?? 'UTC',
        dayBoundaryHour: decoded['dayBoundaryHour'] as int? ?? 0,
        device: Map<String, String>.from(
          (decoded['device'] as Map?)?.cast<String, String>() ?? const {},
        ),
        rowCounts: Map<String, int>.from(
          (decoded['rowCounts'] as Map?)?.cast<String, int>() ?? const {},
        ),
        encrypted: decoded['encrypted'] as bool? ?? false,
      ),
      error: null,
    );
  }

  static const currentFormat = 'app-archive/1';

  final String format;
  final String app;
  final String appVersion;

  /// The whole game. An import must refuse anything newer than the running app.
  final int schemaVersion;

  final String installId;
  final int exportedAt;
  final String timezone;
  final int dayBoundaryHour;
  final Map<String, String> device;
  final Map<String, int> rowCounts;
  final bool encrypted;

  int get totalRows => rowCounts.values.fold(0, (a, b) => a + b);

  /// Checks this archive against the running app.
  ///
  /// Older archives are fine: they migrate forward through the same drift
  /// migration chain the live database uses, so there is exactly one migration
  /// path and the restore path shares it.
  ArchiveError? checkCompatibility({required int appSchemaVersion}) {
    if (!format.startsWith('app-archive/')) {
      return const ArchiveError(
        ArchiveRejection.malformed,
        'This file is not a lockIn backup.',
      );
    }
    if (schemaVersion > appSchemaVersion) {
      return const ArchiveError(
        ArchiveRejection.futureSchema,
        'This backup was made by a newer version of the app. '
        'Update the app, then restore it.',
      );
    }
    return null;
  }

  String toJson() => const JsonEncoder.withIndent('  ').convert({
        'format': format,
        'app': app,
        'appVersion': appVersion,
        'schemaVersion': schemaVersion,
        'installId': installId,
        'exportedAt': exportedAt,
        'timezone': timezone,
        'dayBoundaryHour': dayBoundaryHour,
        'device': device,
        'rowCounts': rowCounts,
        'encrypted': encrypted,
      });

  /// The filename shape, so a user with five backups in Drive can tell them
  /// apart at a glance.
  ///
  /// `scroll-allowance-backup-2026-08-10-1934.zip`
  static String fileNameFor({
    required String appSlug,
    required DateTime exportedAtLocal,
  }) {
    String two(int v) => v.toString().padLeft(2, '0');
    final d = exportedAtLocal;
    return '$appSlug-backup-${d.year}-${two(d.month)}-${two(d.day)}'
        '-${two(d.hour)}${two(d.minute)}.zip';
  }
}
