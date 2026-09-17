import 'package:patterns_core/patterns_core.dart';
import 'package:test/test.dart';

final createdAt = DateTime.utc(2026, 8, 19, 9);

Metric scaleMarker({int min = 1, int max = 10}) => Metric.create(
      id: 'm1',
      name: 'nadutost',
      domain: MetricDomain.body,
      kind: MetricKind.scale,
      createdAt: createdAt,
      scaleMin: min,
      scaleMax: max,
      lowLabel: 'nista',
      highLabel: 'jako',
    );

Metric tagsMarker(List<MetricOption> options) => Metric.create(
      id: 'm2',
      name: 'osjecanja',
      domain: MetricDomain.mind,
      kind: MetricKind.tags,
      createdAt: createdAt,
      options: options,
    );

const tuga = MetricOption(id: 'o1', label: 'tuga');
const ljutnja = MetricOption(id: 'o2', label: 'ljutnja');
const sram = MetricOption(id: 'o3', label: 'sram');

void main() {
  group('an untouched marker can be changed freely', () {
    test('retyping is allowed while nothing has been recorded', () {
      final before = scaleMarker();
      final after = Metric.create(
        id: 'm1',
        name: 'nadutost',
        domain: MetricDomain.body,
        kind: MetricKind.boolean,
        createdAt: createdAt,
      );

      expect(
        validateMetricChange(before, after, facts: MetricReadingFacts.none),
        isEmpty,
      );
    });

    test('an option added by mistake can be removed outright', () {
      // Nothing ever picked it, so nothing points at its id, so removing it
      // costs no history. Archiving here would be ceremony.
      final before = tagsMarker(const [tuga, ljutnja]);
      final after = tagsMarker(const [tuga, MetricOption(id: 'o3', label: 'sram')]);

      expect(
        validateMetricChange(before, after, facts: MetricReadingFacts.none),
        isEmpty,
      );
    });
  });

  group('readings make some edits data loss', () {
    test('retyping a marker that holds readings is refused, with the count', () {
      final before = scaleMarker();
      final after = Metric.create(
        id: 'm1',
        name: 'nadutost',
        domain: MetricDomain.body,
        kind: MetricKind.percent,
        createdAt: createdAt,
      );

      final problems = validateMetricChange(
        before,
        after,
        facts: const MetricReadingFacts(count: 214),
      );

      expect(problems.map((p) => p.field), contains('kind'));
      expect(problems.first.message, contains('214'));
      expect(problems.first.message, contains('Archive'));
    });

    test('the two widenings that cannot lose meaning stay allowed', () {
      final before = Metric.create(
        id: 'm1',
        name: 'case',
        domain: MetricDomain.body,
        kind: MetricKind.count,
        createdAt: createdAt,
      );
      final after = Metric.create(
        id: 'm1',
        name: 'case',
        domain: MetricDomain.body,
        kind: MetricKind.amount,
        createdAt: createdAt,
        unit: 'g',
      );

      expect(
        validateMetricChange(
          before,
          after,
          facts: const MetricReadingFacts(count: 90),
        ),
        isEmpty,
      );
    });

    test('narrowing a scale under a reading that exists is refused', () {
      final problems = validateMetricChange(
        scaleMarker(),
        scaleMarker(min: 4),
        facts: const MetricReadingFacts(
          count: 12,
          lowestNumber: 2,
          highestNumber: 9,
        ),
      );

      expect(problems.single.field, 'scale');
      expect(problems.single.message, contains('2'));
    });

    test('narrowing a scale over a reading that exists is refused', () {
      final problems = validateMetricChange(
        scaleMarker(),
        scaleMarker(max: 7),
        facts: const MetricReadingFacts(
          count: 12,
          lowestNumber: 2,
          highestNumber: 9,
        ),
      );

      expect(problems.single.field, 'scale');
      expect(problems.single.message, contains('9'));
    });

    test('widening a scale is always fine', () {
      expect(
        validateMetricChange(
          scaleMarker(),
          scaleMarker(min: 0, max: 12),
          facts: const MetricReadingFacts(
            count: 12,
            lowestNumber: 2,
            highestNumber: 9,
          ),
        ),
        isEmpty,
      );
    });

    test('removing an option that has been picked is refused by name', () {
      final problems = validateMetricChange(
        tagsMarker(const [tuga, ljutnja]),
        tagsMarker(const [tuga, sram]),
        facts: const MetricReadingFacts(count: 30, usedOptionIds: {'o2'}),
      );

      expect(problems.single.field, 'options');
      expect(problems.single.message, contains('ljutnja'));
      expect(problems.single.message, contains('Archive'));

      // The same refusal in the other language, same fields, same count.
      final serbian = validateMetricChange(
        tagsMarker(const [tuga, ljutnja]),
        tagsMarker(const [tuga, sram]),
        facts: const MetricReadingFacts(count: 30, usedOptionIds: {'o2'}),
        language: TextLanguage.sr,
      );
      expect(serbian.single.field, 'options');
      expect(serbian.single.message, contains('Arhiviraj'));
    });

    test('archiving an option is not removing it', () {
      // The id stays on the marker, so every reading that picked it still
      // resolves. It just stops being offered.
      final problems = validateMetricChange(
        tagsMarker(const [tuga, ljutnja, sram]),
        tagsMarker(const [
          tuga,
          MetricOption(id: 'o2', label: 'ljutnja', archived: true),
          sram,
        ]),
        facts: const MetricReadingFacts(count: 30, usedOptionIds: {'o2'}),
      );

      expect(problems, isEmpty);
    });

    test('archiving down to one live option is refused, as it always was', () {
      // Not a history guard - the ordinary rule that a list to pick from
      // needs something to pick between. Worth pinning here because archiving
      // is the escape hatch this file keeps recommending.
      final problems = validateMetricChange(
        tagsMarker(const [tuga, ljutnja]),
        tagsMarker(const [
          tuga,
          MetricOption(id: 'o2', label: 'ljutnja', archived: true),
        ]),
        facts: const MetricReadingFacts(count: 30, usedOptionIds: {'o2'}),
      );

      expect(problems.single.message, 'Add at least two options.');
    });
  });

  test('the ordinary rules still apply to the edited marker', () {
    // validateMetricChange is validateMetric plus the history guards, never
    // a way around it.
    final problems = validateMetricChange(
      scaleMarker(),
      scaleMarker().copyWith(name: '   '),
      facts: MetricReadingFacts.none,
    );

    expect(problems.map((p) => p.field), contains('name'));
  });
}
