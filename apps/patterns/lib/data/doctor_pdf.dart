import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vitals_core/vitals_core.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';

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
/// either: a point sits higher because the number is higher, and that is all
/// its height means.
Future<Uint8List> renderDoctorPdf(
  DoctorPage page, {
  required DateTime generatedAt,
  DoctorPaper paper = DoctorPaper.a4,
  ({pw.Font regular, pw.Font bold})? fonts,
  bool compress = true,
  AppStrings strings = const AppStrings(AppLanguage.en),
}) async {
  final s = strings;
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

  // A MultiPage rather than one fixed page: eight markers with a comparison
  // and the reading guide do not fit on one sheet, and a single page clips
  // what overflows without a word. Whatever does not fit moves to a second
  // page; eight markers alone still print on one.
  doc.addPage(
    pw.MultiPage(
      pageFormat: paper.format,
      theme: theme,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 28),
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              t(s.pdfTitle),
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: ink,
              ),
            ),
            pw.Text(s.pdfMade(_date(_dayKeyOf(generatedAt))), style: small),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          t(
            '${_date(page.from)} - ${_date(page.to)}  ·  '
            '${s.pdfDays(page.daysInPeriod)}  ·  '
            '${s.pdfAnyEntry(page.daysWithAnyEntry)}',
          ),
          style: body,
        ),
        if (page.periodStarts.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            t(
              '${s.pdfPeriodStarts}: '
              '${page.periodStarts.map(_date).join(', ')}',
            ),
            style: body,
          ),
        ],
        pw.SizedBox(height: 6),
        pw.Divider(color: stroke, thickness: 0.5),
        pw.SizedBox(height: 4),
        for (final entry in page.entries) ...[
          _entry(entry, page, s, t: t, body: body, small: small),
          pw.SizedBox(height: 4),
        ],
        // The one place on the page where two markers are read against
        // each other rather than side by side. A clinician reading a
        // printed page should not have to hold two grids in their head.
        if (page.comparison case final comparison?) ...[
          pw.SizedBox(height: 4),
          pw.Divider(color: stroke, thickness: 0.5),
          pw.SizedBox(height: 4),
          _comparison(comparison, s, t: t, body: body, small: small),
        ],
        pw.SizedBox(height: 10),
        // For whoever holds the paper: a clinician seeing this layout for
        // the first time should not need the phone to read it.
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: stroke, width: 0.5),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                t(s.pdfHowToReadTitle),
                style: small.copyWith(
                  fontWeight: pw.FontWeight.bold,
                  color: ink,
                ),
              ),
              pw.SizedBox(height: 2),
              for (final line in s.pdfHowToRead)
                pw.Text(t('- $line'), style: small),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: stroke, thickness: 0.5),
        pw.Text(t(s.pdfFooter), style: small),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _entry(
  DoctorEntry entry,
  DoctorPage page,
  AppStrings s, {
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
            for (final line in doctorFacts(entry, s))
              pw.Text(t(line), style: small),
          ],
        ),
      ),
      pw.SizedBox(width: 10),
      pw.Expanded(child: _chart(entry, color)),
    ],
  );
}

