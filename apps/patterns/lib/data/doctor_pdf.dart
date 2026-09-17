import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vitals_core/vitals_core.dart';

/// Paper sizes worth offering: the page is printed, not read on the phone.
enum DoctorPaper {
  a4('A4', PdfPageFormat.a4),
  letter('Letter', PdfPageFormat.letter);

  const DoctorPaper(this.label, this.format);

  final String label;
  final PdfPageFormat format;
}

/// Android's own Roboto, so a marker named `raspoloženje` prints its `ž`.
///
/// Read from the system rather than bundled: the font is already on every
/// Android phone, and shipping a second copy costs a megabyte for nothing.
/// Null anywhere it is missing - a test, a desktop - and the page falls back
/// to the built-in Helvetica with the diacritics folded, which is legible
/// rather than broken.
Future<({pw.Font regular, pw.Font bold})?> loadSystemFonts() async {
  const regular = '/system/fonts/Roboto-Regular.ttf';
  const bold = '/system/fonts/Roboto-Bold.ttf';
  try {
    final r = File(regular);
    if (!await r.exists()) return null;
    final regularBytes = await r.readAsBytes();
    final b = File(bold);
    final boldBytes = await b.exists() ? await b.readAsBytes() : regularBytes;
    return (
      regular: pw.Font.ttf(regularBytes.buffer.asByteData()),
      bold: pw.Font.ttf(boldBytes.buffer.asByteData()),
    );
  } on FileSystemException {
    return null;
  }
}

/// One printable page.
///
/// **Facts only.** Counts, ranges with their dates, coverage. No word anywhere
/// that means better, worse, normal or concerning, and no colour that does
/// either: a square is darker because the number is higher, and that is all a
/// darker square means.
Future<Uint8List> renderDoctorPdf(
  DoctorPage page, {
  required DateTime generatedAt,
  DoctorPaper paper = DoctorPaper.a4,
  ({pw.Font regular, pw.Font bold})? fonts,
  bool compress = true,
}) async {
  final hasFont = fonts != null;
  String t(String text) => hasFont ? text : _foldForHelvetica(text);

  final doc = pw.Document(compress: compress);
  final theme = fonts == null
      ? pw.ThemeData.base()
      : pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);

  const ink = PdfColor.fromInt(0xFF1A1D23);
  const muted = PdfColor.fromInt(0xFF5C6370);
  const stroke = PdfColor.fromInt(0xFFC9CED6);

  final small = pw.TextStyle(fontSize: 7.5, color: muted);
  final body = const pw.TextStyle(fontSize: 9, color: ink);

  doc.addPage(
    pw.Page(
      pageFormat: paper.format,
      theme: theme,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Pregled zabiljezenog',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: ink,
                ),
              ),
              pw.Text(
                'Napravljeno ${_date(_dayKeyOf(generatedAt))}',
                style: small,
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${_date(page.from)} - ${_date(page.to)}  ·  '
            '${page.daysInPeriod} dana  ·  '
            'bar jedan unos: ${page.daysWithAnyEntry} dana',
            style: body,
          ),
          if (page.periodStarts.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Pocetak menstruacije: '
              '${page.periodStarts.map(_date).join(', ')}',
              style: body,
            ),
          ],
          pw.SizedBox(height: 6),
          pw.Divider(color: stroke, thickness: 0.5),
          pw.SizedBox(height: 4),
          for (final entry in page.entries) ...[
            _entry(entry, page, t: t, body: body, small: small),
            pw.SizedBox(height: 8),
          ],
          pw.Spacer(),
          pw.Divider(color: stroke, thickness: 0.5),
          pw.Text(
            'Samostalno zabiljezeno. Brojevi su ono sto je upisano, bez '
            'tumacenja. Tipicno = medijana dana sa unosom. '
            'Prazan kvadrat = taj dan nije upisan.',
            style: small,
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

pw.Widget _entry(
  DoctorEntry entry,
  DoctorPage page, {
  required String Function(String) t,
  required pw.TextStyle body,
  required pw.TextStyle small,
}) {
  final color = _color(entry.metric.colorHex);
  final unit = entry.metric.unit == null ? '' : ' (${entry.metric.unit})';

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 200,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: pw.BoxDecoration(
                    color: color,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.Text(
                    t('${entry.metric.name}$unit'),
                    style: body.copyWith(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            for (final line in doctorFacts(entry))
              pw.Text(t(line), style: small),
          ],
        ),
      ),
      pw.SizedBox(width: 10),
      pw.Expanded(child: _grid(entry, color)),
    ],
  );
}

/// The lines printed under a marker's name. Public so a test can hold the
/// copy to the no-interpretation rule without parsing a PDF.
List<String> doctorFacts(DoctorEntry entry) {
  final stats = entry.stats;
  final coverage = '${stats.daysLogged}/${stats.daysInPeriod} dana upisano';
  final unit = entry.metric.unit == null ? '' : ' ${entry.metric.unit}';

  switch (entry.metric.kind) {
    case MetricKind.boolean:
      return [
        'da: ${entry.daysOn} od ${stats.daysLogged} upisanih dana',
        coverage,
      ];
    case MetricKind.tags || MetricKind.choice:
      final shown = entry.optionCounts.take(6).toList();
      return [
        if (shown.isEmpty && entry.explicitNoneDays == 0) 'nista izabrano',
        if (shown.isNotEmpty)
          shown.map((o) => '${o.label} ${o.days}').join(' · '),
        if (entry.optionCounts.length > shown.length)
          '+ jos ${entry.optionCounts.length - shown.length}',
        if (entry.explicitNoneDays > 0)
          'nista od ovoga: ${entry.explicitNoneDays}',
        coverage,
      ];
    case MetricKind.timeOfDay:
      return [
        if (entry.typicalMinute case final minute?) 'tipicno ${_clock(minute)}',
        coverage,
      ];
    default:
      return [
        if (stats.typical case final typical?)
          'tipicno ${_number(typical)}$unit',
        if ((entry.lowest, entry.highest) case (
          final low?,
          final high?,
        ) when low.value != high.value)
          'najnize ${_number(low.value)} (${_shortDate(low.dayKey)}), '
              'najvise ${_number(high.value)} (${_shortDate(high.dayKey)})',
        coverage,
      ];
  }
}

