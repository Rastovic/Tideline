import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';
import 'metric_editor_screen.dart';
import 'metric_labels.dart';

/// Everything tracked, and the way to change it.
///
/// The home list answers "what have I logged today"; this one answers "what do
/// I track" - so it shows the type rather than a tick, and it shows archived
/// markers, which home deliberately hides. A supplement finished in May has to
/// stay reachable, or archiving it is indistinguishable from losing it.
class MetricsScreen extends StatelessWidget {
  const MetricsScreen({required this.controller, super.key});

  final PatternsController controller;

  Future<void> _open(
    BuildContext context, {
    Metric? metric,
    MetricDomain domain = MetricDomain.body,
  }) =>
      Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => MetricEditorScreen(
            controller: controller,
            metric: metric,
            initialDomain: domain,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Markeri')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context),
        icon: const Icon(Icons.add),
        label: const Text('Novi marker'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final all = controller.allMarkers;
            final archived = all.where((m) => m.isArchived).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                VitalsSpacing.screenH,
                VitalsSpacing.lg,
                VitalsSpacing.screenH,
                VitalsSpacing.giant,
              ),
              children: [
                for (final domain in MetricDomain.values)
                  ..._section(
                    context,
                    theme,
                    title: domainNames[domain]!,
                    markers:
                        all.where((m) => m.domain == domain && !m.isArchived),
                    domain: domain,
                  ),
                if (archived.isNotEmpty)
                  ..._section(
                    context,
                    theme,
                    title: 'ARHIVIRANO',
                    markers: archived,
                    domain: MetricDomain.body,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _section(
    BuildContext context,
    VitalsThemeData theme, {
    required String title,
    required Iterable<Metric> markers,
    required MetricDomain domain,
  }) {
    final rows = markers.toList();
    if (rows.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(
          top: VitalsSpacing.lg,
          bottom: VitalsSpacing.sm,
        ),
        child: Text(
          title,
          style: theme.typography.label.copyWith(
            color: theme.colors.inkFaint,
            letterSpacing: 1.2,
          ),
        ),
      ),
      for (final metric in rows)
        _MetricRow(
          metric: metric,
          onTap: () => _open(context, metric: metric, domain: domain),
        ),
    ];
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric, required this.onTap});

  final Metric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;
    final dotColor = _parseHex(metric.colorHex) ?? colors.accent;
    final faded = metric.isArchived;

    return InkWell(
      onTap: onTap,
      borderRadius: VitalsRadius.nestedAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: VitalsSpacing.md,
          horizontal: VitalsSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: faded ? colors.inkFaint : dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: VitalsSpacing.md),
            Expanded(
              child: Text(
                metric.name,
                style: theme.typography.body.copyWith(
                  color: faded ? colors.inkMuted : colors.ink,
                ),
              ),
            ),
            Text(
              kindNames[metric.kind]!,
              style: theme.typography.caption.copyWith(color: colors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }
}
