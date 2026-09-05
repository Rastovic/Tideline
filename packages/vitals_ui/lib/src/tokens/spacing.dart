import 'package:flutter/widgets.dart';

/// The 4pt spacing scale and the radius set, from section 3 of
/// `00-foundation/DESIGN-SYSTEM.md`.
final class VitalsSpacing {
  const VitalsSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 56;

  /// Horizontal padding on every screen.
  static const double screenH = 20;

  /// Gap between stacked cards.
  static const double cardGap = 12;

  /// Padding inside a card.
  static const double cardPadding = 20;

  /// Standard height of a primary or secondary button.
  static const double buttonHeight = 56;

  /// Standard list row height. An app may shift this by up to 8 either way as
  /// part of its 4.3 differentiation.
  static const double listRowHeight = 72;

  /// Bottom navigation height.
  static const double bottomNavHeight = 64;

  /// The accessibility floor for anything tappable. Checked in Phase 7 and not
  /// negotiable.
  static const double minTapTarget = 44;
}

/// Corner radii. An app may shift these by up to 4 either way.
final class VitalsRadius {
  const VitalsRadius._();

  static const Radius hero = Radius.circular(28);
  static const Radius card = Radius.circular(24);
  static const Radius nested = Radius.circular(16);

  /// Chips, pills, FABs and primary buttons are fully round.
  static const Radius pill = Radius.circular(999);

  static const BorderRadius heroAll = BorderRadius.all(hero);
  static const BorderRadius cardAll = BorderRadius.all(card);
  static const BorderRadius nestedAll = BorderRadius.all(nested);
  static const BorderRadius pillAll = BorderRadius.all(pill);

  /// A bottom sheet rounds its top corners only.
  static const BorderRadius sheet = BorderRadius.vertical(top: hero);
}
