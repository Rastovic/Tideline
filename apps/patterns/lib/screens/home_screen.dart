import 'dart:async';

import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/app_database.dart';
import '../data/app_lock.dart';
import '../data/evening_reminder.dart';
import '../data/patterns_controller.dart';
import '../data/photo_picker.dart';
import '../data/quick_log_widget.dart';
import 'day_detail_screen.dart';
import 'log_sheet.dart';
import 'metric_labels.dart';
import 'metrics_screen.dart';
import 'photo_timeline_screen.dart';
import 'report_view_screen.dart';
import 'reports_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import '../l10n/app_language.dart';

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
    this.lock,
    this.quickLog,
    super.key,
  });

  final AppLock? lock;

  /// The home screen widget. Null where there is none, as in most tests.
  final QuickLogWidget? quickLog;

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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  PatternsController get controller => widget.controller;

  StreamSubscription<String>? _widgetTaps;
  String _publishedToWidget = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final quickLog = widget.quickLog;
    if (quickLog != null) {
      controller.addListener(_publishWidget);
      _widgetTaps = quickLog.taps.listen(_logById);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _publishWidget();
        if (await quickLog.launchedFor() case final id?) _logById(id);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_publishWidget);
    _widgetTaps?.cancel();
    super.dispose();
  }

  /// Sends the widget its markers, only when the names or order changed.
  Future<void> _publishWidget() async {
    final quickLog = widget.quickLog;
    if (quickLog == null || controller.isLoading) return;
    final markers = await WidgetMarkers.load(controller.homeOrder);
    final signature = markers.map((m) => '${m.id}=${m.name}').join('|');
    if (signature == _publishedToWidget) return;
    _publishedToWidget = signature;
    await quickLog.publish(markers, emptyText: _widgetEmptyText);
  }

  /// Kept from the last build, because publishing happens outside one.
  String _widgetEmptyText = '';

  /// A widget tap: straight to that marker's log sheet.
  void _logById(String id) {
    final metric = controller.byId(id);
    if (!mounted || metric == null || !metric.isActive) return;
    _log(metric);
  }

  /// Re-reads the day on every return to the app.
  ///
  /// A phone keeps the app alive in the background for days. Without this, one
  /// opened in the morning still shows yesterday's date and yesterday's ticks,
  /// which reads as today already being logged.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller.refresh();
  }

  late ReminderSettings _settings = widget.initialSettings;


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

  void _openTimeline(Metric metric) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PhotoTimelineScreen(controller: controller, metric: metric),
      ),
    );
  }

  void _openReport(Metric metric) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportViewScreen.forMarker(
          controller: controller,
          metric: metric,
        ),
      ),
    );
  }

  Future<void> _capture(String? metricId, PhotoSource source) async {
    final ghost =
        metricId == null ? null : await controller.ghostPathFor(metricId);
    if (!mounted) return;
    final bytes = await widget.picker.pick(
      source,
      context: context,
      ghostPath: ghost,
    );
    if (bytes == null) return;
    await controller.capturePhoto(bytes, metricId: metricId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;
    _widgetEmptyText = context.s.widgetEmpty;

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
                // Shortcuts above the date rather than beside it: five
                // buttons are 240dp, and beside "17. septembar" in display
                // type they run off a 360dp phone.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: context.s.search,
                          icon: const Icon(Icons.search),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  SearchScreen(controller: controller),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.s.dayDetail,
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
                        // Not the long-press on a marker row: that opens the
                        // marker's own last month.
                        // MY-SETUP puts saved reports behind one shortcut,
                        // not on the home list: home answers "what did I log
                        // today", and a chart there would start grading it.
                        IconButton(
                          tooltip: context.s.reports,
                          icon: const Icon(Icons.stacked_bar_chart),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ReportsScreen(controller: controller),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.s.markers,
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
                            tooltip: context.s.settings,
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SettingsScreen(
                                  reminder: reminder,
                                  settings: _settings,
                                  controller: controller,
                                  lock: widget.lock,
                                  quickLog: widget.quickLog,
                                  onWidgetMarkersChanged: () {
                                    _publishedToWidget = '';
                                    _publishWidget();
                                  },
                                  onChanged: (next) =>
                                      setState(() => _settings = next),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      context.s.humanDate(controller.today),
                      style: theme.typography.displayL,
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
                        context.s.domainName(domain),
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
                        // A photo marker opens its timeline; a diary has
                        // nothing to chart, so holding it does nothing.
                        onLongPress: switch (status.metric) {
                          Metric(kind: MetricKind.photo) => () =>
                              _openTimeline(status.metric),
                          Metric(displayStyle: null) => null,
                          _ => () => _openReport(status.metric),
                        },
                      ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

}

class _MarkerRow extends StatelessWidget {
  const _MarkerRow({
    required this.status,
    required this.onTap,
    this.onLongPress,
  });

  final MarkerStatus status;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;
    final dotColor = markerColor(status.metric.colorHex) ?? colors.accent;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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
}
