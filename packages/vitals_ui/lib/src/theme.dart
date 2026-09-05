// Cupertino is imported for the iOS page transition only. This is declarative
// theming, not a platform branch: no `Platform.is` check exists here, and the
// same ThemeData is built on both platforms. See CROSS-PLATFORM.md rule 1.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens/colors.dart';
import 'tokens/motion.dart';
import 'tokens/spacing.dart';
import 'tokens/typography.dart';

/// Carries the Vitals tokens down the tree.
///
/// Components read `VitalsTheme.of(context)` and never a literal colour. A
/// widget test in Phase 7 asserts exactly that, per app.
@immutable
final class VitalsThemeData extends ThemeExtension<VitalsThemeData> {
  VitalsThemeData({required this.accent, required Brightness brightness})
      : colors = brightness == Brightness.dark
            ? VitalsColors.dark(accent)
            : VitalsColors.light(accent),
        typography = VitalsTypography.forColor(
          brightness == Brightness.dark
              ? const Color(0xFFF5F7FA)
              : const Color(0xFF0E1116),
        );

  const VitalsThemeData._raw({
    required this.accent,
    required this.colors,
    required this.typography,
  });

  final AppAccent accent;
  final VitalsColors colors;

  /// The type scale.
  ///
  /// **Do not rename this back to `type`.** `ThemeExtension` declares
  /// `Object get type`, used as the key this extension is stored under in
  /// `ThemeData.extensions`. A field called `type` silently overrides it, the
  /// extension gets filed under the typography instance instead of the class,
  /// and every `VitalsTheme.of(context)` throws at runtime while the code still
  /// analyzes clean.
  final VitalsTypography typography;

  @override
  VitalsThemeData copyWith({
    AppAccent? accent,
    VitalsColors? colors,
    VitalsTypography? typography,
  }) =>
      VitalsThemeData._raw(
        accent: accent ?? this.accent,
        colors: colors ?? this.colors,
        typography: typography ?? this.typography,
      );

  /// Token sets are swapped wholesale rather than interpolated: a half-blended
  /// palette mid-transition is never a state the design intends.
  @override
  VitalsThemeData lerp(ThemeExtension<VitalsThemeData>? other, double t) {
    if (other is! VitalsThemeData) return this;
    return t < 0.5 ? this : other;
  }
}

/// Builds a [ThemeData] from an accent and a brightness.
///
/// Every app's `main.dart` does exactly this and nothing more:
///
/// ```dart
/// theme: VitalsTheme.light(accent: AppAccent.tallyMint),
/// darkTheme: VitalsTheme.dark(accent: AppAccent.tallyMint),
/// ```
final class VitalsTheme {
  const VitalsTheme._();

  static ThemeData light({required AppAccent accent}) =>
      _build(accent, Brightness.light);

  static ThemeData dark({required AppAccent accent}) =>
      _build(accent, Brightness.dark);

  /// The Vitals tokens for this subtree.
  ///
  /// Throws rather than returning null: a component rendered outside a
  /// [VitalsTheme] is a wiring bug, and failing loudly in a widget test beats
  /// silently falling back to Material defaults in a release build.
  static VitalsThemeData of(BuildContext context) {
    final data = Theme.of(context).extension<VitalsThemeData>();
    if (data == null) {
      throw FlutterError(
        'No VitalsThemeData found. Wrap the app in a theme built by '
        'VitalsTheme.light() or VitalsTheme.dark().',
      );
    }
    return data;
  }

  static ThemeData _build(AppAccent accent, Brightness brightness) {
    final vitals = VitalsThemeData(accent: accent, brightness: brightness);
    final c = vitals.colors;
    final t = vitals.typography;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.stroke,
      extensions: [vitals],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.accent,
        onPrimary: c.onAccent,
        secondary: c.accent,
        onSecondary: c.onAccent,
        error: c.danger,
        onError: c.onAccent,
        surface: c.surface,
        onSurface: c.ink,
        surfaceContainerHighest: c.surfaceAlt,
        outline: c.stroke,
      ),
      textTheme: TextTheme(
        displayLarge: t.displayXL,
        displayMedium: t.displayL,
        titleLarge: t.title,
        bodyLarge: t.bodyStrong,
        bodyMedium: t.body,
        labelLarge: t.label,
        labelSmall: t.caption,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: c.stroke, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(borderRadius: VitalsRadius.sheet),
        showDragHandle: true,
        dragHandleColor: c.inkFaint,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: VitalsRadius.cardAll,
          side: BorderSide(color: c.stroke),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          minimumSize: const Size.fromHeight(VitalsSpacing.buttonHeight),
          textStyle: t.bodyStrong,
          shape: const RoundedRectangleBorder(
            borderRadius: VitalsRadius.pillAll,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          minimumSize: const Size.fromHeight(VitalsSpacing.buttonHeight),
          textStyle: t.bodyStrong,
          side: BorderSide(color: c.stroke),
          shape: const RoundedRectangleBorder(
            borderRadius: VitalsRadius.pillAll,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        height: VitalsSpacing.bottomNavHeight,
        indicatorColor: c.accent.withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(t.label),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? c.accent : c.inkMuted,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceAlt,
        contentTextStyle: t.body,
        shape: const RoundedRectangleBorder(
          borderRadius: VitalsRadius.nestedAll,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceAlt,
        circularTrackColor: c.surfaceAlt,
      ),
    );
  }
}

/// Convenience access to the tokens.
extension VitalsThemeContext on BuildContext {
  VitalsThemeData get vitals => VitalsTheme.of(this);

  VitalsColors get colors => VitalsTheme.of(this).colors;

  VitalsTypography get type => VitalsTheme.of(this).typography;

  /// [duration], or zero when the OS asks for reduced motion.
  Duration motion(Duration duration) => VitalsMotion.respecting(this, duration);
}
