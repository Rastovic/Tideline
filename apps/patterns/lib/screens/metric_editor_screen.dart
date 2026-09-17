import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';
import '../l10n/app_language.dart';

/// The type system's UI, and the reason a new marker no longer needs a build.
///
/// **Every marker in the app is editable here, seeded ones included.** There is
/// no built-in list this screen cannot reach and no field a seeded marker has
/// that a new one does not, because "track my own thing" is the reason the app
/// exists and a privileged path is how that promise quietly stops being true.
///
/// **What is deliberately absent: a goal, a target, a direction, a streak.**
/// Their absence is the feature. A field for a target is how grading gets added
/// by accident, and this app records rather than grades.
///
/// Three things are refused rather than warned about, all of them the same bug
/// - readings on disk meaning something other than what they meant when they
/// were written. Retyping a marker that holds readings, narrowing a scale under
/// a reading that exists, and removing an option that has been picked. Each one
/// offers the honest alternative instead: archive it and start a new one.
class MetricEditorScreen extends StatefulWidget {
  const MetricEditorScreen({
    required this.controller,
    this.metric,
    this.initialDomain = MetricDomain.body,
    super.key,
  });

  final PatternsController controller;

  /// Null creates a marker. Anything else edits that one.
  final Metric? metric;

  /// Which section a new marker starts in, so arriving from the Body heading
  /// does not open the form on Mind.
  final MetricDomain initialDomain;

  @override
  State<MetricEditorScreen> createState() => _MetricEditorScreenState();
}

class _MetricEditorScreenState extends State<MetricEditorScreen> {
  late final String _id = widget.metric?.id ?? Ids.newId();
  late final DateTime _createdAt =
      widget.metric?.createdAt ?? DateTime.now().toUtc();
  late final DateTime? _archivedAt = widget.metric?.archivedAt;
  late final int _sortOrder =
      widget.metric?.sortOrder ?? widget.controller.nextSortOrder(_domain);

  late final TextEditingController _name =
      TextEditingController(text: widget.metric?.name ?? '');
  late final TextEditingController _unit =
      TextEditingController(text: widget.metric?.unit ?? '');
  late final TextEditingController _lowLabel =
      TextEditingController(text: widget.metric?.lowLabel ?? '');
  late final TextEditingController _highLabel =
      TextEditingController(text: widget.metric?.highLabel ?? '');

  late MetricDomain _domain = widget.metric?.domain ?? widget.initialDomain;
  late MetricKind _kind = widget.metric?.kind ?? MetricKind.scale;
  late DayAggregation _aggregation =
      widget.metric?.aggregation ?? DayAggregation.defaultFor(_kind);
  late DisplayStyle? _displayStyle =
      widget.metric?.displayStyle ?? DisplayStyle.defaultFor(_kind);
  late String? _colorHex = widget.metric?.colorHex;
  late int _scaleMin = widget.metric?.scaleMin ?? 1;
  late int _scaleMax = widget.metric?.scaleMax ?? 10;
  late List<MetricOption> _options = [...?widget.metric?.options];

  /// What is already recorded. Null until it has been read, which is why the
  /// kind field is disabled rather than wrong for the first frame of an edit:
  /// offering a retype and then refusing it is worse than waiting.
  MetricReadingFacts? _facts;

  final ScrollController _scroll = ScrollController();

  List<ValidationFailure> _problems = const [];
  bool _saving = false;

