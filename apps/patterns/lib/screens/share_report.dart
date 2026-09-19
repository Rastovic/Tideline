import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import 'doctor_page_screen.dart' show FontLoader;

import '../data/archive_transfer.dart';
import '../data/doctor_pdf.dart';
import '../data/patterns_controller.dart';
import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';

/// What one report leaves the phone as.
enum ReportShare { ai, csv, doctorPdf }

/// Shares a single report: its markers, its period, nothing else.
///
/// The whole-app export in Settings covers "everything since forever"; this
/// covers "this question, to this person". The same rules hold either way:
/// **photos never leave, private diary entries never leave**, and the rest of
/// the diary and the notes only travel when the tick says so - which is off
/// by default, because a report sent to a doctor or pasted into a chat is the
/// worst possible place for free text to arrive unasked.
Future<void> shareReport(
  BuildContext context,
  PatternsController controller,
  ReportDefinition definition, {
  ArchiveTransfer transfer = const PlatformArchiveTransfer(),
  FontLoader? fonts,
}) async {
  final s = context.s;
  var includeDiary = false;

  final choice = await showModalBottomSheet<ReportShare>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VitalsSpacing.screenH,
                VitalsSpacing.md,
                VitalsSpacing.screenH,
                0,
              ),
              child: Text(
                s.shareThisReport,
                style: VitalsTheme.of(context).typography.title,
              ),
            ),
            SwitchListTile(
              value: includeDiary,
              onChanged: (on) => setState(() => includeDiary = on),
              title: Text(s.shareDiaryIncluded),
              subtitle: Text(s.privateExplained),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(s.shareForAi),
              subtitle: Text(s.shareForAiHint),
              onTap: () => Navigator.of(context).pop(ReportShare.ai),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(s.shareCsv),
              subtitle: Text(s.shareCsvHint),
              onTap: () => Navigator.of(context).pop(ReportShare.csv),
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: Text(s.shareDoctor),
              subtitle: Text(s.shareDoctorHint),
              onTap: () => Navigator.of(context).pop(ReportShare.doctorPdf),
            ),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  final language = s.language;
  final metricIds = [
    for (final series in definition.series)
      if (!series.isBand) series.metricId,
  ];
  final (from, to) = definition.period.resolve(controller.today);
  final slug = _slug(definition.name);

  switch (choice) {
    case ReportShare.ai:
      final data = await controller.exportData(
        metricIds,
        from: from,
        to: to,
        includeDiary: includeDiary,
        language: language.text,
      );
      final comparison = await controller.comparisonFor(definition);
      final text = StringBuffer(
        exportAiMarkdown(data, language: language.text),
      );
      if (comparison != null && !comparison.isEmpty) {
        text.writeln();
        text.writeln(_comparisonSection(comparison, s));
      }
      await transfer.send(utf8.encode(text.toString()), '$slug-$to.md');

    case ReportShare.csv:
      final data = await controller.exportData(
        metricIds,
        from: from,
        to: to,
        includeDiary: includeDiary,
        language: language.text,
      );
      await transfer.send(utf8.encode(exportCsv(data)), '$slug-$to.csv');

    case ReportShare.doctorPdf:
      final page = await controller.doctorPage(
        metricIds,
        FixedPeriod(from: from, to: to),
        compare: definition.compare,
      );
      // The phone's own font, so diacritics survive. A test hands none.
      final loaded = fonts == null ? await loadSystemFonts() : await fonts();
      final bytes = await renderDoctorPdf(
        page,
        generatedAt: DateTime.now(),
        fonts: loaded,
        strings: s,
      );
      await transfer.send(bytes, '$slug-$to.pdf');
  }
}

/// The comparison, written out for a reader who cannot see the chart: each
/// group, its typical value and the days behind it. **Counted, never claimed.**
String _comparisonSection(Comparison comparison, AppStrings s) {
  final buffer = StringBuffer()
    ..writeln('## ${s.compareTitle(
      comparison.outcome.name,
      comparison.condition.name,
    )}')
    ..writeln();
  if (comparison.pairing == ComparePairing.nextDay) {
    buffer.writeln('${s.compareNextDayNote}\n');
  }
  for (final bucket in comparison.buckets) {
    final typical = bucket.typical;
    buffer.writeln('- ${bucket.label}: '
        '${typical ?? '-'}, ${bucket.days} '
        '${s.daysLoggedLabel.split(' ').first}');
  }
  buffer
    ..writeln()
    ..writeln(s.compareNoClaim);
  return buffer.toString();
}

String _slug(String name) {
  final cleaned = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return cleaned.isEmpty ? 'report' : cleaned;
}
