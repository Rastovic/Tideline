import 'package:flutter/material.dart';
import 'package:vitals_ui/vitals_ui.dart';

/// The one card shape in the app: flat, a hairline edge, and a short accent
/// stroke at its top-left corner.
///
/// **2D on purpose.** No shadow, no gradient, no blur: depth comes from the
/// surface being one step off the ground and from the edge. The accent stroke
/// is the only ornament, and it marks where a card starts when several are
/// stacked, which is most screens in this app.
class Panel extends StatelessWidget {
  const Panel({
    required this.child,
    this.label,
    this.trailing,
    this.color,
    this.padding = const EdgeInsets.all(VitalsSpacing.lg),
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget child;

  /// Uppercase heading inside the card. Null leaves the card unlabelled.
  final String? label;
  final Widget? trailing;

  /// The stroke and the label's marker. The theme accent when null.
  final Color? color;

  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final c = theme.colors;
    final mark = color ?? c.accent;

    final body = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null || trailing != null) ...[
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: mark,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: VitalsSpacing.sm),
                Expanded(
                  child: Text(
                    (label ?? '').toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.label.copyWith(
                      color: c.inkMuted,
                      letterSpacing: 1.4,
                      fontSize: 11,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: VitalsSpacing.md),
          ],
          child,
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: VitalsSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.stroke),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: body,
              ),
            ),
            // The corner stroke: short, thin, and the only ornament.
            Positioned(
              left: radius,
              top: 0,
              child: Container(
                width: 28,
                height: 2,
                decoration: BoxDecoration(
                  color: mark,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
