import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/data/photo_picker.dart';
import 'package:patterns/data/photo_store.dart';
import 'package:patterns/screens/day_detail_screen.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_ui/vitals_ui.dart';

const install = '018f2c00-aaaa-7000-8000-000000000001';

/// Hands back bytes without a camera.
class FakePicker extends PhotoPicker {
  const FakePicker(this.bytes);

  final Uint8List? bytes;

  @override
  Future<Uint8List?> pick(
    PhotoSource source, {
    required BuildContext context,
    String? ghostPath,
  }) async =>
      bytes;
}

/// A photo bigger than the storage rule allows, so the resize is observable.
Uint8List bigPhoto() {
  final image = img.Image(width: 2400, height: 1600);
  img.fill(image, color: img.ColorRgb8(120, 140, 200));
  return img.encodeJpg(image, quality: 95);
}

/// Remembers which previous photo the camera was asked to show.
class RecordingPicker extends PhotoPicker {
  RecordingPicker(this.bytes);

  final Uint8List bytes;
  final ghosts = <String?>[];

  @override
  Future<Uint8List?> pick(
    PhotoSource source, {
    required BuildContext context,
    String? ghostPath,
  }) async {
    ghosts.add(ghostPath);
    return bytes;
  }
}

void main() {
  late Directory temp;
  late PatternsController controller;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('patterns_photos');
    controller = PatternsController(
      db: PatternsDatabase(NativeDatabase.memory()),
      installId: install,
      dayBoundaryHour: 4,
      photoStore: PhotoStore(temp, useIsolate: false),
    );
    await controller.seedIfNeeded();
  });

  tearDown(() {
    controller.dispose();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('a captured photo is downscaled at capture, and the original is not kept',
      () async {
    final photo = await controller.capturePhoto(bigPhoto());
    expect(photo, isNotNull);

    final store = controller.photoStore!;
    final full = img.decodeJpg(
      await store.fileFor(photo!.fileName).readAsBytes(),
    )!;
    final thumb = img.decodeJpg(
      await store.fileFor(photo.thumbFileName).readAsBytes(),
    )!;

    expect(full.width, PhotoStore.longEdge);
    expect(thumb.width, PhotoStore.thumbEdge);
    // A 3000px q95 original is megabytes. Daily for a year at that size is an
    // app people uninstall to reclaim space.
    expect(photo.byteSize, lessThan(500 * 1024));
    expect(store.bytesOnDisk(), photo.byteSize);
  });

  test('a free photo belongs to the day, with no marker and no observation',
      () async {
    final photo = await controller.capturePhoto(bigPhoto());
    expect(photo!.isFree, isTrue);
    expect(await controller.readingsOn(controller.today), isEmpty);
    expect(await controller.photosOn(controller.today), hasLength(1));
  });

  test('a marker photo also writes a reading pointing at it', () async {
    // A photo marker is made the ordinary way: no seeded marker is a photo
    // marker, because which part of yourself you photograph is not something
    // the app gets to assume.
    final skin = Metric.create(
      id: '0198aa03-0000-7000-8000-000000000001',
      name: 'koza',
      domain: MetricDomain.body,
      kind: MetricKind.photo,
      createdAt: DateTime.now().toUtc(),
    );
    await controller.metrics.save(skin, now: DateTime.now().toUtc());
    await controller.refresh();

    final photo = await controller.capturePhoto(
      bigPhoto(),
      metricId: skin.id,
    );
    final readings = await controller.readingsOn(controller.today);
    expect(readings, hasLength(1));
    expect((readings.single.value as PhotoValue).photoId, photo!.id);
  });

  test('deleting a photo removes the row and the files, and only on request',
      () async {
    final photo = await controller.capturePhoto(bigPhoto());
    final store = controller.photoStore!;
    expect(store.fileFor(photo!.fileName).existsSync(), isTrue);

    await controller.deletePhoto(photo);

    expect(store.fileFor(photo.fileName).existsSync(), isFalse);
    expect(store.fileFor(photo.thumbFileName).existsSync(), isFalse);
    expect(await controller.photosOn(controller.today), isEmpty);
  });

  // Everything below runs its file work inside `runAsync`.
  //
  // `testWidgets` drives a fake clock, and a real file write or a real JPEG
  // decode never completes against one - the test simply waits out its ten
  // minute timeout. This cost an hour to find, so it is written down here
  // rather than rediscovered.

  testWidgets('the day screen captures a photo through the sheet',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: DayDetailScreen(
        controller: controller,
        dayKey: controller.today,
        picker: FakePicker(bigPhoto()),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo of the day'));
    await tester.pumpAndSettle();

    // The tap has to happen against the fake clock, and the file write that
    // follows it has to happen against the real one. Pumping inside runAsync
    // is forbidden, so the two are interleaved rather than nested.
    await tester.tap(find.text('From gallery'));
    // pumpAndSettle, not pump: the sheet's dismissal animation has to finish
    // before showModalBottomSheet's future resolves and the picker is called.
    await tester.pumpAndSettle();

    // The capture crosses the two clocks several times - pick, resize, two file
    // writes, two inserts - and each crossing needs one turn of each. runAsync
    // lets the real IO finish; the pump after it delivers the continuation back
    // into the fake zone. One round is not enough, so this alternates.
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }

    final stored = await tester.runAsync(
      () => controller.photosOn(controller.today),
    );
    expect(stored, hasLength(1));
  });

  testWidgets('a stored photo renders as a thumbnail on its day',
      (tester) async {
    await tester.runAsync(() => controller.capturePhoto(bigPhoto()));

    await tester.pumpWidget(MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: DayDetailScreen(controller: controller, dayKey: controller.today),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a photo whose file is gone says so instead of breaking',
      (tester) async {
    await tester.runAsync(() async {
      final photo = await controller.capturePhoto(bigPhoto(), caption: 'koza');
      await controller.photoStore!.deleteFiles(
        photo!.fileName,
        photo.thumbFileName,
      );
    });

    await tester.pumpWidget(MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: DayDetailScreen(controller: controller, dayKey: controller.today),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('koza'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
  group('the ghost at capture', () {
    test('is the marker\'s most recent photo, and its file exists', () async {
      final metric = Metric.create(
        id: '018f2c00-dddd-7000-8000-000000000002',
        name: 'kosa',
        domain: MetricDomain.body,
        kind: MetricKind.photo,
        createdAt: DateTime.utc(2026),
      );
      await controller.saveMetric(metric);
      expect(await controller.ghostPathFor(metric.id), isNull);

      await controller.capturePhoto(bigPhoto(), metricId: metric.id);
      final second =
          await controller.capturePhoto(bigPhoto(), metricId: metric.id);

      final ghost = await controller.ghostPathFor(metric.id);
      expect(ghost, controller.photoStore!.pathFor(second!.fileName));
      expect(File(ghost!).existsSync(), isTrue);
    });

    testWidgets('a photo of the day on its own has nothing to line up with',
        (tester) async {
      final picker = RecordingPicker(bigPhoto());
      await tester.pumpWidget(MaterialApp(
        theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
        home: DayDetailScreen(
          controller: controller,
          dayKey: controller.today,
          picker: picker,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo of the day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      expect(picker.ghosts, [null]);
    });
  });
}
