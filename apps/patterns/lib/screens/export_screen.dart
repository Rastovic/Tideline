import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/archive_transfer.dart';
import '../data/patterns_controller.dart';

/// The two text files that leave the phone: one for an AI chat, one for a
/// spreadsheet.
enum ExportShape { ai, csv }

/// Exporting readings as a file.
///
/// **Shape first**, because what goes in depends on where it is going. Then the
/// period, then the markers, then a plain statement of what is held back -
/// photos never, private diary entries never, the rest of the diary only when
/// ticked - before anything is written. Nothing is sent anywhere by the app:
/// the file goes to the system share sheet and the person picks where.
class ExportScreen extends StatefulWidget {
  const ExportScreen({
    required this.controller,
    this.transfer = const PlatformArchiveTransfer(),
    super.key,
  });

  final PatternsController controller;
  final ArchiveTransfer transfer;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  ExportShape _shape = ExportShape.ai;

  /// Days back from today; null is everything.
  int? _days = 90;

  late final Set<String> _picked = {
    for (final m in _offered)
      if (m.kind != MetricKind.text) m.id,
  };
  final _preamble = TextEditingController(text: defaultAiPreamble);

  Future<ExportData>? _preview;

  List<Metric> get _offered => widget.controller.allMarkers
      .where((m) => !m.isDeleted && m.kind != MetricKind.photo)
      .toList();

  (String, String) get _range {
    final today = widget.controller.today;
    final days = _days;
    // Far enough back to hold anything this app could have recorded.
    return (days == null ? '2000-01-01' : addDays(today, -(days - 1)), today);
  }

  bool get _includeDiary => _offered.any(
        (m) => m.kind == MetricKind.text && _picked.contains(m.id),
      );

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _preamble.dispose();
    super.dispose();
  }

  void _refresh() {
    final (from, to) = _range;
    setState(() {
      _preview = widget.controller.exportData(
        // Diary markers are always asked for, so a held-back count exists
        // even when they are not ticked.
        [
          for (final m in _offered)
            if (_picked.contains(m.id) || m.kind == MetricKind.text) m.id,
        ],
        from: from,
        to: to,
        includeDiary: _includeDiary,
      );
    });
  }

  Future<void> _share(ExportData data) async {
    final (text, name) = switch (_shape) {
      ExportShape.ai => (
          exportAiMarkdown(data, preamble: _preamble.text),
          'zapis-${data.to}.md',
        ),
      ExportShape.csv => (exportCsv(data), 'zapis-${data.to}.csv'),
    };
    await widget.transfer.send(utf8.encode(text), name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);

    Widget heading(String label) => Padding(
          padding: const EdgeInsets.only(
            top: VitalsSpacing.xl,
            bottom: VitalsSpacing.sm,
          ),
          child: Text(
            label.toUpperCase(),
            style: theme.typography.label.copyWith(
              color: theme.colors.inkFaint,
              letterSpacing: 1.2,
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Izvoz')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VitalsSpacing.screenH,
            0,
            VitalsSpacing.screenH,
            VitalsSpacing.huge,
          ),
          children: [
            heading('Za sta'),
            Wrap(
              spacing: VitalsSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('Za AI'),
                  selected: _shape == ExportShape.ai,
                  onSelected: (_) => setState(() => _shape = ExportShape.ai),
                ),
                ChoiceChip(
                  label: const Text('Tabela (CSV)'),
                  selected: _shape == ExportShape.csv,
                  onSelected: (_) => setState(() => _shape = ExportShape.csv),
                ),
              ],
            ),
            heading('Period'),
            Wrap(
              spacing: VitalsSpacing.sm,
              children: [
                for (final (days, label) in const [
                  (30, 'mjesec'),
                  (90, '3 mjeseca'),
                  (365, 'godina'),
                  (null, 'sve'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _days == days,
                    onSelected: (_) {
                      _days = days;
                      _refresh();
                    },
                  ),
              ],
            ),
            if (_shape == ExportShape.ai) ...[
              heading('Uvod'),
              TextField(
                controller: _preamble,
                minLines: 3,
                maxLines: 6,
                style: theme.typography.body,
              ),
            ],
            heading('Sta ide u fajl'),
            for (final metric in _offered)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _picked.contains(metric.id),
                onChanged: (on) {
                  on == true ? _picked.add(metric.id) : _picked.remove(metric.id);
                  _refresh();
                },
                title: Text(metric.name, style: theme.typography.body),
              ),
            const SizedBox(height: VitalsSpacing.lg),
            FutureBuilder<ExportData>(
              future: _preview,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(VitalsSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colors.surface,
                        borderRadius: VitalsRadius.nestedAll,
                        border: Border.all(color: theme.colors.stroke),
                      ),
                      child: Text(
                        [
                          '${data.rows.length} unosa ide u fajl.',
                          'Fotografije: nikad.',
                          'Privatni unosi dnevnika izostavljeni: '
                              '${data.heldBackPrivate}.',
                          if (data.heldBackDiary > 0)
                            'Dnevnik nije izabran, izostavljeno: '
                                '${data.heldBackDiary}.',
                        ].join('\n'),
                        style: theme.typography.caption,
                      ),
                    ),
                    const SizedBox(height: VitalsSpacing.lg),
                    FilledButton.icon(
                      onPressed: data.rows.isEmpty ? null : () => _share(data),
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Podijeli fajl'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
