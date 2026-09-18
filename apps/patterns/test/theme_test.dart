import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patterns/app/patterns_app.dart';
import 'package:patterns/app/tideline_themes.dart';
import 'package:patterns/data/app_database.dart';
import 'package:patterns/data/evening_reminder.dart';
import 'package:patterns/data/patterns_controller.dart';
import 'package:patterns/l10n/app_language.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_notify/vitals_notify.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  group('every theme is readable, light and dark', () {
    for (final theme in TidelineTheme.values) {
      for (final brightness in Brightness.values) {
        test('${theme.label} ${brightness.name}', () {
          final c = theme.colors(brightness);
          // Button text on the accent.
          expect(contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
          // Body text on cards and on the ground.
          expect(contrast(c.ink, c.surface), greaterThanOrEqualTo(7));
          expect(contrast(c.ink, c.bg), greaterThanOrEqualTo(7));
          // Secondary text, which carries the facts under every chart.
          expect(contrast(c.inkMuted, c.surface), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });

  test('the choice is remembered', () async {
    SharedPreferences.setMockInitialValues({});
    expect((await ThemeChoice.load()).theme, TidelineTheme.tide);
    await const ThemeChoice(theme: TidelineTheme.nebula, mode: ThemeMode.dark)
        .save();
    final loaded = await ThemeChoice.load();
    expect(loaded.theme, TidelineTheme.nebula);
    expect(loaded.mode, ThemeMode.dark);
  });

  testWidgets('picking a theme in Settings changes the app at once',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = PatternsController(
      db: PatternsDatabase(NativeDatabase.memory()),
      installId: '018f2c00-aaaa-7000-8000-000000000001',
      dayBoundaryHour: 4,
    );
    await controller.seedIfNeeded();
    final theme = ValueNotifier(const ThemeChoice(mode: ThemeMode.light));

    await tester.pumpWidget(PatternsApp(
      controller: controller,
      reminder: EveningReminder(RecordingNotifier()),
      settings: ReminderSettings.off,
      language: ValueNotifier(AppLanguage.en),
      theme: theme,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Circuit'), 200);
    await tester.ensureVisible(find.text('Circuit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Circuit'));
    await tester.pumpAndSettle();

    expect(theme.value.theme, TidelineTheme.circuit);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold, isNotNull);
    expect(
      Theme.of(tester.element(find.text('Circuit'))).scaffoldBackgroundColor,
      TidelineTheme.circuit.colors(Brightness.light).bg,
    );
    expect((await ThemeChoice.load()).theme, TidelineTheme.circuit);
    controller.dispose();
  });
}
