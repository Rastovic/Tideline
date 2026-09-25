import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_ads/vitals_ads.dart';

/// The app's side of [AdPolicy]: it holds the counters the rules read, keeps
/// them across launches, and is the only thing the UI talks to.
///
/// **Banners only**, the way LockIn has them: the interstitial exists in
/// `vitals_ads` but nothing here loads or shows one. And **only under screens
/// with no entry on them** - Settings and the marker list. A private record
/// with an ad beside someone's worst week is the screenshot that ends the app.
///
/// **Every question has a safe answer before [start] finishes.** The banner
/// asks on the first frame, and a controller that answered "allowed" while
/// still loading would show an ad to a first-run user.
final class AdsController {
  AdsController({AdGateway? gateway, this.policy = const AdPolicy()})
    : gateway = gateway ?? const NoAds();

  final AdGateway gateway;
  final AdPolicy policy;

  static const _sessionCountKey = 'ads.sessionCount';
  static const _coreActionKey = 'ads.coreActionDone';

  AdSession _session = const AdSession(sessionCount: 1);
  bool _coreActionDone = false;
  bool _ready = false;

  /// Set once the user owns the Pro unlock. Wired to RevenueCat later; false
  /// here means the prototype shows what a free user sees.
  bool isPro = false;

  /// Counts this launch, restores the core-action flag, then starts the SDK.
  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_sessionCountKey) ?? 0) + 1;
    await prefs.setInt(_sessionCountKey, count);
    _coreActionDone = prefs.getBool(_coreActionKey) ?? false;

    _session = AdSession(sessionCount: count, coldStartAt: DateTime.now());
    await gateway.initialise();
    _ready = true;
  }

  /// Records that the user has reached the point of the app at least once.
  ///
  /// In Tideline that is the first reading she logs herself. Before it, the
  /// app has not yet been used for what it is for.
  Future<void> markCoreAction() async {
    if (_coreActionDone) return;
    _coreActionDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_coreActionKey, true);
  }

  /// Whether a banner may be drawn under the current screen.
  ///
  /// [screenBusy] is the caller's answer to rule 4 - a timer running or a text
  /// field on screen - because only the screen knows.
  bool bannerAllowed({bool screenBusy = false}) =>
      _ready &&
      policy.allows(
        placement: AdPlacement.banner,
        session: _session,
        now: DateTime.now(),
        isPro: isPro,
        hasConsent: gateway.hasConsent,
        coreActionComplete: _coreActionDone,
        screenBusy: screenBusy,
      );

  void dispose() => gateway.dispose();
}

/// Makes the ads reachable from the screens that carry a banner, without
/// threading them through every constructor on the way.
class AdsScope extends InheritedWidget {
  const AdsScope({required this.ads, required super.child, super.key});

  final AdsController ads;

  static AdsController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdsScope>()?.ads;

  @override
  bool updateShouldNotify(AdsScope oldWidget) => ads != oldWidget.ads;
}

/// The banner strip for a screen, or nothing where no ads are wired in.
class ScreenBanner extends StatelessWidget {
  const ScreenBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ads = AdsScope.of(context);
    if (ads == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: AdSlot(gateway: ads.gateway, allowed: ads.bannerAllowed()),
    );
  }
}
