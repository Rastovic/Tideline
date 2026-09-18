import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';
import 'doctor_page_screen.dart';
import 'export_screen.dart';
import 'panel.dart';
import 'report_builder_screen.dart';
import 'report_view_screen.dart';
import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';

/// The saved reports: questions worth asking again.
///
/// Empty on a fresh install and that is correct - the app suggests nothing,
/// because the whole point is that the comparisons are hers. The empty state
/// says what a report is and stops there.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({required this.controller, super.key});

  final PatternsController controller;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<ReportDefinition>? _reports;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reports = await widget.controller.savedReports();
    if (mounted) setState(() => _reports = reports);
  }

  Future<void> _build() async {
    final made = await Navigator.of(context).push<ReportDefinition>(
      MaterialPageRoute(
        builder: (_) => ReportBuilderScreen(controller: widget.controller),
      ),
    );
    await _load();
    if (made != null && mounted) await _open(made);
  }

  Future<void> _open(ReportDefinition definition) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReportViewScreen(
          controller: widget.controller,
          definition: definition,
        ),
      ),
    );
    await _load();
  }

  Future<void> _delete(ReportDefinition definition) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s.deleteReportQuestion),
        // Worth saying plainly: this is the one delete in the app that cannot
        // cost data, and knowing that is what makes it safe to tidy up.
        content: Text(context.s.deleteReportExplained),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.s.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.controller.deleteReport(definition.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final reports = _reports;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.reports),
        actions: [
          IconButton(
            tooltip: context.s.export,
            icon: const Icon(Icons.ios_share),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ExportScreen(controller: widget.controller),
              ),
            ),
          ),
          IconButton(
            tooltip: context.s.doctorPage,
            icon: const Icon(Icons.print_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    DoctorPageScreen(controller: widget.controller),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _build,
        icon: const Icon(Icons.add),
        label: Text(context.s.newReport),
      ),
      body: SafeArea(
        child: reports == null
            ? const Center(child: CircularProgressIndicator())
            : reports.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(VitalsSpacing.screenH),
                    child: Text(
                      context.s.noReportsYet,
                      style: theme.typography.body
                          .copyWith(color: theme.colors.inkMuted),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      VitalsSpacing.screenH,
                      VitalsSpacing.lg,
                      VitalsSpacing.screenH,
                      VitalsSpacing.giant,
                    ),
                    children: [
                      for (final report in reports)
                        Panel(
                          label: _describe(report, context.s),
                          trailing: IconButton(
                            tooltip: context.s.delete,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: theme.colors.inkFaint,
                            ),
                            onPressed: () => _delete(report),
                          ),
                          onTap: () => _open(report),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  report.name,
                                  style: theme.typography.title,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: theme.colors.accent,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  static String _describe(ReportDefinition report, AppStrings s) {
    final rows = report.series.where((s) => !s.isBand).length;
    final period = switch (report.period) {
      LastDays(:final days) => switch (days) {
          _ => s.window(days),
        },
      FixedPeriod(:final from, :final to) => '$from - $to',
    };
    final axis = switch (report.axis) {
      ReportAxis.cycleDay => ' · ${s.byCycleDay.toLowerCase()}',
      ReportAxis.grid => ' · ${s.grid.toLowerCase()}',
      ReportAxis.date => '',
    };
    return '${s.markerCount(rows)} · $period$axis';
  }
}
