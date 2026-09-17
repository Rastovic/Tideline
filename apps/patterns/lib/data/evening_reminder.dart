import 'package:vitals_notify/vitals_notify.dart';

import 'app_database.dart';
import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';

/// When a reminder set for [minute] next fires, counting from [now].
///
/// Pure, and separated from the scheduling so the awkward part can be tested
/// without a plugin or a clock. Today if that time has not passed yet,
/// tomorrow if it has - and **exactly now counts as passed**, because a
/// reminder scheduled for the instant it was set fires immediately, which
/// reads as the app shouting at you for opening Settings.
DateTime nextReminderAt(DateTime now, int minute) {
  final today = DateTime(
    now.year,
    now.month,
    now.day,
    minute ~/ 60,
    minute % 60,
  );
  if (today.isAfter(now)) return today;
  return today.add(const Duration(days: 1));
}

/// The one reminder, and everything that keeps it true.
///
/// **It says the same thing every night.** It does not know whether the day was
/// logged, whether yesterday was missed, or how anything went, and it must
/// never learn: a reminder that comments on a blank day is the app grading you
/// through the notification shade, which is the one thing this app does not do.
///
/// Tapping it opens the app on the marker list, which is the entry screen - no
/// summary, no recap, no message in between. That needs no routing code, and
/// the fact that it needs none is the point: the screen you land on is already
/// the place to log.
final class EveningReminder {
  const EveningReminder(this.notifier);

  final Notifier notifier;

  /// One fixed id, because there is exactly one reminder. Rescheduling
  /// overwrites rather than accumulating a second alarm every time the time is
  /// changed.
  static const int notificationId = 1;

  static const String title = 'Tideline';

  /// Neutral on purpose, and asserted by a test. No "you missed", no count of
  /// what is left, no encouragement.
  static String bodyFor(AppLanguage language) =>
      AppStrings(language).reminderBody;

  /// Makes the OS agree with [settings]. Safe to call as often as you like.
  ///
  /// Called on every launch as well as on every change, because Android drops
  /// pending alarms on a reboot and on an app update, and re-arming from the
  /// app's own record is cheaper than trusting that they survived. Idempotent:
  /// the fixed id means a second call replaces rather than duplicates.
  Future<void> apply(
    ReminderSettings settings, {
    DateTime? now,
    AppLanguage language = AppLanguage.en,
  }) async {
    if (!settings.enabled) {
      await notifier.cancel(notificationId);
      return;
    }

    await notifier.initialise();
    await notifier.scheduleDaily(
      Nudge(
        id: notificationId,
        // Never capped and never silenced by a budget: she asked for this one
        // at this time, and dropping it would be the app deciding it knew
        // better.
        kind: NudgeKind.scheduled,
        title: title,
        body: bodyFor(language),
        at: nextReminderAt(now ?? DateTime.now(), settings.minute),
        tag: 'evening',
        quietHoursExempt: true,
      ),
    );
  }
}
