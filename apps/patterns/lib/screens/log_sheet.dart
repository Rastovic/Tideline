import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/photo_picker.dart';
import '../l10n/app_language.dart';

/// The entry sheet for one marker.
///
/// **One marker per sheet, two taps to finish.** There is no runner that walks
/// you through eight questions, because the app never decides what today needs:
/// the home list is the menu, and anything can be answered or left alone.
///
/// Returns the value to record, or null when it was dismissed.
/// [onCapture] is supplied for photo markers. The sheet closes as soon as it is
/// called: capture is its own flow, and a sheet waiting behind a camera is a
/// sheet the user comes back to and cannot remember the purpose of.
Future<MetricValue?> showLogSheet(
  BuildContext context, {
  required Metric metric,
  MetricValue? initial,
  Future<void> Function(PhotoSource source)? onCapture,
}) =>
    showModalBottomSheet<MetricValue>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogSheet(
        metric: metric,
        initial: initial,
        onCapture: onCapture,
      ),
    );

class _LogSheet extends StatefulWidget {
  const _LogSheet({required this.metric, this.initial, this.onCapture});

  final Metric metric;
  final MetricValue? initial;
  final Future<void> Function(PhotoSource source)? onCapture;

  @override
  State<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<_LogSheet> {
  late num _number = _initialNumber();
  late final Set<String> _picked = _initialTags();
  late final TextEditingController _text =
      TextEditingController(text: _initialText());

  /// The amount as typed. Starts from the reading being edited, so an edit
  /// shows the number it is changing instead of a blank field.
  late final TextEditingController _amountText = TextEditingController(
    text: switch (widget.initial) {
      NumberValue(:final number) => _plain(number),
      _ => '',
    },
  );
  late TimeOfDay _time = _initialTime();
  late bool _private = switch (widget.initial) {
    TextValue(:final isPrivate) => isPrivate,
    _ => false,
  };

  Metric get metric => widget.metric;

  num _initialNumber() {
    final value = widget.initial;
    if (value is NumberValue) return value.number;
    return switch (metric.kind) {
      // Starting in the middle of the scale rather than at the bottom: a
      // slider parked on 1 quietly suggests that 1 is the answer, and the
      // first drag then reads as an improvement on nothing.
      MetricKind.scale => ((metric.scaleMin + metric.scaleMax) / 2).round(),
      MetricKind.percent => 50,
      _ => 0,
    };
  }

  Set<String> _initialTags() {
    final value = widget.initial;
    if (value is TagsValue) return value.optionIds.toSet();
    if (value is ChoiceValue) return {value.optionId};
    return {};
  }

  String _initialText() {
    final value = widget.initial;
    return value is TextValue ? value.text : '';
  }

  TimeOfDay _initialTime() {
    final value = widget.initial;
    if (value is TimeOfDayValue) {
      return TimeOfDay(hour: value.hour, minute: value.minute);
    }
    return TimeOfDay.now();
  }

  static String _plain(num value) => value == value.roundToDouble()
      ? '${value.round()}'
      : '$value';

  /// Null for anything that is not a number, or is below zero.
  ///
  /// **An empty or unreadable field is not zero.** Saving it as 0 g would put
  /// a reading on the day that nobody made, and a dose of 0 is a real answer
  /// that means something different from "not typed".
  num? get _typedAmount {
    final parsed = num.tryParse(_amountText.text.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0 || !parsed.isFinite) return null;
    return parsed;
  }

  @override
  void dispose() {
    _amountText.dispose();
    _text.dispose();
    super.dispose();
  }

  void _submit(MetricValue value) => Navigator.of(context).pop(value);

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: VitalsRadius.sheet,
        ),
        padding: const EdgeInsets.fromLTRB(
          VitalsSpacing.screenH,
          VitalsSpacing.lg,
          VitalsSpacing.screenH,
          VitalsSpacing.xxl,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.stroke,
                    borderRadius: VitalsRadius.pillAll,
                  ),
                ),
              ),
              const SizedBox(height: VitalsSpacing.lg),
              Text(metric.name, style: theme.typography.title),
              const SizedBox(height: VitalsSpacing.lg),
              ..._body(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, VitalsThemeData theme) =>
      switch (metric.kind) {
        MetricKind.scale => _scale(theme),
        MetricKind.percent => _scale(theme),
        MetricKind.boolean => _boolean(theme),
        MetricKind.tags => _tags(theme, multiple: true),
        MetricKind.choice => _tags(theme, multiple: false),
        MetricKind.text => _freeText(theme),
        MetricKind.timeOfDay => _clock(context, theme),
        MetricKind.count ||
        MetricKind.duration ||
        MetricKind.amount =>
          _amount(theme),
        MetricKind.photo => _photo(theme),
      };

  List<Widget> _photo(VitalsThemeData theme) {
    final capture = widget.onCapture;
    if (capture == null) {
      return [
        Text(
          context.s.captureUnavailable,
          style: theme.typography.body.copyWith(color: theme.colors.inkMuted),
        ),
      ];
    }
    return [
      _primary(context.s.takePhoto, () {
        Navigator.of(context).pop();
        capture(PhotoSource.camera);
      }),
      const SizedBox(height: VitalsSpacing.md),
      _secondary(context.s.fromGallery, () {
        Navigator.of(context).pop();
        capture(PhotoSource.gallery);
      }),
      const SizedBox(height: VitalsSpacing.lg),
      Text(
        context.s.photosStayInApp,
        style: theme.typography.caption.copyWith(color: theme.colors.inkFaint),
      ),
    ];
  }

  List<Widget> _scale(VitalsThemeData theme) {
    final min = metric.kind == MetricKind.percent ? 0 : metric.scaleMin;
    final max = metric.kind == MetricKind.percent ? 100 : metric.scaleMax;
    final divisions = metric.kind == MetricKind.percent ? 20 : max - min;
    return [
      Center(
        child: Text('${_number.round()}', style: theme.typography.displayL),
      ),
      Slider(
        value: _number.toDouble().clamp(min.toDouble(), max.toDouble()),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: divisions,
        onChanged: (value) => setState(() => _number = value.round()),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            metric.lowLabel ?? '$min',
            style: theme.typography.caption.copyWith(color: theme.colors.inkMuted),
          ),
          Text(
            metric.highLabel ?? '$max',
            style: theme.typography.caption.copyWith(color: theme.colors.inkMuted),
          ),
        ],
      ),
      const SizedBox(height: VitalsSpacing.xl),
      _primary(context.s.log, () {
        _submit(NumberValue(_number.round(), kind: metric.kind));
      }),
    ];
  }

  List<Widget> _amount(VitalsThemeData theme) {
    final unit = metric.unit ?? '';
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: TextField(
              controller: _amountText,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: theme.typography.displayL,
              decoration: const InputDecoration(hintText: '0'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: VitalsSpacing.md),
            Text(unit, style: theme.typography.title),
          ],
        ],
      ),
      const SizedBox(height: VitalsSpacing.xl),
      _primary(
        context.s.log,
        switch (_typedAmount) {
          final amount? => () =>
              _submit(NumberValue(amount, kind: metric.kind)),
          null => null,
        },
      ),
    ];
  }

  List<Widget> _boolean(VitalsThemeData theme) => [
        Row(
          children: [
            Expanded(
              child: _secondary(context.s.didNotHappen, () {
                _submit(const BooleanValue(false));
              }),
            ),
            const SizedBox(width: VitalsSpacing.md),
            Expanded(
              child: _primary(context.s.happened, () {
                _submit(const BooleanValue(true));
              }),
            ),
          ],
        ),
      ];

  List<Widget> _tags(VitalsThemeData theme, {required bool multiple}) {
    final options = metric.liveOptions;
    return [
      Wrap(
        spacing: VitalsSpacing.sm,
        runSpacing: VitalsSpacing.sm,
        children: [
          for (final option in options)
            FilterChip(
              label: Text(option.label),
              selected: _picked.contains(option.id),
              onSelected: (on) => setState(() {
                if (!multiple) _picked.clear();
                if (on) {
                  _picked.add(option.id);
                } else {
                  _picked.remove(option.id);
                }
              }),
            ),
        ],
      ),
      const SizedBox(height: VitalsSpacing.xl),
      if (multiple) ...[
        // "None of these" is a recorded answer, not an empty form. Without it
        // there is no difference between a day with no sadness and a day never
        // filled in, and every later number is computed over the second kind.
        _secondary(context.s.noneOfTheseButton, () => _submit(TagsValue(const []))),
        const SizedBox(height: VitalsSpacing.md),
      ],
      // Nothing picked is not an answer here. "None of these" has its own
      // button, and letting an empty tap record it would put that answer on
      // days nobody gave it.
      _primary(
        context.s.log,
        _picked.isEmpty
            ? null
            : () => _submit(
                  multiple
                      ? TagsValue(_picked)
                      : ChoiceValue(_picked.first),
                ),
      ),
    ];
  }

  List<Widget> _freeText(VitalsThemeData theme) => [
        TextField(
          controller: _text,
          autofocus: true,
          maxLines: 8,
          minLines: 4,
          style: theme.typography.body,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: context.s.diaryHint,
          ),
        ),
        // Off unless turned on for this entry. Private keeps it out of search
        // and off the doctor page, and never out of the backup.
        // Its own Material: the sheet paints its background on a plain
        // container, which would hide the tile's ink.
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _private,
            onChanged: (on) => setState(() => _private = on),
            title: Text(context.s.private, style: theme.typography.body),
            subtitle: Text(
              context.s.privateExplained,
              style: theme.typography.caption,
            ),
          ),
        ),
        const SizedBox(height: VitalsSpacing.lg),
        _primary(
          context.s.save,
          _text.text.trim().isEmpty
              ? null
              : () => _submit(TextValue(_text.text.trim(), isPrivate: _private)),
        ),
      ];

  List<Widget> _clock(BuildContext context, VitalsThemeData theme) => [
        Center(
          child: TextButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (picked != null) setState(() => _time = picked);
            },
            child: Text(
              '${_time.hour.toString().padLeft(2, '0')}:'
              '${_time.minute.toString().padLeft(2, '0')}',
              style: theme.typography.displayL,
            ),
          ),
        ),
        const SizedBox(height: VitalsSpacing.xl),
        _primary(context.s.log, () {
          _submit(TimeOfDayValue(_time.hour * 60 + _time.minute));
        }),
      ];

  Widget _primary(String label, VoidCallback? onPressed) => SizedBox(
        height: VitalsSpacing.buttonHeight,
        child: FilledButton(onPressed: onPressed, child: Text(label)),
      );

  Widget _secondary(String label, VoidCallback onPressed) => SizedBox(
        height: VitalsSpacing.buttonHeight,
        child: OutlinedButton(onPressed: onPressed, child: Text(label)),
      );
}
