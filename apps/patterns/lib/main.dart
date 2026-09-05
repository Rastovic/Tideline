import 'package:flutter/material.dart';

import 'app/patterns_app.dart';
import 'data/app_database.dart';
import 'data/patterns_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = openPatternsDatabase();
  final installId = await InstallId.load();
  final dayBoundaryHour = await DayBoundary.load();

  final controller = PatternsController(
    db: db,
    installId: installId,
    dayBoundaryHour: dayBoundaryHour,
  );
  // Seeding is idempotent and checks for any marker, deleted ones included, so
  // a marker removed on purpose does not reappear after an update.
  await controller.seedIfNeeded();

  runApp(PatternsApp(controller: controller));
}
