import 'package:drift_flutter/drift_flutter.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_core/vitals_core.dart';

/// Opens the database on the device.
///
/// One file in the app's own documents directory, so Android's auto-backup can
/// take it and nobody has to think about where it lives.
PatternsDatabase openPatternsDatabase() =>
    PatternsDatabase(driftDatabase(name: 'patterns'));

/// The id every row written on this device is stamped with.
///
/// Generated once and kept. It must survive restarts, and it must **not** be
/// regenerated on a restore, or every row imported from the old phone would
/// look like it came from somewhere else.
final class InstallId {
  const InstallId._();

  static const _key = 'patterns.installId';

  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && Ids.isValid(existing)) return existing;

    final fresh = Ids.newId();
    await prefs.setString(_key, fresh);
    return fresh;
  }
}

/// The local hour a new day starts.
///
/// 04:00 by default: a reading at 01:30 belongs to the day that just ended,
/// because that is where the person filing it thinks they are.
final class DayBoundary {
  const DayBoundary._();

  static const _key = 'patterns.dayBoundaryHour';
  static const defaultHour = 4;

  static Future<int> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? defaultHour;
  }

  static Future<void> save(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, hour);
  }
}

/// The one reminder: whether it is on, and at what minute of the day.
///
/// **One, at the end of the day, at a time I set.** Not three check-ins, not a
/// morning ping, not a preset chosen in onboarding. Everything else in the app
/// is quick-log, and the reminder is a convenience rather than the way the app
/// works - which is why turning it off changes nothing else.
final class ReminderSettings {
  const ReminderSettings({required this.enabled, required this.minute});

  /// Off until asked for. A tracker that starts by notifying you is a tracker
  /// whose notifications get switched off at OS level within a week, and that
  /// costs the reminder you would have wanted.
  static const ReminderSettings off =
      ReminderSettings(enabled: false, minute: defaultMinute);

  /// 21:00, as minutes from midnight. Only a starting point for the picker.
  static const int defaultMinute = 21 * 60;

  final bool enabled;

  /// Minutes from local midnight.
  final int minute;

  int get hour => minute ~/ 60;
  int get minuteOfHour => minute % 60;

  ReminderSettings copyWith({bool? enabled, int? minute}) => ReminderSettings(
        enabled: enabled ?? this.enabled,
        minute: minute ?? this.minute,
      );

  static const _enabledKey = 'patterns.reminder.enabled';
  static const _minuteKey = 'patterns.reminder.minute';

  static Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      minute: prefs.getInt(_minuteKey) ?? defaultMinute,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    await prefs.setInt(_minuteKey, minute);
  }
}
