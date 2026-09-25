/// Where an ad was asked for. Kept as a closed set so a new placement is a
/// deliberate decision rather than a string typed at a call site.
enum AdPlacement {
  /// A strip pinned under a screen that is being read, not acted on.
  banner,

  /// Full screen, between two things the user was doing anyway.
  interstitial,
}

/// The state the policy reasons over. Held by the caller and persisted by it,
/// so the rules stay pure and testable without a clock or a database.
final class AdSession {
  const AdSession({
    required this.sessionCount,
    this.interstitialsShown = 0,
    this.lastInterstitialAt,
    this.coldStartAt,
  });

  /// How many times the app has been opened, this one included. **1 on a first
  /// ever launch**, which is the session that must stay free of ads.
  final int sessionCount;

  final int interstitialsShown;
  final DateTime? lastInterstitialAt;

  /// When this session began. Used for the cold-start rule.
  final DateTime? coldStartAt;

  AdSession recordInterstitial(DateTime at) => AdSession(
        sessionCount: sessionCount,
        interstitialsShown: interstitialsShown + 1,
        lastInterstitialAt: at,
        coldStartAt: coldStartAt,
      );
}

/// Why an ad was refused. The caller does not need this to work, but a refusal
/// that cannot be explained is a refusal nobody can debug.
enum AdRefusal {
  /// `MONETIZATION.md` rule 6: a paying user sees no ads, ever.
  isPro,

  /// Rule 1: nothing in the first session.
  firstSession,

  /// Rule 2: the core action has not happened yet.
  coreActionIncomplete,

  /// Rule 5: consent has not resolved, so no SDK may even initialise.
  noConsent,

  /// Rule 3, the per-session ceiling.
  interstitialCapReached,

  /// Rule 3, the spacing between two interstitials.
  tooSoon,

  /// Rule 3: never on cold start.
  coldStart,

  /// Rule 4: a timer is running or a text field is focused.
  screenBusy,

  /// The app is not the thing on screen.
  ///
  /// AdMob treats a full screen ad shown from the background as a policy
  /// violation and blocks serving for it, and it is indefensible anyway: the
  /// user is somewhere else, and the ad lands on top of whatever they were
  /// actually doing.
  appBackgrounded,
}

/// The caps from `MONETIZATION.md`. Defaults are the spec; they are constructor
/// arguments so Remote Config can lower them on a live app without a release.
final class AdCaps {
  const AdCaps({
    this.interstitialSpacing = const Duration(seconds: 180),
    this.interstitialsPerSession = 3,
    this.coldStartGrace = const Duration(seconds: 30),
  });

  final Duration interstitialSpacing;
  final int interstitialsPerSession;

  /// How long after launch counts as "cold start" for rule 3.
  final Duration coldStartGrace;
}

/// The answer to "may I show an ad here, now".
///
/// **This is the whole business logic of `vitals_ads`.** It is deliberately
/// separate from the SDK: the rules are the part that gets an app removed from
/// the store when they are wrong, and they must be testable without a network,
/// a device, or an AdMob account.
final class AdPolicy {
  const AdPolicy({this.caps = const AdCaps()});

  final AdCaps caps;

  /// Null when the ad is allowed, otherwise why it is not.
  AdRefusal? refuse({
    required AdPlacement placement,
    required AdSession session,
    required DateTime now,
    required bool isPro,
    required bool hasConsent,
    required bool coreActionComplete,
    bool screenBusy = false,
    bool appForegrounded = true,
  }) {
    // Order matters: the first three are absolute and are checked before
    // anything that could be tuned, so a misconfigured cap can never let an
    // ad through to a paying user or a first-run user.
    if (isPro) return AdRefusal.isPro;
    if (!hasConsent) return AdRefusal.noConsent;
    if (session.sessionCount <= 1) return AdRefusal.firstSession;
    if (!coreActionComplete) return AdRefusal.coreActionIncomplete;
    if (screenBusy) return AdRefusal.screenBusy;
    if (!appForegrounded) return AdRefusal.appBackgrounded;

    if (placement == AdPlacement.banner) return null;

    final coldStartAt = session.coldStartAt;
    if (coldStartAt != null &&
        now.difference(coldStartAt) < caps.coldStartGrace) {
      return AdRefusal.coldStart;
    }
    if (session.interstitialsShown >= caps.interstitialsPerSession) {
      return AdRefusal.interstitialCapReached;
    }
    final last = session.lastInterstitialAt;
    if (last != null && now.difference(last) < caps.interstitialSpacing) {
      return AdRefusal.tooSoon;
    }
    return null;
  }

  /// Whether it is worth fetching an interstitial ahead of time.
  ///
  /// Only the absolute rules apply. The caps are about *when* an ad may be
  /// shown, and an ad has to be in hand before that moment arrives - waiting
  /// for the spacing to elapse and only then asking means the first eligible
  /// break point always passes with nothing loaded.
  ///
  /// The absolute rules do apply, and that is the point: a request that could
  /// never become an impression costs bandwidth and lowers the match rate the
  /// network judges the app by.
  bool mayPreload({
    required AdSession session,
    required bool isPro,
    required bool hasConsent,
    required bool coreActionComplete,
  }) =>
      !isPro &&
      hasConsent &&
      session.sessionCount > 1 &&
      coreActionComplete;

  bool allows({
    required AdPlacement placement,
    required AdSession session,
    required DateTime now,
    required bool isPro,
    required bool hasConsent,
    required bool coreActionComplete,
    bool screenBusy = false,
    bool appForegrounded = true,
  }) =>
      refuse(
        placement: placement,
        session: session,
        now: now,
        isPro: isPro,
        hasConsent: hasConsent,
        coreActionComplete: coreActionComplete,
        screenBusy: screenBusy,
        appForegrounded: appForegrounded,
      ) ==
      null;
}
