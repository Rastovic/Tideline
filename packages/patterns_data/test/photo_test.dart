import 'package:drift/native.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:test/test.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';
final now = DateTime.utc(2026, 8, 19, 10);

void main() {
  late PatternsDatabase db;
  late PhotoRepository photos;

  setUp(() {
    db = PatternsDatabase(NativeDatabase.memory());
    photos = PhotoRepository(db, installId: install);
  });
  tearDown(() => db.close());

  Future<StoredPhoto> add({
    String dayKey = '2026-08-19',
    String? metricId,
    String? caption,
    int bytes = 240000,
    int hour = 9,
  }) =>
      photos.add(
        dayKey: dayKey,
        utcOffsetMinutes: 120,
        fileName: '${dayKey}_$hour.jpg',
        thumbFileName: '${dayKey}_$hour-thumb.jpg',
        byteSize: bytes,
        capturedAt: DateTime.utc(2026, 8, 19, hour),
        metricId: metricId,
        caption: caption,
      );

  test('a photo can belong to a marker or to the day alone', () async {
    await add(metricId: seedIds['bloating']);
    await add(hour: 20, caption: 'poslije treninga');

    final onDay = await photos.onDay('2026-08-19');
    expect(onDay, hasLength(2));
    expect(onDay.where((p) => p.isFree), hasLength(1));
    expect(onDay.last.caption, 'poslije treninga');
  });

  test('there is no count cap, only a size budget', () async {
    for (var hour = 0; hour < 30; hour++) {
      await add(hour: hour, metricId: seedIds['bloating']);
    }
    final stored = await photos.forMetric(seedIds['bloating']!);
    expect(stored, hasLength(30));
    expect(await photos.totalBytes(), 30 * 240000);
  });

  test('the previous shot is available for the ghost overlay', () async {
    await add(hour: 8, metricId: seedIds['bloating']);
    await add(hour: 19, metricId: seedIds['bloating']);
    final latest = await photos.mostRecentFor(seedIds['bloating']!);
    expect(latest!.fileName, contains('_19'));
  });

  test('deleting is soft, and never touches the file', () async {
    final photo = await add(metricId: seedIds['bloating']);
    await photos.softDelete(photo.id, now: now);

    expect(await photos.onDay('2026-08-19'), isEmpty);
    // The row survives with its file name, so a restore or an undo has
    // something to point at. Removing bytes is always the user's call.
    final raw = await db.select(db.photos).get();
    expect(raw.single.fileName, photo.fileName);
    expect(raw.single.deletedAt, isNotNull);
    expect(await photos.totalBytes(), 0);
  });

  test('a caption can be added later, and it is searchable text', () async {
    final photo = await add();
    await photos.setCaption(photo.id, 'koza poslije mjesec dana');
    final stored = await photos.onDay('2026-08-19');
    expect(stored.single.caption, 'koza poslije mjesec dana');
  });
}
