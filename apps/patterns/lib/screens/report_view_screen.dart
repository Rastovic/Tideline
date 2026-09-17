import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';
import 'day_detail_screen.dart';
import 'day_grid_chart.dart';
import 'metric_labels.dart';
import 'report_builder_screen.dart';
import 'report_chart.dart';
import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';

/// A built report: stacked rows on one shared axis.
///
/// **The app draws what was logged and says nothing about it.** There is no
/// headline, no summary sentence, no "your best week", no arrow and no colour
/// that means good or bad. The facts under each row are counts and ranges, and
/// the reading is hers.
///
/// Rebuilt from the readings every time it opens. Nothing is cached, so
/// changing a marker's day rule re-reads history instead of leaving an old
/// number frozen here.
class ReportViewScreen extends StatefulWidget {
  const ReportViewScreen({
    required this.controller,
    required this.definition,
    this.isSaved = true,
    super.key,
  });

  /// One marker's last month, opened by a long-press on home.
  ///
  /// **Not saved.** Looking at a marker is not asking a question worth keeping,
  /// and a list that grows by one every time a row is held stops being hers.
  /// Changing the axis here stays on this screen; the builder is one tap away
  /// if this turns out to be one to keep.
  ReportViewScreen.forMarker({
    required PatternsController controller,
    required Metric metric,
    Key? key,
  }) : this(
          controller: controller,
          definition: ReportDefinition(
            id: Ids.newId(),
            name: metric.name,
            series: [ReportSeries(metricId: metric.id)],
            period: const LastDays(30),
            createdAt: DateTime.now().toUtc(),
          ),
          isSaved: false,
          key: key,
        );

  final PatternsController controller;
  final ReportDefinition definition;

  /// False for a report that exists only on this screen.
  final bool isSaved;

  @override
  State<ReportViewScreen> createState() => _ReportViewScreenState();
}

class _ReportViewScreenState extends State<ReportViewScreen> {
  late ReportDefinition _definition = widget.definition;
  late bool _isSaved = widget.isSaved;
  Report? _report;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  Future<void> _rebuild() async {
    final report = await widget.controller.buildSavedReport(_definition);
    if (mounted) setState(() => _report = report);
  }

  /// Re-sorting is a view of the same readings, not a different report.
  ///
  /// Saved immediately, because the axis is part of the question: "irritability
  /// by cycle day" and "irritability by date" are two things to ask.
  Future<void> _setAxis(ReportAxis axis) async {
    if (axis == _definition.axis) return;
    setState(() {
      _definition = _definition.copyWith(axis: axis);
      _report = null;
    });
    if (_isSaved) await widget.controller.saveReport(_definition);
    await _rebuild();
  }

  Future<void> _edit() async {
    final edited = await Navigator.of(context).push<ReportDefinition>(
      MaterialPageRoute(
        builder: (_) => ReportBuilderScreen(
          controller: widget.controller,
          definition: _definition,
        ),
      ),
    );
    if (edited == null) return;
    setState(() {
      // The builder saves on the way out, so an unsaved view becomes a saved
      // report exactly when she pressed the button that says so.
      _isSaved = true;
      _definition = edited;
      _report = null;
    });
    await _rebuild();
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final report = _report;

    return Scaffold(
      appBar: AppBar(
        title: Text(_definition.name),
        actions: [
          IconButton(
            tooltip: _isSaved ? context.s.edit : context.s.saveAsReport,
            icon: const Icon(Icons.tune),
            onPressed: _edit,
          ),
        ],
      ),
      body: SafeArea(
        child: report == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  VitalsSpacing.screenH,
                  VitalsSpacing.lg,
                  VitalsSpacing.screenH,
                  VitalsSpacing.huge,
                ),
                children: [
                  Text(
                    '${report.from} - ${report.to}',
                    style: theme.typography.caption
                        .copyWith(color: theme.colors.inkMuted),
                  ),
                  const SizedBox(height: VitalsSpacing.md),
                  _axisPicker(theme),
                  const SizedBox(height: VitalsSpacing.xl),
                  if (report.rows.isEmpty)
                    Text(
                      context.s.reportMarkersGone,
                      style: theme.typography.body
                          .copyWith(color: theme.colors.inkMuted),
                    ),
                  for (final row in report.rows) ...[
                    _RowBlock(
                      row: row,
                      report: report,
                      onDayTap: report.definition.axis == ReportAxis.cycleDay
                          ? null
                          : (dayKey) => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => DayDetailScreen(
                                    controller: widget.controller,
                                    dayKey: dayKey,
                                  ),
                                ),
                              ),
                    ),
                    const SizedBox(height: VitalsSpacing.xl),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _axisPicker(VitalsThemeData theme) => Wrap(
        spacing: VitalsSpacing.sm,
        children: [
          ChoiceChip(
            label: Text(context.s.byDate),
            selected: _definition.axis == ReportAxis.date,
            onSelected: (_) => _setAxis(ReportAxis.date),
          ),
          ChoiceChip(
            label: Text(context.s.byCycleDay),
            selected: _definition.axis == ReportAxis.cycleDay,
            onSelected: (_) => _setAxis(ReportAxis.cycleDay),
          ),
          ChoiceChip(
            label: Text(context.s.grid),
            selected: _definition.axis == ReportAxis.grid,
            onSelected: (_) => _setAxis(ReportAxis.grid),
          ),
        ],
      );
}

class _RowBlock extends StatelessWidget {
  const _RowBlock({required this.row, required this.report, this.onDayTap});

  final ReportRow row;
  final Report report;
  final ValueChanged<String>? onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final color = markerColor(row.metric.colorHex) ?? theme.colors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: VitalsSpacing.sm),
            Expanded(
              child: Text(row.metric.name, style: theme.typography.body),
            ),
            if (row.bandMetric case final band?)
              Text(
                context.s.behind(band.name),
                style: theme.typography.caption
                    .copyWith(color: theme.colors.inkFaint),
              ),
          ],
        ),
        const SizedBox(height: VitalsSpacing.sm),
        // Same cells either way - the grid is a layout, not a different
        // reading of the data.
        if (report.definition.axis == ReportAxis.grid)
          DayGridChart(
            row: row,
            dayKeys: report.dayKeys,
            color: color,
            onDayTap: onDayTap,
          )
        else
          ReportRowChart(row: row, color: color, onDayTap: onDayTap),
        const SizedBox(height: VitalsSpacing.xs),
        Text(
          _facts(row, context.s),
          style:
              theme.typography.caption.copyWith(color: theme.colors.inkMuted),
        ),
      ],
    );
  }

  /// Counts and ranges. **Coverage always travels with them**, because a
  /// typical over nine days of a month is a different statement from one over
  /// twenty-eight, and hiding that is how a tracker quietly lies.
  static String _facts(ReportRow row, AppStrings s) {
    final stats = row.stats;
    final parts = <String>[];
    if (stats.typical case final typical?) {
      parts.add('${s.typical} ${_number(typical)}');
    }
    if (stats.lowest case final low?) {
      final high = stats.highest ?? low;
      if (high != low) parts.add('${_number(low)}-${_number(high)}');
    }
    if (row.weeklyTypical case final weekly?) {
      parts.add('${s.weekly} ${_number(weekly)}');
    }
    parts.add(s.daysOf(stats.daysLogged, stats.daysInPeriod));
    return parts.join(' · ');
  }

  static String _number(num value) =>
      value == value.roundToDouble() ? '${value.round()}' : value.toStringAsFixed(1);
}
