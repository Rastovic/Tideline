import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/screens/home_screen.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

Future<PatternsController> freshController() async {
  final controller = PatternsController(
    db: PatternsDatabase(NativeDatabase.memory()),
    installId: '018f2c00-aaaa-7000-8000-000000000001',
    dayBoundaryHour: 4,
  );
  await controller.seedIfNeeded();
  return controller;
}

Widget wrap(PatternsController controller) => MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: HomeScreen(controller: controller),
    );

Future<void> openCard(WidgetTester tester, PatternsController controller) async {
  await tester.pumpWidget(wrap(controller));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('CYCLE'), 120);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with nothing recorded it says so, and offers no end',
      (tester) async {
    final controller = await freshController();
    await openCard(tester, controller);

    expect(find.text('No cycle day'), findsOneWidget);
    expect(find.textContaining('Nothing recorded yet'), findsOneWidget);
    // The two marker rows are gone: the card is what replaces them.
    expect(find.text('period start'), findsNothing);
    expect(find.text('period end'), findsNothing);
    // Nothing is open, so there is nothing to end.
    expect(
      tester
          .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Period ended'))
          .onPressed,
      isNull,
    );
    controller.dispose();
  });

  testWidgets('logging a start from the card counts from that day',
      (tester) async {
    final controller = await freshController();
    await openCard(tester, controller);

    await tester.tap(find.text('Period started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yesterday'));
    await tester.pumpAndSettle();

    // Yesterday is day 1, so today is day 2.
    expect(find.text('Day 2'), findsOneWidget);
    expect(find.textContaining('bleeding, day 2'), findsOneWidget);

    final yesterday = addDays(controller.today, -1);
    final readings = await controller.readingsOn(yesterday);
    expect(readings.single.value, const BooleanValue(true));
    expect(await controller.readingsOn(controller.today), isEmpty);
    controller.dispose();
  });

  testWidgets('an ended period reports its length, and completed cycles',
      (tester) async {
    final controller = await freshController();
    final today = controller.today;
    for (final (start, day) in [
      (true, addDays(today, -60)),
      (false, addDays(today, -56)),
      (true, addDays(today, -31)),
      (false, addDays(today, -27)),
      (true, addDays(today, -3)),
      (false, addDays(today, -1)),
    ]) {
      await controller.logPeriod(start: start, dayKey: day);
    }

    await openCard(tester, controller);

    expect(find.text('Day 4'), findsOneWidget);
    expect(find.textContaining('3 days of bleeding'), findsOneWidget);
    // 60 to 31 days ago is 29, 31 to 3 days ago is 28. The current stretch
    // has no next start and is not a length.
    expect(find.text('Cycles: 29, 28'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('a start older than the counting limit stops counting',
      (tester) async {
    final controller = await freshController();
    await controller.logPeriod(
      start: true,
      dayKey: addDays(controller.today, -90),
    );
    await openCard(tester, controller);

    expect(find.text('No cycle day'), findsOneWidget);
    expect(find.textContaining('too far back'), findsOneWidget);
    controller.dispose();
  });
}
