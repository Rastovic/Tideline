import 'dart:math';

import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

/// The dependency chart: one dot per day, the condition across, the outcome up.
///
/// **Two y axes stay banned**, which is exactly why this shape exists. Drawing
/// creatine and bloating as two lines in one frame means scaling one against
/// the other until they appear to agree; putting one on each axis and a dot on
/// every day shows whatever relationship is really there, including none.
///
/// A number condition gives a scatter. A yes/no or tags condition gives one
/// column of dots per group, because there is nothing to measure along the
/// bottom. Each group carries a line at its median - the same number the card
/// below prints, drawn where the dots are.
///
/// Nothing is fitted: no trend line, no curve, no smoothing. A fitted line is
/// a claim, and this app does not make them.
class ComparisonChart extends StatelessWidget {
  const ComparisonChart({
    required this.comparison,
    required this.color,
    super.key,
  });

  final Comparison comparison;
  final Color color;

  static const height = 170.0;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final points = [
      for (final p in comparison.points)
        if (p.outcome != null) p,
    ];
    if (points.length < 2) return const SizedBox.shrink();

    final scatter = points.first.condition != null;

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ChartPainter(
          points: points,
          buckets: comparison.buckets,
          scatter: scatter,
          outcomeBounds: _bounds(comparison.outcome, points.map((p) => p.outcome!)),
          conditionBounds: scatter
              ? _bounds(
                  comparison.condition,
                  points.map((p) => p.condition ?? 0),
                )
              : null,
          color: color,
          axis: theme.colors.stroke,
          label: theme.typography.caption.copyWith(color: theme.colors.inkMuted),
          median: theme.colors.ink,
        ),
      ),
    );
  }

  /// A rating draws against its declared ends, so a month that never went
  /// below four does not redraw four as the floor. Everything else uses what
  /// is there, padded a little so dots are not on the frame.
  static (num, num) _bounds(Metric metric, Iterable<num> values) {
    if (metric.kind == MetricKind.scale) {
      return (metric.scaleMin, metric.scaleMax);
    }
    if (metric.kind == MetricKind.percent) return (0, 100);
    if (metric.kind == MetricKind.timeOfDay) return (0, 1439);
    final list = values.toList()..sort();
    if (list.isEmpty) return (0, 1);
    final low = list.first;
    final high = list.last;
    if (low == high) return (low - 1, high + 1);
    return (low, high);
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.buckets,
    required this.scatter,
    required this.outcomeBounds,
    required this.conditionBounds,
    required this.color,
    required this.axis,
    required this.label,
    required this.median,
  });

  final List<ComparePoint> points;
  final List<CompareBucket> buckets;
  final bool scatter;
  final (num, num) outcomeBounds;
  final (num, num)? conditionBounds;
  final Color color;
  final Color axis;
  final TextStyle label;
  final Color median;

  static const _left = 34.0;
  static const _bottom = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_left, 4, size.width, size.height - _bottom);
    final frame = Paint()
      ..color = axis
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(plot.bottomLeft, plot.bottomRight, frame);
    canvas.drawLine(plot.topLeft, plot.bottomLeft, frame);

    final (low, high) = outcomeBounds;
    double y(num value) {
      final span = high - low;
      final t = span == 0 ? 0.5 : (value - low) / span;
      return plot.bottom - t.clamp(0.0, 1.0) * plot.height;
    }

    _text(canvas, _number(high), Offset(0, plot.top - 2));
    _text(canvas, _number(low), Offset(0, plot.bottom - 12));

    final dot = Paint()..color = color.withValues(alpha: 0.65);

    if (scatter) {
      final (cLow, cHigh) = conditionBounds!;
      double x(num value) {
        final span = cHigh - cLow;
        final t = span == 0 ? 0.5 : (value - cLow) / span;
        return plot.left + 6 + t.clamp(0.0, 1.0) * (plot.width - 12);
      }

      for (final point in points) {
        canvas.drawCircle(
          Offset(x(point.condition!), y(point.outcome!)),
          3.5,
          dot,
        );
      }
      _text(canvas, _number(cLow), Offset(plot.left, plot.bottom + 3));
      _text(
        canvas,
        _number(cHigh),
        Offset(size.width - 28, plot.bottom + 3),
      );
      return;
    }

    // One column of dots per group, spread a little so a repeated value does
    // not hide behind itself.
    final groups = buckets.map((b) => b.label).toList();
    if (groups.isEmpty) return;
    final step = plot.width / groups.length;
    final random = Random(11);

    for (var i = 0; i < groups.length; i++) {
      final centre = plot.left + step * (i + 0.5);
      final mine = points.where((p) => p.bucket == groups[i]);
      for (final point in mine) {
        final jitter = (random.nextDouble() - 0.5) * min(step * 0.6, 40);
        canvas.drawCircle(
          Offset(centre + jitter, y(point.outcome!)),
          3.5,
          dot,
        );
      }
      if (buckets[i].typical case final typical?) {
        canvas.drawLine(
          Offset(centre - step * 0.32, y(typical)),
          Offset(centre + step * 0.32, y(typical)),
          Paint()
            ..color = median
            ..strokeWidth = 2,
        );
      }
      _text(
        canvas,
        groups[i],
        Offset(centre - step * 0.4, plot.bottom + 3),
        width: step,
      );
    }
  }

  void _text(Canvas canvas, String value, Offset at, {double width = 60}) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: label),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: width);
    painter.paint(canvas, at);
  }

  static String _number(num value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(1);

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.points != points || old.color != color;
}
