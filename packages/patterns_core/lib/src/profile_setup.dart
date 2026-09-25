import 'metric.dart';
import 'metric_kind.dart';
import 'seed.dart';

/// How a new profile starts.
enum ProfileStart {
  /// No markers at all; everything is made in the editor.
  empty,

  /// The starting set every install gets, without the cycle.
  starter,

  /// The markers of an existing profile. Markers only, never a reading.
  copy,
}

/// Re-homes [source] markers into [profileId] under fresh ids.
///
/// **Fresh ids for the marker and for every option**, because an id is what a
/// reading stores: sharing one would let a child's reading appear in a parent's
/// chart. Archived and deleted markers are left behind - a new profile starts
/// with what is in use, not with someone else's history of changes.
List<Metric> copyMarkers(
  Iterable<Metric> source, {
  required String profileId,
  required DateTime createdAt,
  required String Function() newId,
}) {
  var order = 0;
  return [
    for (final metric in source)
      if (metric.isActive)
        Metric(
          id: newId(),
          profileId: profileId,
          name: metric.name,
          domain: metric.domain,
          kind: metric.kind,
          aggregation: metric.aggregation,
          displayStyle: metric.displayStyle,
          colorHex: metric.colorHex,
          unit: metric.unit,
          scaleMin: metric.scaleMin,
          scaleMax: metric.scaleMax,
          lowLabel: metric.lowLabel,
          highLabel: metric.highLabel,
          sortOrder: order++,
          createdAt: createdAt,
          options: [
            for (final option in metric.liveOptions)
              MetricOption(
                id: newId(),
                label: option.label,
                colorHex: option.colorHex,
                sortOrder: option.sortOrder,
              ),
          ],
        ),
  ];
}

/// The starting set for a new profile: the seed, without the cycle, under
/// fresh ids.
List<Metric> starterMarkers({
  required String profileId,
  required DateTime createdAt,
  required String Function() newId,
}) =>
    copyMarkers(
      seedMetrics(createdAt: createdAt)
          .where((m) => m.domain != MetricDomain.cycle),
      profileId: profileId,
      createdAt: createdAt,
      newId: newId,
    );

/// The two period markers for a profile turning the cycle on.
///
/// Built from the seed's own pair so every profile's cycle markers look and
/// behave alike, then renamed only if the caller asks.
(Metric start, Metric end) cycleMarkers({
  required String profileId,
  required DateTime createdAt,
  required String Function() newId,
  required int sortOrder,
}) {
  final seeded = seedMetrics(createdAt: createdAt);
  Metric take(String key, int order) {
    final base = seeded.firstWhere((m) => m.id == seedIds[key]);
    return Metric(
      id: newId(),
      profileId: profileId,
      name: base.name,
      domain: MetricDomain.cycle,
      kind: MetricKind.boolean,
      aggregation: base.aggregation,
      displayStyle: base.displayStyle,
      colorHex: base.colorHex,
      sortOrder: order,
      createdAt: createdAt,
    );
  }

  return (take('period-start', sortOrder), take('period-end', sortOrder + 1));
}

/// The seeded markers the demo profile shows, by slug.
///
/// **A handful, not the whole seed.** The demo is a first look at the app, and
/// eighteen rows of someone else's life read as homework. These seven cover
/// every kind of answer - a rating, tags, yes or no, a time, text - and are
/// enough for each saved report to show something.
const Set<String> demoMarkerSlugs = {
  'mood',
  'tiredness',
  'feelings',
  'bloating',
  'training',
  'bedtime',
  'diary',
};

/// The demo profile's markers: [demoMarkerSlugs] from the seed, without the
/// cycle, under fresh ids.
List<Metric> demoMarkers({
  required String profileId,
  required DateTime createdAt,
  required String Function() newId,
}) {
  final ids = {for (final slug in demoMarkerSlugs) seedIds[slug]!};
  return copyMarkers(
    seedMetrics(createdAt: createdAt).where((m) => ids.contains(m.id)),
    profileId: profileId,
    createdAt: createdAt,
    newId: newId,
  );
}
