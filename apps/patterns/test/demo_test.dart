import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/demo_data.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_core/vitals_core.dart';

Future<PatternsController> freshController() async {
  final controller = PatternsController(
    db: PatternsDatabase(NativeDatabase.memory()),
    installId: '018f2c00-aaaa-7000-8000-000000000001',
    dayBoundaryHour: 4,
  );
  await controller.seedIfNeeded();
  return controller;
}

const names = (
  moodAndTiredness: 'Mood and tiredness',
  trainingAndMood: 'Training and mood',
  byCycleDay: 'Through the cycle',
  weeklyRhythm: 'Weekly rhythm',
);

void main() {
  test('the generator is the same every time for a seed', () {
    final markers = starterMarkers(
      profileId: 'p',
      createdAt: DateTime.utc(2026),
      newId: () => Ids.newId(),
    );
    List<String> run() => [
          for (final r in demoReadings(
            markers: markers,
            today: '2026-09-18',
            periodStartId: 's',
            periodEndId: 'e',
          ))
            '${r.dayKey}|${markers.firstWhere((m) => m.id == r.metricId, orElse: () => markers.first).name}|${r.value}',
        ];
    expect(run(), run());
  });

  test('the demo lands in its own profile and nowhere else', () async {
    final controller = await freshController();
    await controller.log(
        seedIds['mood']!, const NumberValue(8, kind: MetricKind.scale));

    final demo = await controller.createDemoProfile(
      name: 'Demo',
      reportNames: names,
      days: 60,
    );
    expect(controller.activeProfileId, demo.id);
    expect(controller.cycleEnabled, isTrue);

    final reports = await controller.savedReports();
    expect(reports.map((r) => r.name), [
      'Mood and tiredness',
      'Training and mood',
      'Through the cycle',
      'Weekly rhythm',
    ]);

    // Every report has rows with real data behind them.
    for (final report in reports) {
      final built = await controller.buildSavedReport(report);
      expect(built.rows, isNotEmpty, reason: report.name);
      expect(
        built.rows.any((row) => row.stats.daysLogged > 0),
        isTrue,
        reason: report.name,
      );
    }
    // A recorded cycle, so the cycle-day report folds something.
    expect(await controller.cyclePeriods(), isNotEmpty);

    // The original profile is untouched: one reading, today.
    await controller.switchProfile(defaultProfileId);
    expect(await controller.readingsOn(controller.today), hasLength(1));
    expect(await controller.savedReports(), isEmpty);

    // And deleting the demo leaves nothing of it showing.
    await controller.deleteProfile(demo.id);
    expect(controller.profileList, hasLength(1));
    controller.dispose();
  });

  test('the Sunday dip is there to be found', () async {
    final controller = await freshController();
    await controller.createDemoProfile(name: 'Demo', reportNames: names);
    final mood = controller.allMarkers.firstWhere((m) => m.name == 'mood');
    final readings = await controller.observations.range(
      metricIds: [mood.id],
      from: addDays(controller.today, -119),
      to: controller.today,
      kinds: controller.kinds,
    );
    double average(bool Function(int weekday) pick) {
      final values = [
        for (final r in readings)
          if (pick(parseDayKey(r.dayKey)!.weekday))
            (r.value as NumberValue).number,
      ];
      return values.reduce((a, b) => a + b) / values.length;
    }

    expect(
      average((d) => d == DateTime.sunday),
      lessThan(average((d) => d != DateTime.sunday) - 0.8),
    );
    controller.dispose();
  });
}
