import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

/// One marker laid out seven wide, one square per day.
///
/// **A different question from the linear row, not a prettier version of it.**
/// A strip answers "how did this move"; a grid answers "does this repeat
/// weekly", and it can only answer that because every Monday sits in the same
/// column. In a scrolling row the day of the week is smeared across the whole
/// strip and the pattern people most want to find is invisible.
///
/// The same rule as everywhere else: **an unlogged day is an empty outline**,
/// never a pale fill and never borrowed from a neighbour. A light square reads
/// as a low value, and a day nobody answered is not a low day.
class DayGridChart extends StatelessWidget {
  const DayGridChart({
    required this.row,
    required this.dayKeys,
    required this.color,
    super.key,
  });

  final ReportRow row;

  /// The dates behind the cells, in the same order. The grid needs the real
  /// dates because the whole point is which weekday each one fell on.
  final List<String> dayKeys;

  final Color color;

  /// Short and unambiguous: two of the seven start with the same letter in this
  /// language, so a single initial cannot carry the header.
  static const weekdayLabels = ['pon', 'uto', 'sri', 'cet', 'pet', 'sub', 'ned'];

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final cells = _cells();
    if (cells.isEmpty) return const SizedBox.shrink();

    final weeks = (cells.length / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth / 7;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final label in weekdayLabels)
                  SizedBox(
                    width: side,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.typography.caption
                          .copyWith(color: theme.colors.inkFaint),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: VitalsSpacing.xs),
            SizedBox(
              height: weeks * side,
              child: CustomPaint(
                size: Size.infinite,
                painter: _GridPainter(
                  cells: cells,
                  metric: row.metric,
                  stats: row.stats,
                  color: color,
                  empty: theme.colors.stroke,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The cells padded to whole weeks, Monday first.
  ///
  /// A leading blank for every weekday before the first logged date, so the
  /// columns mean something. Padding with real days instead - stretching the
  /// period out to the nearest Monday - would silently draw days nobody asked
  /// about, which is the same lie as interpolating one.
  List<DaySummary?> _cells() {
    if (dayKeys.isEmpty || row.cells.isEmpty) return const [];
    final first = parseDayKey(dayKeys.first);
    if (first == null) return const [];

    final leading = first.weekday - DateTime.monday;
    final cells = <DaySummary?>[
      for (var i = 0; i < leading; i++) null,
      ...row.cells,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.cells,
    required this.metric,
    required this.stats,
    required this.color,
    required this.empty,
  });

  final List<DaySummary?> cells;
  final Metric metric;
  final PeriodStats stats;
  final Color color;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width / 7;
    final inset = (side * 0.12).clamp(0.5, 3.0);
    final (low, high) = _bounds();

    for (var i = 0; i < cells.length; i++) {
      final cell = cells[i];
      // A padding slot is not a day. Nothing is drawn there at all, not even
      // an empty outline, or the month would appear to start on a Monday.
      if (cell == null) continue;

      final rect = Rect.fromLTWH(
        (i % 7) * side,
        (i ~/ 7) * side,
        side,
        side,
      ).deflate(inset);

      final value = cell.value;
      if (value == null) {
        if (!cell.isLogged) {
          canvas.drawRect(
            rect.deflate(0.5),
            Paint()
              ..color = empty
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
          continue;
        }
        // Logged, but this kind carries no number - tags, a diary, a photo.
        // Full colour: it happened, and there is no intensity to shade it by.
        canvas.drawRect(rect, Paint()..color = color);
        continue;
      }

      final fraction = high <= low
          ? 1.0
          : ((value - low) / (high - low)).clamp(0.0, 1.0).toDouble();
      canvas.drawRect(
        rect,
        Paint()..color = color.withValues(alpha: 0.25 + 0.75 * fraction),
      );
    }
  }

  /// A rating shades against its **declared** bounds, so a good month and a bad
  /// month are comparable at a glance. Anything else has no ceiling to declare,
  /// so it shades against what was actually recorded.
  (num, num) _bounds() {
    if (metric.kind == MetricKind.scale) {
      return (metric.scaleMin, metric.scaleMax);
    }
    if (metric.kind == MetricKind.percent) return (0, 100);
    final high = stats.highest ?? 1;
    return (0, high == 0 ? 1 : high);
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.cells != cells || old.color != color;
}
