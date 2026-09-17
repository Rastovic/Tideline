import 'package:flutter/widgets.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

/// The two languages the app speaks.
///
/// **English by default.** Marker names are never translated: they are what
/// she typed, in whatever language she typed them, and a switch that rewrote
/// "nadutost" as "bloating" would be the app editing her record.
enum AppLanguage {
  en('en', 'English'),
  sr('sr', 'Srpski');

  const AppLanguage(this.code, this.nativeName);

  final String code;

  /// Always in its own language, so the choice can be found by someone who
  /// cannot read the current one.
  final String nativeName;

  TextLanguage get text =>
      this == AppLanguage.en ? TextLanguage.en : TextLanguage.sr;

  static AppLanguage fromCode(String? code) =>
      code == 'sr' ? AppLanguage.sr : AppLanguage.en;

  static const _key = 'patterns.language';

  static Future<AppLanguage> load() async {
    final prefs = await SharedPreferences.getInstance();
    return fromCode(prefs.getString(_key));
  }

  static Future<void> save(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language.code);
  }
}

/// Holds the current language above the whole app, so changing it in
/// Settings redraws every screen at once.
class LanguageScope extends InheritedNotifier<ValueNotifier<AppLanguage>> {
  const LanguageScope({
    required ValueNotifier<AppLanguage> language,
    required super.child,
    super.key,
  }) : super(notifier: language);

  static ValueNotifier<AppLanguage>? notifierOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()?.notifier;
}

extension AppStringsContext on BuildContext {
  /// The words for the current language. English where no scope is above,
  /// which is every widget test that does not ask for another.
  AppStrings get s =>
      AppStrings(LanguageScope.notifierOf(this)?.value ?? AppLanguage.en);
}
