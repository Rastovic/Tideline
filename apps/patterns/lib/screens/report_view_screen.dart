import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';
import 'report_builder_screen.dart';
import 'report_chart.dart';

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
    super.key,
  });

  final PatternsController controller;
  final ReportDefinition definition;

  @override
  State<ReportViewScreen> createState() => _ReportViewScreenState();
}

class _ReportViewScreenState extends State<ReportViewScreen> {
  late ReportDefinition _definition = widget.definition;
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
    await widget.controller.saveReport(_definition);
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
            tooltip: 'Izmijeni',
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
                      'Nijedan marker u ovom izvjestaju vise ne postoji.',
                      style: theme.typography.body
                          .copyWith(color: theme.colors.inkMuted),
                    ),
                  for (final row in report.rows) ...[
                    _RowBlock(row: row, report: report),
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
            label: const Text('Po datumu'),
            selected: _definition.axis == ReportAxis.date,
            onSelected: (_) => _setAxis(ReportAxis.date),
          ),
          ChoiceChip(
            label: const Text('Po danu ciklusa'),
            selected: _definition.axis == ReportAxis.cycleDay,
            onSelected: (_) => _setAxis(ReportAxis.cycleDay),
          ),
        ],
      );
}

class _RowBlock extends StatelessWidget {
  const _RowBlock({required this.row, required this.report});

  final ReportRow row;
  final Report report;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final color = _parseHex(row.metric.colorHex) ?? theme.colors.accent;

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
                'iza: ${band.name}',
                style: theme.typography.caption
                    .copyWith(color: theme.colors.inkFaint),
              ),
          ],
        ),
        const SizedBox(height: VitalsSpacing.sm),
        ReportRowChart(row: row, color: color),
        const SizedBox(height: VitalsSpacing.xs),
        Text(
          _facts(row),
          style:
              theme.typography.caption.copyWith(color: theme.colors.inkMuted),
        ),
      ],
    );
  }

  /// Counts and ranges. **Coverage always travels with them**, because a
  /// typical over nine days of a month is a different statement from one over
  /// twenty-eight, and hiding that is how a tracker quietly lies.
  static String _facts(ReportRow row) {
    final stats = row.stats;
    final parts = <String>[];
    if (stats.typical case final typical?) {
      parts.add('tipicno ${_number(typical)}');
    }
    if (stats.lowest case final low?) {
      final high = stats.highest ?? low;
      if (high != low) parts.add('${_number(low)}-${_number(high)}');
    }
    if (row.weeklyTypical case final weekly?) {
      parts.add('tjedno ${_number(weekly)}');
    }
    parts.add('${stats.daysLogged}/${stats.daysInPeriod} dana');
    return parts.join(' · ');
  }

  static String _number(num value) =>
      value == value.roundToDouble() ? '${value.round()}' : value.toStringAsFixed(1);

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }
}
