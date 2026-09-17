/// The markers the app starts with.
///
/// **Seed data, not built-ins.** Every one of these is an ordinary [Metric]
/// written through the same constructor the editor uses, and every one can be
/// renamed, recoloured, re-styled, archived or deleted on the first evening.
/// The list is short on purpose: fifteen markers someone actually answers beat
/// a hundred-item catalogue they scroll past, and anything missing is one tap
/// in the editor away.
///
/// Ids are stable slugs rather than generated uuids so a reinstall that
/// re-seeds cannot produce two of the same marker.
library;

import 'aggregation.dart';
import 'metric.dart';
import 'metric_kind.dart';


/// The palette every marker colour comes from.
///
/// A fixed set rather than a free picker: two markers in near-identical colours
/// ruin the one screen colours exist for, which is a stack of rows read
/// together. A free colour stays available behind one extra tap in the editor.
const List<String> markerPalette = [
  '#3B6FE0', // plava
  '#5A6BA8', // sivo-plava
  '#17A2A2', // tirkiz
  '#3F8FA8', // petrol
  '#2F9E5E', // zelena
  '#8AB825', // limun
  '#E0A100', // zlatna
  '#E2711D', // narandzasta
  '#D93B3B', // crvena
  '#C4478E', // magenta
  '#8E5BD6', // ljubicasta
  '#B06A86', // prigusena roza
  '#7A8A99', // siva
  '#4A8FA8', // svijetli petrol
];

/// Stable ids for the seeded markers, keyed by slug.
///
/// Hand-written uuids rather than generated ones, and rather than the slugs
/// themselves: every portable row is a 36-character uuid by rule 1, and a
/// re-seed on a reinstall has to land on the same id or the same marker exists
/// twice. Written out in full rather than derived from a hash, because a
/// greppable constant beats a clever function nobody can read back.
const Map<String, String> seedIds = {
  'mood': '0198aa00-0000-7000-8000-000000000001',
  'tiredness': '0198aa00-0000-7000-8000-000000000002',
  'motivation': '0198aa00-0000-7000-8000-000000000003',
  'irritability': '0198aa00-0000-7000-8000-000000000004',
  'feelings': '0198aa00-0000-7000-8000-000000000005',
  'context': '0198aa00-0000-7000-8000-000000000006',
  'diary': '0198aa00-0000-7000-8000-000000000007',
  'creatine': '0198aa00-0000-7000-8000-000000000008',
  'creatine-dose': '0198aa00-0000-7000-8000-000000000009',
  'bloating': '0198aa00-0000-7000-8000-000000000010',
  'training': '0198aa00-0000-7000-8000-000000000011',
  'training-quality': '0198aa00-0000-7000-8000-000000000012',
  'appetite': '0198aa00-0000-7000-8000-000000000013',
  'overeating-urge': '0198aa00-0000-7000-8000-000000000014',
  'bedtime': '0198aa00-0000-7000-8000-000000000015',
  'waketime': '0198aa00-0000-7000-8000-000000000016',
  'period-start': '0198aa00-0000-7000-8000-000000000017',
  'period-end': '0198aa00-0000-7000-8000-000000000018',
};

/// Stable ids for the seeded options, keyed by `marker.option`.
///
/// Options are portable rows too, so they carry uuids for the same reason the
/// markers do. The **id is what a reading stores**, which is why an option can
/// be renamed freely: relabelling `overthink` leaves every day that ever had
/// it pointing at the same row.
const Map<String, String> seedOptionIds = {
  'feelings.tuga': '0198aa01-0000-7000-8000-000000000001',
  'feelings.overthink': '0198aa01-0000-7000-8000-000000000002',
  'feelings.anksioznost': '0198aa01-0000-7000-8000-000000000003',
  'feelings.ravnodusnost': '0198aa01-0000-7000-8000-000000000004',
  'feelings.preplavljenost': '0198aa01-0000-7000-8000-000000000005',
  'feelings.sram': '0198aa01-0000-7000-8000-000000000006',
  'feelings.usamljenost': '0198aa01-0000-7000-8000-000000000007',
  'feelings.ljutnja': '0198aa01-0000-7000-8000-000000000008',
  'context.posao': '0198aa01-0000-7000-8000-000000000009',
  'context.konflikt': '0198aa01-0000-7000-8000-000000000010',
  'context.los-san': '0198aa01-0000-7000-8000-000000000011',
  'context.novac': '0198aa01-0000-7000-8000-000000000012',
  'context.samoca': '0198aa01-0000-7000-8000-000000000013',
  'context.bolest': '0198aa01-0000-7000-8000-000000000014',
  'context.putovanje': '0198aa01-0000-7000-8000-000000000015',
};