/// Two markers against each other: a dot per day, and the groups counted.
///
/// **The same numbers as the app's card, and the same silence about why.**
/// Nothing is fitted through the dots, and the caption says so, because a
/// line through a cloud of days is a claim and this page makes none.
pw.Widget _comparison(
  Comparison comparison,
  AppStrings s, {
  required String Function(String) t,
  required pw.TextStyle body,
  required pw.TextStyle small,
}) {
  final color = _color(comparison.outcome.colorHex);
  final points = [
    for (final p in comparison.points)
      if (p.outcome != null) p,
  ];
  final values = [for (final p in points) p.outcome!]..sort();
  final (low, high) = switch (comparison.outcome.kind) {
    MetricKind.scale => (
      comparison.outcome.scaleMin as num,
      comparison.outcome.scaleMax as num,
    ),
    MetricKind.percent => (0 as num, 100 as num),
    _ =>
      values.isEmpty
          ? (0 as num, 1 as num)
          : (
              values.first,
              values.last == values.first ? values.first + 1 : values.last,
            ),
  };
  final groups = comparison.buckets.map((b) => b.label).toList();
  final scatter = points.isNotEmpty && points.first.condition != null;
  final conditions = [
    for (final p in points)
      if (p.condition case final c?) c,
  ]..sort();

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        t(s.compareTitle(comparison.outcome.name, comparison.condition.name)),
        style: body.copyWith(fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        t(
          '${s.comparePairedDays(comparison.pairedDays)}'
          '${comparison.pairing == ComparePairing.nextDay ? ' · ${s.compareNextDayNote}' : ''}',
        ),
        style: small,
      ),
      pw.SizedBox(height: 4),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final bucket in comparison.buckets)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            t(_bucketLabel(bucket.label, s)),
                            style: small,
                          ),
                        ),
                        pw.Text(
                          bucket.typical == null
                              ? '-'
                              : _number(bucket.typical!),
                          style: body,
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text('${bucket.days} d', style: small),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.SizedBox(
              height: 78,
              child: pw.CustomPaint(
                painter: (canvas, size) => _paintComparison(
                  canvas,
                  size,
                  points: points,
                  groups: groups,
                  buckets: comparison.buckets,
                  scatter: scatter,
                  low: low,
                  high: high,
                  conditionLow: conditions.isEmpty ? 0 : conditions.first,
                  conditionHigh: conditions.isEmpty ? 1 : conditions.last,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 2),
      pw.Text(t('${s.compareChartHint} ${s.compareNoClaim}'), style: small),
    ],
  );
}

String _bucketLabel(String raw, AppStrings s) => switch (raw) {
  'yes' => s.compareYes,
  'no' => s.compareNo,
  'high' => s.compareHigh,
  'low' => s.compareLow,
  _ => raw,
};

/// One dot per day, in PDF coordinates - which run from the bottom up, unlike
/// the screen's.
void _paintComparison(
  PdfGraphics canvas,
  PdfPoint size, {
  required List<ComparePoint> points,
  required List<String> groups,
  required List<CompareBucket> buckets,
  required bool scatter,
  required num low,
  required num high,
  required num conditionLow,
  required num conditionHigh,
  required PdfColor color,
}) {
  const inset = 3.0;
  double y(num value) {
    final span = high - low;
    final t = span == 0 ? 0.5 : (value - low) / span;
    return inset + t.clamp(0.0, 1.0) * (size.y - inset * 2);
  }

  canvas
    ..setStrokeColor(const PdfColor.fromInt(0xFFC9CED6))
    ..setLineWidth(0.5)
    ..drawLine(0, 0, size.x, 0)
    ..drawLine(0, 0, 0, size.y)
    ..strokePath();

  canvas.setFillColor(color);

  if (scatter) {
    final random = Random(5);
    for (final point in points) {
      final span = conditionHigh - conditionLow;
      final t = span == 0 ? 0.5 : (point.condition! - conditionLow) / span;
      final jitter = (random.nextDouble() - 0.5) * 8;
      final x = (inset + t.clamp(0.0, 1.0) * (size.x - inset * 2) + jitter)
          .clamp(inset, size.x - inset);
      canvas.drawEllipse(x, y(point.outcome!), 1.4, 1.4);
    }
    canvas.fillPath();
    return;
  }

  final step = groups.isEmpty ? size.x : size.x / groups.length;
  final random = Random(11);
  for (var i = 0; i < groups.length; i++) {
    final centre = step * (i + 0.5);
    for (final point in points.where((p) => p.bucket == groups[i])) {
      final jitter = (random.nextDouble() - 0.5) * (step * 0.5);
      canvas.drawEllipse(centre + jitter, y(point.outcome!), 1.4, 1.4);
    }
  }
  canvas.fillPath();

  // The median of each group, drawn where its dots are.
  canvas
    ..setStrokeColor(const PdfColor.fromInt(0xFF1A1D23))
    ..setLineWidth(0.8);
  for (var i = 0; i < groups.length; i++) {
    if (buckets[i].typical case final typical?) {
      final centre = step * (i + 0.5);
      canvas.drawLine(
        centre - step * 0.3,
        y(typical),
        centre + step * 0.3,
        y(typical),
      );
    }
  }
  canvas.strokePath();
}

