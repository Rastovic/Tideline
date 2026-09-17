/// The language the engine writes its own words in.
///
/// Only messages the engine composes - a refusal, an export heading. Marker
/// names, option labels and diary text are the person's own and are never
/// translated by anything in here.
enum TextLanguage {
  en,
  sr;

  String pick(String en, String sr) => this == TextLanguage.en ? en : sr;
}
