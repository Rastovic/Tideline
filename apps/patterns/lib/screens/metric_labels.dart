import 'dart:ui' show Color;


/// A marker's own colour, or null when it has none this build can read.
///
/// Null rather than a fallback, because the fallback is a theme colour and this
/// file does not know the theme.
Color? markerColor(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}
