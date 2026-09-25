import 'package:flutter/widgets.dart';

import 'ad_policy.dart';

/// The ad unit ids for one app, per placement.
///
/// **The test ids are the default on purpose.** They are Google's own, they
/// serve real ads, they need no AdMob account, and they can never earn or be
/// flagged as invalid traffic. A build that forgets to pass real ids therefore
/// shows working ads that bill nobody, rather than crashing or quietly
/// showing nothing.
final class AdUnits {
  const AdUnits({
    this.banner = testBanner,
    this.interstitial = testInterstitial,
  });

  static const testBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  /// The AdMob application id that goes in the Android manifest. Test value,
  /// swapped for the real one when the AdMob account exists.
  static const testApplicationId = 'ca-app-pub-3940256099942544~3347511713';

  final String banner;
  final String interstitial;

  bool get isTest => banner == testBanner && interstitial == testInterstitial;
}

/// The platform surface for ads.
///
/// `CROSS-PLATFORM.md` rule 2: the SDK sits behind an interface, so the ad
/// network is swappable and every test runs without one. Rule 3: it is shaped
/// around the question the app asks ("is there a banner to put here") rather
/// than around `google_mobile_ads`.
abstract interface class AdGateway {
  /// Resolves consent and starts the SDK. **Must complete before any ad is
  /// requested** - `MONETIZATION.md` rule 5.
  Future<void> initialise();

  /// Whether consent has resolved and ads may be requested at all.
  bool get hasConsent;

  /// Whether this user has to be offered a way back into the consent form.
  ///
  /// True where UMP says so (the EEA, the UK, Switzerland). Google's consent
  /// policy requires the entry point there, and only there.
  bool get privacyOptionsRequired;

  /// Re-opens the consent form, so a choice made once can be changed. Consent
  /// is re-read afterwards: a withdrawal stops ads from the next request.
  Future<void> showPrivacyOptions();

  /// A banner sized for [width], or null when policy or loading says no.
  ///
  /// Returning a widget rather than an ad object keeps the SDK's types out of
  /// the app, and lets [NoAds] answer null without importing anything.
  Widget? banner({required double width});

  /// Fetches an interstitial so one is in hand when a break point arrives.
  ///
  /// Separate from [initialise] because eligibility is the caller's to judge:
  /// the gateway does not know whether the user has reached the core action,
  /// and an ad fetched for someone who cannot be shown one is a request the
  /// network counts against the app.
  Future<void> prepareInterstitial();

  /// Shows a full-screen ad if one is loaded and [AdPolicy] allows it.
  ///
  /// Returns whether one was actually shown, so the caller can record it
  /// against the session cap. **Never blocks the user**: a missing or failed
  /// ad returns false and the app carries on.
  Future<bool> showInterstitial();

  /// Releases native ad objects. Called when the owner is disposed.
  void dispose();
}

/// The implementation for every case where ads must not appear: a paying user,
/// a platform with no SDK, a test, the web preview.
///
/// **This is the default.** Ads are the exception that has to be wired in, not
/// the baseline that has to be switched off.
final class NoAds implements AdGateway {
  const NoAds();

  @override
  Future<void> initialise() async {}

  @override
  bool get hasConsent => false;

  @override
  bool get privacyOptionsRequired => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<void> prepareInterstitial() async {}

  @override
  Widget? banner({required double width}) => null;

  @override
  Future<bool> showInterstitial() async => false;

  @override
  void dispose() {}
}
