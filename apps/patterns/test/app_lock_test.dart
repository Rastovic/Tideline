import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/data/app_lock.dart';
import 'package:patterns/screens/app_lock_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_ui/vitals_ui.dart';

final class FakeUnlocker implements Unlocker {
  FakeUnlocker({this.available = true, this.answer = true});

  bool available;
  bool answer;
  int asked = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> unlock({required String reason}) async {
    asked++;
    return answer;
  }
}

Widget gated(AppLock lock) => MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      builder: (context, child) => AppLockGate(lock: lock, child: child!),
      home: const Scaffold(body: Text('tajni dnevnik')),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('on by default, and locked from the start', () async {
    final lock = AppLock(unlocker: FakeUnlocker());
    await lock.load();
    expect(lock.enabled, isTrue);
    expect(lock.locked, isTrue);
  });

  test('a phone with no screen lock never locks the app shut', () async {
    final lock = AppLock(unlocker: FakeUnlocker(available: false));
    await lock.load();
    expect(lock.locked, isFalse);
  });

  test('a minute away locks again; a quick switch does not', () async {
    var now = DateTime(2026, 9, 17, 10);
    final lock = AppLock(unlocker: FakeUnlocker(), clock: () => now);
    await lock.load();
    await lock.tryUnlock();

    lock.wentToBackground();
    now = now.add(const Duration(seconds: 20));
    lock.cameBack();
    expect(lock.locked, isFalse);

    lock.wentToBackground();
    now = now.add(const Duration(minutes: 2));
    lock.cameBack();
    expect(lock.locked, isTrue);
  });

  test('switching it off needs an unlock', () async {
    final unlocker = FakeUnlocker(answer: false);
    final lock = AppLock(unlocker: unlocker);
    await lock.load();

    expect(await lock.setEnabled(false), isFalse);
    expect(lock.enabled, isTrue);

    unlocker.answer = true;
    expect(await lock.setEnabled(false), isTrue);
    final again = AppLock(unlocker: unlocker);
    await again.load();
    expect(again.enabled, isFalse);
    expect(again.locked, isFalse);
  });

  testWidgets('nothing underneath is seen or read out while locked',
      (tester) async {
    final unlocker = FakeUnlocker(answer: false);
    final lock = AppLock(unlocker: unlocker);
    await lock.load();
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(gated(lock));
    await tester.pumpAndSettle();

    expect(find.text('Tideline is locked'), findsOneWidget);
    expect(find.bySemanticsLabel('tajni dnevnik'), findsNothing);
    // Asked once on its own, and a refusal does not start a loop.
    expect(unlocker.asked, 1);

    unlocker.answer = true;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Tideline is locked'), findsNothing);
    expect(find.text('tajni dnevnik'), findsOneWidget);
    semantics.dispose();
  });
}
