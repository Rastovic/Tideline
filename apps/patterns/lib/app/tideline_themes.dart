import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_ui/vitals_ui.dart';

/// Tideline's themes. Each is authored twice, light and dark, so the system
/// switch never fights the choice.
///
/// **Clean and a little futuristic**: near-black navy grounds rather than
/// pure black, surfaces one step up with a hairline edge instead of a shadow,
/// and one accent per theme that carries buttons, active chips and chart
/// fills. The accents are mid-light on purpose: every one of them carries ink
/// text at 4.5:1 or better in both modes, which `theme_test.dart` measures.
enum TidelineTheme {
  tide(
    'Tide',
    accent: Color(0xFF5B8DEF),
    dark: _Ground(
      bg: Color(0xFF0A0F1C),
      surface: Color(0xFF111827),
      surfaceAlt: Color(0xFF182236),
      stroke: Color(0xFF243049),
    ),
    light: _Ground(
      bg: Color(0xFFF2F5FB),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFE8EDF7),
      stroke: Color(0xFFD7DFEE),
    ),
  ),
  nebula(
    'Nebula',
    accent: Color(0xFFA78BFA),
    dark: _Ground(
      bg: Color(0xFF0D0A17),
      surface: Color(0xFF161226),
      surfaceAlt: Color(0xFF1F1934),
      stroke: Color(0xFF2E2649),
    ),
    light: _Ground(
      bg: Color(0xFFF6F4FC),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFEEEAF9),
      stroke: Color(0xFFE0DAF2),
    ),
  ),
  circuit(
    'Circuit',
    accent: Color(0xFF2DD4BF),
    dark: _Ground(
      bg: Color(0xFF071210),
      surface: Color(0xFF0D1B19),
      surfaceAlt: Color(0xFF132623),
      stroke: Color(0xFF1F3834),
    ),
    light: _Ground(
      bg: Color(0xFFF0F8F6),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFE3F1EE),
      stroke: Color(0xFFCFE4DF),
    ),
  ),
  ember(
    'Ember',
    accent: Color(0xFFF59E6B),
    dark: _Ground(
      bg: Color(0xFF130E0B),
      surface: Color(0xFF1C1612),
      surfaceAlt: Color(0xFF261E19),
      stroke: Color(0xFF3A2D25),
    ),
    light: _Ground(
      bg: Color(0xFFFBF6F2),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFF5ECE5),
      stroke: Color(0xFFEBDDD2),
    ),
  );

  const TidelineTheme(
    this.label, {
    required this.accent,
    required _Ground dark,
    required _Ground light,
  })  :
        // ignore: prefer_initializing_formals
        _dark = dark,
        // ignore: prefer_initializing_formals
        _light = light;

  /// A name, not a word to translate: themes are brands, the same in every
  /// language.
  final String label;
  final Color accent;
  final _Ground _dark;
  final _Ground _light;

  static const _ink = Color(0xFF0E1116);

  VitalsColors colors(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final g = dark ? _dark : _light;
    return VitalsColors(
      brightness: brightness,
      bg: g.bg,
      surface: g.surface,
      surfaceAlt: g.surfaceAlt,
      stroke: g.stroke,
      ink: dark ? const Color(0xFFEEF2FA) : const Color(0xFF0B1220),
      inkMuted: dark ? const Color(0xFF97A3BA) : const Color(0xFF55617A),
      inkFaint: dark ? const Color(0xFF5A667E) : const Color(0xFF98A2B6),
      accent: accent,
      onAccent: _ink,
      success: const Color(0xFF37D67A),
      warning: const Color(0xFFFFB84D),
      danger: const Color(0xFFFF5A5F),
    );
  }

  ThemeData data(Brightness brightness) => VitalsTheme.fromColors(
        colors(brightness),
        accent: AppAccent.patternsCobalt,
      );
}

final class _Ground {
  const _Ground({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.stroke,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color stroke;
}

/// The chosen theme and light / dark / system, remembered on the phone.
final class ThemeChoice {
  const ThemeChoice({this.theme = TidelineTheme.tide, this.mode = ThemeMode.system});

  final TidelineTheme theme;
  final ThemeMode mode;

  ThemeChoice copyWith({TidelineTheme? theme, ThemeMode? mode}) =>
      ThemeChoice(theme: theme ?? this.theme, mode: mode ?? this.mode);

  static const _themeKey = 'patterns.theme';
  static const _modeKey = 'patterns.themeMode';

  static Future<ThemeChoice> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeChoice(
      theme: TidelineTheme.values.firstWhere(
        (t) => t.name == prefs.getString(_themeKey),
        orElse: () => TidelineTheme.tide,
      ),
      mode: ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_modeKey),
        orElse: () => ThemeMode.system,
      ),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    await prefs.setString(_modeKey, mode.name);
  }
}

/// Holds the theme choice above the app, so Settings can change it and every
/// screen redraws at once.
class ThemeScope extends InheritedNotifier<ValueNotifier<ThemeChoice>> {
  const ThemeScope({
    required ValueNotifier<ThemeChoice> choice,
    required super.child,
    super.key,
  }) : super(notifier: choice);

  static ValueNotifier<ThemeChoice>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;
}
