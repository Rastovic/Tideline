import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

/// A thin strip under a report row: which days carry a note or a photo.
///
/// **Marks, not content.** A report is numbers over time; the words and the
/// pictures live on the day. A tick here says "there is something written on
/// this day" and the tap takes you to it, which keeps a private sentence off
/// a screen that might be held up to someone else.
class MarkedDaysStrip extends StatelessWidget {
  const MarkedDaysStrip({
    required this.cells,
    required this.notes,
    required this.photos,
    this.onDayTap,
    super.key,
  });

  /// The row's cells, in the same order the chart draws them.
  final List<DaySummary> cells;

  final Set<String> notes;
  final Set<String> photos;
  final ValueChanged<String>? onDayTap;

  static const height = 10.0;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    if (cells.isEmpty || (notes.isEmpty && photos.isEmpty)) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onDayTap == null
            ? null
            : (details) {
                final width = constraints.maxWidth / cells.length;
                final index = (details.localPosition.dx / width)
                    .floor()
                    .clamp(0, cells.length - 1);
                onDayTap!(cells[index].dayKey);
              },
        child: SizedBox(
          height: height,
          child: CustomPaint(
            size: Size.infinite,
            painter: _StripPainter(
              cells: cells,
              notes: notes,
              photos: photos,
              note: theme.colors.inkMuted,
              photo: theme.colors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter({
    required this.cells,
    required this.notes,
    required this.photos,
    required this.note,
    required this.photo,
  });

  final List<DaySummary> cells;
  final Set<String> notes;
  final Set<String> photos;
  final Color note;
  final Color photo;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width / cells.length;
    for (var i = 0; i < cells.length; i++) {
      final day = cells[i].dayKey;
      final hasNote = notes.contains(day);
      final hasPhoto = photos.contains(day);
      if (!hasNote && !hasPhoto) continue;
      final centre = Offset((i + 0.5) * width, size.height / 2);
      // A photo wins the colour where a day has both: it is the rarer of the
      // two, and the one worth spotting from across the row.
      canvas.drawCircle(centre, 2.5, Paint()..color = hasPhoto ? photo : note);
    }
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.cells != cells || old.notes != notes || old.photos != photos;
}
