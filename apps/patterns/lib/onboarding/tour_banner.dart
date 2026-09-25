import 'package:flutter/material.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import 'onboarding.dart';

/// Puts the tour's card under whatever screen is showing.
///
/// **Under, not over.** The screen above it is shortened rather than covered,
/// so the tour never hides the thing it is talking about. Hidden while the
/// keyboard is up, because a note being typed matters more than the tour.
class TourFrame extends StatelessWidget {
  const TourFrame({required this.onboarding, required this.child, super.key});

  final Onboarding onboarding;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      OnboardingScope(onboarding: onboarding, child: _frame());

  Widget _frame() => ListenableBuilder(
    listenable: onboarding,
    builder: (context, _) {
      final step = onboarding.step;
      final media = MediaQuery.of(context);
      if (step == null || onboarding.inSetup || media.viewInsets.bottom > 0) {
        return child;
      }
      return Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: child,
            ),
          ),
          _TourCard(onboarding: onboarding, step: step),
        ],
      );
    },
  );
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.onboarding, required this.step});

  final Onboarding onboarding;
  final TourStep step;

  static (String, String) _words(AppStrings s, TourStep step) => switch (step) {
    TourStep.home => (s.tourHomeTitle, s.tourHomeBody),
    TourStep.logging => (s.tourLogTitle, s.tourLogBody),
    TourStep.day => (s.tourDayTitle, s.tourDayBody),
    TourStep.reports => (s.tourReportsTitle, s.tourReportsBody),
    TourStep.lines => (s.tourLinesTitle, s.tourLinesBody),
    TourStep.cycle => (s.tourCycleTitle, s.tourCycleBody),
    TourStep.grid => (s.tourGridTitle, s.tourGridBody),
    TourStep.markers => (s.tourMarkersTitle, s.tourMarkersBody),
    TourStep.done => (s.tourDoneTitle, s.tourDoneBody),
  };

  /// The same words, except the end: a replay goes back to her profile.
  static (String, String) _replayWords(AppStrings s, TourStep step) =>
      step == TourStep.done
      ? (s.tourDoneTitle, s.tourReplayDoneBody)
      : _words(s, step);

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;
    final s = context.s;
    final (title, body) = onboarding.isReplay
        ? _replayWords(s, step)
        : _words(s, step);
    final last = step == TourStep.done;
    final next = FilledButton(
      // The theme's buttons are full width; this one shares a row.
      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: onboarding.next,
      child: Text(
        last ? (onboarding.isReplay ? s.tourEnd : s.tourFinish) : s.tourNext,
      ),
    );

    return Material(
      color: colors.surfaceAlt,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.stroke)),
          ),
          padding: const EdgeInsets.fromLTRB(
            VitalsSpacing.screenH,
            VitalsSpacing.md,
            VitalsSpacing.sm,
            VitalsSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.tourProgress(step.index + 1, TourStep.values.length),
                style: theme.typography.label.copyWith(
                  color: colors.accent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: VitalsSpacing.xs),
              Text(title, style: theme.typography.title),
              const SizedBox(height: VitalsSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(right: VitalsSpacing.sm),
                child: Text(
                  body,
                  style: theme.typography.body.copyWith(color: colors.inkMuted),
                ),
              ),
              Row(
                children: [
                  if (!last) ...[
                    TextButton(
                      onPressed: onboarding.skip,
                      child: Text(s.tourSkip),
                    ),
                    const Spacer(),
                  ],
                  if (step.index > 0)
                    TextButton(
                      onPressed: onboarding.back,
                      child: Text(s.tourBack),
                    ),
                  const SizedBox(width: VitalsSpacing.xs),
                  // The last step's button takes the rest of the row: its
                  // label is long, and in Serbian longer.
                  if (last) Expanded(child: next) else next,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
