import 'package:drift/native.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:test/test.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';
const kid = '018f2c00-bbbb-7000-8000-000000000002';

void main() {
  late PatternsDatabase db;
  late ProfileRepository profiles;
  late MetricRepository metrics;
  final now = DateTime.utc(2026, 9, 18, 10);

  setUp(() async {
    db = PatternsDatabase(NativeDatabase.memory());
    profiles = ProfileRepository(db, installId: install);
    metrics = MetricRepository(db, installId: install);
    await metrics.seedIfEmpty(now: now);
  });

  tearDown(() => db.close());

  test('the seeded markers belong to the default profile', () async {
    final all = await metrics.all(profileId: defaultProfileId);
    expect(all, hasLength(seedIds.length));
  });

  test('the default profile is written once, with the cycle on', () async {
    await profiles.ensureDefault(name: 'Me', now: now);
    await profiles.ensureDefault(name: 'Renamed', now: now);
    final list = await profiles.all();
    expect(list, hasLength(1));
    expect(list.single.name, 'Me');
    expect(list.single.cycleEnabled, isTrue);
    expect(list.single.periodStartMetricId, seedIds['period-start']);
  });

  test('another profile\'s markers are its own', () async {
    await profiles.save(
      Profile(id: kid, name: 'Kid', createdAt: now),
      now: now,
    );
    for (final m in starterMarkers(
      profileId: kid,
      createdAt: now,
      newId: _ids(),
    )) {
      await metrics.save(m, now: now);
    }

    final mine = await metrics.all(profileId: defaultProfileId);
    final theirs = await metrics.all(profileId: kid);
    expect(mine.map((m) => m.id).toSet().intersection(
          theirs.map((m) => m.id).toSet(),
        ), isEmpty);
    expect(theirs.any((m) => m.domain == MetricDomain.cycle), isFalse);
  });

  test('deleting a profile hides its markers and nobody else\'s', () async {
    await profiles.ensureDefault(name: 'Me', now: now);
    await profiles.save(
      Profile(id: kid, name: 'Kid', createdAt: now),
      now: now,
    );
    for (final m in starterMarkers(
      profileId: kid,
      createdAt: now,
      newId: _ids(),
    )) {
      await metrics.save(m, now: now);
    }

    await profiles.softDelete(kid, now: now);

    expect((await profiles.all()).map((p) => p.id), [defaultProfileId]);
    expect(await metrics.all(profileId: kid), isEmpty);
    expect(await metrics.all(profileId: defaultProfileId),
        hasLength(seedIds.length));
  });

  test('profiles and their markers survive a backup round trip', () async {
    await profiles.ensureDefault(name: 'Me', now: now);
    await profiles.save(
      Profile(id: kid, name: 'Kid', createdAt: now),
      now: now,
    );
    await metrics.save(
      Metric.create(
        id: '018f2c00-ffff-7000-8000-000000000001',
        profileId: kid,
        name: 'sleep',
        domain: MetricDomain.body,
        kind: MetricKind.scale,
        createdAt: now,
        lowLabel: 'bad',
        highLabel: 'good',
      ),
      now: now,
    );

    final exported = await PatternsBackup(db).export(
      appVersion: '0.1.0',
      installId: install,
      exportedAtMillis: now.millisecondsSinceEpoch,
      timezone: 'Europe/Belgrade',
      dayBoundaryHour: 4,
      readPhoto: (_) async => null,
    );

    final restored = PatternsDatabase(NativeDatabase.memory());
    final result = await PatternsBackup(restored).import(
      exported.bytes,
      writePhoto: (_, __) async {},
    );
    expect(result.error, isNull);

    final restoredProfiles = await ProfileRepository(restored, installId: install).all();
    expect(restoredProfiles.map((p) => p.name), containsAll(['Me', 'Kid']));
    final kidMarkers = await MetricRepository(restored, installId: install)
        .all(profileId: kid);
    expect(kidMarkers.single.name, 'sleep');
    await restored.close();
  });
}

String Function() _ids() {
  var n = 0;
  return () => '018f2c00-eeee-7000-8000-${(n++).toString().padLeft(12, '0')}';
}
