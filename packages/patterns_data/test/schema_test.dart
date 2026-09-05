import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:test/test.dart';

PatternsDatabase openMemory() => PatternsDatabase(NativeDatabase.memory());

void main() {
  late PatternsDatabase db;

  setUp(() => db = openMemory());
  tearDown(() => db.close());

  group('the portability rules are structural, not aspirational', () {
    test('every table carries the four portable columns', () {
      // Rules 1 to 4 of DATA-PORTABILITY.md, asserted over the real schema so
      // a table added later without the mixin fails here rather than six
      // months into use, when the archive is the only copy that matters.
      for (final table in db.allTables) {
        final columns = {for (final c in table.$columns) c.name};
        expect(columns, contains('id'), reason: table.actualTableName);
        expect(columns, contains('updated_at'), reason: table.actualTableName);
        expect(columns, contains('deleted_at'), reason: table.actualTableName);
        expect(columns, contains('install_id'), reason: table.actualTableName);
      }
    });

    test('rows that belong to a day carry a frozen day key and an offset', () {
      for (final name in ['observations', 'photos']) {
        final table =
            db.allTables.firstWhere((t) => t.actualTableName == name);
        final columns = {for (final c in table.$columns) c.name};
        expect(columns, contains('day_key'), reason: name);
        expect(columns, contains('tz_offset_minutes'), reason: name);
      }
    });

    test('the observations table is long, not wide', () async {
      // One row per reading. A column per marker would make every new marker a
      // migration, which kills user-created markers outright - and they are the
      // reason this app exists.
      final table =
          db.allTables.firstWhere((t) => t.actualTableName == 'observations');
      final columns = {for (final c in table.$columns) c.name};
      expect(columns, contains('metric_id'));
      expect(columns, contains('value_json'));
      expect(columns.length, lessThan(15));
    });

    test('no enum is stored as a number', () {
      final metrics =
          db.allTables.firstWhere((t) => t.actualTableName == 'metrics');
      for (final name in ['kind', 'domain', 'aggregation', 'display_style']) {
        final column = metrics.$columns.firstWhere((c) => c.name == name);
        expect(column.type, DriftSqlType.string, reason: name);
      }
    });

    test('schema version is recorded, because restore depends on it', () {
      expect(db.schemaVersion, PatternsDatabase.currentSchemaVersion);
      expect(db.schemaVersion, greaterThan(0));
    });
  });

  test('the indexes the reports actually need exist', () async {
    await db.customSelect('SELECT 1').get();
    final indexes = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    final names = indexes.map((row) => row.read<String>('name')).toSet();
    expect(names, contains('idx_observations_metric_day'));
    expect(names, contains('idx_observations_day'));
  });
}
