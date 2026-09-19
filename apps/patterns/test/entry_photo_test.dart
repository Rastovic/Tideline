import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/data/photo_picker.dart';
import 'package:patterns/data/photo_store.dart';
import 'package:patterns/screens/home_screen.dart';
import 'package:patterns/screens/marked_days_strip.dart';
import 'package:patterns/screens/report_view_screen.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

class FakePicker extends PhotoPicker {
  const FakePicker(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List?> pick(
    PhotoSource source, {
    required BuildContext context,
    String? ghostPath,
  }) async =>
      bytes;
}

Uint8List photoBytes() {
  final image = img.Image(width: 400, height: 300);
  img.fill(image, color: img.ColorRgb8(150, 120, 90));
  return img.encodeJpg(image);
}

Widget wrap(Widget child) => MaterialApp(
      theme: VitalsTheme.light(accent: AppAccent.patternsCobalt),
      home: child,
    );

void main() {
  late Directory temp;
  late PatternsController controller;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('patterns_entry_photo');
    controller = PatternsController(
      db: PatternsDatabase(NativeDatabase.memory()),
      installId: '018f2c00-aaaa-7000-8000-000000000001',
      dayBoundaryHour: 4,
      photoStore: PhotoStore(temp, useIsolate: false),
    );
    await controller.seedIfNeeded();
  });

  tearDown(() {
    controller.dispose();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('a photo on an ordinary reading adds no reading of its own', () async {
    await controller.log(
      seedIds['bloating']!,
      const NumberValue(7, kind: MetricKind.scale),
      note: 'after the pizza',
    );
    final photo = await controller.attachPhoto(
      photoBytes(),
      metricId: seedIds['bloating']!,
      dayKey: controller.today,
    );

    expect(photo, isNotNull);
    // One reading, not two: the photo rides along, it is not a value.
    final readings = await controller.readingsOn(controller.today);
    expect(readings, hasLength(1));
    expect(readings.single.value, const NumberValue(7, kind: MetricKind.scale));
    // And it is on the day, next to what happened.
    expect(await controller.photosOn(controller.today), hasLength(1));
  });

  testWidgets('the sheet offers a photo on any marker but the photo one',
      (tester) async {
    await tester.pumpWidget(wrap(HomeScreen(
      controller: controller,
      picker: FakePicker(photoBytes()),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('tiredness'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Photo'), findsOneWidget);

    await tester.tap(find.byTooltip('Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('From gallery'));
    await tester.pumpAndSettle();
    // Ticked, so it is clear a photo is attached before the reading is saved.
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump();
    }

    expect(await controller.photosOn(controller.today), hasLength(1));
    expect(await controller.readingsOn(controller.today), hasLength(1));
  });

  testWidgets('a report marks the days that carry a note or a photo',
      (tester) async {
    final mood = seedIds['mood']!;
    for (var i = 0; i < 6; i++) {
      await controller.logForDay(
        mood,
        NumberValue(5 + i % 3, kind: MetricKind.scale),
        addDays(controller.today, -i),
        note: i == 2 ? 'a hard one' : null,
      );
    }
    // Writing the file is real I/O, which never completes inside the fake
    // clock a widget test runs under.
    await tester.runAsync(() => controller.attachPhoto(
          photoBytes(),
          metricId: mood,
          dayKey: addDays(controller.today, -4),
        ));

    final marked = await controller.markedDays(
      mood,
      from: addDays(controller.today, -6),
      to: controller.today,
    );
    expect(marked.notes, {addDays(controller.today, -2)});
    expect(marked.photos, {addDays(controller.today, -4)});

    await tester.pumpWidget(wrap(ReportViewScreen.forMarker(
      controller: controller,
      metric: controller.byId(mood)!,
    )));
    await tester.pumpAndSettle();

    expect(find.byType(MarkedDaysStrip), findsOneWidget);
    expect(find.textContaining('1 with a note, 1 with a photo'),
        findsOneWidget);
  });
}
