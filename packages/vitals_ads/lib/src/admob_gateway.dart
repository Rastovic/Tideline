import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_gateway.dart';
import 'ad_slot.dart';

/// AdMob behind [AdGateway].
///
/// Everything `google_mobile_ads` is confined to this file. The app sees
/// widgets and futures; it never sees an `Ad`, and it never has to know that
/// a banner has to be disposed or that an interstitial is single-use.
final class AdMobGateway implements AdGateway, AdMobGatewayRebuilds {
  AdMobGateway({this.units = const AdUnits(), this.onDiagnostic});

  final AdUnits units;

  /// Called with a one-line reason whenever an ad fails. Wired to a logger in
  /// debug and to nothing in release: ad failures are normal traffic, not
  /// errors, and must never surface to the user.
  final void Function(String message)? onDiagnostic;

  bool _consent = false;
  bool _started = false;

  BannerAd? _banner;
  bool _bannerLoaded = false;
  double? _bannerWidth;

  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;

  @override
  bool get hasConsent => _consent;

  bool _privacyOptionsRequired = false;

  @override
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  @override
  Future<void> showPrivacyOptions() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) {
        onDiagnostic?.call('privacy options: ${error.message}');
      }
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    final had = _consent;
    _consent = await ConsentInformation.instance.canRequestAds();
    if (had && !_consent) _disposeBanner();
    if (!had && _consent) await MobileAds.instance.initialize();
    _onChanged?.call();
  }

  @override
  Future<void> initialise() async {
    if (_started) return;
    _started = true;

    // Rule 5: consent resolves *before* the SDK starts. UMP decides whether a
    // form is needed at all - outside the EEA it usually is not, and the call
    // completes without showing anything.
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) {
            if (error != null) {
              onDiagnostic?.call('consent form: ${error.message}');
            }
            if (!completer.isCompleted) completer.complete();
          });
        } on Object catch (error) {
          onDiagnostic?.call('consent form threw: $error');
          if (!completer.isCompleted) completer.complete();
        }
      },
      (error) {
        // No consent info means no ads, and that is the whole consequence.
        onDiagnostic?.call('consent update: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;

    _privacyOptionsRequired =
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    _consent = await ConsentInformation.instance.canRequestAds();
    if (!_consent) return;

    await MobileAds.instance.initialize();
  }

  @override
  Future<void> prepareInterstitial() => _loadInterstitial();

  @override
  Widget? banner({required double width}) {
    if (!_consent) return null;

    // A width change means a rotation or a resize, and an anchored banner is
    // sized for one width only. Rebuild rather than stretch.
    if (_banner != null && _bannerWidth != width) _disposeBanner();
    if (_banner == null) {
      _bannerWidth = width;
      unawaited(_loadBanner(width));
      return null;
    }
    if (!_bannerLoaded) return null;

    final ad = _banner!;
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }

  Future<void> _loadBanner(double width) async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
      width.truncate(),
    );
    if (size == null) {
      onDiagnostic?.call('no adaptive banner size for width $width');
      return;
    }
    final ad = BannerAd(
      size: size,
      adUnitId: units.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _bannerLoaded = true;
          _onChanged?.call();
        },
        onAdFailedToLoad: (ad, error) {
          onDiagnostic?.call('banner: ${error.message}');
          ad.dispose();
          _banner = null;
          _bannerLoaded = false;
        },
      ),
    );
    _banner = ad;
    await ad.load();
  }

  VoidCallback? _onChanged;

  /// Rebuilds the host when a banner finishes loading. Without it the first
  /// banner appears only on the next unrelated rebuild.
  @override
  set onChanged(VoidCallback? callback) => _onChanged = callback;

  Future<void> _loadInterstitial() async {
    if (_interstitial != null || _interstitialLoading || !_consent) return;
    _interstitialLoading = true;
    await InterstitialAd.load(
      adUnitId: units.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
          onDiagnostic?.call('interstitial: ${error.message}');
        },
      ),
    );
  }

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      // Nothing loaded. Start one for next time and let the user through -
      // an ad that failed must never be felt.
      unawaited(_loadInterstitial());
      return false;
    }
    _interstitial = null;

    final shown = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(_loadInterstitial());
        if (!shown.isCompleted) shown.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        onDiagnostic?.call('interstitial show: ${error.message}');
        ad.dispose();
        unawaited(_loadInterstitial());
        if (!shown.isCompleted) shown.complete(false);
      },
    );
    await ad.show();
    return shown.future;
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _bannerLoaded = false;
  }

  @override
  void dispose() {
    _disposeBanner();
    _interstitial?.dispose();
    _interstitial = null;
    _onChanged = null;
  }
}
