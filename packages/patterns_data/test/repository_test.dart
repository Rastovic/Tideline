import 'package:drift/native.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:test/test.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';
final now = DateTime.utc(2026, 8, 19, 10);

void main() {
  late PatternsDatabase db;
  late MetricRepository metrics;
  late ObservationRepository readings;

  setUp(() async {
    db = PatternsDatabase(NativeDatabase.memory());
    metrics = MetricRepository(db, installId: install);
    readings = ObservationRepository(db, installId: install);
    await metrics.seedIfEmpty(now: now);
  });
  tearDown(() => db.close());

  Future<Map<String, MetricKind>> kinds() async {
    final all = await metrics.all();
    return {for (final m in all) m.id: m.kind};
  }

  group('seeding', () {
    test('writes the starting markers once', () async {
      final all = await metrics.all();
      expect(all, hasLength(18));
      expect(await metrics.seedIfEmpty(now: now), isFalse);
      expect(await metrics.all(), hasLength(18));
    });

    test('a marker deleted on purpose does not come back', () async {
      await metrics.softDelete(seedIds['creatine']!, now: now);
      await metrics.seedIfEmpty(now: now);
      final ids = (await metrics.all()).map((m) => m.id);
      expect(ids, isNot(contains(seedIds['creatine'])));
    });

    test('options survive the round trip with their ids', () async {
      final feelings = await metrics.byId(seedIds['feelings']!);
      expect(feelings!.options.map((o) => o.id),
          contains(seedOptionIds['feelings.overthink']));
      expect(feelings.liveOptions, hasLength(8));
    });

    test('a marker comes back exactly as it went in', () async {
      final bloating = await metrics.byId(seedIds['bloating']!);
      expect(bloating!.kind, MetricKind.scale);
      expect(bloating.aggregation, DayAggregation.peak);
      expect(bloating.displayStyle, DisplayStyle.squares);
      expect(bloating.colorHex, '#E2711D');
      expect(bloating.lowLabel, 'nista');
    });
  });

  group('recording', () {
    test('a day holds as many readings as it needs', () async {
      await readings.log(
        metricId: seedIds['creatine-dose']!,
        value: const NumberValue(3, kind: MetricKind.amount),
        at: DateTime.utc(2026, 8, 19, 7),
        utcOffsetMinutes: 120,
      );
      await readings.log(
        metricId: seedIds['creatine-dose']!,
        value: const NumberValue(2, kind: MetricKind.amount),
        at: DateTime.utc(2026, 8, 19, 19),
        utcOffsetMinutes: 120,
      );

      final dose = await metrics.byId(seedIds['creatine-dose']!);
      final rows = await readings.range(
        metricIds: [seedIds['creatine-dose']!],
        from: '2026-08-19',
        to: '2026-08-19',
        kinds: await kinds(),
      );
      expect(rows, hasLength(2));

      final summaries = summariseDays(
        dose!,
        rows,
        from: '2026-08-19',
        to: '2026-08-19',
      );
      expect(summaries.single.value, 5);
    });

    test('every kind survives storage unchanged', () async {
      final samples = <String, MetricValue>{
        seedIds['mood']!: const NumberValue(7, kind: MetricKind.scale),
        seedIds['creatine']!: const BooleanValue(true),
        seedIds['feelings']!: TagsValue([seedOptionIds['feelings.tuga']!, seedOptionIds['feelings.overthink']!]),
        seedIds['diary']!: const TextValue('zbog posla'),
        seedIds['bedtime']!: const TimeOfDayValue(23 * 60 + 40),
        seedIds['creatine-dose']!: const NumberValue(5.5, kind: MetricKind.amount),
      };
      for (final entry in samples.entries) {
        await readings.log(
          metricId: entry.key,
          value: entry.value,
          at: DateTime.utc(2026, 8, 19, 20),
          utcOffsetMinutes: 120,
        );
      }
      final stored = await readings.onDay('2026-08-19', kinds: await kinds());
      for (final entry in samples.entries) {
        final row = stored.firstWhere((o) => o.metricId == entry.key);
        expect(row.value, entry.value, reason: entry.key);
      }
    });

    test('an empty tag set is stored as the answer it is', () async {
      await readings.log(
        metricId: seedIds['feelings']!,
        value: TagsValue(const []),
        at: DateTime.utc(2026, 8, 19, 20),
        utcOffsetMinutes: 120,
      );
      final stored = await readings.onDay('2026-08-19', kinds: await kinds());
      expect((stored.single.value as TagsValue).isExplicitNone, isTrue);
    });
  });

  group('the day boundary is frozen at write time', () {
    test('01:30 belongs to the day that just ended', () async {
      // Local 01:30 on 20 August, in UTC+2, with the 04:00 boundary.
      final observation = await readings.log(
        metricId: seedIds['mood']!,
        value: const NumberValue(4, kind: MetricKind.scale),
        at: DateTime.utc(2026, 8, 19, 23, 30),
        utcOffsetMinutes: 120,
      );
      expect(observation.dayKey, '2026-08-19');
    });

    test('05:00 opens the new day', () async {
      final observation = await readings.log(
        metricId: seedIds['mood']!,
        value: const NumberValue(4, kind: MetricKind.scale),
        at: DateTime.utc(2026, 8, 20, 3),
        utcOffsetMinutes: 120,
      );
      expect(observation.dayKey, '2026-08-20');
    });

    test('the same instant in another zone keeps its original day', () async {
      // Written in Belgrade, read after landing in Tokyo. The stored key does
      // not move, because it was never derived from the reader's clock.
      final observation = await readings.log(
        metricId: seedIds['mood']!,
        value: const NumberValue(4, kind: MetricKind.scale),
        at: DateTime.utc(2026, 8, 19, 22),
        utcOffsetMinutes: 120,
      );
      final stored = await readings.onDay('2026-08-19', kinds: await kinds());
      expect(stored.single.dayKey, observation.dayKey);
      expect(stored.single.utcOffsetMinutes, 120);
    });

    test('retro-filling picks the day and says so', () async {
      final observation = await readings.logForDay(
        metricId: seedIds['mood']!,
        value: const NumberValue(6, kind: MetricKind.scale),
        dayKey: '2026-08-15',
        now: now,
        utcOffsetMinutes: 120,
      );
      expect(observation.dayKey, '2026-08-15');
      expect(observation.enteredLate, isTrue);
    });
  });

  group('reading back', () {
    test('the home list gets counts, not values', () async {
      for (var hour = 8; hour < 11; hour++) {
        await readings.log(
          metricId: seedIds['bloating']!,
          value: NumberValue(hour - 5, kind: MetricKind.scale),
          at: DateTime.utc(2026, 8, 19, hour),
          utcOffsetMinutes: 120,
        );
      }
      final counts = await readings.countsOnDay('2026-08-19');
      expect(counts[seedIds['bloating']!], 3);
      expect(counts[seedIds['mood']!], isNull);
    });

    test('a soft-deleted reading disappears from reads and stays on disk',
        () async {
      final observation = await readings.log(
        metricId: seedIds['mood']!,
        value: const NumberValue(5, kind: MetricKind.scale),
        at: DateTime.utc(2026, 8, 19, 20),
        utcOffsetMinutes: 120,
      );
      await readings.softDelete(observation.id, now: now);
      expect(await readings.onDay('2026-08-19', kinds: await kinds()), isEmpty);
      final raw = await db.select(db.observations).get();
      expect(raw, hasLength(1));
      expect(raw.single.deletedAt, isNotNull);
    });

    test('deleting a marker leaves its readings alone', () async {
      await readings.log(
        metricId: seedIds['mood']!,
        value: const NumberValue(5, kind: MetricKind.scale),
        at: DateTime.utc(2026, 8, 19, 20),
        utcOffsetMinutes: 120,
      );
      await metrics.softDelete(seedIds['mood']!, now: now);
      final raw = await db.select(db.observations).get();
      expect(raw, hasLength(1), reason: 'a year of numbers must survive a tap');
    });

    test('archiving keeps the marker readable for old reports', () async {
      await metrics.archive(seedIds['creatine']!, now: now);
      expect((await metrics.all(includeArchived: false)).map((m) => m.id),
          isNot(contains(seedIds['creatine'])));
      expect((await metrics.all()).map((m) => m.id), contains(seedIds['creatine']));
    });
  });

  test('cycle days come out of ordinary boolean readings', () async {
    for (final day in ['2026-07-04', '2026-08-01']) {
      await readings.logForDay(
        metricId: seedIds['period-start']!,
        value: const BooleanValue(true),
        dayKey: day,
        now: now,
        utcOffsetMinutes: 120,
      );
    }
    await readings.logForDay(
      metricId: seedIds['period-end']!,
      value: const BooleanValue(true),
      dayKey: '2026-08-05',
      now: now,
      utcOffsetMinutes: 120,
    );

    final periods = buildPeriods(
      startDayKeys: await readings.trueDays(seedIds['period-start']!),
      endDayKeys: await readings.trueDays(seedIds['period-end']!),
    );
    expect(periods, hasLength(2));
    expect(cycleDayFor('2026-08-19', periods), 19);
    expect(periods.last.lengthDays, 5);
  });
}