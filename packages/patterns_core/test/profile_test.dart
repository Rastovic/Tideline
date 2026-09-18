import 'package:patterns_core/patterns_core.dart';
import 'package:test/test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 9, 18);
  var n = 0;
  String newId() => 'id-${n++}';

  test('everything written before profiles belongs to the default one', () {
    final metric = Metric.create(
      id: 'm',
      name: 'mood',
      domain: MetricDomain.mind,
      kind: MetricKind.scale,
      createdAt: createdAt,
    );
    expect(metric.profileId, defaultProfileId);
  });

  test('the starter set is the seed without the cycle, under fresh ids', () {
    final markers = starterMarkers(
      profileId: 'p2',
      createdAt: createdAt,
      newId: newId,
    );
    expect(markers, isNotEmpty);
    expect(markers.every((m) => m.profileId == 'p2'), isTrue);
    expect(markers.any((m) => m.domain == MetricDomain.cycle), isFalse);
    final seedIdSet = seedIds.values.toSet();
    expect(markers.any((m) => seedIdSet.contains(m.id)), isFalse);
    // Options get fresh ids too: a reading stores an option id.
    final feelings = markers.firstWhere((m) => m.name == 'feelings');
    final seedOptionIdSet = seedOptionIds.values.toSet();
    expect(
      feelings.options.any((o) => seedOptionIdSet.contains(o.id)),
      isFalse,
    );
  });

  test('copying takes what is in use and leaves archived markers behind', () {
    final live = Metric.create(
      id: 'a',
      name: 'sleep',
      domain: MetricDomain.body,
      kind: MetricKind.scale,
      createdAt: createdAt,
    );
    final archived = live.copyWith(
      id: 'b',
      name: 'old supplement',
      archivedAt: createdAt,
    );
    final copied = copyMarkers(
      [live, archived],
      profileId: 'kid',
      createdAt: createdAt,
      newId: newId,
    );
    expect(copied.map((m) => m.name), ['sleep']);
    expect(copied.single.id, isNot('a'));
    expect(copied.single.profileId, 'kid');
  });

  test('cycle markers are a fresh pair for the profile', () {
    final (start, end) = cycleMarkers(
      profileId: 'p3',
      createdAt: createdAt,
      newId: newId,
      sortOrder: 40,
    );
    expect(start.domain, MetricDomain.cycle);
    expect(end.kind, MetricKind.boolean);
    expect(start.profileId, 'p3');
    expect(start.id, isNot(end.id));
    expect([start.sortOrder, end.sortOrder], [40, 41]);
  });
}
