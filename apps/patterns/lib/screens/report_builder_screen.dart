import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';
import 'metric_labels.dart';

/// Building a report: which markers, over what stretch, drawn how.
///
/// **She builds the report; the app never offers one.** There is no suggested
/// comparison, no "markers that go together", no correlation the app noticed.
/// Connections are made here, by her, afterwards - which is the same rule that
/// keeps markers from owning each other in the model.
///
/// A report is a lens over flat data and nothing hangs off it, so deleting one
/// loses a question and never an observation. That is why protocols became
/// saved reports rather than a structure the readings belong to.
class ReportBuilderScreen extends StatefulWidget {
  const ReportBuilderScreen({
    required this.controller,
    this.definition,
    super.key,
  });

  final PatternsController controller;

  /// Null builds a new report. Anything else edits that one.
  final ReportDefinition? definition;

  @override
  State<ReportBuilderScreen> createState() => _ReportBuilderScreenState();
}

class _ReportBuilderScreenState extends State<ReportBuilderScreen> {
  late final String _id = widget.definition?.id ?? Ids.newId();
  late final DateTime _createdAt =
      widget.definition?.createdAt ?? DateTime.now().toUtc();
  late final TextEditingController _name =
      TextEditingController(text: widget.definition?.name ?? '');

  late List<ReportSeries> _series = [...?widget.definition?.series];
  late ReportPeriod _period = widget.definition?.period ?? const LastDays(30);
  late ReportAxis _axis = widget.definition?.axis ?? ReportAxis.date;

  String? _problem;

  bool get _isNew => widget.definition == null;

  /// The windows worth having on a phone. A fixed stretch is reachable from a
  /// saved report that already carries one; offering a date-range picker here
  /// would be the most-used screen serving the least-used case.
  static const _windows = [7, 30, 90, 365];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool _isPicked(String metricId) =>
      _series.any((s) => s.metricId == metricId);

  void _toggle(Metric metric) {
    setState(() {
      if (_isPicked(metric.id)) {
        _series = [
          for (final s in _series)
            if (s.metricId != metric.id &&
                s.bandBehindMetricId != metric.id)
              s,
        ];
      } else {
        _series = [..._series, ReportSeries(metricId: metric.id)];
      }
    });
  }