/// Seven rows, Monday at the top, one column per week.
///
/// The same layout as the grid report, for the same reason: a weekly rhythm
/// is a visible stripe here and invisible in a single row of ninety days.
pw.Widget _grid(DoctorEntry entry, PdfColor color) {
  final days = entry.days;
  if (days.isEmpty) return pw.SizedBox();

  final first = parseDayKey(days.first.dayKey)!;
  final lead = first.weekday - 1;
  final columns = ((lead + days.length) / 7).ceil();
  final (low, high) = entry.bounds;

  return pw.LayoutBuilder(
    builder: (context, constraints) {
      const labelWidth = 12.0;
      final width = (constraints?.maxWidth ?? 300) - labelWidth;
      final cell = (width / columns).clamp(2.0, 9.0);
      final gap = cell > 5 ? 1.0 : 0.4;

      PdfColor? fill(DaySummary day) {
        if (!day.isLogged) return null;
        switch (entry.metric.kind) {
          case MetricKind.boolean:
            return (day.value ?? 0) > 0 ? color : _tint(color, 0.15);
          case MetricKind.tags || MetricKind.choice:
            return day.explicitNone ? _tint(color, 0.15) : _tint(color, 0.8);
          case MetricKind.timeOfDay:
            return _tint(color, 0.6);
          default:
            final value = day.value;
            if (value == null) return _tint(color, 0.15);
            final span = high - low;
            final fraction = span == 0
                ? 1.0
                : ((value - low) / span).clamp(0.0, 1.0);
            return _tint(color, 0.25 + 0.75 * fraction);
        }
      }

      const label = pw.TextStyle(
        fontSize: 4.5,
        color: PdfColor.fromInt(0xFF5C6370),
      );
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Two letters, because two weekdays share a first letter in Serbian.
              pw.SizedBox(
                width: labelWidth,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (final day in const [
                      'po',
                      'ut',
                      'sr',
                      'ce',
                      'pe',
                      'su',
                      'ne',
                    ])
                      pw.SizedBox(
                        height: cell,
                        child: pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text(day, style: label),
                        ),
                      ),
                  ],
                ),
              ),
              for (var col = 0; col < columns; col++)
                pw.Column(
                  children: [
                    for (var row = 0; row < 7; row++)
                      () {
                        final index = col * 7 + row - lead;
                        final inside = index >= 0 && index < days.length;
                        final colour = inside ? fill(days[index]) : null;
                        return pw.Container(
                          width: cell - gap,
                          height: cell - gap,
                          margin: pw.EdgeInsets.only(right: gap, bottom: gap),
                          decoration: !inside
                              ? null
                              : pw.BoxDecoration(
                                  color: colour,
                                  // An unlogged day is an outline, never a pale fill:
                                  // a pale square reads as a low value.
                                  border: colour == null
                                      ? pw.Border.all(
                                          color: const PdfColor.fromInt(
                                            0xFFC9CED6,
                                          ),
                                          width: 0.4,
                                        )
                                      : null,
                                ),
                        );
                      }(),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 1),
          pw.SizedBox(
            width: labelWidth + columns * cell,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: labelWidth),
                  child: pw.Text(_shortDate(days.first.dayKey), style: label),
                ),
                pw.Text(_shortDate(days.last.dayKey), style: label),
              ],
            ),
          ),
        ],
      );
    },
  );
}

/// [color] laid over white at [alpha]. Blended here rather than using PDF
/// transparency, which some print drivers flatten badly.
PdfColor _tint(PdfColor color, double alpha) => PdfColor(
  1 - (1 - color.red) * alpha,
  1 - (1 - color.green) * alpha,
  1 - (1 - color.blue) * alpha,
);

PdfColor _color(String? hex) {
  final value = hex != null && hex.length == 7 && hex.startsWith('#')
      ? int.tryParse(hex.substring(1), radix: 16)
      : null;
  return PdfColor.fromInt(0xFF000000 | (value ?? 0x4C7DFF));
}

String _dayKeyOf(DateTime local) =>
    formatDayKey(local.year, local.month, local.day);

String _date(String dayKey) {
  final d = parseDayKey(dayKey);
  return d == null ? dayKey : '${d.day}.${d.month}.${d.year}.';
}

String _shortDate(String dayKey) {
  final d = parseDayKey(dayKey);
  return d == null ? dayKey : '${d.day}.${d.month}.';
}

String _clock(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';

String _number(num value) => value == value.roundToDouble()
    ? '${value.round()}'
    : value.toStringAsFixed(1);

/// Helvetica in a PDF covers Latin-1, which has no `č`, `ć` or `đ`.
String _foldForHelvetica(String text) {
  const folds = {
    'č': 'c',
    'ć': 'c',
    'đ': 'dj',
    'š': 's',
    'ž': 'z',
    'Č': 'C',
    'Ć': 'C',
    'Đ': 'Dj',
    'Š': 'S',
    'Ž': 'Z',
  };
  return text.split('').map((c) => folds[c] ?? c).join();
}
