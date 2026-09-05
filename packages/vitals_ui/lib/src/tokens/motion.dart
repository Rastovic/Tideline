import 'package:flutter/widgets.dart';

/// Motion tokens from section 5 of `00-foundation/DESIGN-SYSTEM.md`.
final class VitalsMotion {
  const VitalsMotion._();

  /// The default transition.
  static const Duration standard = Duration(milliseconds: 220);

  /// Presenting a bottom sheet.
  static const Duration sheet = Duration(milliseconds: 320);

  /// Press feedback.
  static const Duration press = Duration(milliseconds: 90);

  static const Curve standardCurve = Curves.easeOutCubic;

  /// Spring damping for a presenting sheet.
  static const double sheetDamping = 0.85;

  /// Scale applied while a control is held down.
  static const double pressScale = 0.97;

  /// Returns [duration], or [Duration.zero] when the OS asks for reduced
  /// motion.
  ///
  /// **This is an accessibility requirement, not a nicety.** Every non-essential
  /// animation in the portfolio routes through here.
  static Duration respecting(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

  /// True when the OS has asked for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
