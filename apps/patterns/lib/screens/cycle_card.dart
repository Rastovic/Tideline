import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../l10n/app_language.dart';

/// The cycle, on the home screen: which day it is and what was recorded.
///
/// **Counting, never predicting.** There is no expected next date here, no
/// "late", no window - only the day counted from a start she recorded, the
/// bleeding days she recorded, and the lengths of cycles that have already
/// finished. An unanchored stretch says so instead of guessing.
///
/// It replaces the two marker rows it is built from, because "period start"
/// answered with "It did not" is not an answer anyone gives, and the pair of
/// rows said nothing about where the cycle actually stands.
class CycleCard extends StatelessWidget {
  const CycleCard({
    required this.status,
    required this.today,
    required this.onLog,
    super.key,
  });

  final CycleStatus? status;

  /// Today as the app counts it, so "yesterday" is a day boundary away and
  /// not a midnight away.
  final String today;

  /// (start, dayKey): true records a period start, false a period end.
  final void Function(bool start, String dayKey) onLog;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;
    final s = context.s;
    final status = this.status;

    final lines = <String>[
      if (status?.lastStart case final start?)
        s.cycleStartedOn(s.humanDate(start)),
      if (status?.bleedingDays case final days?)
        status!.bleedingNow
            ? s.cycleBleedingSoFar(days)
            : s.cycleBleedingDays(days),
    ];

    // Drawn inside the home screen's cycle panel, so it carries no card of
    // its own.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          switch (status?.day) {
            final day? => s.cycleDayNumber(day),
            null => s.cycleNotAnchored,
          },
          style: theme.typography.displayL.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (lines.isNotEmpty) ...[
          const SizedBox(height: VitalsSpacing.xs),
          Text(
            lines.join(' · '),
            style: theme.typography.caption.copyWith(color: colors.inkMuted),
          ),
        ],
        if (status != null && !status.isAnchored) ...[
          const SizedBox(height: VitalsSpacing.xs),
          Text(
            status.lastStart == null
                ? s.cycleNothingRecorded
                : s.cycleTooFarBack,
            style: theme.typography.caption.copyWith(color: colors.inkFaint),
          ),
        ],
        if (status != null && status.recentLengths.isNotEmpty) ...[
          const SizedBox(height: VitalsSpacing.xs),
          Text(
            s.cycleLengthsLine(status.recentLengths.join(', ')),
            style: theme.typography.caption.copyWith(color: colors.inkMuted),
          ),
        ],
        const SizedBox(height: VitalsSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickDay(context, start: true),
                child: Text(s.periodStarted, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: VitalsSpacing.sm),
            Expanded(
              child: OutlinedButton(
                // Nothing to end when nothing is open. Offering it anyway
                // would record an end that pairs with no start.
                onPressed: status?.bleedingNow == true
                    ? () => _pickDay(context, start: false)
                    : null,
                child: Text(s.periodEnded, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Today, yesterday, or a date - because a period is remembered a day late
  /// as often as it is logged on the day.
  Future<void> _pickDay(BuildContext context, {required bool start}) async {
    final s = context.s;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(s.today),
              onTap: () => Navigator.of(context).pop(today),
            ),
            ListTile(
              title: Text(s.yesterday),
              onTap: () => Navigator.of(context).pop(addDays(today, -1)),
            ),
            ListTile(
              title: Text(s.pickADate),
              onTap: () => Navigator.of(context).pop('pick'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    if (choice != 'pick') {
      onLog(start, choice);
      return;
    }

    final last = parseDayKey(today)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: last,
      firstDate: DateTime(last.year - 5),
      // Nothing after today: a period that has not happened is not a record.
      lastDate: last,
      helpText: start ? s.periodStarted : s.periodEnded,
    );
    if (picked == null) return;
    onLog(start, formatDayKey(picked.year, picked.month, picked.day));
  }
}
