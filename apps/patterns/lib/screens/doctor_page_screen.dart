import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vitals_ui/vitals_ui.dart';

import '../data/archive_transfer.dart';
import '../data/doctor_pdf.dart';
import '../data/patterns_controller.dart';
import 'metric_labels.dart';

/// Loads the fonts the page prints with. Injected so a test does not read
/// `/system/fonts`.
typedef FontLoader = Future<({pw.Font regular, pw.Font bold})?> Function();

/// One printable page for a doctor's appointment.
///
/// **A feature, not the product.** It is here because the day it is needed it
/// is really needed, and it is one screen deep so it never competes with the
/// reports. She picks what goes on it; nothing is preselected, because which
/// markers matter depends entirely on why she is going.
class DoctorPageScreen extends StatefulWidget {
  const DoctorPageScreen({
    required this.controller,
    this.transfer = const PlatformArchiveTransfer(),
    this.fonts = loadSystemFonts,
    super.key,
  });

  final PatternsController controller;

  /// Shares the finished file. The same seam the backup uses.
  final ArchiveTransfer transfer;

  final FontLoader fonts;

  @override
  State<DoctorPageScreen> createState() => _DoctorPageScreenState();
}

class _DoctorPageScreenState extends State<DoctorPageScreen> {
  /// Picked marker ids, in the order they were picked - which is the order
  /// they print in.
  final List<String> _picked = [];
  int _days = 90;
  DoctorPaper _paper = DoctorPaper.a4;
  bool _working = false;
  String? _problem;

  static const _windows = [30, 90, 180];

  void _toggle(Metric metric) {
    setState(() {
      _problem = null;
      if (_picked.contains(metric.id)) {
        _picked.remove(metric.id);
      } else if (_picked.length < doctorPageMaxMarkers) {
        _picked.add(metric.id);
      }
    });
  }

  Future<void> _make() async {
    if (_picked.isEmpty) {
      setState(() => _problem = 'Izaberi bar jedan marker.');
      return;
    }
    setState(() {
      _working = true;
      _problem = null;
    });
    try {
      final page =
          await widget.controller.doctorPage(_picked, LastDays(_days));
      final bytes = await renderDoctorPdf(
        page,
        generatedAt: DateTime.now(),
        paper: _paper,
        fonts: await widget.fonts(),
      );
      await widget.transfer.send(bytes, 'pregled-${page.to}.pdf');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final markers = widget.controller.allMarkers
        .where((m) => m.isActive && m.displayStyle != null)
        .toList();
    final full = _picked.length >= doctorPageMaxMarkers;

    return Scaffold(
      appBar: AppBar(title: const Text('Stranica za doktora')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VitalsSpacing.screenH,
            VitalsSpacing.lg,
            VitalsSpacing.screenH,
            VitalsSpacing.huge,
          ),
          children: [
            Text(
              'Jedna stranica za stampu: brojevi, rasponi sa datumima i '
              'koliko je dana upisano. Bez tumacenja. Dnevnik nikad ne ide '
              'na ovu stranicu.',
              style:
                  theme.typography.caption.copyWith(color: theme.colors.inkMuted),
            ),
            if (_problem case final problem?) ...[
              const SizedBox(height: VitalsSpacing.lg),
              Text(problem,
                  style: theme.typography.body
                      .copyWith(color: theme.colors.danger)),
            ],
            const SizedBox(height: VitalsSpacing.xl),
            _heading(theme, 'Period'),
            Wrap(
              spacing: VitalsSpacing.sm,
              children: [
                for (final days in _windows)
                  ChoiceChip(
                    label: Text(switch (days) {
                      30 => 'mjesec',
                      90 => '3 mjeseca',
                      _ => '6 mjeseci',
                    }),
                    selected: _days == days,
                    onSelected: (_) => setState(() => _days = days),
                  ),
              ],
            ),
            const SizedBox(height: VitalsSpacing.xl),
            _heading(theme, 'Papir'),
            Wrap(
              spacing: VitalsSpacing.sm,
              children: [
                for (final paper in DoctorPaper.values)
                  ChoiceChip(
                    label: Text(paper.label),
                    selected: _paper == paper,
                    onSelected: (_) => setState(() => _paper = paper),
                  ),
              ],
            ),
            const SizedBox(height: VitalsSpacing.xl),
            _heading(
              theme,
              'Markeri (${_picked.length}/$doctorPageMaxMarkers)',
            ),
            for (final metric in markers)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _picked.contains(metric.id),
                // A ninth marker is a second page, and the second page is the
                // one that gets lost - so the rest wait rather than overflow.
                onChanged: full && !_picked.contains(metric.id)
                    ? null
                    : (_) => _toggle(metric),
                title: Text(metric.name, style: theme.typography.body),
                subtitle: Text(
                  kindNames[metric.kind]!,
                  style: theme.typography.caption
                      .copyWith(color: theme.colors.inkFaint),
                ),
                secondary: _picked.contains(metric.id)
                    ? Text('${_picked.indexOf(metric.id) + 1}.',
                        style: theme.typography.caption)
                    : null,
              ),
            const SizedBox(height: VitalsSpacing.xl),
            FilledButton.icon(
              onPressed: _working ? null : _make,
              icon: _working
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Napravi PDF'),
            ),
          ],
        ),
      ),
    );
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
}
