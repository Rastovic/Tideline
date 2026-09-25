import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../l10n/app_language.dart';
import 'comparison_chart.dart';
import 'metric_labels.dart';

/// Both markers over time: two lines, one above the other, on one date axis.
///
/// **Two frames, never two y axes in one.** Creatine in grams and bloating on
/// a 1-10 rating only share a frame once one is scaled against the other, and
/// the scale then decides whether they appear to move together. Stacked, each
/// keeps its own honest scale and the days still line up column for column.
///
/// A day nobody logged is a gap: the line crosses it only as a faint dashed
/// stroke, and there is no dot, so a guess is never drawn as a reading. A
/// yes/no or tags condition has nothing to draw a line through, so its frame
/// is a row of marks instead - filled on the days it happened.
class ComparisonTimeline extends StatelessWidget {
  const ComparisonTimeline({required this.comparison, super.key});

  final Comparison comparison;

  static const lineHeight = 110.0;
  static const markHeight = 28.0;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final days = comparison.timeline;
    if (days.length < 2) return const SizedBox.shrink();

    final conditionColor =
        markerColor(comparison.condition.colorHex) ?? theme.colors.inkMuted;
    final outcomeColor =
        markerColor(comparison.outcome.colorHex) ?? theme.colors.accent;
    final numeric = days.any((d) => d.condition != null);
    final caption = theme.typography.caption.copyWith(
      color: theme.colors.inkFaint,
    );
    final label = theme.typography.caption.copyWith(
      color: theme.colors.inkMuted,
    );

    Widget frame(String name, Widget chart) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(name, style: caption),
        const SizedBox(height: VitalsSpacing.xs),
        chart,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        frame(
          comparison.condition.name,
          SizedBox(
            height: numeric ? lineHeight : markHeight,
            child: CustomPaint(
              size: Size.infinite,
              painter: numeric
                  ? _LinePainter(
                      values: [for (final d in days) d.condition],
                      bounds: ComparisonChart.bounds(comparison.condition, [
                        for (final d in days)
                          if (d.condition case final v?) v,
                      ]),
                      color: conditionColor,
                      axis: theme.colors.stroke,
                      label: label,
                    )
                  : _MarkPainter(
                      marks: [for (final d in days) d.conditionOn],
                      color: conditionColor,
                      axis: theme.colors.stroke,
                    ),
            ),
          ),
        ),
        const SizedBox(height: VitalsSpacing.md),
        frame(
          comparison.outcome.name,
          SizedBox(
            height: lineHeight,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LinePainter(
                values: [for (final d in days) d.outcome],
                bounds: ComparisonChart.bounds(comparison.outcome, [
                  for (final d in days)
                    if (d.outcome case final v?) v,
                ]),
                color: outcomeColor,
                axis: theme.colors.stroke,
                label: label,
              ),
            ),
          ),
        ),
        const SizedBox(height: VitalsSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(left: _plotLeft),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_date(context, days.first.dayKey), style: label),
              Text(_date(context, days.last.dayKey), style: label),
            ],
          ),
        ),
      ],
    );
  }

  static String _date(BuildContext context, String dayKey) {
    final date = parseDayKey(dayKey);
    if (date == null) return dayKey;
    return context.s.shortDate(date.day, date.month);
  }
}

/// Where the plot starts in both frames, so the days line up column for
/// column whichever frame has the wider numbers.
const _plotLeft = 34.0;

double _x(Rect plot, int index, int count) =>
    plot.left + 4 + (plot.width - 8) * (count == 1 ? 0.5 : index / (count - 1));

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.bounds,
    required this.color,
    required this.axis,
    required this.label,
  });

  final List<num?> values;
  final (num, num) bounds;
  final Color color;
  final Color axis;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_plotLeft, 4, size.width, size.height - 4);
    final frame = Paint()
      ..color = axis
      ..strokeWidth = 1;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, frame);
    canvas.drawLine(plot.topLeft, plot.bottomLeft, frame);

    final (low, high) = bounds;
    double y(num value) {
      final span = high - low;
      final t = span == 0 ? 0.5 : (value - low) / span;
      return plot.bottom - t.clamp(0.0, 1.0) * plot.height;
    }

    _text(canvas, _number(high), Offset(0, plot.top - 2));
    _text(canvas, _number(low), Offset(0, plot.bottom - 12));

    final solid = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final bridge = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final dot = Paint()..color = color;

    Offset? previous;
    var previousIndex = -1;
    final count = values.length;
    for (var i = 0; i < count; i++) {
      final value = values[i];
      if (value == null) continue;
      final point = Offset(_x(plot, i, count), y(value));
      if (previous != null) {
        if (i - previousIndex == 1) {
          canvas.drawLine(previous, point, solid);
        } else {
          _dashed(canvas, previous, point, bridge);
        }
      }
      // Dots only on thin windows; at ninety days they would merge into a
      // second, thicker line.
      if (count <= 45) canvas.drawCircle(point, 2.5, dot);
      previous = point;
      previousIndex = i;
    }
  }

  static void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final length = (b - a).distance;
    if (length == 0) return;
    const dash = 3.0;
    const gap = 3.0;
    final direction = (b - a) / length;
    for (var d = 0.0; d < length; d += dash + gap) {
      final end = (d + dash).clamp(0.0, length);
      canvas.drawLine(a + direction * d, a + direction * end, paint);
    }
  }

  void _text(Canvas canvas, String value, Offset at) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: label),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: _plotLeft - 4);
    painter.paint(canvas, at);
  }

  static String _number(num value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(1);

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.color != color;
}

/// A yes/no or tags condition, one mark per day: filled when it happened,
/// outlined when it was answered no, nothing when it was not logged.
class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.marks, required this.color, required this.axis});

  final List<bool?> marks;
  final Color color;
  final Color axis;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_plotLeft, 0, size.width, size.height);
    final count = marks.length;
    final width = ((plot.width - 8) / count).clamp(2.0, 10.0) * 0.8;
    final filled = Paint()..color = color;
    final outlined = Paint()
      ..color = axis
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < count; i++) {
      final mark = marks[i];
      if (mark == null) continue;
      final rect = Rect.fromCenter(
        center: Offset(_x(plot, i, count), plot.center.dy),
        width: width,
        height: plot.height * 0.7,
      );
      final shape = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      canvas.drawRRect(shape, mark ? filled : outlined);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.marks != marks || old.color != color;
}
