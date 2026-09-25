import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/app/patterns_app.dart';
import 'package:patterns/data/ads.dart';
import 'package:patterns/data/app_database.dart';
import 'package:patterns/data/evening_reminder.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/l10n/app_language.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_ads/vitals_ads.dart';
import 'package:vitals_notify/vitals_notify.dart';

/// A gateway that always has a banner, so the test sees where one is drawn.
final class FakeAds implements AdGateway {
  @override
  Future<void> initialise() async {}

  @override
  bool get hasConsent => true;

  @override
  bool get privacyOptionsRequired => true;

  int privacyOptionsShown = 0;

  @override
  Future<void> showPrivacyOptions() async => privacyOptionsShown++;

  @override
  Widget? banner({required double width}) =>
      const SizedBox(key: Key('banner'), height: 50);

  @override
  Future<void> prepareInterstitial() async {}

  @override
  Future<bool> showInterstitial() async => false;

  @override
  void dispose() {}
}

Future<(PatternsController, AdsController)> setUpApp(
  WidgetTester tester, {
  required Map<String, Object> prefs,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final controller = PatternsController(
    db: PatternsDatabase(NativeDatabase.memory()),
    installId: '018f2c00-aaaa-7000-8000-000000000001',
    dayBoundaryHour: 4,
  );
  final ads = AdsController(gateway: FakeAds());
  await tester.runAsync(() async {
    await controller.seedIfNeeded();
    await ads.start();
  });
  await tester.pumpWidget(
    PatternsApp(
      controller: controller,
      reminder: EveningReminder(RecordingNotifier()),
      settings: ReminderSettings.off,
      language: ValueNotifier(AppLanguage.en),
      ads: ads,
    ),
  );
  await tester.pumpAndSettle();
  return (controller, ads);
}

void main() {
  testWidgets('a banner under Settings and the markers, never on home', (
    tester,
  ) async {
    final (controller, _) = await setUpApp(
      tester,
      prefs: {'ads.sessionCount': 4, 'ads.coreActionDone': true},
    );
    expect(find.byKey(const Key('banner')), findsNothing);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('banner')), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Markers'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('banner')), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Screens with entries on them never carry one.
    await tester.tap(find.byTooltip('Reports'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('banner')), findsNothing);
    controller.dispose();
  });

  testWidgets('no banner in the first session, even under Settings', (
    tester,
  ) async {
    final (controller, _) = await setUpApp(tester, prefs: {});
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('banner')), findsNothing);
    controller.dispose();
  });

  testWidgets('no banner before she has logged anything herself', (
    tester,
  ) async {
    final (controller, ads) = await setUpApp(
      tester,
      prefs: {'ads.sessionCount': 4},
    );
    expect(ads.bannerAllowed(), isFalse);
    await tester.runAsync(ads.markCoreAction);
    expect(ads.bannerAllowed(), isTrue);
    controller.dispose();
  });

  testWidgets('privacy choices in Settings re-open the consent form', (
    tester,
  ) async {
    final (controller, ads) = await setUpApp(tester, prefs: {});
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Privacy choices'), 200);
    await tester.ensureVisible(find.text('Privacy choices'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy choices'));
    await tester.pumpAndSettle();
    expect((ads.gateway as FakeAds).privacyOptionsShown, 1);
    controller.dispose();
  });
}