/// Builds the starting set of markers, all created at [createdAt].
List<Metric> seedMetrics({required DateTime createdAt}) {
  var order = 0;

  Metric scale(
    String id,
    String name,
    MetricDomain domain,
    String color, {
    required String low,
    required String high,
    DayAggregation? rule,
  }) =>
      Metric.create(
        id: id,
        name: name,
        domain: domain,
        kind: MetricKind.scale,
        createdAt: createdAt,
        colorHex: color,
        lowLabel: low,
        highLabel: high,
        sortOrder: order++,
      ).copyWith(aggregation: rule);

  return [
    // --- Mind -------------------------------------------------------------
    // A plain 1-10, not a two-axis pad. The pad's argument was that "anxious"
    // and "numb" are both a 2 on one scale - true, and the named feelings below
    // carry that split instead, at a fraction of the interaction cost.
    scale(seedIds['mood']!, 'mood', MetricDomain.mind, '#3B6FE0',
        low: 'awful', high: 'great'),
    scale(seedIds['tiredness']!, 'tiredness', MetricDomain.mind, '#5A6BA8',
        low: 'exhausted', high: 'rested'),
    scale(seedIds['motivation']!, 'motivation', MetricDomain.mind, '#17A2A2',
        low: 'none', high: 'full'),
    scale(seedIds['irritability']!, 'irritability', MetricDomain.mind, '#D93B3B',
        low: 'calm', high: 'everything annoys me'),

    // Feelings are tags rather than eight sliders because they are events, not
    // levels: most days most of them are absent, and an empty row is the honest
    // way to say so. The "nothing today" answer is an empty set, which is a
    // recorded fact and not a skipped day.
    Metric.create(
      id: seedIds['feelings']!,
      name: 'feelings',
      domain: MetricDomain.mind,
      kind: MetricKind.tags,
      createdAt: createdAt,
      colorHex: '#8E5BD6',
      sortOrder: order++,
      options: [
        MetricOption(id: seedOptionIds['feelings.tuga']!, label: 'sadness', colorHex: '#4C7BD9', sortOrder: 0),
        MetricOption(id: seedOptionIds['feelings.overthink']!, label: 'overthinking', colorHex: '#8E6BD6', sortOrder: 1),
        MetricOption(id: seedOptionIds['feelings.anksioznost']!, label: 'anxiety', colorHex: '#C4478E', sortOrder: 2),
        MetricOption(id: seedOptionIds['feelings.ravnodusnost']!, label: 'numbness', colorHex: '#8A94A6', sortOrder: 3),
        MetricOption(id: seedOptionIds['feelings.preplavljenost']!, label: 'overwhelm', colorHex: '#E2711D', sortOrder: 4),
        MetricOption(id: seedOptionIds['feelings.sram']!, label: 'shame', colorHex: '#B5573F', sortOrder: 5),
        MetricOption(id: seedOptionIds['feelings.usamljenost']!, label: 'loneliness', colorHex: '#4A8FA8', sortOrder: 6),
        MetricOption(id: seedOptionIds['feelings.ljutnja']!, label: 'anger', colorHex: '#D93B3B', sortOrder: 7),
      ],
    ),

    // What was going on. This is the marker that makes a stack of rows worth
    // reading: a symptom row above a context row is where a person finds their
    // own answer, without the app offering one.
    Metric.create(
      id: seedIds['context']!,
      name: 'context',
      domain: MetricDomain.mind,
      kind: MetricKind.tags,
      createdAt: createdAt,
      colorHex: '#7A8A99',
      sortOrder: order++,
      options: [
        MetricOption(id: seedOptionIds['context.posao']!, label: 'work', sortOrder: 0),
        MetricOption(id: seedOptionIds['context.konflikt']!, label: 'conflict', sortOrder: 1),
        MetricOption(id: seedOptionIds['context.los-san']!, label: 'bad sleep', sortOrder: 2),
        MetricOption(id: seedOptionIds['context.novac']!, label: 'money', sortOrder: 3),
        MetricOption(id: seedOptionIds['context.samoca']!, label: 'alone', sortOrder: 4),
        MetricOption(id: seedOptionIds['context.bolest']!, label: 'illness', sortOrder: 5),
        MetricOption(id: seedOptionIds['context.putovanje']!, label: 'travel', sortOrder: 6),
      ],
    ),

    Metric.create(
      id: seedIds['diary']!,
      name: 'diary',
      domain: MetricDomain.mind,
      kind: MetricKind.text,
      createdAt: createdAt,
      colorHex: '#5A6BA8',
      sortOrder: order++,
    ),

    // --- Body -------------------------------------------------------------
    Metric.create(
      id: seedIds['creatine']!,
      name: 'creatine',
      domain: MetricDomain.body,
      kind: MetricKind.boolean,
      createdAt: createdAt,
      colorHex: '#2F9E5E',
      sortOrder: order++,
    ),
    Metric.create(
      id: seedIds['creatine-dose']!,
      name: 'creatine dose',
      domain: MetricDomain.body,
      kind: MetricKind.amount,
      createdAt: createdAt,
      colorHex: '#8AB825',
      unit: 'g',
      sortOrder: order++,
    ),
    // Peak rather than typical: what you remember about a bloated day is how
    // bad it got, and a median over three readings hides exactly that.
    scale(seedIds['bloating']!, 'bloating', MetricDomain.body, '#E2711D',
        low: 'none', high: 'severe', rule: DayAggregation.peak),
    Metric.create(
      id: seedIds['training']!,
      name: 'training',
      domain: MetricDomain.body,
      kind: MetricKind.boolean,
      createdAt: createdAt,
      colorHex: '#3F8FA8',
      sortOrder: order++,
    ),
    scale(seedIds['training-quality']!, 'training quality', MetricDomain.body, '#E0A100',
        low: 'barely', high: 'great'),
    scale(seedIds['appetite']!, 'appetite', MetricDomain.body, '#C4478E',
        low: 'none', high: 'huge'),
    scale(seedIds['overeating-urge']!, 'urge to overeat', MetricDomain.body,
        '#8E5BD6',
        low: 'none', high: 'strong', rule: DayAggregation.peak),
    Metric.create(
      id: seedIds['bedtime']!,
      name: 'bedtime',
      domain: MetricDomain.body,
      kind: MetricKind.timeOfDay,
      createdAt: createdAt,
      colorHex: '#7A8A99',
      sortOrder: order++,
    ),
    Metric.create(
      id: seedIds['waketime']!,
      name: 'wake-up',
      domain: MetricDomain.body,
      kind: MetricKind.timeOfDay,
      createdAt: createdAt,
      colorHex: '#7A8A99',
      sortOrder: order++,
    ),

    // --- Cycle ------------------------------------------------------------
    // Two taps and nothing else. Everything a cycle app would put here - flow,
    // pain, discharge - is an ordinary marker on Body if it is ever wanted, so
    // this domain owns no symptom and claims no meaning.
    Metric.create(
      id: seedIds['period-start']!,
      name: 'period start',
      domain: MetricDomain.cycle,
      kind: MetricKind.boolean,
      createdAt: createdAt,
      colorHex: '#B06A86',
      sortOrder: order++,
    ),
    Metric.create(
      id: seedIds['period-end']!,
      name: 'period end',
      domain: MetricDomain.cycle,
      kind: MetricKind.boolean,
      createdAt: createdAt,
      colorHex: '#B06A86',
      sortOrder: order++,
    ),
  ];
}
