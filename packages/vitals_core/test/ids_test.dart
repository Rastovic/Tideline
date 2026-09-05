import 'package:test/test.dart';
import 'package:vitals_core/vitals_core.dart';

void main() {
  group('Ids', () {
    test('newId produces a valid uuid', () {
      expect(Ids.isValid(Ids.newId()), isTrue);
    });

    test('newId is unique across a large batch', () {
      final ids = {for (var i = 0; i < 10000; i++) Ids.newId()};
      expect(ids.length, 10000);
    });

    test('newId sorts chronologically across milliseconds', () async {
      // The reason v7 was chosen: an index over ids stays local instead of
      // scattering. The guarantee is millisecond-granular, so the ids must be
      // minted in distinct milliseconds for order to mean anything.
      final ids = <String>[];
      for (var i = 0; i < 5; i++) {
        ids.add(Ids.newId());
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      expect(ids, orderedEquals([...ids]..sort()));
    });

    test('ids minted in the same millisecond carry no order guarantee', () {
      // Documents the limit rather than pretending it away. Anything needing a
      // definite order carries an explicit sortOrder or timestamp column.
      final batch = List.generate(200, (_) => Ids.newId());
      expect(batch.toSet().length, 200, reason: 'still unique');
    });

    test('newRandomId is valid and unique', () {
      final ids = {for (var i = 0; i < 1000; i++) Ids.newRandomId()};
      expect(ids.length, 1000);
      expect(ids.every(Ids.isValid), isTrue);
    });

    test('isValid rejects things that are not uuids', () {
      for (final bad in [
        '',
        '47',
        'not-a-uuid',
        '018f2c00-0000-0000-0000',
        '018f2c00-0000-0000-0000-00000000000g',
      ]) {
        expect(Ids.isValid(bad), isFalse, reason: bad);
      }
    });

    test('isValid accepts both cases', () {
      final id = Ids.newId();
      expect(Ids.isValid(id.toUpperCase()), isTrue);
      expect(Ids.isValid(id.toLowerCase()), isTrue);
    });
  });
}
