import 'package:flutter/material.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../l10n/app_language.dart';
import 'onboarding.dart';

/// The first screen of a fresh install: the language, then a tour or not.
///
/// **Language first**, because every word after it - the tour, the suggested
/// markers - is written in whatever is picked here. The chips carry each
/// language's own name, so the choice can be made by someone who cannot read
/// the current one.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({required this.onboarding, super.key});

  final Onboarding onboarding;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _busy = false;

  Future<void> _setLanguage(AppLanguage language) async {
    widget.onboarding.language.value = language;
    await AppLanguage.save(language);
  }

  Future<void> _tour() async {
    setState(() => _busy = true);
    try {
      await widget.onboarding.startTour();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;
    final s = context.s;

    // Nothing to go back to: home underneath is an empty profile.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              VitalsSpacing.screenH,
              VitalsSpacing.huge,
              VitalsSpacing.screenH,
              VitalsSpacing.xl,
            ),
            children: [
              Icon(Icons.waves, size: 48, color: colors.accent),
              const SizedBox(height: VitalsSpacing.lg),
              Text(s.welcomeTitle, style: theme.typography.displayL),
              const SizedBox(height: VitalsSpacing.md),
              Text(
                s.welcomeBody,
                style: theme.typography.body.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: VitalsSpacing.xl),
              Text(
                s.languageHeading,
                style: theme.typography.label.copyWith(
                  color: colors.inkFaint,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: VitalsSpacing.sm),
              Wrap(
                spacing: VitalsSpacing.sm,
                children: [
                  for (final language in AppLanguage.values)
                    ChoiceChip(
                      label: Text(language.nativeName),
                      selected: s.language == language,
                      onSelected: _busy ? null : (_) => _setLanguage(language),
                    ),
                ],
              ),
              const SizedBox(height: VitalsSpacing.huge),
              FilledButton.icon(
                onPressed: _busy ? null : _tour,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(_busy ? s.makingDemo : s.welcomeTour),
              ),
              const SizedBox(height: VitalsSpacing.sm),
              Text(
                s.welcomeTourHint,
                textAlign: TextAlign.center,
                style: theme.typography.caption.copyWith(
                  color: colors.inkFaint,
                ),
              ),
              const SizedBox(height: VitalsSpacing.lg),
              TextButton(
                onPressed: _busy ? null : widget.onboarding.openSetup,
                child: Text(s.welcomeSkip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
