import 'dart:convert';

import 'package:patterns_core/patterns_core.dart';
import 'package:test/test.dart';

final createdAt = DateTime.utc(2026, 8, 1);

Metric marker(String id, MetricKind kind,
        {String? unit, List<MetricOption>? options}) =>
    Metric.create(
      id: id,
      name: id,
      domain: MetricDomain.body,
      kind: kind,
      createdAt: createdAt,
      unit: unit,
    ).copyWith(options: options);

var _n = 0;
Observation reading(String metricId, String dayKey, MetricValue value,
        {int hourUtc = 18, bool late = false}) =>
    Observation(
      id: 'o${_n++}',
      metricId: metricId,
      dayKey: dayKey,
      recordedAt: DateTime.parse('${dayKey}T${hourUtc.toString().padLeft(2, '0')}:05:00Z'),
      utcOffsetMinutes: 120,
      value: value,
      enteredLate: late,
    );

void main() {
  final mood = marker('raspolozenje', MetricKind.scale);
  final dose = marker('kreatin doza', MetricKind.amount, unit: 'g');
  final diary = marker('dnevnik', MetricKind.text);
  final photo = marker('koza', MetricKind.photo);
  final feelings = marker('osjecanja', MetricKind.tags, options: const [
    MetricOption(id: 't1', label: 'tuga'),
    MetricOption(id: 't2', label: 'overthink'),
  ]);

  final observations = [
    reading('raspolozenje', '2026-09-01', const NumberValue(6, kind: MetricKind.scale)),
    reading('raspolozenje', '2026-09-01', const NumberValue(4, kind: MetricKind.scale), hourUtc: 20),
    reading('kreatin doza', '2026-09-02', const NumberValue(2.5, kind: MetricKind.amount), late: true),
    reading('osjecanja', '2026-09-02', TagsValue(const ['t1', 't2'])),
    reading('osjecanja', '2026-09-03', TagsValue(const [])),
    reading('dnevnik', '2026-09-02', const TextValue('rekla je "dosta", pa, tisina')),
    reading('dnevnik', '2026-09-03', const TextValue('tajna', isPrivate: true)),
    reading('koza', '2026-09-03', const PhotoValue(photoId: 'p', caption: 'lice')),
    reading('raspolozenje', '2026-10-01', const NumberValue(9, kind: MetricKind.scale)),
  ];
  final all = [mood, dose, diary, photo, feelings];

  test('one row per reading, in time order, inside the period only', () {
    final data = buildExport(
      metrics: all,
      observations: observations,
      from: '2026-09-01',
      to: '2026-09-30',
    );
    expect(data.rows.map((r) => r.value),
        ['6', '4', '2.5', 'tuga|overthink', 'nista od ovoga']);
    expect(data.rows.first.time, '20:05');
    expect(data.rows[2].enteredLate, isTrue);
  });

  test('photos and private entries never leave; the diary needs a tick', () {
    final without = buildExport(
      metrics: all,
      observations: observations,
      from: '2026-09-01',
      to: '2026-09-30',
    );
    expect(without.heldBackPrivate, 1);
    expect(without.heldBackDiary, 1);
    expect(without.metrics.map((m) => m.id), isNot(contains('koza')));

    final withDiary = buildExport(
      metrics: all,
      observations: observations,
      from: '2026-09-01',
      to: '2026-09-30',
      includeDiary: true,
    );
    final csv = exportCsv(withDiary);
    expect(csv, contains('rekla je'));
    expect(csv, isNot(contains('tajna')));
    expect(csv, isNot(contains('lice')));
    expect(withDiary.heldBackPrivate, 1);
    expect(withDiary.heldBackDiary, 0);
  });

  test('CSV quotes what needs quoting and nothing else', () {
    final data = buildExport(
      metrics: all,
      observations: observations,
      from: '2026-09-01',
      to: '2026-09-30',
      includeDiary: true,
    );
    final lines = exportCsv(data).split('\r\n');
    expect(lines.first, 'date,time,marker,kind,value,unit,entered_late');
    expect(lines, contains('2026-09-02,20:05,kreatin doza,amount,2.5,g,true'));
    expect(lines,
        contains('2026-09-02,20:05,dnevnik,text,"rekla je ""dosta"", pa, tisina",,false'));
  });

  test('the AI export carries its schema, its gaps, and valid JSON', () {
    final data = buildExport(
      metrics: all,
      observations: observations,
      from: '2026-09-01',
      to: '2026-09-30',
    );
    final md = exportAiMarkdown(data, preamble: 'moj uvod');
    expect(md, startsWith('moj uvod'));
    expect(md, contains('**raspolozenje** - ocjena 1-10'));
    expect(md, contains('Privatni unosi dnevnika izostavljeni: 1.'));
    expect(md, contains('ne nulu'));

    final json = md.split('```json\n')[1].split('\n```')[0];
    final decoded = jsonDecode(json) as Map<String, Object?>;
    expect((decoded['readings']! as List), hasLength(5));
    expect(((decoded['markers']! as List).first as Map)['max'], 10);
  });
}
