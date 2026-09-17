import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import 'chart_semantics.dart';
import '../l10n/app_language.dart';

/// One marker's row, drawn.
///
/// **No painter in this file ever fills a gap.** An unlogged day is an empty
/// outline, a skipped bar, a missing dot, a break in a line - never a value
/// borrowed from either neighbour. That single rule is what decides which
/// shapes exist here: bars, squares and dots cannot invent a day, and a line is
/// allowed only because [_BrokenLinePainter] refuses to join across one.
///
/// **A row draws one marker.** There is no second series and no second y axis,
/// which is why nothing here takes two value lists. The one overlay is
/// [ReportRow.bandOn], a boolean drawn behind as a pale band - safe precisely
/// because a band has no scale of its own to stretch until it agrees.
class ReportRowChart extends StatelessWidget {
  const ReportRowChart({
    required this.row,
    required this.color,
    this.onDayTap,
    super.key,
  });

  final ReportRow row;
  final Color color;

  /// The day key under a tap. Null where a position is not one day - on the
  /// cycle-day axis a column is many dates.
  final ValueChanged<String>? onDayTap;

  /// Tall enough to read, short enough that six markers fit on a phone.
  static const double rowHeight = 44;
  static const double stripHeight = 14;
  static const double tagRowHeight = 12;

  double get _height => switch (row.displayStyle) {
        DisplayStyle.presenceStrip ||
        DisplayStyle.backgroundBand =>
          stripHeight,
        DisplayStyle.tagRows =>
          (row.metric.liveOptions.length * (tagRowHeight + 2)).toDouble(),
        _ => rowHeight,
      };

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final style = row.displayStyle;
    if (style == null) {
      return const SizedBox.shrink();
    }

    final (low, high) = _bounds();

    final onDayTap = this.onDayTap;
    final chart = SizedBox(
      height: _height,
      child: CustomPaint(
        size: Size.infinite,
        foregroundPainter: CellSemanticsPainter(
          metric: row.metric,
          strings: context.s,
          cells: row.cells,
          rectFor: (index, size) {
            final width = size.width / row.cells.length;
            return Rect.fromLTWH(index * width, 0, width, size.height);
          },
        ),
        painter: switch (style) {
          DisplayStyle.squares => _SquaresPainter(
              row: row,
              color: color,
              low: low,
              high: high,
              empty: theme.colors.stroke,
              band: color.withValues(alpha: 0.14),
            ),
          DisplayStyle.bars => _BarsPainter(
              row: row,
              color: color,
              high: high,
              baseline: theme.colors.stroke,
              band: color.withValues(alpha: 0.14),
            ),
          DisplayStyle.dots => _DotsPainter(
              row: row,
              color: color,
              low: low,
              high: high,
              band: color.withValues(alpha: 0.14),
            ),
          DisplayStyle.brokenLine => _BrokenLinePainter(
              row: row,
              color: color,
              low: low,
              high: high,
              band: color.withValues(alpha: 0.14),
            ),
          DisplayStyle.presenceStrip ||
          DisplayStyle.backgroundBand =>
            _StripPainter(row: row, color: color, empty: theme.colors.stroke),
          DisplayStyle.tagRows => _TagRowsPainter(
              row: row,
              color: color,
              empty: theme.colors.stroke,
            ),
        },
      ),
    );
    if (onDayTap == null || row.cells.isEmpty) return chart;

    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final width = constraints.maxWidth / row.cells.length;
          final index = (details.localPosition.dx / width)
              .floor()
              .clamp(0, row.cells.length - 1);
          onDayTap(row.cells[index].dayKey);
        },
        child: chart,
      ),
    );
  }

  /// The y range this row is drawn against.
  ///
  /// A rating uses **its own declared bounds**, not the range that happened to
  /// be recorded: a month where nothing went below 4 must not redraw 4 as the
  /// floor, because then every month looks equally bad. Everything else uses
  /// what is there, from zero, since a dose has no declared ceiling.
  (num, num) _bounds() {
    if (row.metric.kind == MetricKind.scale) {
      return (row.metric.scaleMin, row.metric.scaleMax);
    }
    if (row.metric.kind == MetricKind.percent) return (0, 100);
    if (row.metric.kind == MetricKind.timeOfDay) return (0, 1439);
    final high = row.stats.highest ?? 1;
    return (0, high == 0 ? 1 : high);
  }
}

/// Geometry shared by every painter: one column per cell, left to right.
class _Columns {
  _Columns(this.size, this.count)
      : width = count == 0 ? 0 : size.width / count;

  final Size size;
  final int count;
  final double width;

  double centreOf(int index) => (index + 0.5) * width;

  /// A visible column even when a year is on screen, with a hairline gap.
  double get cellWidth => (width - 1).clamp(1.0, 24.0);
}

void _paintBand(Canvas canvas, Size size, _Columns cols, List<bool> on,
    Color band) {
  if (on.isEmpty) return;
  final paint = Paint()..color = band;
  for (var i = 0; i < on.length && i < cols.count; i++) {
    if (!on[i]) continue;
    canvas.drawRect(
      Rect.fromLTWH(i * cols.width, 0, cols.width, size.height),
      paint,
    );
  }
}

double _fraction(num value, num low, num high) {
  if (high <= low) return 0;
  return ((value - low) / (high - low)).clamp(0.0, 1.0).toDouble();
}

class _SquaresPainter extends CustomPainter {
  _SquaresPainter({
    required this.row,
    required this.color,
    required this.low,
    required this.high,
    required this.empty,
    required this.band,
  });

  final ReportRow row;
  final Color color;
  final num low;
  final num high;
  final Color empty;
  final Color band;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = _Columns(size, row.cells.length);
    _paintBand(canvas, size, cols, row.bandOn, band);

