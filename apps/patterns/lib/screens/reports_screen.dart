import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';
import 'report_builder_screen.dart';
import 'report_view_screen.dart';

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
        title: const Text('Obrisati izvjestaj?'),
        // Worth saying plainly: this is the one delete in the app that cannot
        // cost data, and knowing that is what makes it safe to tidy up.
        content: const Text(
          'Nijedan unos se ne dira. Izvjestaj je samo pitanje nad podacima.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Obrisi'),
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
      appBar: AppBar(title: const Text('Izvjestaji')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _build,
        icon: const Icon(Icons.add),
        label: const Text('Novi izvjestaj'),
      ),
      body: SafeArea(
        child: reports == null
            ? const Center(child: CircularProgressIndicator())
            : reports.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(VitalsSpacing.screenH),
                    child: Text(
                      'Jos nijedan. Izvjestaj je set markera i period - '
                      'slozeni redovi na istoj vremenskoj osi, da ih citas '
                      'jedan uz drugi.',
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
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title:
                              Text(report.name, style: theme.typography.body),
                          subtitle: Text(
                            _describe(report),
                            style: theme.typography.caption
                                .copyWith(color: theme.colors.inkFaint),
                          ),
                          trailing: IconButton(
                            tooltip: 'Obrisi',
                            icon: const Icon(Icons.close),
                            onPressed: () => _delete(report),
                          ),
                          onTap: () => _open(report),
                        ),
                    ],
                  ),
      ),
    );
  }

  static String _describe(ReportDefinition report) {
    final rows = report.series.where((s) => !s.isBand).length;
    final period = switch (report.period) {
      LastDays(:final days) => switch (days) {
          7 => '7 dana',
          30 => 'mjesec',
          90 => '3 mjeseca',
          365 => 'godina',
          _ => '$days dana',
        },
      FixedPeriod(:final from, :final to) => '$from - $to',
    };
    final axis = switch (report.axis) {
      ReportAxis.cycleDay => ' · po danu ciklusa',
      ReportAxis.grid => ' · mreza',
      ReportAxis.date => '',
    };
    return '$rows markera · $period$axis';
  }
}
