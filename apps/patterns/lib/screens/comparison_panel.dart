import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import 'comparison_chart.dart';
import 'metric_labels.dart';
import 'panel.dart';

/// Two markers read against each other, as counted groups.
///
/// **It compares and never concludes.** Each group carries the days behind it,
/// and the card says in words that the app claims nothing about why - because
/// the difference between "this is what the days look like" and "this caused
/// that" is the whole boundary this app is built on.
class ComparisonPanel extends StatelessWidget {
  const ComparisonPanel({required this.comparison, super.key});

  final Comparison comparison;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final s = context.s;
    final color = markerColor(comparison.outcome.colorHex) ?? theme.colors.accent;

    if (comparison.isEmpty) {
      return Panel(
        label: s.compareHeading,
        color: color,
        child: Text(
          s.compareTooLittle,
          style: theme.typography.body.copyWith(color: theme.colors.inkMuted),
        ),
      );
    }

    final widest = comparison.buckets
        .map((b) => b.days)
        .reduce((a, b) => a > b ? a : b);

    return Panel(
      label: s.compareTitle(comparison.outcome.name, comparison.condition.name),
      color: color,
      trailing: Text(
        s.comparePairedDays(comparison.pairedDays),
        style: theme.typography.caption.copyWith(color: theme.colors.inkFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (comparison.pairing == ComparePairing.nextDay) ...[
            Text(
              s.compareNextDayNote,
              style: theme.typography.caption
                  .copyWith(color: theme.colors.inkMuted),
            ),
            const SizedBox(height: VitalsSpacing.sm),
          ],
          // The chart first: one dot per day, the condition across, the
          // outcome up. The rows under it are the same days, counted.
          Text(
            comparison.outcome.name,
            style: theme.typography.caption
                .copyWith(color: theme.colors.inkFaint),
          ),
          ComparisonChart(comparison: comparison, color: color),
          const SizedBox(height: VitalsSpacing.xs),
          Text(
            comparison.condition.name,
            textAlign: TextAlign.center,
            style: theme.typography.caption
                .copyWith(color: theme.colors.inkFaint),
          ),
          const SizedBox(height: VitalsSpacing.md),
          for (final bucket in comparison.buckets)
            _Bucket(
              bucket: bucket,
              widest: widest,
              color: color,
              unit: comparison.outcome.unit,
              kind: comparison.outcome.kind,
            ),
          const SizedBox(height: VitalsSpacing.sm),
          Text(
            s.compareChartHint,
            style:
                theme.typography.caption.copyWith(color: theme.colors.inkFaint),
          ),
          Text(
            s.compareNoClaim,
            style:
                theme.typography.caption.copyWith(color: theme.colors.inkFaint),
          ),
        ],
      ),
    );
  }
}

class _Bucket extends StatelessWidget {
  const _Bucket({
    required this.bucket,
    required this.widest,
    required this.color,
    required this.kind,
    this.unit,
  });

  final CompareBucket bucket;

  /// Unused now that the row carries no bar; kept so the caller reads the
  /// same either way.
  final int widest;

  final Color color;
  final MetricKind kind;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final s = context.s;
    final typical = bucket.typical;

    // No bar. A bar under a number reads as that number's size, and the only
    // thing there was to draw here is how many days the group holds - which
    // the count already says, without pretending to be a measurement.
    return Padding(
      padding: const EdgeInsets.only(bottom: VitalsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              _label(bucket.label, s),
              style: theme.typography.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            typical == null ? '—' : _value(typical),
            style: theme.typography.title.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: VitalsSpacing.md),
          SizedBox(
            width: 64,
            child: Text(
              '${bucket.days} ${s.daysLoggedLabel.split(' ').first}',
              textAlign: TextAlign.right,
              style: theme.typography.caption.copyWith(
                color: theme.colors.inkMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String raw, AppStrings s) => switch (raw) {
        'yes' => s.compareYes,
        'no' => s.compareNo,
        'high' => s.compareHigh,
        'low' => s.compareLow,
        _ => raw,
      };

  String _value(num typical) {
    if (kind == MetricKind.timeOfDay) {
      final minute = typical.round() % 1440;
      return '${(minute ~/ 60).toString().padLeft(2, '0')}:'
          '${(minute % 60).toString().padLeft(2, '0')}';
    }
    final number = typical == typical.roundToDouble()
        ? '${typical.round()}'
        : typical.toStringAsFixed(1);
    return unit == null ? number : '$number $unit';
  }
}
