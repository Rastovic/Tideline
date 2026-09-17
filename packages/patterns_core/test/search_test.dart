import 'package:patterns_core/patterns_core.dart';
import 'package:test/test.dart';

void main() {
  test('diacritics and case do not count', () {
    expect(matchesQuery('Bila sam tužna zbog posla', 'TUZNA'), isTrue);
    expect(matchesQuery('bila sam tuzna', 'tužna'), isTrue);
    expect(matchesQuery('Đurđevdan', 'djurdjevdan'), isTrue);
    expect(matchesQuery('čćšžđ', 'ccszd'), isTrue);
  });

  test('every word must be there, in any order', () {
    const entry = 'umorna, konflikt na poslu';
    expect(matchesQuery(entry, 'poslu umorna'), isTrue);
    expect(matchesQuery(entry, 'poslu trening'), isFalse);
  });

  test('an empty query matches nothing', () {
    expect(matchesQuery('bilo sta', ''), isFalse);
    expect(matchesQuery('bilo sta', '   '), isFalse);
  });
}
