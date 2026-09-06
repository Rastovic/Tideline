import 'package:vitals_core/vitals_core.dart';

/// What a notification is for.
///
/// Kinds exist so caps can be applied per kind. A nudge the user did not ask
/// for and a reminder they explicitly scheduled are not the same thing and must
/// not share a budget.
enum NudgeKind {
  /// The user asked for this at a specific time. Never capped, never silenced
  /// by a budget: silently dropping a reminder someone set is a broken app.
  scheduled,

  /// The app decided this was worth interrupting for. **Capped.**
  nudge,

  /// A milestone worth knowing about. Capped, and lowest priority of the three.
  milestone,
}

/// One notification the app would like to send.
final class Nudge {
  const Nudge({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.tag,
    this.quietHoursExempt = false,
  });

  final int id;
  final NudgeKind kind;
  final String title;
  final String body;
  final DateTime at;

  /// Groups nudges that mean the same thing, so a cap counts them once.
  final String? tag;

  /// Whether this may fire inside quiet hours.
  final bool quietHoursExempt;

  @override
  String toString() => 'Nudge($id, ${kind.name}, "$title")';
}

/// Why a nudge was not sent. Kept so the reason is inspectable rather than a
/// silent drop.
enum NudgeRejection {
  /// The daily budget for this kind is spent.
  overDailyCap,

  /// An identical nudge already went out inside the cooldown.
  duplicateInCooldown,

  /// Quiet hours, and this nudge is not exempt.
  quietHours,

  /// The user turned this kind off.
  disabled,

  /// Notifications are not permitted at OS level.
  ///
  /// The app stays fully usable. What would have been a notification becomes an
  /// in-app banner on next open, and Settings states once what is missing.
  notPermitted,
}

/// The decision about one nudge.
final class NudgeDecision {
  const NudgeDecision.send(this.nudge)
      : rejection = null,
        showInAppInstead = false;

  const NudgeDecision.reject(this.nudge, this.rejection,
      {this.showInAppInstead = false});

  final Nudge nudge;
  final NudgeRejection? rejection;

  /// True when the user should still see this, just not as a notification.
  final bool showInAppInstead;

  bool get isSend => rejection == null;
}

/// One nudge that has already been delivered.
final class DeliveredNudge {
  const DeliveredNudge({
    required this.kind,
    required this.at,
    this.tag,
  });

  final NudgeKind kind;
  final DateTime at;
  final String? tag;
}

/// Decides what is worth interrupting someone for.
///
/// Pure Dart, no plugin, so every rule below is testable without a device.
///
/// The stance: **an app that notifies too much gets its notifications turned
/// off, which costs you the ones that mattered.** Caps are not politeness, they
/// are how the important nudge still lands in week six.
final class NudgePolicy {
  const NudgePolicy({
    this.dailyNudgeCap = 3,
    this.dailyMilestoneCap = 1,
    this.cooldown = const Duration(minutes: 30),
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
    this.dayBoundaryHour = 4,
  });

  /// Most self-initiated nudges in one day. Tally's plan sets this at three.
  final int dailyNudgeCap;

  final int dailyMilestoneCap;

  /// How long the same [Nudge.tag] is suppressed after being sent.
  final Duration cooldown;

  /// Local hour quiet hours begin.
  final int quietHoursStart;

  /// Local hour quiet hours end.
  final int quietHoursEnd;

  final int dayBoundaryHour;

  /// Decides one nudge against the recent history.
  NudgeDecision decide(
    Nudge nudge, {
    required List<DeliveredNudge> delivered,
    required bool permitted,
    required int offsetMinutes,
    Set<NudgeKind> disabledKinds = const {},
  }) {
    if (!permitted) {
      // Not a failure. The app is fully usable; this becomes an in-app banner.
      return NudgeDecision.reject(
        nudge,
        NudgeRejection.notPermitted,
        showInAppInstead: true,
      );
    }

    if (disabledKinds.contains(nudge.kind)) {
      return NudgeDecision.reject(nudge, NudgeRejection.disabled);
    }

    // A reminder the user set for a time is never second-guessed.
    if (nudge.kind == NudgeKind.scheduled) return NudgeDecision.send(nudge);

    if (!nudge.quietHoursExempt &&
        isQuietHour(nudge.at, offsetMinutes: offsetMinutes)) {
      return NudgeDecision.reject(
        nudge,
        NudgeRejection.quietHours,
        showInAppInstead: true,
      );
    }

    final tag = nudge.tag;
    if (tag != null) {
      final recent = delivered.where(
        (d) => d.tag == tag && nudge.at.difference(d.at).abs() < cooldown,
      );
      if (recent.isNotEmpty) {
        return NudgeDecision.reject(nudge, NudgeRejection.duplicateInCooldown);
      }
    }

    final today = dayKeyFor(
      nudge.at,
      offsetMinutes: offsetMinutes,
      dayBoundaryHour: dayBoundaryHour,
    );
    final sameDay = delivered.where(
      (d) =>
          d.kind == nudge.kind &&
          dayKeyFor(
                d.at,
                offsetMinutes: offsetMinutes,
                dayBoundaryHour: dayBoundaryHour,
              ) ==
              today,
    );

    final cap = switch (nudge.kind) {
      NudgeKind.nudge => dailyNudgeCap,
      NudgeKind.milestone => dailyMilestoneCap,
      NudgeKind.scheduled => 1 << 30,
    };

    if (sameDay.length >= cap) {
      return NudgeDecision.reject(
        nudge,
        NudgeRejection.overDailyCap,
        showInAppInstead: true,
      );
    }

    return NudgeDecision.send(nudge);
  }

  /// True when [instant] falls inside quiet hours.
  ///
  /// Handles a window crossing midnight, which is the normal case: 22:00 to
  /// 08:00 is one window, not two.
  bool isQuietHour(DateTime instant, {required int offsetMinutes}) {
    if (quietHoursStart == quietHoursEnd) return false;
    final local = instant.toUtc().add(Duration(minutes: offsetMinutes));
    final hour = local.hour;
    if (quietHoursStart < quietHoursEnd) {
      return hour >= quietHoursStart && hour < quietHoursEnd;
    }
    return hour >= quietHoursStart || hour < quietHoursEnd;
  }

  /// Decides a batch in order, so each decision sees the ones before it.
  ///
  /// Without this, three nudges queued in the same reconcile would each check a
  /// cap that none of them had yet consumed, and all three would send.
  List<NudgeDecision> decideAll(
    List<Nudge> nudges, {
    required List<DeliveredNudge> delivered,
    required bool permitted,
    required int offsetMinutes,
    Set<NudgeKind> disabledKinds = const {},
  }) {
    final history = [...delivered];
    final decisions = <NudgeDecision>[];

    for (final nudge in [...nudges]..sort((a, b) => a.at.compareTo(b.at))) {
      final decision = decide(
        nudge,
        delivered: history,
        permitted: permitted,
        offsetMinutes: offsetMinutes,
        disabledKinds: disabledKinds,
      );
      decisions.add(decision);
      if (decision.isSend) {
        history.add(
          DeliveredNudge(kind: nudge.kind, at: nudge.at, tag: nudge.tag),
        );
      }
    }
    return decisions;
  }
}
