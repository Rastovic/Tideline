/// Ads behind an interface, and the policy that decides when one is allowed.
///
/// The policy is pure Dart and is the part worth testing: the caps in
/// `MONETIZATION.md` are what keeps the app in the store, and they must hold
/// without a device or an AdMob account. [AdMobGateway] is only plumbing.
library;

export 'src/ad_gateway.dart';
export 'src/ad_policy.dart';
export 'src/admob_gateway.dart';
export 'src/ad_slot.dart';
