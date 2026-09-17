import 'dart:ui' show Color;

import 'package:patterns_core/patterns_core.dart';

/// The words the editor uses for the type system.
///
/// **Copy, not model.** The wire names in `patterns_core` are stable storage
/// keys and are never shown; these are what a person reads, and changing one
/// changes nothing on disk. They live together in one file so the editor and
/// the marker list cannot drift into calling the same thing two names.
///
/// Each kind carries a one-line `hint` as well, because the difference between
/// `scale` and `percent`, or `choice` and `tags`, is the sort of thing that is
/// obvious while writing the code and not at all obvious at 23:00 six months
/// later.
const Map<MetricKind, String> kindNames = {
  MetricKind.scale: 'Ocjena',
  MetricKind.percent: 'Postotak',
  MetricKind.count: 'Broj',
  MetricKind.duration: 'Trajanje',
  MetricKind.amount: 'Kolicina',
  MetricKind.boolean: 'Da ili ne',
  MetricKind.choice: 'Jedan izbor',
  MetricKind.tags: 'Vise izbora',
  MetricKind.text: 'Tekst',
  MetricKind.photo: 'Fotografija',
  MetricKind.timeOfDay: 'Vrijeme',
};

const Map<MetricKind, String> kindHints = {
  MetricKind.scale: 'Klizac izmedju dvije granice koje sama postavis',
  MetricKind.percent: '0 do 100, u koracima od pet',
  MetricKind.count: 'Koliko puta. Case vode, cigarete',
  MetricKind.duration: 'Sati i minute',
  MetricKind.amount: 'Broj s jedinicom. Doza, tezina',
  MetricKind.boolean: 'Bilo je ili nije bilo',
  MetricKind.choice: 'Tacno jedna opcija s tvoje liste',
  MetricKind.tags: 'Koliko god opcija s tvoje liste',
  MetricKind.text: 'Slobodan tekst. Dnevnik',
  MetricKind.photo: 'Slika s opisom',
  MetricKind.timeOfDay: 'Sat u danu. Lijeganje, ustajanje',
};

/// How a day holding several readings collapses into one value in a report.
const Map<DayAggregation, String> aggregationNames = {
  DayAggregation.sum: 'Zbir',
  DayAggregation.typical: 'Tipicno',
  DayAggregation.peak: 'Najvise',
  DayAggregation.lowest: 'Najmanje',
  DayAggregation.last: 'Zadnje',
  DayAggregation.anyTrue: 'Bilo kad tacno',
  DayAggregation.union: 'Sve zajedno',
  DayAggregation.none: 'Svaki unos posebno',
};

const Map<DayAggregation, String> aggregationHints = {
  DayAggregation.sum: '3 g i 2 g istog dana su 5 g',
  DayAggregation.typical: 'Medijana, ne prosjek',
  DayAggregation.peak: 'Vrhunac dana. Za nadutost i bol',
  DayAggregation.lowest: 'Najniza vrijednost dana',
  DayAggregation.last: 'Posljednji unos po vremenu',
  DayAggregation.anyTrue: 'Dan se broji ako je bilo makar jednom',
  DayAggregation.union: 'Sve sto je taj dan oznaceno',
  DayAggregation.none: 'Bez sazimanja',
};

const Map<DisplayStyle, String> displayNames = {
  DisplayStyle.squares: 'Kvadratici',
  DisplayStyle.bars: 'Stupci',
  DisplayStyle.dots: 'Tacke',
  DisplayStyle.brokenLine: 'Prekinuta linija',
  DisplayStyle.presenceStrip: 'Traka prisustva',
  DisplayStyle.backgroundBand: 'Pozadinska traka',
  DisplayStyle.tagRows: 'Red po opciji',
};

const Map<MetricDomain, String> domainNames = {
  MetricDomain.mind: 'UM',
  MetricDomain.body: 'TIJELO',
  MetricDomain.cycle: 'CIKLUS',
};

/// A marker's own colour, or null when it has none this build can read.
///
/// Null rather than a fallback, because the fallback is a theme colour and this
/// file does not know the theme.
Color? markerColor(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}
