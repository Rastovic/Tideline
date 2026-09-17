import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_archive/vitals_archive.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/archive_transfer.dart';
import '../data/patterns_controller.dart';
import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';

/// Backup and restore.
///
/// **The only screen in the app where a mistake costs data that cannot be typed
/// again**, and it is built around that: the export states its size and its
/// photo count before it goes anywhere, the restore shows what is in the file
/// and what will be replaced before it writes a byte, and afterwards it says
/// with a number what did not come back.
///
/// Photos are inside the archive rather than beside it. A backup that silently
/// omits half of what you would cry over is not a backup.
class BackupScreen extends StatefulWidget {
  const BackupScreen({
    required this.controller,
    this.transfer = const PlatformArchiveTransfer(),
    this.appVersion = '0.1.0',
    super.key,
  });

  final PatternsController controller;

  /// Injected so a widget test can drive the whole restore path without a
  /// platform channel. The one flow that must be testable end to end.
  final ArchiveTransfer transfer;

  final String appVersion;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  /// True only while the app is actually working - building the archive or
  /// writing one in. **Never while a dialog is asking a question**: a spinner
  /// behind a modal says the app is busy when it is in fact waiting on her, and
  /// it also means the frame never settles, which is how a widget test finds
  /// this rather than a person finding it on a phone.
  bool _busy = false;

  /// The last thing that happened, shown as a plain paragraph rather than a
  /// toast: a restore result is something to read, not something to catch
  /// before it slides away.
  String? _outcome;
  bool _outcomeIsProblem = false;

  void _say(String message, {bool problem = false}) {
    if (!mounted) return;
    setState(() {
      _outcome = message;
      _outcomeIsProblem = problem;
      _busy = false;
    });
  }

  Future<void> _export() async {
    final strings = context.s;
    setState(() {
      _busy = true;
      _outcome = null;
    });
    final archive =
        await widget.controller.exportArchive(appVersion: widget.appVersion);
    if (!mounted) return;
    setState(() => _busy = false);

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.archiveReady),
        content: Text(_exportSummary(archive, strings)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.share),
          ),
        ],
      ),
    );
    if (proceed != true) {
      _say(strings.archiveNotSent);
      return;
    }

    setState(() => _busy = true);
    await widget.transfer.send(
      archive.bytes,
      ArchiveManifest.fileNameFor(
        appSlug: 'tideline',
        exportedAtLocal: DateTime.now(),
      ),
    );
    _say(_exportSummary(archive, strings));
  }

  Future<void> _restore() async {
    final strings = context.s;
    setState(() {
      _busy = true;
      _outcome = null;
    });
    final bytes = await widget.transfer.pick();
    if (bytes == null) {
      _say(strings.nothingLoaded);
      return;
    }

    final read = widget.controller.previewArchive(bytes);
    if (read.error case final error?) {
      _say(_refusal(error, strings), problem: true);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    final confirmed = await showDialog<bool>(
      context: context,
      // Deliberately not dismissible by tapping away. This is the last point
      // before everything currently in the app is replaced.
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(strings.restoreQuestion),
        content: Text(_restoreWarning(read.preview!, strings)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.restore),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      _say(strings.nothingChanged);
      return;
    }

    setState(() => _busy = true);
    final result = await widget.controller.restoreArchive(bytes);
    if (result.error case final error?) {
      _say(_refusal(error, strings), problem: true);
      return;
    }
    _say(
      _restoreSummary(result.report!, strings),
      problem: !result.report!.isComplete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.s.archive)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VitalsSpacing.screenH,
            VitalsSpacing.lg,
            VitalsSpacing.screenH,
            VitalsSpacing.huge,
          ),
          children: [
            Text(
              context.s.archiveExplained,
              style:
                  theme.typography.body.copyWith(color: theme.colors.inkMuted),
            ),
            const SizedBox(height: VitalsSpacing.xl),
            SizedBox(
              height: VitalsSpacing.buttonHeight,
              child: FilledButton(
                onPressed: _busy ? null : _export,
                child: Text(context.s.makeArchive),
              ),
            ),
            const SizedBox(height: VitalsSpacing.md),
            SizedBox(
              height: VitalsSpacing.buttonHeight,
              child: OutlinedButton(
                onPressed: _busy ? null : _restore,
                child: Text(context.s.restoreFromArchive),
              ),
            ),
            const SizedBox(height: VitalsSpacing.md),
            Text(
              context.s.restoreExplained,
              style: theme.typography.caption
                  .copyWith(color: theme.colors.inkFaint),
            ),
            if (_busy) ...[
              const SizedBox(height: VitalsSpacing.xl),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_outcome case final outcome?) ...[
              const SizedBox(height: VitalsSpacing.xl),
              Container(
                padding: const EdgeInsets.all(VitalsSpacing.md),
                decoration: BoxDecoration(
                  color: _outcomeIsProblem
                      ? theme.colors.danger.withValues(alpha: 0.10)
                      : theme.colors.surfaceAlt,
                  borderRadius: VitalsRadius.nestedAll,
                ),
                child: Text(outcome, style: theme.typography.body),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Why the file was refused, in this app's own words.
  ///
  /// Switched on [ArchiveRejection] rather than passed through, because
  /// `vitals_archive` is shared portfolio infrastructure and writes English -
  /// showing its sentence here would put one English paragraph in the middle of
  /// a Serbian app, at the exact moment someone is worried about their data.
  ///
  /// Every one of these says what happened and what state the app is in. None
  /// of them is a code or a stack trace.
  static String _refusal(ArchiveError error, AppStrings s) =>
      switch (error.reason) {
        ArchiveRejection.malformed => s.refusedMalformed,
        ArchiveRejection.futureSchema => s.refusedFuture,
        ArchiveRejection.checksumMismatch => s.refusedDamaged,
        ArchiveRejection.missingFile => s.refusedIncomplete,
      };

  /// Size first, because that is the number that says whether the photos are
  /// really in there.
  static String _exportSummary(
    ({Uint8List bytes, int photosIncluded, int photosMissing}) archive,
    AppStrings s,
  ) {
    final size = megabytes(archive.bytes.length);
    final parts = ['$size, ${s.photoCount(archive.photosIncluded)}'];
    if (archive.photosMissing > 0) {
      // Said out loud rather than logged. The file is already lost; the archive
      // pretending otherwise is what would turn it into a surprise in March.
      parts.add(
        s.photosWithoutFile(archive.photosMissing),
      );
    }
    return parts.join('. ');
  }

  /// What is in the file, and what it replaces. Both, always.
  static String _restoreWarning(ImportPreview preview, AppStrings s) {
    final observations = preview.rowCounts['observations'] ?? 0;
    final photos = preview.rowCounts['photos'] ?? 0;
    final range = preview.earliestDay != null && preview.latestDay != null
        ? ', ${s.dayRange(preview.earliestDay!, preview.latestDay!)}'
        : '';
    return '${s.entriesAndPhotos(observations, photos)}$range.\n\n'
        '${s.replacesEverything}';
  }

  /// Afterwards, with a count, what did not come back.
  static String _restoreSummary(RestoreReport report, AppStrings s) {
    final done = s.restored(report.rowsWritten, report.photosRestored);
    if (report.isComplete) return done;
    return '$done ${s.photosNotInArchive(report.photosMissing.length)}';
  }
}

/// `3.4 MB`, or `640 KB` under a tenth of a megabyte.
String megabytes(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb < 0.1) return '${(bytes / 1024).round()} KB';
  return '${mb.toStringAsFixed(1)} MB';
}