  bool get _isNew => widget.metric == null;

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      _facts = MetricReadingFacts.none;
    } else {
      widget.controller.factsFor(widget.metric!).then((facts) {
        if (mounted) setState(() => _facts = facts);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _lowLabel.dispose();
    _highLabel.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The marker as the form currently describes it.
  ///
  /// Built fresh rather than via `copyWith`, because `copyWith` refuses to
  /// change the kind on purpose and a retype is legitimate while nothing has
  /// been recorded.
  Metric _asMetric() => Metric(
        id: _id,
        name: _name.text.trim(),
        domain: _domain,
        kind: _kind,
        aggregation: _aggregation,
        displayStyle: _displayStyle,
        createdAt: _createdAt,
        colorHex: _colorHex,
        unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
        scaleMin: _scaleMin,
        scaleMax: _scaleMax,
        lowLabel: _lowLabel.text.trim().isEmpty ? null : _lowLabel.text.trim(),
        highLabel:
            _highLabel.text.trim().isEmpty ? null : _highLabel.text.trim(),
        options: _options,
        sortOrder: _sortOrder,
        archivedAt: _archivedAt,
      );

  /// Changing the kind resets the two settings that are kind-specific.
  ///
  /// Carrying `sum` from a dose onto a rating would fail validation anyway;
  /// resetting here means the form is never briefly in a state it would refuse
  /// to save, which is what makes the error banner mean something.
  void _setKind(MetricKind kind) {
    setState(() {
      _kind = kind;
      _aggregation = DayAggregation.defaultFor(kind);
      _displayStyle = DisplayStyle.defaultFor(kind);
    });
  }

  Future<void> _save() async {
    final candidate = _asMetric();
    final before = widget.metric;
    final problems = before == null
        ? validateMetric(candidate, context.s.language.text)
        : validateMetricChange(
            before,
            candidate,
            facts: _facts ?? MetricReadingFacts.none,
            language: context.s.language.text,
          );

    if (problems.isNotEmpty) {
      setState(() => _problems = problems);
      // The banner is at the top of a long form, and Save is in the app bar
      // where it is reachable from the bottom of it. Without this, refusing an
      // edit made at the bottom of the screen looks like the button doing
      // nothing at all.
      await _scroll.animateTo(
        0,
        duration: VitalsMotion.standard,
        curve: VitalsMotion.standardCurve,
      );
      return;
    }

    setState(() {
      _problems = const [];
      _saving = true;
    });
    await widget.controller.saveMetric(candidate);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? context.s.newMarker : context.s.marker),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(context.s.save),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(
            VitalsSpacing.screenH,
            VitalsSpacing.lg,
            VitalsSpacing.screenH,
            VitalsSpacing.huge,
          ),
          children: [
            if (_problems.isNotEmpty) _ProblemBanner(problems: _problems),
            TextField(
              controller: _name,
              autofocus: _isNew,
              style: theme.typography.title,
              decoration: InputDecoration(
                labelText: context.s.name,
                hintText: context.s.markerNameHint,
              ),
            ),
            const SizedBox(height: VitalsSpacing.xl),
            _Heading(label: context.s.section, theme: theme),
            _domainPicker(theme),
            const SizedBox(height: VitalsSpacing.xl),
            _Heading(label: context.s.type, theme: theme),
            _kindPicker(theme),
            ..._kindFields(theme),
            const SizedBox(height: VitalsSpacing.xl),
            _Heading(label: context.s.dayWithSeveralEntries, theme: theme),
            _aggregationPicker(theme),
            if (DisplayStyle.allowedFor(_kind).isNotEmpty) ...[
              const SizedBox(height: VitalsSpacing.xl),
              _Heading(label: context.s.howItIsDrawn, theme: theme),
              _displayPicker(theme),
            ],
            const SizedBox(height: VitalsSpacing.xl),
            _Heading(label: context.s.colour, theme: theme),
            _colorPicker(theme),
            if (!_isNew) ...[
              const SizedBox(height: VitalsSpacing.huge),
              _lifecycle(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _domainPicker(VitalsThemeData theme) => Wrap(
        spacing: VitalsSpacing.sm,
        children: [
          for (final domain in MetricDomain.values)
            ChoiceChip(
              label: Text(context.s.domainName(domain)),
              selected: _domain == domain,
              onSelected: (_) => setState(() => _domain = domain),
            ),
        ],
      );

  /// The kind picker, and the one field that locks.
  ///
  /// Locked with the count and the alternative spelled out, never greyed out in
  /// silence: a disabled control with no reason attached reads as a bug.
  Widget _kindPicker(VitalsThemeData theme) {
    final facts = _facts;
    final loading = facts == null;
    final locked = !loading && facts.hasReadings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: VitalsSpacing.sm,
          runSpacing: VitalsSpacing.sm,
          children: [
            for (final kind in MetricKind.values)
              if (!locked ||
                  canRetype(widget.metric!.kind, kind, hasReadings: true))
                ChoiceChip(
                  label: Text(context.s.kindName(kind)),
                  selected: _kind == kind,
                  onSelected: loading ? null : (_) => _setKind(kind),
                ),
          ],
        ),
        const SizedBox(height: VitalsSpacing.sm),
        Text(
          locked
              ? context.s.typeLocked(facts.count)
              : context.s.kindHint(_kind),
          style: theme.typography.caption.copyWith(color: theme.colors.inkMuted),
        ),
      ],
    );
  }

  List<Widget> _kindFields(VitalsThemeData theme) => switch (_kind) {
        MetricKind.scale => [
            const SizedBox(height: VitalsSpacing.xl),
            _Heading(label: context.s.range, theme: theme),
            Row(
              children: [
                Expanded(
                  child: _Stepper(
                    label: context.s.from,
                    value: _scaleMin,
                    onChanged: (v) => setState(() => _scaleMin = v),
                  ),
                ),
                const SizedBox(width: VitalsSpacing.md),
                Expanded(
                  child: _Stepper(
                    label: context.s.to,
                    value: _scaleMax,
                    onChanged: (v) => setState(() => _scaleMax = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VitalsSpacing.md),
            // Unlabelled ends are the reason old ratings become unreadable: a 3
            // means nothing in March unless you wrote down what 1 and 10 were.
            TextField(
              controller: _lowLabel,
              decoration: InputDecoration(
                labelText: context.s.whatLowMeans,
                hintText: context.s.lowHint,
              ),
            ),
            const SizedBox(height: VitalsSpacing.md),
            TextField(
              controller: _highLabel,
              decoration: InputDecoration(
                labelText: context.s.whatHighMeans,
                hintText: context.s.highHint,
              ),
            ),
          ],
        MetricKind.amount => [
            const SizedBox(height: VitalsSpacing.xl),
            TextField(
              controller: _unit,
              decoration: InputDecoration(
                labelText: context.s.unit,
                hintText: 'g',
              ),
            ),
          ],
        MetricKind.choice || MetricKind.tags => [
            const SizedBox(height: VitalsSpacing.xl),
            _Heading(label: context.s.options, theme: theme),
            _optionEditor(theme),
          ],
        _ => const [],
      };

  /// The option list, where archiving and deleting are two different things.
  ///
  /// An option nothing ever picked can go outright; one that carries history
  /// can only be archived, because every reading that picked it points at its
  /// id and renaming it later must not orphan four months of it.
  Widget _optionEditor(VitalsThemeData theme) {
    final used = _facts?.usedOptionIds ?? const <String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _options.length; i++)
          _OptionRow(
            key: ValueKey(_options[i].id),
            option: _options[i],
            hasHistory: used.contains(_options[i].id),
            onLabel: (label) => setState(
              () => _options[i] = _options[i].copyWith(label: label),
            ),
            onToggleArchived: () => setState(
              () => _options[i] =
                  _options[i].copyWith(archived: !_options[i].archived),
            ),
            onRemove: () => setState(() => _options.removeAt(i)),
          ),
        const SizedBox(height: VitalsSpacing.sm),
        TextButton.icon(
          onPressed: () => setState(() {
            _options = [
              ..._options,
              MetricOption(
                id: Ids.newId(),
                label: '',
                sortOrder: _options.length,
              ),
            ];
          }),
          icon: const Icon(Icons.add),
          label: Text(context.s.addOption),
        ),
      ],
    );
  }

  Widget _aggregationPicker(VitalsThemeData theme) {
    final allowed = DayAggregation.allowedFor(_kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: VitalsSpacing.sm,
          runSpacing: VitalsSpacing.sm,
          children: [
            for (final rule in allowed)
              ChoiceChip(
                label: Text(context.s.aggregationName(rule)),
                selected: _aggregation == rule,
                onSelected: (_) => setState(() => _aggregation = rule),
              ),
          ],
        ),
        const SizedBox(height: VitalsSpacing.sm),
        Text(
          context.s.aggregationHint(_aggregation),
          style: theme.typography.caption.copyWith(color: theme.colors.inkMuted),
        ),
      ],
    );
  }

  Widget _displayPicker(VitalsThemeData theme) => Wrap(
        spacing: VitalsSpacing.sm,
        runSpacing: VitalsSpacing.sm,
        children: [
          for (final style in DisplayStyle.allowedFor(_kind))
            ChoiceChip(
              label: Text(context.s.displayName(style)),
              selected: _displayStyle == style,
              onSelected: (_) => setState(() => _displayStyle = style),
            ),
        ],
      );

  /// The fixed palette first, a free colour behind one more tap.
  ///
  /// Not a free picker by default: two markers in near-identical colours ruin
  /// the one screen colours exist for, which is a stack of rows read together.
  Widget _colorPicker(VitalsThemeData theme) => Wrap(
        spacing: VitalsSpacing.sm,
        runSpacing: VitalsSpacing.sm,
        children: [
          for (final hex in markerPalette)
            _Swatch(
              hex: hex,
              selected: _colorHex == hex,
              onTap: () => setState(() => _colorHex = hex),
            ),
          IconButton(
            tooltip: context.s.otherColour,
            icon: const Icon(Icons.colorize),
            onPressed: _pickFreeColor,
          ),
        ],
      );

  Future<void> _pickFreeColor() async {
    final field = TextEditingController(text: _colorHex ?? '#');
    final hex = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s.otherColour),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: const InputDecoration(hintText: '#4C7BD9'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(field.text.trim()),
            child: Text(context.s.use),
          ),
        ],
      ),
    );
    field.dispose();
    if (hex == null) return;
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return;
    setState(() => _colorHex = hex.toUpperCase());
  }

  /// Archive, unarchive, delete - in that order, and archive is the one the
  /// screen argues for.
  ///
  /// Finishing a course of a supplement is archiving, not deleting: the reports
  /// still draw those months. Deleting is soft and leaves every reading on
  /// disk, so the worst case of a mistap is a marker to recreate rather than a
  /// year of numbers to re-answer.
  Widget _lifecycle(VitalsThemeData theme) {
    final archived = widget.metric!.isArchived;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: VitalsSpacing.md),
        OutlinedButton(
          onPressed: () async {
            if (archived) {
              await widget.controller.unarchiveMarker(_id);
            } else {
              await widget.controller.archiveMarker(_id);
            }
            if (mounted) Navigator.of(context).pop(true);
          },
          child: Text(archived ? context.s.putBackOnList : context.s.archiveVerb),
        ),
        const SizedBox(height: VitalsSpacing.sm),
        Text(
          context.s.archivedExplained,
          style: theme.typography.caption.copyWith(color: theme.colors.inkFaint),
        ),
        const SizedBox(height: VitalsSpacing.lg),
        TextButton(
          onPressed: _confirmDelete,
          child: Text(
            context.s.deleteMarker,
            style: TextStyle(color: theme.colors.danger),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final count = _facts?.count ?? 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s.deleteMarkerQuestion),
        content: Text(
          count == 0
              ? context.s.deleteMarkerNoEntries
              : context.s.deleteMarkerWithEntries(count),
        ),
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
    await widget.controller.deleteMarker(_id);
    if (mounted) Navigator.of(context).pop(true);
  }
}

