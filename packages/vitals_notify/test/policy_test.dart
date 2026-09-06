import 'package:flutter_test/flutter_test.dart';
import 'package:vitals_notify/vitals_notify.dart';

const policy = NudgePolicy();

DateTime at(int hour, [int day = 11, int minute = 0]) =>
    DateTime.utc(2026, 8, day, hour, minute);

Nudge nudge({
  int id = 1,
  NudgeKind kind = NudgeKind.nudge,
  String? tag,
  DateTime? when,
  bool quietExempt = false,
}) =>
    Nudge(
      id: id,
      kind: kind,
      title: 'Balance empty',
      body: 'Five minutes of grace, then you are borrowing.',
      at: when ?? at(14),
      tag: tag,
      quietHoursExempt: quietExempt,
    );

DeliveredNudge sent({
  NudgeKind kind = NudgeKind.nudge,
  String? tag,
  DateTime? when,
}) =>
    DeliveredNudge(kind: kind, at: when ?? at(10), tag: tag);

void main() {
  group('permission refused', () {
    test('nothing is sent, and the app is not broken', () {
      // Settled decision 9: the app stays fully usable, the grace warning
      // becomes an in-app banner, and Settings states once what is missing.
      final decision = policy.decide(
        nudge(),
        delivered: const [],
        permitted: false,
        offsetMinutes: 0,
      );
      expect(decision.isSend, isFalse);
      expect(decision.rejection, NudgeRejection.notPermitted);
      expect(
        decision.showInAppInstead,
        isTrue,
        reason: 'the user still needs to know',
      );
    });
  });

  group('the daily cap', () {
    test('three nudges land and the fourth does not', () {
      final delivered = [
        sent(when: at(9)),
        sent(when: at(11)),
        sent(when: at(13)),
      ];
      final decision = policy.decide(
        nudge(when: at(15)),
        delivered: delivered,
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decision.rejection, NudgeRejection.overDailyCap);
      // Capped is not the same as unimportant.
      expect(decision.showInAppInstead, isTrue);
    });

    test('the cap resets at the day boundary, not at midnight', () {
      // The app's day starts at 04:00, so a nudge at 02:00 still belongs to
      // yesterday and must not get a fresh budget.
      final yesterday = [
        sent(when: at(20, 10)),
        sent(when: at(21, 10)),
        sent(when: at(22, 10)),
      ];
      // Quiet-hours-exempt so the cap is what is being tested here: 02:00 is
      // inside quiet hours, and that check fires first.
      final lateNight = policy.decide(
        nudge(when: at(2, 11), quietExempt: true),
        delivered: yesterday,
        permitted: true,
        offsetMinutes: 0,
      );
      expect(lateNight.rejection, NudgeRejection.overDailyCap);

      final afterBoundary = policy.decide(
        nudge(when: at(9, 11)),
        delivered: yesterday,
        permitted: true,
        offsetMinutes: 0,
      );
      expect(afterBoundary.isSend, isTrue);
    });

    test('milestones have their own smaller budget', () {
      // A milestone must not eat the budget a grace warning needs.
      final decisions = policy.decideAll(
        [
          nudge(id: 1, kind: NudgeKind.milestone, when: at(9)),
          nudge(id: 2, kind: NudgeKind.milestone, when: at(11)),
          nudge(id: 3, when: at(12)),
        ],
        delivered: const [],
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decisions[0].isSend, isTrue);
      expect(decisions[1].rejection, NudgeRejection.overDailyCap);
      expect(decisions[2].isSend, isTrue, reason: 'separate budget');
    });

    test('a reminder the user set is never capped', () {
      // Silently dropping a reminder someone scheduled is a broken app, not a
      // considerate one.
      final delivered = [
        for (var i = 0; i < 20; i++)
          sent(kind: NudgeKind.scheduled, when: at(6 + i % 12)),
      ];
      final decision = policy.decide(
        nudge(kind: NudgeKind.scheduled, when: at(15)),
        delivered: delivered,
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decision.isSend, isTrue);
    });
  });

  group('batches', () {
    test('a batch consumes its own budget as it goes', () {
      // Without this, three nudges queued in one reconcile would each check a
      // cap none of them had yet consumed, and all three would fire.
      final decisions = policy.decideAll(
        [
          nudge(id: 1, when: at(9)),
          nudge(id: 2, when: at(10)),
          nudge(id: 3, when: at(11)),
          nudge(id: 4, when: at(12)),
          nudge(id: 5, when: at(13)),
        ],
        delivered: const [],
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decisions.where((d) => d.isSend), hasLength(3));
      expect(decisions.last.rejection, NudgeRejection.overDailyCap);
    });

    test('a batch is decided in time order, not the order it arrived', () {
      final decisions = policy.decideAll(
        [
          nudge(id: 3, when: at(16)),
          nudge(id: 1, when: at(9)),
          nudge(id: 2, when: at(12)),
        ],
        delivered: const [],
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decisions.map((d) => d.nudge.id), [1, 2, 3]);
    });
  });

  group('duplicates', () {
    test('the same tag inside the cooldown is suppressed', () {
      // Reconciles run every 10 to 15 seconds while a watched app is open. The
      // same "you are borrowing" nudge must not fire on every pass.
      final decision = policy.decide(
        nudge(tag: 'grace', when: at(14, 11, 10)),
        delivered: [sent(tag: 'grace', when: at(14))],
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decision.rejection, NudgeRejection.duplicateInCooldown);
      // Genuinely redundant, so there is nothing to show in-app either.
      expect(decision.showInAppInstead, isFalse);
    });

    test('the same tag after the cooldown is allowed', () {
      final decision = policy.decide(
        nudge(tag: 'grace', when: at(15)),
        delivered: [sent(tag: 'grace', when: at(14))],
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decision.isSend, isTrue);
    });

    test('different tags do not suppress each other', () {
      final decision = policy.decide(
        nudge(tag: 'debt_15', when: at(14, 11, 5)),
        delivered: [sent(tag: 'grace', when: at(14))],
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decision.isSend, isTrue);
    });

    test('an untagged nudge is never treated as a duplicate', () {
      final decision = policy.decide(
        nudge(when: at(14, 11, 1)),
        delivered: [sent(when: at(14))],
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decision.isSend, isTrue);
    });
  });

  group('quiet hours', () {
    test('a window crossing midnight is one window', () {
      // 22:00 to 08:00 is the normal case and the one naive code gets wrong.
      expect(policy.isQuietHour(at(23), offsetMinutes: 0), isTrue);
      expect(policy.isQuietHour(at(2), offsetMinutes: 0), isTrue);
      expect(policy.isQuietHour(at(7), offsetMinutes: 0), isTrue);
      expect(policy.isQuietHour(at(8), offsetMinutes: 0), isFalse);
      expect(policy.isQuietHour(at(14), offsetMinutes: 0), isFalse);
      expect(policy.isQuietHour(at(21, 11, 59), offsetMinutes: 0), isFalse);
      expect(policy.isQuietHour(at(22), offsetMinutes: 0), isTrue);
    });

    test('quiet hours are local, not UTC', () {
      // 23:00 in Dublin is 22:00 UTC. Judging by UTC would nudge someone at
      // midnight and let a 21:00 nudge through as if it were quiet.
      final instant = DateTime.utc(2026, 8, 11, 22);
      expect(policy.isQuietHour(instant, offsetMinutes: 60), isTrue);
      expect(policy.isQuietHour(instant, offsetMinutes: -300), isFalse);
    });

    test('a nudge inside quiet hours is held back and shown in-app', () {
      final decision = policy.decide(
        nudge(when: at(23)),
        delivered: const [],
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decision.rejection, NudgeRejection.quietHours);
      expect(decision.showInAppInstead, isTrue);
    });

    test('an exempt nudge fires anyway', () {
      final decision = policy.decide(
        nudge(when: at(23), quietExempt: true),
        delivered: const [],
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decision.isSend, isTrue);
    });

    test('quiet hours never hold back a reminder the user set', () {
      // Someone who sets an alarm for 06:00 means 06:00.
      final decision = policy.decide(
        nudge(kind: NudgeKind.scheduled, when: at(6)),
        delivered: const [],
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decision.isSend, isTrue);
    });

    test('quiet hours can be switched off entirely', () {
      const always = NudgePolicy(quietHoursStart: 0, quietHoursEnd: 0);
      expect(always.isQuietHour(at(3), offsetMinutes: 0), isFalse);
    });
  });

  group('the user turned it off', () {
    test('a disabled kind is silent and stays silent', () {
      final decision = policy.decide(
        nudge(),
        delivered: const [],
        permitted: true,
        offsetMinutes: 0,
        disabledKinds: {NudgeKind.nudge},
      );
      expect(decision.rejection, NudgeRejection.disabled);
      // Explicitly turned off, so it must not reappear as a banner instead.
      expect(decision.showInAppInstead, isFalse);
    });
  });

  group('dispatch', () {
    test('sends the survivors and reports every decision', () async {
      final notifier = RecordingNotifier();
      final dispatcher = NudgeDispatcher(notifier: notifier, policy: policy);

      final decisions = await dispatcher.dispatch(
        [
          nudge(id: 1, when: at(9)),
          nudge(id: 2, when: at(10)),
          nudge(id: 3, when: at(11)),
          nudge(id: 4, when: at(12)),
        ],
        delivered: const [],
        offsetMinutes: 0,
      );

      expect(notifier.shown.map((n) => n.id), [1, 2, 3]);
      expect(decisions.last.isSend, isFalse);
    });

    test('scheduled nudges are scheduled, not shown', () async {
      final notifier = RecordingNotifier();
      final dispatcher = NudgeDispatcher(notifier: notifier, policy: policy);

      await dispatcher.dispatch(
        [nudge(id: 7, kind: NudgeKind.scheduled, when: at(9))],
        delivered: const [],
        offsetMinutes: 0,
      );

      expect(notifier.scheduled.map((n) => n.id), [7]);
      expect(notifier.shown, isEmpty);
    });

    test('nothing is posted when permission is refused', () async {
      final notifier = RecordingNotifier()
        ..permissionState = NotificationPermission.denied;
      final dispatcher = NudgeDispatcher(notifier: notifier, policy: policy);

      final decisions = await dispatcher.dispatch(
        [nudge()],
        delivered: const [],
        offsetMinutes: 0,
      );

      expect(notifier.shown, isEmpty);
      expect(notifier.scheduled, isEmpty);
      expect(decisions.single.showInAppInstead, isTrue);
    });

    test('cancelling removes a pending nudge', () async {
      final notifier = RecordingNotifier();
      await notifier.schedule(nudge(id: 5, kind: NudgeKind.scheduled));
      expect(await notifier.pending(), [5]);
      await notifier.cancel(5);
      expect(await notifier.pending(), isEmpty);
    });
  });

  group('the cap holds for any three unrelated nudges', () {
    // This used to be named for lockIn's three balance nudges - grace, -15,
    // -60 - and those have been removed from that app: each interrupted the
    // user to announce a number already on screen in the ongoing notice.
    //
    // The case is kept because what it actually tests belongs to this package
    // rather than to any app: three distinct tags fill the day's budget in
    // order, and the fourth is capped rather than dropped silently. Renamed so
    // it stops documenting a feature that no longer exists.
    test('three distinct tags land, the fourth is capped', () {
      final decisions = policy.decideAll(
        [
          nudge(id: 1, tag: 'first', when: at(14)),
          nudge(id: 2, tag: 'second', when: at(15)),
          nudge(id: 3, tag: 'third', when: at(16)),
          nudge(id: 4, tag: 'fourth', when: at(17)),
        ],
        delivered: const [],
        permitted: true,
        offsetMinutes: 0,
      );
      expect(decisions.take(3).every((d) => d.isSend), isTrue);
      expect(decisions.last.rejection, NudgeRejection.overDailyCap);
    });
  });
}
