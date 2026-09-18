import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/archive_transfer.dart';
import '../data/patterns_controller.dart';
import '../l10n/app_language.dart';

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
  final _preamble = TextEditingController();

  /// The intro starts in the app's language, and follows a language change
  /// until she edits it - after that it is her text.
  AppLanguage? _preambleLanguage;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = context.s.language;
    if (_preambleLanguage == language) return;
    final untouched = _preambleLanguage == null ||
        _preamble.text == defaultAiPreamble(_preambleLanguage!.text);
    if (untouched) _preamble.text = defaultAiPreamble(language.text);
    _preambleLanguage = language;
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
        language: context.s.language.text,
      );
    });
  }

  Future<void> _share(ExportData data) async {
    final (text, name) = switch (_shape) {
      ExportShape.ai => (
          exportAiMarkdown(
            data,
            preamble: _preamble.text,
            language: context.s.language.text,
          ),
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
      appBar: AppBar(title: Text(context.s.export)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VitalsSpacing.screenH,
            0,
            VitalsSpacing.screenH,
            VitalsSpacing.huge,
          ),
          children: [
            heading(context.s.exportFor),
            Wrap(
              spacing: VitalsSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text(context.s.forAi),
                  selected: _shape == ExportShape.ai,
                  onSelected: (_) => setState(() => _shape = ExportShape.ai),
                ),
                ChoiceChip(
                  label: Text(context.s.spreadsheetCsv),
                  selected: _shape == ExportShape.csv,
                  onSelected: (_) => setState(() => _shape = ExportShape.csv),
                ),
              ],
            ),
            heading(context.s.period),
            Wrap(
              spacing: VitalsSpacing.sm,
              children: [
                for (final (days, label) in [
                  (30, context.s.window(30)),
                  (90, context.s.window(90)),
                  (365, context.s.window(365)),
                  (null, context.s.all),
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
              heading(context.s.intro),
              TextField(
                controller: _preamble,
                minLines: 3,
                maxLines: 6,
                style: theme.typography.body,
              ),
            ],
            heading(context.s.whatGoesIn),
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
                          context.s.exportRowCount(data.rows.length),
                          context.s.photosNever,
                          context.s.privateHeldBack(data.heldBackPrivate),
                          if (data.heldBackDiary > 0)
                            context.s.diaryHeldBack(data.heldBackDiary),
                          if (data.heldBackNotes > 0)
                            context.s.notesHeldBack(data.heldBackNotes),
                        ].join('\n'),
                        style: theme.typography.caption,
                      ),
                    ),
                    const SizedBox(height: VitalsSpacing.lg),
                    FilledButton.icon(
                      onPressed: data.rows.isEmpty ? null : () => _share(data),
                      icon: const Icon(Icons.ios_share),
                      label: Text(context.s.shareFile),
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
