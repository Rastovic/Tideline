import 'package:flutter_test/flutter_test.dart';
import 'package:vitals_ads/vitals_ads.dart';

void main() {
  final now = DateTime(2026, 9, 6, 12);
  const policy = AdPolicy();

  AdRefusal? refuse({
    AdPlacement placement = AdPlacement.interstitial,
    AdSession? session,
    bool isPro = false,
    bool hasConsent = true,
    bool coreActionComplete = true,
    bool screenBusy = false,
    bool appForegrounded = true,
    DateTime? at,
  }) =>
      policy.refuse(
        placement: placement,
        session: session ?? const AdSession(sessionCount: 5),
        now: at ?? now,
        isPro: isPro,
        hasConsent: hasConsent,
        coreActionComplete: coreActionComplete,
        screenBusy: screenBusy,
        appForegrounded: appForegrounded,
      );

  group('the absolute rules', () {
    test('a paying user is refused before anything else is considered', () {
      // Even a request that is wrong in several other ways must come back as
      // isPro: this is the check that turns into a refund when it is missed.
      expect(
        refuse(isPro: true, hasConsent: false, coreActionComplete: false),
        AdRefusal.isPro,
      );
      expect(
        refuse(placement: AdPlacement.banner, isPro: true),
        AdRefusal.isPro,
      );
    });

    test('no ad of any kind without consent', () {
      expect(refuse(hasConsent: false), AdRefusal.noConsent);
      expect(
        refuse(placement: AdPlacement.banner, hasConsent: false),
        AdRefusal.noConsent,
      );
    });

    test('the first session is free of ads', () {
      expect(
        refuse(session: const AdSession(sessionCount: 1)),
        AdRefusal.firstSession,
      );
      expect(
        refuse(
          placement: AdPlacement.banner,
          session: const AdSession(sessionCount: 1),
        ),
        AdRefusal.firstSession,
      );
    });

    test('nothing before the core action has completed', () {
      expect(refuse(coreActionComplete: false), AdRefusal.coreActionIncomplete);
    });

    test('nothing at all while the app is in the background', () {
      // A countdown that keeps running after the user leaves can reach an ad
      // call from the background. AdMob blocks serving for that, and the ad
      // lands on top of whatever the user actually switched to.
      expect(refuse(appForegrounded: false), AdRefusal.appBackgrounded);
      expect(
        refuse(placement: AdPlacement.banner, appForegrounded: false),
        AdRefusal.appBackgrounded,
      );
    });

    test('no banner on a screen with a timer or a text field', () {
      expect(
        refuse(placement: AdPlacement.banner, screenBusy: true),
        AdRefusal.screenBusy,
      );
    });
  });

  group('interstitial caps', () {
    test('never during the cold-start grace window', () {
      expect(
        refuse(
          session: AdSession(sessionCount: 5, coldStartAt: now),
          at: now.add(const Duration(seconds: 29)),
        ),
        AdRefusal.coldStart,
      );
      expect(
        refuse(
          session: AdSession(sessionCount: 5, coldStartAt: now),
          at: now.add(const Duration(seconds: 31)),
        ),
        isNull,
      );
    });

    test('three per session and no more', () {
      expect(
        refuse(session: const AdSession(sessionCount: 5, interstitialsShown: 2)),
        isNull,
      );
      expect(
        refuse(session: const AdSession(sessionCount: 5, interstitialsShown: 3)),
        AdRefusal.interstitialCapReached,
      );
    });

    test('180 seconds between two of them', () {
      final session = AdSession(
        sessionCount: 5,
        interstitialsShown: 1,
        lastInterstitialAt: now,
      );
      expect(
        refuse(session: session, at: now.add(const Duration(seconds: 179))),
        AdRefusal.tooSoon,
      );
      expect(
        refuse(session: session, at: now.add(const Duration(seconds: 180))),
        isNull,
      );
    });

    test('recording one advances both the count and the clock', () {
      const before = AdSession(sessionCount: 5);
      final after = before.recordInterstitial(now);

      expect(after.interstitialsShown, 1);
      expect(after.lastInterstitialAt, now);
      expect(after.sessionCount, 5, reason: 'the session itself is unchanged');
    });
  });

  group('banners', () {
    test('are not subject to the interstitial caps', () {
      // A banner is a strip on a page being read, not an interruption, so
      // spacing and per-session ceilings do not apply to it.
      expect(
        refuse(
          placement: AdPlacement.banner,
          session: AdSession(
            sessionCount: 5,
            interstitialsShown: 9,
            lastInterstitialAt: now,
            coldStartAt: now,
          ),
        ),
        isNull,
      );
    });
  });

  group('preloading', () {
    bool mayPreload({
      AdSession? session,
      bool isPro = false,
      bool hasConsent = true,
      bool coreActionComplete = true,
    }) =>
        policy.mayPreload(
          session: session ?? const AdSession(sessionCount: 5),
          isPro: isPro,
          hasConsent: hasConsent,
          coreActionComplete: coreActionComplete,
        );

    test('nothing is fetched for a user who could not be shown one', () {
      expect(mayPreload(isPro: true), isFalse);
      expect(mayPreload(hasConsent: false), isFalse);
      expect(mayPreload(session: const AdSession(sessionCount: 1)), isFalse);
      expect(mayPreload(coreActionComplete: false), isFalse);
    });

    test('the caps do not hold a preload back', () {
      // The ad has to be in hand *before* the spacing elapses, or the first
      // eligible break point always passes with nothing loaded.
      expect(
        mayPreload(
          session: AdSession(
            sessionCount: 5,
            interstitialsShown: 3,
            lastInterstitialAt: now,
            coldStartAt: now,
          ),
        ),
        isTrue,
      );
    });
  });

  test('allows mirrors refuse', () {
    expect(
      policy.allows(
        placement: AdPlacement.interstitial,
        session: const AdSession(sessionCount: 1),
        now: now,
        isPro: false,
        hasConsent: true,
        coreActionComplete: true,
      ),
      isFalse,
    );
  });

  test('NoAds answers nothing to everything', () async {
    const gateway = NoAds();
    await gateway.initialise();

    expect(gateway.hasConsent, isFalse);
    await gateway.prepareInterstitial();

    expect(gateway.banner(width: 400), isNull);
    expect(await gateway.showInterstitial(), isFalse);
  });

  test('the default units are Google test ids, which cannot earn', () {
    expect(const AdUnits().isTest, isTrue);
  });
}
