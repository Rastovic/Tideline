import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../l10n/app_language.dart';
import '../screens/metric_editor_screen.dart';
import '../screens/metric_labels.dart';
import 'onboarding.dart';
import 'suggested_markers.dart';

/// The end of the first run: tick suggested markers, or make her own.
///
/// **Named in the language picked at the welcome**, and only then. Once made,
/// a marker's name is hers, the same as one she typed.
class SetupScreen extends StatefulWidget {
  const SetupScreen({required this.onboarding, super.key});

  final Onboarding onboarding;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final Set<String> _picked = {
    for (final m in suggestedMarkers)
      if (m.preselected) m.key,
  };
  bool _cycle = false;
  bool _keepDemo = false;
  bool _own = false;
  bool _saving = false;

  Future<void> _finish() async {
    setState(() => _saving = true);
    final onboarding = widget.onboarding;
    final navigator = onboarding.navigatorKey.currentState!;
    final messenger = ScaffoldMessenger.of(context);
    final done = context.s.setupDone;
    await onboarding.finish(
      picked: _picked,
      cycle: _cycle,
      keepDemo: _keepDemo,
    );
    if (_own) {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => MetricEditorScreen(controller: onboarding.controller),
        ),
      );
    }
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;
    final s = context.s;
    final language = s.language;

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(
        top: VitalsSpacing.xl,
        bottom: VitalsSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: theme.typography.label.copyWith(
          color: colors.inkFaint,
          letterSpacing: 1.2,
        ),
      ),
    );

    Widget suggestion(SuggestedMarker marker) => CheckboxListTile(
      key: ValueKey('suggested-${marker.key}'),
      contentPadding: EdgeInsets.zero,
      value: _picked.contains(marker.key),
      onChanged: _saving
          ? null
          : (on) => setState(
              () => on! ? _picked.add(marker.key) : _picked.remove(marker.key),
            ),
      secondary: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: markerColor(marker.colorHex) ?? colors.accent,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(marker.nameIn(language), style: theme.typography.body),
      subtitle: Text(
        s.kindName(marker.kind),
        style: theme.typography.caption.copyWith(color: colors.inkFaint),
      ),
    );

    Widget toggle(
      String title,
      String hint,
      bool value,
      ValueChanged<bool> onChanged,
    ) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: _saving ? null : onChanged,
      title: Text(title, style: theme.typography.body),
      subtitle: Text(
        hint,
        style: theme.typography.caption.copyWith(color: colors.inkFaint),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(s.setupTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VitalsSpacing.screenH,
            VitalsSpacing.sm,
            VitalsSpacing.screenH,
            VitalsSpacing.md,
          ),
          child: FilledButton(
            onPressed: _saving ? null : _finish,
            child: Text(s.setupStart(_picked.length)),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VitalsSpacing.screenH,
          VitalsSpacing.md,
          VitalsSpacing.screenH,
          VitalsSpacing.xl,
        ),
        children: [
          Text(
            s.setupIntro,
            style: theme.typography.body.copyWith(color: colors.inkMuted),
          ),
          for (final domain in [MetricDomain.mind, MetricDomain.body]) ...[
            heading(s.domainName(domain)),
            for (final marker in suggestedMarkers)
              if (marker.domain == domain) suggestion(marker),
          ],
          heading(s.domainName(MetricDomain.cycle)),
          toggle(
            s.setupCycle,
            s.setupCycleHint,
            _cycle,
            (on) => setState(() => _cycle = on),
          ),
          const Divider(height: VitalsSpacing.xl),
          toggle(
            s.setupOwn,
            s.setupOwnHint,
            _own,
            (on) => setState(() => _own = on),
          ),
          if (widget.onboarding.hasDemo)
            toggle(
              s.setupKeepDemo,
              s.setupKeepDemoHint,
              _keepDemo,
              (on) => setState(() => _keepDemo = on),
            ),
        ],
      ),
    );
  }
}
