import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/app_database.dart';
import '../data/evening_reminder.dart';
import '../data/patterns_controller.dart';
import '../data/photo_picker.dart';
import 'day_detail_screen.dart';
import 'log_sheet.dart';
import 'metrics_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

/// The home screen: what I track, and whether it is logged today.
///
/// **Not a dashboard and not a grid.** A list of markers, a tick where there is
/// a reading, a dash where there is not, and a count only when a day holds more
/// than one. Deliberately absent: badges, percentages, streaks, completion
/// rings and any copy about a missed day. A dash is just a dash.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.controller,
    this.picker = const PhotoPicker(),
    this.reminder,
    this.initialSettings = ReminderSettings.off,
    super.key,
  });

  final PatternsController controller;

  /// Injected so a widget test can hand back bytes without a camera.
  final PhotoPicker picker;

  /// Null on a surface with no notifications, the same way [PhotoStore] is
  /// null where the photo directory could not be opened. The settings entry
  /// point is hidden rather than opening a screen whose switch cannot work.
  final EveningReminder? reminder;

  final ReminderSettings initialSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PatternsController get controller => widget.controller;

  late ReminderSettings _settings = widget.initialSettings;

  static const _sectionTitles = {
    MetricDomain.mind: 'UM',
    MetricDomain.body: 'TIJELO',
    MetricDomain.cycle: 'CIKLUS',
  };

  Future<void> _log(Metric metric) async {
    final value = await showLogSheet(
      context,
      metric: metric,
      onCapture: metric.kind == MetricKind.photo
          ? (source) => _capture(metric.id, source)
          : null,
    );
    if (value == null) return;
    await controller.log(metric.id, value);
  }

  Future<void> _capture(String? metricId, PhotoSource source) async {
    final bytes = await widget.picker.pick(source);
    if (bytes == null) return;
    await controller.capturePhoto(bytes, metricId: metricId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final sections = controller.sections;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                VitalsSpacing.screenH,
                VitalsSpacing.lg,
                VitalsSpacing.screenH,
                VitalsSpacing.huge,
              ),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _humanDate(controller.today),
                      style: theme.typography.displayL,
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Detalji dana',
                          icon: const Icon(Icons.today_outlined),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DayDetailScreen(
                                controller: controller,
                                dayKey: controller.today,
                              ),
                            ),
                          ),
                        ),
                        // Deliberately not the long-press on a marker row:
                        // that gesture is spoken for by the marker's report,
                        // and squatting on it now means moving it later.
                        // MY-SETUP puts saved reports behind one shortcut,
                        // not on the home list: home answers "what did I log
                        // today", and a chart there would start grading it.
                        IconButton(
                          tooltip: 'Izvjestaji',
                          icon: const Icon(Icons.stacked_bar_chart),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ReportsScreen(controller: controller),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Markeri',
                          icon: const Icon(Icons.tune),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  MetricsScreen(controller: controller),
                            ),
                          ),
                        ),
                        if (widget.reminder case final reminder?)
                          IconButton(
                            tooltip: 'Podesavanja',
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SettingsScreen(
                                  reminder: reminder,
                                  settings: _settings,
                                  controller: controller,
                                  onChanged: (next) =>
                                      setState(() => _settings = next),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: VitalsSpacing.lg),
                for (final domain in MetricDomain.values)
                  if (sections[domain]?.isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: VitalsSpacing.lg,
                        bottom: VitalsSpacing.sm,
                      ),
                      child: Text(
                        _sectionTitles[domain]!,
                        style: theme.typography.label.copyWith(
                          color: colors.inkFaint,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    for (final status in sections[domain]!)
                      _MarkerRow(
                        status: status,
                        onTap: () => _log(status.metric),
                      ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// `2026-08-19` as `19. avgust`. No weekday and no relative wording: "danas"
  /// on a screen you open at 01:00 with a 04:00 day boundary is a lie.
  static String _humanDate(String dayKey) {
    const months = [
      'januar', 'februar', 'mart', 'april', 'maj', 'jun',
      'jul', 'avgust', 'septembar', 'oktobar', 'novembar', 'decembar',
    ];
    final parts = dayKey.split('-');
    if (parts.length != 3) return dayKey;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    return '$day. ${months[(month - 1).clamp(0, 11)]}';
  }
}

class _MarkerRow extends StatelessWidget {
  const _MarkerRow({required this.status, required this.onTap});

  final MarkerStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;
    final dotColor = _parseHex(status.metric.colorHex) ?? colors.accent;

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
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: VitalsSpacing.md),
            Expanded(
              child: Text(status.metric.name, style: theme.typography.body),
            ),
            Text(
              status.isLoggedToday ? '✓' : '—',
              style: theme.typography.body.copyWith(
                color: status.isLoggedToday ? colors.ink : colors.inkFaint,
              ),
            ),
            if (status.count > 1) ...[
              const SizedBox(width: VitalsSpacing.sm),
              Text(
                '${status.count}×',
                style: theme.typography.caption.copyWith(
                  color: colors.inkMuted,
                ),
              ),
            ],
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
