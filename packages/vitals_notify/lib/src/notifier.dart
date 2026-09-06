import 'policy.dart';

/// Whether the OS will let the app post notifications.
enum NotificationPermission {
  granted,

  /// Denied, or never asked. **The app must stay fully usable.**
  denied,

  /// Denied permanently, so asking again does nothing and Settings is the only
  /// route. The UI must say so rather than showing a button that no longer
  /// works.
  permanentlyDenied,

  /// Not yet requested.
  notDetermined,
}

/// The platform surface for notifications.
///
/// `CROSS-PLATFORM.md` rule 2: every OS capability sits behind an interface
/// with an Android implementation today. iOS becomes a second implementation
/// and no caller changes.
///
/// Rule 3 also applies - this is shaped around the question ("tell the user
/// this, at this time") rather than around
/// `flutter_local_notifications`' API, so an iOS implementation using
/// `UNUserNotificationCenter` fits without reshaping the callers.
abstract interface class Notifier {
  /// Prepares channels and timezone data. Safe to call more than once.
  Future<void> initialise();

  Future<NotificationPermission> permission();

  /// Asks for permission.
  ///
  /// **Never call this cold.** Both stores expect the reason to be on screen
  /// first, and in a tracker the permission funnel is where users drop.
  Future<NotificationPermission> requestPermission();

  /// Posts immediately.
  Future<void> show(Nudge nudge);

  /// Posts at [Nudge.at].
  Future<void> schedule(Nudge nudge);

  /// Posts at [Nudge.at] and again at the same clock time every day.
  ///
  /// A separate call rather than a flag on [schedule], because the two have
  /// different failure modes: a one-shot that never fires is a missed alarm,
  /// a repeat that never fires is a feature that quietly stopped working and
  /// is noticed weeks later.
  ///
  /// **The clock time is what repeats, not the interval.** A daily reminder set
  /// for 21:00 has to stay at 21:00 across a DST change rather than sliding to
  /// 20:00, which is why the implementation matches on time components instead
  /// of adding 24 hours.
  Future<void> scheduleDaily(Nudge nudge);

  Future<void> cancel(int id);

  Future<void> cancelAll();

  /// Ids the OS still has pending.
  ///
  /// Needed after a reboot: Android drops scheduled alarms, so the app
  /// reschedules from its own records rather than assuming they survived.
  Future<List<int>> pending();
}

/// A [Notifier] that records instead of posting.
///
/// Used in tests and on any surface where notifications are not wanted, so a
/// caller never has to branch on whether notifications exist.
final class RecordingNotifier implements Notifier {
  final List<Nudge> shown = [];
  final List<Nudge> scheduled = [];
  final List<int> cancelled = [];

  /// Ids scheduled to repeat, so a test can tell a daily reminder from a
  /// one-shot without inspecting the plugin.
  final List<int> daily = [];

  NotificationPermission _permission = NotificationPermission.granted;

  set permissionState(NotificationPermission value) => _permission = value;

  @override
  Future<void> initialise() async {}

  @override
  Future<NotificationPermission> permission() async => _permission;

  @override
  Future<NotificationPermission> requestPermission() async => _permission;

  @override
  Future<void> show(Nudge nudge) async => shown.add(nudge);

  @override
  Future<void> schedule(Nudge nudge) async => scheduled.add(nudge);

  @override
  Future<void> scheduleDaily(Nudge nudge) async {
    scheduled.add(nudge);
    daily.add(nudge.id);
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.removeWhere((n) => n.id == id);
    daily.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelled.addAll(scheduled.map((n) => n.id));
    scheduled.clear();
    daily.clear();
  }

  @override
  Future<List<int>> pending() async => [for (final n in scheduled) n.id];
}

/// Applies [NudgePolicy] and then hands the survivors to a [Notifier].
///
/// The two halves are kept separate on purpose: the policy is pure and heavily
/// tested, the platform layer is thin and hard to test, and the seam between
/// them is where the interesting rules live.
final class NudgeDispatcher {
  const NudgeDispatcher({
    required this.notifier,
    required this.policy,
  });

  final Notifier notifier;
  final NudgePolicy policy;

  /// Sends what survives the policy and returns every decision.
  ///
  /// Rejected nudges carrying [NudgeDecision.showInAppInstead] are the caller's
  /// to render as a banner on next open. **Nothing is dropped silently.**
  Future<List<NudgeDecision>> dispatch(
    List<Nudge> nudges, {
    required List<DeliveredNudge> delivered,
    required int offsetMinutes,
    Set<NudgeKind> disabledKinds = const {},
  }) async {
    final permitted =
        await notifier.permission() == NotificationPermission.granted;

    final decisions = policy.decideAll(
      nudges,
      delivered: delivered,
      permitted: permitted,
      offsetMinutes: offsetMinutes,
      disabledKinds: disabledKinds,
    );

    for (final decision in decisions.where((d) => d.isSend)) {
      if (decision.nudge.kind == NudgeKind.scheduled) {
        await notifier.schedule(decision.nudge);
      } else {
        await notifier.show(decision.nudge);
      }
    }
    return decisions;
  }
}
