import 'package:flutter/material.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../app/tideline_themes.dart';
import '../l10n/app_language.dart';

/// Theme swatches and light / dark / system, applied the moment they are
/// tapped and remembered.
///
/// Each swatch is drawn in the brightness currently on screen, so what it
/// shows is what tapping it gives.
class ThemePicker extends StatelessWidget {
  const ThemePicker({required this.choice, super.key});

  final ValueNotifier<ThemeChoice> choice;

  Future<void> _set(ThemeChoice next) async {
    choice.value = next;
    await next.save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final s = context.s;
    final current = choice.value;
    final brightness = theme.colors.brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final option in TidelineTheme.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: VitalsSpacing.sm),
                  child: _Swatch(
                    option: option,
                    brightness: brightness,
                    selected: option == current.theme,
                    onTap: () => _set(current.copyWith(theme: option)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: VitalsSpacing.lg),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: ThemeMode.system, label: Text(s.modeSystem)),
            ButtonSegment(value: ThemeMode.light, label: Text(s.modeLight)),
            ButtonSegment(value: ThemeMode.dark, label: Text(s.modeDark)),
          ],
          selected: {current.mode},
          onSelectionChanged: (modes) =>
              _set(current.copyWith(mode: modes.first)),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.option,
    required this.brightness,
    required this.selected,
    required this.onTap,
  });

  final TidelineTheme option;
  final Brightness brightness;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final c = option.colors(brightness);
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? c.accent : c.stroke,
                    width: selected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A card, and on it the accent: the two things a theme
                    // changes that the eye reads first.
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.stroke),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: VitalsSpacing.xs),
            Text(
              option.label,
              style: theme.typography.caption.copyWith(
                color: selected ? theme.colors.ink : theme.colors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
