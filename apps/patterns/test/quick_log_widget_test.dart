import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/app_database.dart';
import 'package:patterns/data/evening_reminder.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/data/quick_log_widget.dart';
import 'package:patterns/screens/home_screen.dart';
import 'package:patterns/screens/settings_screen.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_notify/vitals_notify.dart';
import 'package:vitals_ui/vitals_ui.dart';

final class FakeQuickLog implements QuickLogWidget {
  final published = <List<Metric>>[];
  final _taps = StreamController<String>.broadcast();
  String? launched;

  void tap(String id) => _taps.add(id);

  @override
  Future<void> publish(List<Metric> markers, {required String emptyText}) async =>
      published.add(markers);

  @override
  Future<String?> launchedFor() async => launched;

  @override
  Stream<String> get taps => _taps.stream;
}

Future<PatternsController> freshController() async {
  final controller = PatternsController(
    db: PatternsDatabase(NativeDatabase.memory()),
    installId: '018f2c00-aaaa-7000-8000-000000000001',
    dayBoundaryHour: 4,
  );
  await controller.seedIfNeeded();
  return controller;
}

Widget wrap(Widget child) => MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: child,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('only tideline://log/<id> links name a marker', () {
    expect(markerIdFromLink(Uri.parse('tideline://log/abc')), 'abc');
    expect(markerIdFromLink(Uri.parse('tideline://log')), isNull);
    expect(markerIdFromLink(Uri.parse('https://log/abc')), isNull);
    expect(markerIdFromLink(null), isNull);
  });

  testWidgets('publishes the first four home markers, and names only',
      (tester) async {
    final controller = await freshController();
    final quickLog = FakeQuickLog();
    await tester.pumpWidget(
        wrap(HomeScreen(controller: controller, quickLog: quickLog)));
    await tester.pumpAndSettle();

    expect(quickLog.published, hasLength(1));
    expect(quickLog.published.single.map((m) => m.name),
        ['mood', 'tiredness', 'motivation', 'irritability']);

    // Logging changes nothing the widget shows, so nothing is re-sent.
    await controller.log(
        seedIds['mood']!, const NumberValue(3, kind: MetricKind.scale));
    await tester.pumpAndSettle();
    expect(quickLog.published, hasLength(1));
    controller.dispose();
  });

  testWidgets('a tap opens that marker\'s log sheet', (tester) async {
    final controller = await freshController();
    final quickLog = FakeQuickLog();
    await tester.pumpWidget(
        wrap(HomeScreen(controller: controller, quickLog: quickLog)));
    await tester.pumpAndSettle();

    quickLog.tap(seedIds['creatine-dose']!);
    await tester.pumpAndSettle();
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('g'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('a cold start from the widget opens the sheet too',
      (tester) async {
    final controller = await freshController();
    final quickLog = FakeQuickLog()..launched = seedIds['tiredness'];
    await tester.pumpWidget(
        wrap(HomeScreen(controller: controller, quickLog: quickLog)));
    await tester.pumpAndSettle();
    expect(find.text('Log'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('the choice is made in Settings, four at most', (tester) async {
    final controller = await freshController();
    var changed = 0;
    await tester.pumpWidget(wrap(SettingsScreen(
      reminder: EveningReminder(RecordingNotifier()),
      settings: ReminderSettings.off,
      controller: controller,
      quickLog: FakeQuickLog(),
      onWidgetMarkersChanged: () => changed++,
    )));
    await tester.pumpAndSettle();

    // Four already picked, so a fifth is not offered until one goes.
    final bloating = find.widgetWithText(CheckboxListTile, 'bloating');
    await tester.scrollUntilVisible(bloating, 120,
        scrollable: find.byType(Scrollable).first);
    expect(tester.widget<CheckboxListTile>(bloating).onChanged, isNull);

    final mood = find.widgetWithText(CheckboxListTile, 'mood');
    await tester.scrollUntilVisible(mood, -120,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(mood);
    await tester.pumpAndSettle();
    await tester.tap(mood);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(bloating, 120,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(bloating);
    await tester.pumpAndSettle();
    await tester.tap(bloating);
    await tester.pumpAndSettle();

    final saved = await WidgetMarkers.load(controller.homeOrder);
    expect(saved.map((m) => m.name),
        ['tiredness', 'motivation', 'irritability', 'bloating']);
    expect(changed, 2);
    controller.dispose();
  });
}
