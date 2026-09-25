import 'package:patterns_core/patterns_core.dart';

import '../l10n/app_language.dart';

/// A word in both languages. Picked once, when the marker is made: from then
/// on the name is hers and a language switch never rewrites it.
typedef Words = ({String en, String sr});

String _pick(Words words, AppLanguage language) =>
    language == AppLanguage.en ? words.en : words.sr;

/// One marker offered at the end of the welcome, ready to tick.
final class SuggestedMarker {
  const SuggestedMarker({
    required this.key,
    required this.name,
    required this.domain,
    required this.kind,
    required this.colorHex,
    this.low,
    this.high,
    this.unit,
    this.options = const [],
    this.rule,
    this.preselected = false,
  });

  /// Stable across languages, for tests and for remembering a tick.
  final String key;
  final Words name;
  final MetricDomain domain;
  final MetricKind kind;
  final String colorHex;
  final Words? low;
  final Words? high;
  final Words? unit;
  final List<({Words label, String colorHex})> options;
  final DayAggregation? rule;

  /// Ticked when the list opens: the few almost everyone keeps.
  final bool preselected;

  String nameIn(AppLanguage language) => _pick(name, language);

  /// A real marker in [profileId], worded in [language].
  Metric build({
    required AppLanguage language,
    required String profileId,
    required String id,
    required String Function() newId,
    required DateTime createdAt,
    required int sortOrder,
  }) {
    var order = 0;
    final metric = Metric.create(
      id: id,
      profileId: profileId,
      name: nameIn(language),
      domain: domain,
      kind: kind,
      createdAt: createdAt,
      colorHex: colorHex,
      unit: unit == null ? null : _pick(unit!, language),
      lowLabel: low == null ? null : _pick(low!, language),
      highLabel: high == null ? null : _pick(high!, language),
      sortOrder: sortOrder,
      options: [
        for (final option in options)
          MetricOption(
            id: newId(),
            label: _pick(option.label, language),
            colorHex: option.colorHex,
            sortOrder: order++,
          ),
      ],
    );
    return rule == null ? metric : metric.copyWith(aggregation: rule);
  }
}

/// What the welcome offers. Short on purpose, like the seed: a dozen someone
/// might answer, and the editor for everything else.
///
/// Serbian is written the way the rest of the app writes it: ijekavian, no
/// diacritics.
const List<SuggestedMarker> suggestedMarkers = [
  // --- Mind -------------------------------------------------------------
  SuggestedMarker(
    key: 'mood',
    name: (en: 'mood', sr: 'raspolozenje'),
    domain: MetricDomain.mind,
    kind: MetricKind.scale,
    colorHex: '#3B6FE0',
    low: (en: 'awful', sr: 'uzasno'),
    high: (en: 'great', sr: 'odlicno'),
    preselected: true,
  ),
  SuggestedMarker(
    key: 'energy',
    name: (en: 'energy', sr: 'energija'),
    domain: MetricDomain.mind,
    kind: MetricKind.scale,
    colorHex: '#17A2A2',
    low: (en: 'exhausted', sr: 'bez snage'),
    high: (en: 'full of energy', sr: 'puno energije'),
    preselected: true,
  ),
  SuggestedMarker(
    key: 'stress',
    name: (en: 'stress', sr: 'stres'),
    domain: MetricDomain.mind,
    kind: MetricKind.scale,
    colorHex: '#D93B3B',
    low: (en: 'none', sr: 'nimalo'),
    high: (en: 'very high', sr: 'jako visok'),
    rule: DayAggregation.peak,
  ),
  SuggestedMarker(
    key: 'feelings',
    name: (en: 'feelings', sr: 'osjecanja'),
    domain: MetricDomain.mind,
    kind: MetricKind.tags,
    colorHex: '#8E5BD6',
    options: [
      (label: (en: 'calm', sr: 'mir'), colorHex: '#2F9E5E'),
      (label: (en: 'joy', sr: 'radost'), colorHex: '#E0A100'),
      (label: (en: 'sadness', sr: 'tuga'), colorHex: '#4C7BD9'),
      (label: (en: 'anxiety', sr: 'anksioznost'), colorHex: '#C4478E'),
      (label: (en: 'overwhelm', sr: 'preplavljenost'), colorHex: '#E2711D'),
      (label: (en: 'anger', sr: 'ljutnja'), colorHex: '#D93B3B'),
      (label: (en: 'loneliness', sr: 'usamljenost'), colorHex: '#4A8FA8'),
    ],
    preselected: true,
  ),
  SuggestedMarker(
    key: 'diary',
    name: (en: 'diary', sr: 'dnevnik'),
    domain: MetricDomain.mind,
    kind: MetricKind.text,
    colorHex: '#5A6BA8',
    preselected: true,
  ),

  // --- Body -------------------------------------------------------------
  SuggestedMarker(
    key: 'sleep',
    name: (en: 'sleep quality', sr: 'kvalitet sna'),
    domain: MetricDomain.body,
    kind: MetricKind.scale,
    colorHex: '#5A6BA8',
    low: (en: 'terrible', sr: 'uzasan'),
    high: (en: 'deep and long', sr: 'dubok i dug'),
    preselected: true,
  ),
  SuggestedMarker(
    key: 'bedtime',
    name: (en: 'bedtime', sr: 'odlazak na spavanje'),
    domain: MetricDomain.body,
    kind: MetricKind.timeOfDay,
    colorHex: '#7A8A99',
  ),
  SuggestedMarker(
    key: 'exercise',
    name: (en: 'exercise', sr: 'trening'),
    domain: MetricDomain.body,
    kind: MetricKind.boolean,
    colorHex: '#3F8FA8',
  ),
  SuggestedMarker(
    key: 'water',
    name: (en: 'water', sr: 'voda'),
    domain: MetricDomain.body,
    kind: MetricKind.amount,
    colorHex: '#4A8FA8',
    unit: (en: 'l', sr: 'l'),
  ),
  SuggestedMarker(
    key: 'coffee',
    name: (en: 'coffee', sr: 'kafa'),
    domain: MetricDomain.body,
    kind: MetricKind.count,
    colorHex: '#B5573F',
  ),
  SuggestedMarker(
    key: 'headache',
    name: (en: 'headache', sr: 'glavobolja'),
    domain: MetricDomain.body,
    kind: MetricKind.scale,
    colorHex: '#E2711D',
    low: (en: 'none', sr: 'nimalo'),
    high: (en: 'severe', sr: 'jaka'),
    rule: DayAggregation.peak,
  ),
  SuggestedMarker(
    key: 'bloating',
    name: (en: 'bloating', sr: 'nadutost'),
    domain: MetricDomain.body,
    kind: MetricKind.scale,
    colorHex: '#C4478E',
    low: (en: 'none', sr: 'nimalo'),
    high: (en: 'severe', sr: 'jaka'),
    rule: DayAggregation.peak,
  ),
  SuggestedMarker(
    key: 'medication',
    name: (en: 'medication', sr: 'lijekovi'),
    domain: MetricDomain.body,
    kind: MetricKind.boolean,
    colorHex: '#2F9E5E',
  ),
];

/// The period pair's names, for a first run that turns the cycle on in
/// Serbian. The seed's own pair is English.
const Words periodStartName = (en: 'period start', sr: 'pocetak menstruacije');
const Words periodEndName = (en: 'period end', sr: 'kraj menstruacije');

String periodName(Words words, AppLanguage language) => _pick(words, language);
