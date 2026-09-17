import 'package:patterns_core/patterns_core.dart';
import 'package:test/test.dart';

void main() {
  final samples = <MetricKind, MetricValue>{
    MetricKind.scale: const NumberValue(7, kind: MetricKind.scale),
    MetricKind.percent: const NumberValue(65, kind: MetricKind.percent),
    MetricKind.count: const NumberValue(3, kind: MetricKind.count),
    MetricKind.duration: const NumberValue(45, kind: MetricKind.duration),
    MetricKind.amount: const NumberValue(5.5, kind: MetricKind.amount),
    MetricKind.boolean: const BooleanValue(true),
    MetricKind.choice: const ChoiceValue('vece'),
    MetricKind.tags: TagsValue(const ['tuga', 'overthink']),
    MetricKind.text: const TextValue('bila sam tuzna zbog posla'),
    MetricKind.photo: const PhotoValue(photoId: 'p1', caption: 'poslije treninga'),
    MetricKind.timeOfDay: const TimeOfDayValue(23 * 60 + 40),
  };

  test('every kind has a sample, so this suite cannot rot silently', () {
    expect(samples.keys.toSet(), MetricKind.values.toSet());
  });

  test('every value survives the round trip unchanged', () {
    samples.forEach((kind, value) {
      final restored = decodeValue(kind, value.toWire());
      expect(restored, value, reason: kind.wireName);
    });
  });

  test('an empty tag set survives, because it is an answer', () {
    final restored = decodeValue(MetricKind.tags, TagsValue(const []).toWire());
    expect((restored! as TagsValue).isExplicitNone, isTrue);
  });

  group('a private diary entry', () {
    test('round-trips with its flag', () {
      const value = TextValue('samo za mene', isPrivate: true);
      final restored = decodeValue(MetricKind.text, value.toWire());
      expect(restored, value);
      expect((restored! as TextValue).isPrivate, isTrue);
    });

    test('an entry written before the flag existed reads as not private', () {
      // A plain string is what every diary row looked like until now.
      final restored = decodeValue(MetricKind.text, 'stari unos');
      expect(restored, const TextValue('stari unos'));
    });

    test('a non-private entry still writes the old plain string', () {
      expect(const TextValue('obican').toWire(), 'obican');
    });
  });

  test('a photo with no caption round-trips', () {
    const value = PhotoValue(photoId: 'p2');
    expect(decodeValue(MetricKind.photo, value.toWire()), value);
  });

  group('a bad row costs one row, never the import', () {
    test('a wrong shape decodes to null instead of throwing', () {
      expect(decodeValue(MetricKind.scale, 'seven'), isNull);
      expect(decodeValue(MetricKind.boolean, 1), isNull);
      expect(decodeValue(MetricKind.timeOfDay, 2000), isNull);
      expect(decodeValue(MetricKind.photo, {'caption': 'no file'}), isNull);
    });

    test('an unknown kind name decodes to null', () {
      expect(MetricKind.fromWire('telepathy'), isNull);
    });
  });

  test('kind names are stable strings, not positions in the enum', () {
    expect(MetricKind.scale.wireName, 'scale');
    expect(MetricKind.timeOfDay.wireName, 'timeOfDay');
    expect(DayAggregation.peak.wireName, 'peak');
    expect(DisplayStyle.backgroundBand.wireName, 'backgroundBand');
  });
}