/// The lines printed under a marker's name. Public so a test can hold the
/// copy to the no-interpretation rule without parsing a PDF.
List<String> doctorFacts(
  DoctorEntry entry, [
  AppStrings s = const AppStrings(AppLanguage.en),
]) {
  final stats = entry.stats;
  final coverage = s.pdfCoverage(stats.daysLogged, stats.daysInPeriod);
  final unit = entry.metric.unit == null ? '' : ' ${entry.metric.unit}';

  switch (entry.metric.kind) {
    case MetricKind.boolean:
      return [s.pdfYesDays(entry.daysOn ?? 0, stats.daysLogged), coverage];
    case MetricKind.tags || MetricKind.choice:
      final shown = entry.optionCounts.take(6).toList();
      return [
        if (shown.isEmpty && entry.explicitNoneDays == 0) s.pdfNothingPicked,
        if (shown.isNotEmpty)
          shown.map((o) => '${o.label} ${o.days}').join(' · '),
        if (entry.optionCounts.length > shown.length)
          s.pdfMore(entry.optionCounts.length - shown.length),
        if (entry.explicitNoneDays > 0)
          '${s.noneOfThese}: ${entry.explicitNoneDays}',
        coverage,
      ];
    case MetricKind.timeOfDay:
      return [
        if (entry.typicalMinute case final minute?)
          '${s.typical} ${_clock(minute)}',
        coverage,
      ];
    default:
      return [
        if (stats.typical case final typical?)
          '${s.typical} ${_number(typical)}$unit',
        if ((entry.lowest, entry.highest) case (
          final low?,
          final high?,
        ) when low.value != high.value)
          '${s.lowest} ${_number(low.value)} (${_shortDate(low.dayKey)}), '
              '${s.highest} ${_number(high.value)} (${_shortDate(high.dayKey)})',
        coverage,
      ];
  }
}

/// One marker across the period as a chart: days left to right, oldest first.
///
/// A number is a line through the days it was logged, broken where a day was
/// not, so a gap never reads as a drop to zero. A yes/no is a bar on each yes
/// day and a tick on each no; a tags or choice marker is a bar per logged day,
/// as tall as the options picked. A clock time is a dot at its time.
pw.Widget _chart(DoctorEntry entry, PdfColor color) {
  final days = entry.days;
  if (days.isEmpty) return pw.SizedBox();

  final kind = entry.metric.kind;
  final values = kind == MetricKind.timeOfDay
      ? _unwrappedMinutes(entry)
      : [for (final d in days) d.value];
  final (low, high) = switch (kind) {
    MetricKind.timeOfDay => _clockBounds(values),
    MetricKind.boolean => (0 as num, 1 as num),
    MetricKind.tags || MetricKind.choice => (
      0 as num,
      [for (final d in days) d.optionIds.length].fold(1, max) as num,
    ),
    _ => entry.bounds,
  };
  final quantity =
      kind != MetricKind.boolean &&
      kind != MetricKind.tags &&
      kind != MetricKind.choice;
  String axis(num value) => kind == MetricKind.timeOfDay
      ? _clock(value.round() % 1440)
      : _number(value);

  const label = pw.TextStyle(fontSize: 5, color: PdfColor.fromInt(0xFF5C6370));
  const labelWidth = 22.0;
  final middle = days[days.length ~/ 2].dayKey;

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: labelWidth,
            height: 48,
            child: quantity
                ? pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(axis(high), style: label),
                      pw.Text(axis(low), style: label),
                    ],
                  )
                : null,
          ),
          pw.SizedBox(width: 3),
          pw.Expanded(
            child: pw.SizedBox(
              height: 48,
              child: pw.CustomPaint(
                painter: (canvas, size) => _paintChart(
                  canvas,
                  size,
                  days: days,
                  values: values,
                  kind: kind,
                  low: low,
                  high: high,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 1),
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: labelWidth + 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_shortDate(days.first.dayKey), style: label),
            if (days.length > 2) pw.Text(_shortDate(middle), style: label),
            pw.Text(_shortDate(days.last.dayKey), style: label),
          ],
        ),
      ),
    ],
  );
}

