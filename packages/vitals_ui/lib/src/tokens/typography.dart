import 'package:flutter/widgets.dart';

/// The type scale from section 2 of `00-foundation/DESIGN-SYSTEM.md`.
///
/// System font stack throughout - SF Pro on iOS, Roboto on Android. No custom
/// font files, which saves bundle size and licensing hassle.
@immutable
final class VitalsTypography {
  const VitalsTypography._({
    required this.displayXL,
    required this.displayL,
    required this.title,
    required this.bodyStrong,
    required this.body,
    required this.label,
    required this.caption,
  });

  /// Builds the scale in [color], the app's `ink`.
  factory VitalsTypography.forColor(Color color) => VitalsTypography._(
        displayXL: TextStyle(
          color: color,
          fontSize: 56,
          height: 60 / 56,
          fontWeight: FontWeight.w700,
          letterSpacing: 56 * -0.02,
          fontFeatures: const [_tabular],
        ),
        displayL: TextStyle(
          color: color,
          fontSize: 34,
          height: 40 / 34,
          fontWeight: FontWeight.w700,
        ),
        title: TextStyle(
          color: color,
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w600,
        ),
        bodyStrong: TextStyle(
          color: color,
          fontSize: 15,
          height: 22 / 15,
          fontWeight: FontWeight.w600,
        ),
        body: TextStyle(
          color: color,
          fontSize: 15,
          height: 22 / 15,
          fontWeight: FontWeight.w400,
        ),
        label: TextStyle(
          color: color,
          fontSize: 13,
          height: 18 / 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 13 * 0.02,
        ),
        caption: TextStyle(
          color: color,
          fontSize: 11,
          height: 14 / 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 11 * 0.06,
        ),
      );

  /// The one huge number: a timer, MB freed, a balance, a streak.
  ///
  /// Tabular figures are not optional here. A live countdown in proportional
  /// figures shifts the layout every time a digit changes width.
  final TextStyle displayXL;

  /// Screen titles.
  final TextStyle displayL;

  /// Card headers.
  final TextStyle title;

  /// List primary text.
  final TextStyle bodyStrong;

  /// Body copy.
  final TextStyle body;

  /// Card labels and tab bar.
  final TextStyle label;

  /// Chart axes and badges. Rendered uppercase by the caller.
  final TextStyle caption;

  /// Applies tabular figures to any style that counts up or down.
  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: const [_tabular]);

  static const _tabular = FontFeature.tabularFigures();
}
