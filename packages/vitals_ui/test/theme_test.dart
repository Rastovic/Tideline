import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals_ui/vitals_ui.dart';

/// Relative luminance per WCAG 2.1.
double _luminance(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppAccent', () {
    test('every app in the portfolio has an accent', () {
      // Fourteen apps, fourteen accents. Section 7 of DESIGN-SYSTEM.md is the
      // 4.3 defence, so a missing entry is a store risk, not a style nit.
      expect(AppAccent.values.length, 14);
    });

    test('no two apps share an accent', () {
      final lights = AppAccent.values.map((a) => a.light).toSet();
      expect(lights.length, AppAccent.values.length);
    });

    test('only stitchbook differs between light and dark', () {
      final differing =
          AppAccent.values.where((a) => a.light != a.dark).toList();
      expect(differing, [AppAccent.stitchBerry]);
    });

    test('forBrightness picks the right side', () {
      expect(
        AppAccent.stitchBerry.forBrightness(Brightness.dark),
        AppAccent.stitchBerry.dark,
      );
      expect(
        AppAccent.stitchBerry.forBrightness(Brightness.light),
        AppAccent.stitchBerry.light,
      );
    });
  });

  group('VitalsColors', () {
    test('body text passes 4.5:1 on every surface, both modes, every app', () {
      for (final accent in AppAccent.values) {
        for (final colors in [
          VitalsColors.dark(accent),
          VitalsColors.light(accent),
        ]) {
          for (final surface in [
            colors.bg,
            colors.surface,
            colors.surfaceAlt,
          ]) {
            expect(
              _contrast(colors.ink, surface),
              greaterThanOrEqualTo(4.5),
              reason: '${accent.name} ${colors.brightness.name} ink',
            );
          }
        }
      }
    });

    test('muted text passes 4.5:1 on bg and surface', () {
      for (final colors in [
        VitalsColors.dark(AppAccent.tallyMint),
        VitalsColors.light(AppAccent.tallyMint),
      ]) {
        for (final surface in [colors.bg, colors.surface]) {
          expect(
            _contrast(colors.inkMuted, surface),
            greaterThanOrEqualTo(4.5),
            reason: '${colors.brightness.name} inkMuted',
          );
        }
      }
    });

    test('onAccent passes 4.5:1 against its own accent, every app', () {
      // Button text is 15px w600, which WCAG counts as normal text, so the bar
      // is 4.5 and not the 3.0 that large text would get.
      for (final accent in AppAccent.values) {
        for (final brightness in Brightness.values) {
          expect(
            _contrast(
              accent.onAccentFor(brightness),
              accent.forBrightness(brightness),
            ),
            greaterThanOrEqualTo(4.5),
            reason: '${accent.name} ${brightness.name}',
          );
        }
      }
    });

    test('stitchbook is the only accent needing different text per mode', () {
      final flipped = AppAccent.values
          .where(
            (a) =>
                a.onAccentFor(Brightness.light) != a.onAccentFor(Brightness.dark),
          )
          .toList();
      expect(flipped, [AppAccent.stitchBerry]);
    });

    test('semantic colours are identical across modes', () {
      final dark = VitalsColors.dark(AppAccent.tallyMint);
      final light = VitalsColors.light(AppAccent.tallyMint);
      expect(dark.success, light.success);
      expect(dark.warning, light.warning);
      expect(dark.danger, light.danger);
    });

    test('dark mode has no card shadow, light mode has exactly one', () {
      expect(VitalsColors.dark(AppAccent.tallyMint).cardShadow, isEmpty);
      expect(VitalsColors.light(AppAccent.tallyMint).cardShadow, hasLength(1));
    });

    test('accentGlow fades the accent to fully transparent', () {
      final colors = VitalsColors.dark(AppAccent.tallyMint);
      expect(colors.accentGlow.colors.first, colors.accent);
      expect(colors.accentGlow.colors.last.a, 0);
    });
  });

  group('VitalsThemeData', () {
    test('registers under its own class, not under a field', () {
      // Regression guard. ThemeExtension declares `Object get type` and uses it
      // as the storage key; a field named `type` overrode it, filing the
      // extension under the typography instance so every lookup returned null
      // while the code analyzed clean.
      final theme = VitalsTheme.dark(accent: AppAccent.tallyMint);
      expect(theme.extensions.keys, contains(VitalsThemeData));
      expect(theme.extension<VitalsThemeData>(), isNotNull);
    });
  });

  group('VitalsTypography', () {
    test('displayXL uses tabular figures so a countdown never jitters', () {
      final type = VitalsTypography.forColor(const Color(0xFFFFFFFF));
      expect(
        type.displayXL.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('tabular() can promote any style', () {
      final type = VitalsTypography.forColor(const Color(0xFFFFFFFF));
      expect(
        VitalsTypography.tabular(type.title).fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('the scale matches the spec', () {
      final type = VitalsTypography.forColor(const Color(0xFFFFFFFF));
      expect(type.displayXL.fontSize, 56);
      expect(type.displayL.fontSize, 34);
      expect(type.title.fontSize, 22);
      expect(type.body.fontSize, 15);
      expect(type.label.fontSize, 13);
      expect(type.caption.fontSize, 11);
    });
  });

  group('VitalsTheme', () {
    testWidgets('exposes tokens through context', (tester) async {
      late VitalsThemeData captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: VitalsTheme.dark(accent: AppAccent.tallyMint),
          home: Builder(
            builder: (context) {
              captured = context.vitals;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured.accent, AppAccent.tallyMint);
      expect(captured.typography.displayXL.fontSize, 56);
      expect(captured.colors.brightness, Brightness.dark);
      expect(captured.colors.accent, AppAccent.tallyMint.dark);
    });

    testWidgets('throws a useful error outside a Vitals theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              expect(() => VitalsTheme.of(context), throwsFlutterError);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('reduced motion collapses durations to zero', (tester) async {
      late Duration normal;
      late Duration reduced;

      Widget probe({required bool disableAnimations}) => MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: MaterialApp(
              theme: VitalsTheme.dark(accent: AppAccent.tallyMint),
              home: Builder(
                builder: (context) {
                  final value = context.motion(VitalsMotion.standard);
                  if (disableAnimations) {
                    reduced = value;
                  } else {
                    normal = value;
                  }
                  return const SizedBox();
                },
              ),
            ),
          );

      await tester.pumpWidget(probe(disableAnimations: false));
      await tester.pumpWidget(probe(disableAnimations: true));

      expect(normal, VitalsMotion.standard);
      expect(reduced, Duration.zero);
    });

    test('scaffold and colour scheme are driven by tokens, not defaults', () {
      for (final accent in AppAccent.values) {
        final theme = VitalsTheme.dark(accent: accent);
        final colors = VitalsColors.dark(accent);
        expect(theme.scaffoldBackgroundColor, colors.bg);
        expect(theme.colorScheme.primary, colors.accent);
        expect(theme.colorScheme.surface, colors.surface);
        expect(theme.colorScheme.error, colors.danger);
      }
    });

    test('button heights meet the tap-target floor', () {
      expect(
        VitalsSpacing.buttonHeight,
        greaterThanOrEqualTo(VitalsSpacing.minTapTarget),
      );
      expect(
        VitalsSpacing.listRowHeight,
        greaterThanOrEqualTo(VitalsSpacing.minTapTarget),
      );
    });
  });
}