    final side = cols.cellWidth.clamp(2.0, size.height);
    final top = (size.height - side) / 2;

    for (var i = 0; i < row.cells.length; i++) {
      final cell = row.cells[i];
      final rect = Rect.fromLTWH(i * cols.width, top, side, side);
      final value = cell.value;
      if (value == null) {
        // An empty outline, never a pale fill: a light square reads as a low
        // value, and an unlogged day is not a low day.
        canvas.drawRect(
          rect.deflate(0.5),
          Paint()
            ..color = empty
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        continue;
      }
      final intensity = 0.25 + 0.75 * _fraction(value, low, high);
      canvas.drawRect(
        rect,
        Paint()..color = color.withValues(alpha: intensity),
      );
    }
  }

  @override
  bool shouldRepaint(_SquaresPainter old) =>
      old.row != row || old.color != color;
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.row,
    required this.color,
    required this.high,
    required this.baseline,
    required this.band,
  });

  final ReportRow row;
  final Color color;
  final num high;
  final Color baseline;
  final Color band;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = _Columns(size, row.cells.length);
    _paintBand(canvas, size, cols, row.bandOn, band);

    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()
        ..color = baseline
        ..strokeWidth = 1,
    );

    final paint = Paint()..color = color;
    for (var i = 0; i < row.cells.length; i++) {
      final value = row.cells[i].value;
      // A day with no dose is no bar at all. A zero-height bar and an unlogged
      // day would look identical, and they are not the same fact.
      if (value == null) continue;
      final barHeight = _fraction(value, 0, high) * (size.height - 1);
      canvas.drawRect(
        Rect.fromLTWH(
          i * cols.width,
          size.height - 1 - barHeight,
          cols.cellWidth,
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.row != row || old.color != color;
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({
    required this.row,
    required this.color,
    required this.low,
    required this.high,
    required this.band,
  });

  final ReportRow row;
  final Color color;
  final num low;
  final num high;
  final Color band;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = _Columns(size, row.cells.length);
    _paintBand(canvas, size, cols, row.bandOn, band);

    final radius = (cols.width / 3).clamp(1.5, 4.0);
    final paint = Paint()..color = color;
    for (var i = 0; i < row.cells.length; i++) {
      final value = row.cells[i].value;
      if (value == null) continue;
      final y = size.height - _fraction(value, low, high) * size.height;
      canvas.drawCircle(Offset(cols.centreOf(i), y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.row != row || old.color != color;
}

/// A line that **breaks at every unlogged day**.
///
/// The old plan banned lines outright. The real target of that ban was
/// interpolation - a line drawn straight through days you never logged invents
/// them - so the segment is only ever drawn between two *consecutive* logged
/// days. A gap stays a gap, and the shape is allowed while the lie is not.
class _BrokenLinePainter extends CustomPainter {
  _BrokenLinePainter({
    required this.row,
    required this.color,
    required this.low,
    required this.high,
    required this.band,
  });

  final ReportRow row;
  final Color color;
  final num low;
  final num high;
  final Color band;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = _Columns(size, row.cells.length);
    _paintBand(canvas, size, cols, row.bandOn, band);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset? previous;
    for (var i = 0; i < row.cells.length; i++) {
      final value = row.cells[i].value;
      if (value == null) {
        previous = null;
        continue;
      }
      final point = Offset(
        cols.centreOf(i),
        size.height - _fraction(value, low, high) * size.height,
      );
      if (previous != null) {
        canvas.drawLine(previous, point, paint);
      } else {
        // A logged day between two unlogged ones is a dot rather than nothing:
        // it happened, and a line has nowhere to go from it.
        canvas.drawCircle(point, 2, Paint()..color = color);
      }
      previous = point;
    }
  }

  @override
  bool shouldRepaint(_BrokenLinePainter old) =>
      old.row != row || old.color != color;
}

class _StripPainter extends CustomPainter {
  _StripPainter({
    required this.row,
    required this.color,
    required this.empty,
  });

  final ReportRow row;
  final Color color;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = _Columns(size, row.cells.length);
    for (var i = 0; i < row.cells.length; i++) {
      final cell = row.cells[i];
      final on = (cell.value ?? 0) > 0;
      // Three states, not two: on, recorded-as-off, and never answered. An
      // unlogged day drawn as "off" is the app answering for you.
      if (!cell.isLogged) continue;
      canvas.drawRect(
        Rect.fromLTWH(i * cols.width, 0, cols.cellWidth, size.height),
        Paint()..color = on ? color : empty,
      );
    }
  }

  @override
  bool shouldRepaint(_StripPainter old) => old.row != row || old.color != color;
}

/// One row per option, marked where that option was picked.
///
/// How named feelings are read: eight sparse rows where the dark cells line up
/// or they do not. Sparse is the honest shape - most days most of them are
/// absent - and an empty row is a fact rather than a failure to fill it in.
class _TagRowsPainter extends CustomPainter {
  _TagRowsPainter({
    required this.row,
    required this.color,
    required this.empty,
  });

  final ReportRow row;
  final Color color;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final options = row.metric.liveOptions;
    if (options.isEmpty) return;
    final cols = _Columns(size, row.cells.length);
    final lineHeight = size.height / options.length;

    for (var o = 0; o < options.length; o++) {
      final top = o * lineHeight;
      for (var i = 0; i < row.cells.length; i++) {
        final cell = row.cells[i];
        if (!cell.optionIds.contains(options[o].id)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            i * cols.width,
            top + 1,
            cols.cellWidth,
            lineHeight - 2,
          ),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TagRowsPainter old) =>
      old.row != row || old.color != color;
}
