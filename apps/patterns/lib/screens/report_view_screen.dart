import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/archive_transfer.dart';
import '../data/patterns_controller.dart';
import 'day_detail_screen.dart';
import 'comparison_panel.dart';
import 'day_grid_chart.dart';
import 'marked_days_strip.dart';
import 'panel.dart';
import 'metric_labels.dart';
import 'report_builder_screen.dart';
import 'report_chart.dart';
import 'share_report.dart';
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
    this.transfer = const PlatformArchiveTransfer(),
    super.key,
  });

  /// Where a shared file goes. The same seam the backup uses.
  final ArchiveTransfer transfer;

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
  Comparison? _comparison;

  /// Per marker: the days in the window carrying a note or a photo.
  Map<String, ({Set<String> notes, Set<String> photos})> _marked = const {};

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  Future<void> _rebuild() async {
    final report = await widget.controller.buildSavedReport(_definition);
    final comparison = await widget.controller.comparisonFor(_definition);
    final marked = <String, ({Set<String> notes, Set<String> photos})>{};
    for (final row in report.rows) {
      marked[row.metric.id] = await widget.controller.markedDays(
        row.metric.id,
        from: report.from,
        to: report.to,
      );
    }
    if (mounted) {
      setState(() {
        _report = report;
        _comparison = comparison;
        _marked = marked;
      });
    }
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
            tooltip: context.s.shareThisReport,
            icon: const Icon(Icons.ios_share),
            onPressed: () => shareReport(
              context,
              widget.controller,
              _definition,
              transfer: widget.transfer,
            ),
          ),
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
                    style: theme.typography.caption.copyWith(
                      color: theme.colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: VitalsSpacing.md),
                  _axisPicker(theme),
                  const SizedBox(height: VitalsSpacing.xl),
                  // Above the rows: it is the question the report was built
                  // to ask, and the rows are the days behind it.
                  if (_comparison case final comparison?)
                    ComparisonPanel(comparison: comparison),
                  if (report.rows.isEmpty)
                    Text(
                      context.s.reportMarkersGone,
                      style: theme.typography.body.copyWith(
                        color: theme.colors.inkMuted,
                      ),
                    ),
                  for (final row in report.rows) ...[
                    _RowBlock(
                      row: row,
                      report: report,
                      marked: _marked[row.metric.id],
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
      if (widget.controller.cycleEnabled ||
          _definition.axis == ReportAxis.cycleDay)
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
  const _RowBlock({
    required this.row,
    required this.report,
    this.marked,
    this.onDayTap,
  });

  /// Days in this row's window that carry a note or a photo.
  final ({Set<String> notes, Set<String> photos})? marked;

  final ReportRow row;
  final Report report;
  final ValueChanged<String>? onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final color = markerColor(row.metric.colorHex) ?? theme.colors.accent;

    final (headline, headlineLabel) = _headline(row, context.s);

    return Panel(
      label: row.metric.name,
      color: color,
      trailing: row.bandMetric == null
          ? null
          : Text(
              context.s.behind(row.bandMetric!.name),
              style: theme.typography.caption.copyWith(
                color: theme.colors.inkFaint,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The one number worth reading first, big, with what it is and how
          // much stands behind it right beside it. Never a grade: typical is a
          // median, and the days logged sit next to it every time.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                headline,
                style: theme.typography.displayL.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1,
                ),
              ),
              const SizedBox(width: VitalsSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    headlineLabel,
                    style: theme.typography.caption
                        .copyWith(color: theme.colors.inkMuted),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  context.s.daysOf(row.stats.daysLogged, row.stats.daysInPeriod),
                  style: theme.typography.caption.copyWith(
                    color: theme.colors.inkMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VitalsSpacing.md),
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
          if (marked case final marked?
              when report.definition.axis != ReportAxis.cycleDay &&
                  report.definition.axis != ReportAxis.grid) ...[
            const SizedBox(height: VitalsSpacing.xs),
            MarkedDaysStrip(
              cells: row.cells,
              notes: marked.notes,
              photos: marked.photos,
              onDayTap: onDayTap,
            ),
            if (marked.notes.isNotEmpty || marked.photos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: VitalsSpacing.xs),
                child: Text(
                  context.s
                      .markedDaysLine(marked.notes.length, marked.photos.length),
                  style: theme.typography.caption
                      .copyWith(color: theme.colors.inkFaint),
                ),
              ),
          ],
          if (_facts(row, context.s) case final facts
              when facts.isNotEmpty) ...[
            const SizedBox(height: VitalsSpacing.sm),
            Text(
              facts,
              style: theme.typography.caption.copyWith(
                color: theme.colors.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The big number on the card and its caption. The typical value where the
  /// marker has one - as a clock time for a time marker - and otherwise the
  /// days it was logged, since a tag row or a yes/no has no typical number.
  static (String, String) _headline(ReportRow row, AppStrings s) {
    final typical = row.stats.typical;
    if (typical == null) {
      return ('${row.stats.daysLogged}', s.daysLoggedLabel);
    }
    if (row.metric.kind == MetricKind.timeOfDay) {
      final minute = typical.round() % 1440;
      return (
        '${(minute ~/ 60).toString().padLeft(2, '0')}:'
            '${(minute % 60).toString().padLeft(2, '0')}',
        s.typical,
      );
    }
    final unit = row.metric.unit == null ? '' : ' ${row.metric.unit}';
    return (_number(typical), '${s.typical}$unit');
  }

  /// Counts and ranges. **Coverage always travels with them**, because a
  /// typical over nine days of a month is a different statement from one over
  /// twenty-eight, and hiding that is how a tracker quietly lies.
  static String _facts(ReportRow row, AppStrings s) {
    final stats = row.stats;
    // Typical and days logged are the card's headline, so this line carries
    // what is left: the spread and the typical week.
    final parts = <String>[];
    if (stats.lowest case final low? when row.metric.kind != MetricKind.timeOfDay) {
      final high = stats.highest ?? low;
      if (high != low) {
        parts.add('${s.rangeLower} ${_number(low)}-${_number(high)}');
      }
    }
    if (row.weeklyTypical case final weekly?) {
      parts.add('${s.weekly} ${_number(weekly)}');
    }
    return parts.join(' · ');
  }

  static String _number(num value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(1);
}
