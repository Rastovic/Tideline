import 'dart:convert';

import 'language.dart';
import 'metric.dart';
import 'metric_kind.dart';
import 'metric_value.dart';
import 'observation.dart';

/// One reading, flattened for a file that leaves the phone.
///
/// **Long, not wide**: one line per reading, the same shape as storage. A wide
/// sheet with a column per marker cannot hold two readings a day, and it
/// silently turns a day with no reading into an empty cell that a spreadsheet
/// then averages as zero.
final class ExportRow {
  const ExportRow({
    required this.date,
    required this.time,
    required this.marker,
    required this.kind,
    required this.value,
    this.unit,
    this.note,
    this.enteredLate = false,
  });

  final String date;

  /// Local wall-clock `HH:MM` at the moment it was recorded.
  final String time;
  final String marker;
  final String kind;
  final String value;
  final String? unit;

  /// Free text about this reading. Present only when the diary was ticked,
  /// because a note is the same kind of thing as a diary entry.
  final String? note;

  final bool enteredLate;

  Map<String, Object?> toJson() => {
        'date': date,
        'time': time,
        'marker': marker,
        'kind': kind,
        'value': value,
        if (unit != null) 'unit': unit,
        if (note != null) 'note': note,
        if (enteredLate) 'enteredLate': true,
      };
}

/// What an export holds, and what it deliberately does not.
final class ExportData {
  const ExportData({
    required this.from,
    required this.to,
    required this.metrics,
    required this.rows,
    required this.heldBackPrivate,
    required this.heldBackDiary,
    this.heldBackNotes = 0,
  });

  final String from;
  final String to;

  /// The markers that have at least one row, in the order given.
  final List<Metric> metrics;
  final List<ExportRow> rows;

  /// Private diary entries left out. **Always left out**, and always counted,
  /// so a file that is missing entries says so rather than looking complete.
  final int heldBackPrivate;

  /// Diary entries left out because the diary was not ticked.
  final int heldBackDiary;

  /// Notes on other markers, left out by the same tick. Counted apart, since
  /// losing a note is a different surprise from losing a whole entry.
  final int heldBackNotes;
}

/// Flattens readings of [metrics] between [from] and [to] for export.
///
/// Photos never leave through here - not the image, not the caption. A private
/// diary entry never leaves either. The diary as a whole leaves only when
/// [includeDiary] is set, because free text is the most personal thing the
/// app holds and it should take a deliberate tick.
ExportData buildExport({
  required List<Metric> metrics,
  required Iterable<Observation> observations,
  required String from,
  required String to,
  bool includeDiary = false,
  TextLanguage language = TextLanguage.en,
}) {
  final byId = {for (final m in metrics) m.id: m};
  final ordered = [
    for (final o in observations)
      if (!o.isDeleted &&
          byId.containsKey(o.metricId) &&
          o.dayKey.compareTo(from) >= 0 &&
          o.dayKey.compareTo(to) <= 0)
        o,
  ]..sort((a, b) {
      final day = a.dayKey.compareTo(b.dayKey);
      return day != 0 ? day : a.recordedAt.compareTo(b.recordedAt);
    });

  var heldBackPrivate = 0;
  var heldBackDiary = 0;
  var heldBackNotes = 0;
  final used = <String>{};
  final rows = <ExportRow>[];

  for (final o in ordered) {
    final metric = byId[o.metricId]!;
    if (metric.kind == MetricKind.photo) continue;
    if (o.value case TextValue(:final isPrivate)) {
      if (isPrivate) {
        heldBackPrivate++;
        continue;
      }
      if (!includeDiary) {
        heldBackDiary++;
        continue;
      }
    }
    used.add(metric.id);
    if (o.note != null && !includeDiary) heldBackNotes++;
    final minute = o.localMinuteOfDay;
    rows.add(ExportRow(
      date: o.dayKey,
      time: _clock(minute),
      marker: metric.name,
      kind: metric.kind.wireName,
      value: _value(metric, o.value, language),
      unit: metric.unit,
      note: includeDiary ? o.note : null,
      enteredLate: o.enteredLate,
    ));
  }

  return ExportData(
    from: from,
    to: to,
    metrics: [for (final m in metrics) if (used.contains(m.id)) m],
    rows: rows,
    heldBackPrivate: heldBackPrivate,
    heldBackDiary: heldBackDiary,
    heldBackNotes: heldBackNotes,
  );
}

/// RFC 4180, with a header, `\r\n` line ends, and every field that needs it
/// quoted. Opens in a spreadsheet and in pandas without a setting changed.
String exportCsv(ExportData data) {
  const header = [
    'date',
    'time',
    'marker',
    'kind',
    'value',
    'unit',
    'note',
    'entered_late',
  ];
  final lines = [
    header.join(','),
    for (final row in data.rows)
      [
        row.date,
        row.time,
        row.marker,
        row.kind,
        row.value,
        row.unit ?? '',
        row.note ?? '',
        row.enteredLate ? 'true' : 'false',
      ].map(_csvField).join(','),
  ];
  return '${lines.join('\r\n')}\r\n';
}

/// The default opening of the AI export, which the person edits before
/// sharing. It asks for description, not diagnosis, because the app itself
/// draws no conclusions and a file it hands over should not invite them.
String defaultAiPreamble([TextLanguage lang = TextLanguage.en]) => lang.pick(
      'This is my personal record from a tracking app. I entered the numbers '
          'myself. Describe what you see in the data: what repeats, what goes '
          'together, and how much data is behind each statement. Do not '
          'diagnose.',
      'Ovo je moj licni zapis iz aplikacije za pracenje. Brojeve sam upisivala '
          'sama. Opisi sta vidis u podacima: sta se ponavlja, sta ide zajedno, i '
          'koliko je podataka iza svake tvrdnje. Nemoj postavljati dijagnozu.',
    );

