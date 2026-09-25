import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks the phone who is holding it.
///
/// A seam over `local_auth`, in the same shape as `PhotoPicker` and
/// `ArchiveTransfer`, so the lock can be tested without a fingerprint.
abstract interface class Unlocker {
  /// Whether the phone has any screen lock at all. Without one there is
  /// nothing to check against, and the app must not lock itself shut.
  Future<bool> isAvailable();

  /// True only when the person proved it is them. [reason] is shown in the
  /// system prompt, in the app's language.
  Future<bool> unlock({required String reason});
}

/// The real one: fingerprint or face, falling back to the phone's own PIN,
/// pattern or password.
///
/// **The fallback is the recovery path.** There is no app password to forget
/// and no reset flow that could be used by someone else: whoever can unlock
/// the phone can unlock the app, and nobody else can.
final class PlatformUnlocker implements Unlocker {
  const PlatformUnlocker();

  static final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> unlock({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on Object {
      // Cancelled, too many tries, or no enrolled method. All three leave
      // the app locked, which is the only safe reading of any of them.
      return false;
    }
  }
}

/// Whether the app is locked, and whether it should be.
///
/// **Off by default**, switched on in Settings. A fingerprint asked for on
/// the very first open, before anything is in the app, is a wall rather than
/// a protection; once there is a diary, a cycle and a body to keep from a
/// phone handed over to show a photo, it is one switch away.
final class AppLock extends ChangeNotifier {
  AppLock({
    this.unlocker = const PlatformUnlocker(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Unlocker unlocker;
  final DateTime Function() _clock;

  /// Time in the background before the app asks again. Long enough that
  /// switching to the camera or a message and back does not ask twice.
  static const grace = Duration(minutes: 1);

  static const _key = 'patterns.appLock.enabled';

  bool _enabled = false;
  bool _available = false;
  bool _locked = false;
  DateTime? _leftAt;

  bool get enabled => _enabled;

  /// False on a phone with no screen lock. Settings says so plainly.
  bool get available => _available;

  bool get locked => _locked;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? false;
    _available = await unlocker.isAvailable();
    _locked = _enabled && _available;
    notifyListeners();
  }

  Future<bool> tryUnlock({String reason = 'Unlock Tideline'}) async {
    if (!_locked) return true;
    final ok = await unlocker.unlock(reason: reason);
    if (ok) {
      _locked = false;
      notifyListeners();
    }
    return ok;
  }

  /// Turning the lock off needs the same proof as getting past it, or anyone
  /// holding the unlocked phone could switch it off for later.
  Future<bool> setEnabled(bool on, {String reason = 'Unlock Tideline'}) async {
    if (on == _enabled) return true;
    if (!on && _available && !await unlocker.unlock(reason: reason)) {
      return false;
    }
    _enabled = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, on);
    notifyListeners();
    return true;
  }

  void wentToBackground() => _leftAt ??= _clock();

  void cameBack() {
    final left = _leftAt;
    _leftAt = null;
    if (left == null || !_enabled || !_available || _locked) return;
    if (_clock().difference(left) >= grace) {
      _locked = true;
      notifyListeners();
    }
  }
}
