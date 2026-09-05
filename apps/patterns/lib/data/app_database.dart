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