/// Every problem at once, above the form.
///
/// Not one at a time: fixing a form error by error is how a person gives up on
/// a form, which is why `validateMetric` returns the whole list.
class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({required this.problems});

  final List<ValidationFailure> problems;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: VitalsSpacing.lg),
      padding: const EdgeInsets.all(VitalsSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.danger.withValues(alpha: 0.10),
        borderRadius: VitalsRadius.nestedAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final problem in problems)
            Padding(
              padding: const EdgeInsets.only(bottom: VitalsSpacing.xs),
              child: Text(problem.message, style: theme.typography.caption),
            ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.label, required this.theme});

  final String label;
  final VitalsThemeData theme;

  @override
  Widget build(BuildContext context) => Padding(
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

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    return Row(
      children: [
        Text(label, style: theme.typography.caption),
        const Spacer(),
        IconButton(
          tooltip: context.s.less(label),
          icon: const Icon(Icons.remove),
          onPressed: () => onChanged(value - 1),
        ),
        Text('$value', style: theme.typography.title),
        IconButton(
          tooltip: context.s.more(label),
          icon: const Icon(Icons.add),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _OptionRow extends StatefulWidget {
  const _OptionRow({
    required this.option,
    required this.hasHistory,
    required this.onLabel,
    required this.onToggleArchived,
    required this.onRemove,
    super.key,
  });

  final MetricOption option;

  /// Whether anything ever picked it. Decides between archive and delete.
  final bool hasHistory;
  final ValueChanged<String> onLabel;
  final VoidCallback onToggleArchived;
  final VoidCallback onRemove;

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  late final TextEditingController _label =
      TextEditingController(text: widget.option.label);

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final archived = widget.option.archived;

    return Padding(
      padding: const EdgeInsets.only(bottom: VitalsSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _label,
              onChanged: widget.onLabel,
              style: theme.typography.body.copyWith(
                decoration: archived ? TextDecoration.lineThrough : null,
                color: archived ? theme.colors.inkFaint : null,
              ),
              decoration: InputDecoration(hintText: context.s.option),
            ),
          ),
          if (widget.hasHistory)
            IconButton(
              tooltip: archived ? context.s.restoreOption : context.s.archiveOption,
              icon: Icon(archived ? Icons.unarchive : Icons.archive_outlined),
              onPressed: widget.onToggleArchived,
            )
          else
            IconButton(
              tooltip: context.s.removeOption,
              icon: const Icon(Icons.close),
              onPressed: widget.onRemove,
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final value = int.parse(hex.substring(1), radix: 16);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Semantics(
        label: hex,
        selected: selected,
        child: Container(
          width: VitalsSpacing.minTapTarget,
          height: VitalsSpacing.minTapTarget,
          padding: const EdgeInsets.all(VitalsSpacing.xs),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF000000 | value),
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: theme.colors.ink, width: 3)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