/// Each day's time, moved by a whole day where needed so it sits within
/// twelve hours of the typical time. A bedtime of 00:30 then plots just after
/// 23:30 rather than at the bottom of the chart.
List<num?> _unwrappedMinutes(DoctorEntry entry) {
  final centre = entry.typicalMinute ?? 720;
  return [
    for (final day in entry.days)
      switch (entry.dayMinutes[day.dayKey]) {
        null => null,
        final m when m < centre - 720 => m + 1440,
        final m when m >= centre + 720 => m - 1440,
        final m => m,
      },
  ];
}

/// The earliest and latest recorded time, widened to whole hours.
(num, num) _clockBounds(List<num?> values) {
  final minutes = [
    for (final v in values)
      if (v != null) v,
  ];
  if (minutes.isEmpty) return (0, 1440);
  final low = (minutes.reduce(min) / 60).floor() * 60;
  final high = (minutes.reduce(max) / 60).ceil() * 60;
  return (low, high == low ? low + 60 : high);
}

/// In PDF coordinates, which run from the bottom up.
void _paintChart(
  PdfGraphics canvas,
  PdfPoint size, {
  required List<DaySummary> days,
  required List<num?> values,
  required MetricKind kind,
  required num low,
  required num high,
  required PdfColor color,
}) {
  const inset = 2.0;
  const faint = PdfColor.fromInt(0xFFE3E6EB);
  const axis = PdfColor.fromInt(0xFFC9CED6);
  final step = size.x / days.length;
  double x(int i) => step * (i + 0.5);
  double y(num value) {
    final span = high - low;
    final t = span == 0 ? 0.5 : (value - low) / span;
    return inset + t.clamp(0.0, 1.0) * (size.y - inset * 2);
  }

  canvas
    ..setStrokeColor(faint)
    ..setLineWidth(0.3)
    ..drawLine(0, y(high), size.x, y(high))
    ..drawLine(0, y((low + high) / 2), size.x, y((low + high) / 2))
    ..strokePath()
    ..setStrokeColor(axis)
    ..setLineWidth(0.5)
    ..drawLine(0, 0, size.x, 0)
    ..strokePath();

  final barWidth = (step * 0.7).clamp(0.6, 6.0);
  switch (kind) {
    case MetricKind.boolean:
      canvas.setFillColor(color);
      for (var i = 0; i < days.length; i++) {
        final day = days[i];
        if (!day.isLogged) continue;
        final yes = (day.value ?? 0) > 0;
        final top = yes ? size.y - inset : 2.0;
        canvas.drawRect(x(i) - barWidth / 2, 0, barWidth, top);
      }
      canvas.fillPath();
    case MetricKind.tags || MetricKind.choice:
      canvas.setFillColor(color);
      for (var i = 0; i < days.length; i++) {
        final day = days[i];
        if (!day.isLogged) continue;
        final top = day.explicitNone || day.optionIds.isEmpty
            ? 2.0
            : y(day.optionIds.length);
        canvas.drawRect(x(i) - barWidth / 2, 0, barWidth, top);
      }
      canvas.fillPath();
    default:
      // The line, broken at every day without a value.
      if (kind != MetricKind.timeOfDay) {
        canvas
          ..setStrokeColor(color)
          ..setLineWidth(0.9);
        var drawing = false;
        for (var i = 0; i < days.length; i++) {
          final value = values[i];
          if (value == null) {
            drawing = false;
            continue;
          }
          if (drawing) {
            canvas.lineTo(x(i), y(value));
          } else {
            canvas.moveTo(x(i), y(value));
            drawing = true;
          }
        }
        canvas.strokePath();
      }
      final radius = days.length > 120 ? 0.8 : 1.3;
      canvas.setFillColor(color);
      for (var i = 0; i < days.length; i++) {
        if (values[i] case final value?) {
          canvas.drawEllipse(x(i), y(value), radius, radius);
        }
      }
      canvas.fillPath();
  }
}

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
