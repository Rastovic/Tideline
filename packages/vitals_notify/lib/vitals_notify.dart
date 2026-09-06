/// Local notifications, and the policy that decides what is worth sending.
///
/// The two halves are separate on purpose. [NudgePolicy] is pure Dart and holds
/// every rule worth arguing about - caps, cooldowns, quiet hours, what happens
/// when permission is refused - so all of it is testable without a device.
/// [LocalNotifier] is the thin plugin layer beneath it.
///
/// The stance behind the caps: **an app that notifies too much gets its
/// notifications turned off, which costs you the ones that mattered.**
library;

export 'src/local_notifier.dart';
export 'src/notifier.dart';
export 'src/policy.dart';
