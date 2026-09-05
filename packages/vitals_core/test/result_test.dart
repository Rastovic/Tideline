import 'package:test/test.dart';
import 'package:vitals_core/vitals_core.dart';

void main() {
  group('Result', () {
    test('reports which side it holds', () {
      const ok = Ok<int, String>(1);
      const err = Err<int, String>('boom');
      expect(ok.isOk, isTrue);
      expect(ok.isErr, isFalse);
      expect(err.isErr, isTrue);
      expect(err.isOk, isFalse);
    });

    test('exposes the held side and nulls the other', () {
      const ok = Ok<int, String>(1);
      const err = Err<int, String>('boom');
      expect(ok.valueOrNull, 1);
      expect(ok.errorOrNull, isNull);
      expect(err.valueOrNull, isNull);
      expect(err.errorOrNull, 'boom');
    });

    test('valueOr falls back only on failure', () {
      expect(const Ok<int, String>(1).valueOr(9), 1);
      expect(const Err<int, String>('boom').valueOr(9), 9);
    });

    test('map transforms a value and leaves a failure alone', () {
      expect(const Ok<int, String>(2).map((v) => v * 3), const Ok<int, String>(6));
      expect(
        const Err<int, String>('boom').map((v) => v * 3),
        const Err<int, String>('boom'),
      );
    });

    test('mapErr transforms a failure and leaves a value alone', () {
      expect(
        const Err<int, String>('boom').mapErr((e) => e.length),
        const Err<int, int>(4),
      );
      expect(
        const Ok<int, String>(2).mapErr((e) => e.length),
        const Ok<int, int>(2),
      );
    });

    test('flatMap chains and short-circuits', () {
      Result<int, String> half(int v) =>
          v.isEven ? Ok(v ~/ 2) : const Err('odd');

      expect(const Ok<int, String>(8).flatMap(half), const Ok<int, String>(4));
      expect(const Ok<int, String>(7).flatMap(half), const Err<int, String>('odd'));
      expect(
        const Err<int, String>('earlier').flatMap(half),
        const Err<int, String>('earlier'),
      );
    });

    test('fold collapses both sides', () {
      String describe(Result<int, String> r) =>
          r.fold((v) => 'value $v', (e) => 'error $e');

      expect(describe(const Ok(1)), 'value 1');
      expect(describe(const Err('boom')), 'error boom');
    });

    test('a switch over the sealed type is exhaustive without a default', () {
      // If a third subtype is ever added, this stops compiling. That is the
      // point of sealing it.
      String describe(Result<int, String> r) => switch (r) {
            Ok(:final value) => 'value $value',
            Err(:final error) => 'error $error',
          };

      expect(describe(const Ok(1)), 'value 1');
      expect(describe(const Err('boom')), 'error boom');
    });

    test('equality is by contents', () {
      expect(const Ok<int, String>(1), const Ok<int, String>(1));
      expect(const Ok<int, String>(1), isNot(const Ok<int, String>(2)));
      expect(const Err<int, String>('a'), const Err<int, String>('a'));
      expect(
        const Ok<int, String>(1).hashCode,
        const Ok<int, String>(1).hashCode,
      );
    });
  });
}