  /// Rows the band can sit behind: every picked series that is not itself a
  /// band. A band behind a band would be two overlays in one frame, which is
  /// the thing the single-overlay rule exists to prevent.
  List<ReportSeries> get _rows => [for (final s in _series) if (!s.isBand) s];

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _problem = 'Daj izvjestaju ime.');
      return;
    }
    if (_rows.isEmpty) {
      setState(() => _problem = 'Izaberi bar jedan marker.');
      return;
    }

    final definition = ReportDefinition(
      id: _id,
      name: _name.text.trim(),
      series: _series,
      period: _period,
      axis: _axis,
      createdAt: _createdAt,
    );
    await widget.controller.saveReport(definition);
    if (mounted) Navigator.of(context).pop(definition);
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final markers = widget.controller.allMarkers
        .where((m) => !m.isDeleted && m.displayStyle != null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Novi izvjestaj' : 'Izvjestaj'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Sacuvaj')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VitalsSpacing.screenH,
            VitalsSpacing.lg,
            VitalsSpacing.screenH,
            VitalsSpacing.huge,
          ),
          children: [
            if (_problem case final problem?) ...[
              Container(
                padding: const EdgeInsets.all(VitalsSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colors.danger.withValues(alpha: 0.10),
                  borderRadius: VitalsRadius.nestedAll,
                ),
                child: Text(problem, style: theme.typography.caption),
              ),
              const SizedBox(height: VitalsSpacing.lg),
            ],
            TextField(
              controller: _name,
              autofocus: _isNew,
              style: theme.typography.title,
              decoration: const InputDecoration(
                labelText: 'Ime',
                hintText: 'kreatin i nadutost',
              ),
            ),
            const SizedBox(height: VitalsSpacing.xl),
            _heading(theme, 'Period'),
            Wrap(
              spacing: VitalsSpacing.sm,
              children: [
                for (final days in _windows)
                  ChoiceChip(
                    label: Text(_windowLabel(days)),
                    selected: _period is LastDays &&
                        (_period as LastDays).days == days,
                    onSelected: (_) =>
                        setState(() => _period = LastDays(days)),
                  ),
                if (_period case final FixedPeriod fixed)
                  ChoiceChip(
                    label: Text('${fixed.from} - ${fixed.to}'),
                    selected: true,
                    onSelected: (_) {},
                  ),
              ],
            ),
            const SizedBox(height: VitalsSpacing.xl),
            _heading(theme, 'Osa'),
            Wrap(
              spacing: VitalsSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('Po datumu'),
                  selected: _axis == ReportAxis.date,
                  onSelected: (_) => setState(() => _axis = ReportAxis.date),
                ),
                ChoiceChip(
                  label: const Text('Po danu ciklusa'),
                  selected: _axis == ReportAxis.cycleDay,
                  onSelected: (_) =>
                      setState(() => _axis = ReportAxis.cycleDay),
                ),
                ChoiceChip(
                  label: const Text('Mreza'),
                  selected: _axis == ReportAxis.grid,
                  onSelected: (_) => setState(() => _axis = ReportAxis.grid),
                ),
              ],
            ),
            const SizedBox(height: VitalsSpacing.xl),
            _heading(theme, 'Markeri'),
            for (final metric in markers)
              _MarkerPick(
                metric: metric,
                picked: _isPicked(metric.id),
                series: _seriesFor(metric.id),
                rows: _rows
                    .where((s) => s.metricId != metric.id)
                    .map((s) => widget.controller.byId(s.metricId))
                    .whereType<Metric>()
                    .toList(),
                onToggle: () => _toggle(metric),
                onStyle: (style) => _setStyle(metric.id, style),
                onBand: (behind) => _setBand(metric.id, behind),
              ),
          ],
        ),
      ),
    );
  }

  ReportSeries? _seriesFor(String metricId) {
    for (final series in _series) {
      if (series.metricId == metricId) return series;
    }
    return null;
  }

  void _setStyle(String metricId, DisplayStyle? style) {
    setState(() {
      _series = [
        for (final s in _series)
          if (s.metricId == metricId)
            ReportSeries(
              metricId: s.metricId,
              displayStyle: style,
              bandBehindMetricId: s.bandBehindMetricId,
            )
          else
            s,
      ];
    });
  }

  void _setBand(String metricId, String? behind) {
    setState(() {
      _series = [
        for (final s in _series)
          if (s.metricId == metricId)
            ReportSeries(
              metricId: s.metricId,
              displayStyle: behind == null ? s.displayStyle : null,
              bandBehindMetricId: behind,
            )
          else
            s,
      ];
    });
  }

  Widget _heading(VitalsThemeData theme, String label) => Padding(
        padding: const EdgeInsets.only(bottom: VitalsSpacing.sm),
        child: Text(
          label.toUpperCase(),
          style: theme.typography.label.copyWith(
            color: theme.colors.inkFaint,
            letterSpacing: 1.2,
          ),
        ),
      );

  static String _windowLabel(int days) => switch (days) {
        7 => '7 dana',
        30 => 'mjesec',
        90 => '3 mjeseca',
        365 => 'godina',
        _ => '$days dana',
      };
}

class _MarkerPick extends StatelessWidget {
  const _MarkerPick({
    required this.metric,
    required this.picked,
    required this.series,
    required this.rows,
    required this.onToggle,
    required this.onStyle,
    required this.onBand,
  });

  final Metric metric;
  final bool picked;
  final ReportSeries? series;

  /// The other picked rows this one could ride behind.
  final List<Metric> rows;

  final VoidCallback onToggle;
  final ValueChanged<DisplayStyle?> onStyle;
  final ValueChanged<String?> onBand;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final canBand =
        metric.kind == MetricKind.boolean && rows.isNotEmpty && picked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: picked,
          onChanged: (_) => onToggle(),
          title: Text(metric.name, style: theme.typography.body),
          subtitle: Text(
            kindNames[metric.kind]!,
            style:
                theme.typography.caption.copyWith(color: theme.colors.inkFaint),
          ),
        ),
        if (picked) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: VitalsSpacing.xxl,
              bottom: VitalsSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (series?.isBand != true)
                  Wrap(
                    spacing: VitalsSpacing.sm,
                    runSpacing: VitalsSpacing.sm,
                    children: [
                      for (final style in DisplayStyle.allowedFor(metric.kind))
                        ChoiceChip(
                          label: Text(displayNames[style]!),
                          selected: (series?.displayStyle ??
                                  metric.displayStyle) ==
                              style,
                          onSelected: (_) => onStyle(style),
                        ),
                    ],
                  ),
                if (canBand) ...[
                  const SizedBox(height: VitalsSpacing.sm),
                  // The one overlay the app permits. A band has no scale of its
                  // own, so it cannot be stretched until it agrees with the
                  // series in front of it - which is exactly why two y axes in
                  // one frame stay banned.
                  DropdownButton<String?>(
                    value: series?.bandBehindMetricId,
                    hint: const Text('Kao traka iza...'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        child: Text('Svoj red'),
                      ),
                      for (final row in rows)
                        DropdownMenuItem(
                          value: row.id,
                          child: Text('iza: ${row.name}'),
                        ),
                    ],
                    onChanged: onBand,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
