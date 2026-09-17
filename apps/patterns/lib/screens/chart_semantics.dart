import 'package:flutter/rendering.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';

import '../l10n/app_strings.dart';

/// Paints nothing and describes every cell to a screen reader.
///
/// **A colour-only chart is unreadable without sight or colour vision**, so
/// each square becomes its own node with its date and its value, in order,
/// and TalkBack can walk the days one at a time. Laid over the drawn chart as
/// a foreground painter, so no painter has to know about accessibility.
class CellSemanticsPainter extends CustomPainter {
  CellSemanticsPainter({
    required this.metric,
    required this.strings,
    required this.cells,
    required this.rectFor,
  });

  final Metric metric;

  final AppStrings strings;

  /// Null entries are layout padding, not days, and get no node.
  final List<DaySummary?> cells;

  /// Where cell `index` sits, given the painted size.
  final Rect Function(int index, Size size) rectFor;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) => [
        for (var i = 0; i < cells.length; i++)
          if (cells[i] case final cell?)
            CustomPainterSemantics(
              rect: rectFor(i, size),
              properties: SemanticsProperties(
                label: '${_when(cell.dayKey)}: ${describeCell(metric, cell, strings)}',
                textDirection: TextDirection.ltr,
              ),
            ),
      ];

  /// A cell on the cycle-day axis is keyed by its cycle day, not a date.
  String _when(String key) => parseDayKey(key) == null
      ? strings.cycleDay(int.tryParse(key) ?? 0)
      : strings.humanDate(key, withYear: true);

  @override
  bool shouldRepaint(CellSemanticsPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(CellSemanticsPainter oldDelegate) =>
      oldDelegate.cells != cells ||
      oldDelegate.metric != metric ||
      oldDelegate.strings.language != strings.language;
}

/// One day of one marker in words. An unlogged day says so, and is never
/// read out as zero.
String describeCell(Metric metric, DaySummary cell, AppStrings s) {
  if (!cell.isLogged) return s.notLogged;
  if (cell.explicitNone) return s.noneOfThese;
  if (cell.optionIds.isNotEmpty) {
    final labels = {for (final o in metric.options) o.id: o.label};
    return cell.optionIds.map((id) => labels[id] ?? id).join(', ');
  }
  final value = cell.value;
  if (value == null) return s.logged;
  return switch (metric.kind) {
    MetricKind.boolean => value > 0 ? s.yes : s.no,
    MetricKind.timeOfDay =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:'
          '${(value.round() % 60).toString().padLeft(2, '0')}',
    _ => '${value == value.roundToDouble() ? value.round() : value.toStringAsFixed(1)}'
        '${metric.unit == null ? '' : ' ${metric.unit}'}',
  };
}
