import 'package:flutter/widgets.dart';

/// Per-app accent identity.
///
/// Section 7 of `00-foundation/DESIGN-SYSTEM.md`, and it is mandatory rather
/// than decorative: ten apps that look identical is an App Review 4.3
/// rejection, and on the App Store that costs the whole developer account.
/// The colour drawn on top of an accent is chosen per brightness, not per
/// accent, because one accent needs different text in each mode.
///
/// **Measured, not assumed.** `DESIGN-SYSTEM.md` originally said white text on
/// the coral and violet accents; at 15px that fails WCAG AA outright - 3.27:1
/// on interval red, 3.25:1 on magenta, 2.59:1 on coral. Ink wins on twelve of
/// the fourteen accents. The exception is stitchbook's berry, which is dark
/// enough to need white in light mode and light enough to need ink in dark
/// mode. `theme_test.dart` re-measures every pair on every build.
enum AppAccent {
  soundIndigo(Color(0xFF7C6CFF), onLight: _ink, onDark: _ink),
  intervalRed(Color(0xFFFF4D4D), onLight: _ink, onDark: _ink),
  focusLime(Color(0xFFC8FF3D), onLight: _ink, onDark: _ink),
  babyTeal(Color(0xFF4DD4C0), onLight: _ink, onDark: _ink),
  pantryAmber(Color(0xFFFFB020), onLight: _ink, onDark: _ink),
  plantMoss(Color(0xFF5FBF6A), onLight: _ink, onDark: _ink),
  choreCoral(Color(0xFFFF7A45), onLight: _ink, onDark: _ink),
  photoCyan(Color(0xFF3DD6FF), onLight: _ink, onDark: _ink),
  travelSand(Color(0xFFE0B77A), onLight: _ink, onDark: _ink),
  wheelMagenta(Color(0xFFFF3DA5), onLight: _ink, onDark: _ink),
  stitchBerry(
    Color(0xFF9B2C5F),
    dark: Color(0xFFF06595),
    onLight: _white,
    onDark: _ink,
  ),
  groveBlossom(Color(0xFFFF9EC4), onLight: _ink, onDark: _ink),
  tallyMint(Color(0xFF4FE3A1), onLight: _ink, onDark: _ink),

  /// Patterns. A mid cobalt rather than the pale blue-lavender of the icon:
  /// the pale version fails 4.5:1 against ink, and an accent that cannot carry
  /// button text is decoration rather than an accent.
  patternsCobalt(Color(0xFF5B8DEF), onLight: _ink, onDark: _ink);

  const AppAccent(
    this.light, {
    required Color onLight,
    required Color onDark,
    Color? dark,
  })  : _dark = dark,
        _onLight = onLight,
        _onDark = onDark;

  /// The accent as used on a light ground.
  final Color light;

  final Color? _dark;
  final Color _onLight;
  final Color _onDark;

  /// The accent as used on a dark ground.
  ///
  /// Only `stitchBerry` differs: a berry dark enough to read on warm off-white
  /// disappears against near-black, so it lightens.
  Color get dark => _dark ?? light;

  /// The accent for [brightness].
  Color forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Text and icons drawn on top of the accent in [brightness].
  Color onAccentFor(Brightness brightness) =>
      brightness == Brightness.dark ? _onDark : _onLight;

  static const _ink = Color(0xFF0E1116);
  static const _white = Color(0xFFFFFFFF);
}

/// The colour tokens for one app in one brightness.
///
/// Rule from `CROSS-PLATFORM.md` and the theme rule in tally's plan: **no
/// component may hardcode a colour.** Everything reads from here, which is what
/// makes a fourth theme cost an afternoon instead of a redesign.
@immutable
final class VitalsColors {
  const VitalsColors({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.stroke,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.danger,
  });

  /// The shared dark palette. Design here first; light is the mirror.
  factory VitalsColors.dark(AppAccent accent) => VitalsColors(
        brightness: Brightness.dark,
        bg: const Color(0xFF0E1116),
        surface: const Color(0xFF171B22),
        surfaceAlt: const Color(0xFF1F242D),
        stroke: const Color(0xFF2A313C),
        ink: const Color(0xFFF5F7FA),
        inkMuted: const Color(0xFF9AA4B2),
        inkFaint: const Color(0xFF5C6673),
        accent: accent.dark,
        onAccent: accent.onAccentFor(Brightness.dark),
        success: _success,
        warning: _warning,
        danger: _danger,
      );

  /// The shared light palette. Required, and never skipped.
  factory VitalsColors.light(AppAccent accent) => VitalsColors(
        brightness: Brightness.light,
        bg: const Color(0xFFF4F6F9),
        surface: const Color(0xFFFFFFFF),
        surfaceAlt: const Color(0xFFEDF0F5),
        stroke: const Color(0xFFDDE2EA),
        ink: const Color(0xFF0E1116),
        inkMuted: const Color(0xFF5C6673),
        inkFaint: const Color(0xFF9AA4B2),
        accent: accent.light,
        onAccent: accent.onAccentFor(Brightness.light),
        success: _success,
        warning: _warning,
        danger: _danger,
      );

  final Brightness brightness;

  /// App background.
  final Color bg;

  /// Cards and sheets.
  final Color surface;

  /// Nested cards, input fields, chips.
  final Color surfaceAlt;

  /// Hairlines and dividers.
  final Color stroke;

  /// Primary text and big numerals.
  final Color ink;

  /// Labels, secondary text, axis text.
  final Color inkMuted;

  /// Disabled and placeholder text.
  final Color inkFaint;

  /// Primary action, active state, chart fill.
  ///
  /// A fill and stroke colour. **Never small text on a light ground** - the
  /// lime accent on white fails contrast outright.
  final Color accent;

  /// Text drawn on top of [accent].
  final Color onAccent;

  /// Streaks and completion.
  final Color success;

  /// Caution and expiring-soon.
  final Color warning;

  /// Destructive and overdue.
  final Color danger;

  /// Semantic colours do not change across modes, so a state means one thing
  /// everywhere in the portfolio.
  static const _success = Color(0xFF37D67A);
  static const _warning = Color(0xFFFFB84D);
  static const _danger = Color(0xFFFF5A5F);

  /// The vertical accent fade used under area charts.
  LinearGradient get accentGlow => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent, accent.withValues(alpha: 0)],
      );

  /// The 135 degree sheen allowed on the top hero card only.
  LinearGradient get heroSheen => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [surfaceAlt, surface],
      );

  /// Light mode gets one soft shadow. Dark mode gets none: depth there comes
  /// from surface value contrast plus a 1px [stroke] hairline.
  List<BoxShadow> get cardShadow => brightness == Brightness.dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0F0E1116),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ];
}