/// Markdown for pasting into an AI chat: the preamble, a schema that says what
/// every marker means, the counts that were held back, then every reading as
/// JSON.
///
/// **The schema travels with the data.** A number 7 means nothing without
/// "scale 1-10, 1 = nisko", and a model that has to guess the scale will guess
/// confidently and wrongly.
String exportAiMarkdown(
  ExportData data, {
  String? preamble,
  TextLanguage language = TextLanguage.en,
}) {
  String t(String en, String sr) => language.pick(en, sr);
  final buffer = StringBuffer()
    ..writeln((preamble ?? defaultAiPreamble(language)).trim())
    ..writeln()
    ..writeln('## Period')
    ..writeln()
    ..writeln('${data.from} - ${data.to}, '
        '${data.rows.length} ${t('readings', 'unosa')}.')
    ..writeln()
    ..writeln(t('## Markers', '## Markeri'))
    ..writeln();

  for (final m in data.metrics) {
    buffer.writeln('- **${m.name}** - ${_describeSchema(m, language)}');
  }

  buffer
    ..writeln()
    ..writeln(t('## Not in this file', '## Sta nije u fajlu'))
    ..writeln()
    ..writeln(t(
      '- A day with nothing logged has no row. A missing row means "not '
          'logged", not zero.',
      '- Neupisan dan nema red. Nedostajuci red znaci "nije upisano", ne nulu.',
    ))
    ..writeln(t('- Photos are not included.', '- Fotografije nisu ukljucene.'))
    ..writeln(t(
      '- Private diary entries left out: ${data.heldBackPrivate}.',
      '- Privatni unosi dnevnika izostavljeni: ${data.heldBackPrivate}.',
    ));
  if (data.heldBackDiary > 0) {
    buffer.writeln(t(
      '- Diary entries left out: ${data.heldBackDiary}.',
      '- Unosi dnevnika izostavljeni: ${data.heldBackDiary}.',
    ));
  }
  if (data.heldBackNotes > 0) {
    buffer.writeln(t(
      '- Notes on readings left out: ${data.heldBackNotes}.',
      '- Biljeske uz unose izostavljene: ${data.heldBackNotes}.',
    ));
  }

  buffer
    ..writeln()
    ..writeln(t('## Data', '## Podaci'))
    ..writeln()
    ..writeln('```json')
    ..writeln(const JsonEncoder.withIndent('  ').convert({
      'from': data.from,
      'to': data.to,
      'markers': [
        for (final m in data.metrics)
          {
            'name': m.name,
            'kind': m.kind.wireName,
            'dayRule': m.aggregation.wireName,
            if (m.unit != null) 'unit': m.unit,
            if (m.kind == MetricKind.scale) ...{
              'min': m.scaleMin,
              'max': m.scaleMax,
              if (m.lowLabel != null) 'minLabel': m.lowLabel,
              if (m.highLabel != null) 'maxLabel': m.highLabel,
            },
          },
      ],
      'readings': [for (final row in data.rows) row.toJson()],
    }))
    ..writeln('```');
  return buffer.toString();
}

String _describeSchema(Metric m, TextLanguage lang) {
  String t(String en, String sr) => lang.pick(en, sr);
  final options = m.options.map((o) => o.label).join(', ');
  return switch (m.kind) {
    MetricKind.scale => '${t('rating', 'ocjena')} ${m.scaleMin}-${m.scaleMax}'
        '${m.lowLabel == null ? '' : ', ${m.scaleMin} = ${m.lowLabel}'}'
        '${m.highLabel == null ? '' : ', ${m.scaleMax} = ${m.highLabel}'}',
    MetricKind.percent => t('percent 0-100', 'procenat 0-100'),
    MetricKind.boolean => t('yes/no (true/false)', 'da/ne (true/false)'),
    MetricKind.amount => t('amount', 'kolicina') +
        (m.unit == null ? '' : ' ${t('in', 'u')} ${m.unit}'),
    MetricKind.count => t('count', 'broj'),
    MetricKind.duration => t('duration in minutes', 'trajanje u minutama'),
    MetricKind.timeOfDay => t('time of day, HH:MM', 'vrijeme u danu, HH:MM'),
    MetricKind.choice => '${t('one choice', 'jedan izbor')}: $options',
    MetricKind.tags =>
      '${t('several tags, separated by |', 'vise oznaka, odvojene sa |')}: '
          '$options',
    MetricKind.text => t('free text', 'slobodan tekst'),
    MetricKind.photo => t('photo', 'fotografija'),
  };
}

String _value(Metric metric, MetricValue value, TextLanguage lang) {
  final labels = {for (final o in metric.options) o.id: o.label};
  return switch (value) {
    NumberValue(:final number) => number == number.roundToDouble()
        ? '${number.round()}'
        : '$number',
    BooleanValue(value: final flag) => flag ? 'true' : 'false',
    TimeOfDayValue(:final minutesFromMidnight) => _clock(minutesFromMidnight),
    ChoiceValue(:final optionId) => labels[optionId] ?? optionId,
    TagsValue(:final optionIds) => optionIds.isEmpty
        ? lang.pick('none of these', 'nista od ovoga')
        : optionIds.map((id) => labels[id] ?? id).join('|'),
    TextValue(:final text) => text,
    PhotoValue() => '',
  };
}

String _clock(int minute) => '${(minute ~/ 60).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';

String _csvField(String field) {
  if (!field.contains(RegExp(r'[",\r\n]'))) return field;
  return '"${field.replaceAll('"', '""')}"';
}
