import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';
import '../l10n/app_language.dart';
import 'day_detail_screen.dart';
import 'day_photos.dart';

/// One marker on one day, to read: the readings with their times, the notes
/// under them and the photos next to them.
///
/// **Read-only on purpose.** A report is for looking back, and a tap on a
/// chart that quietly opens an editor is how last March gets changed by
/// accident. Changing a past day happens on the day screen, reached from the
/// calendar.
Future<void> showMarkerDaySheet(
  BuildContext context, {
  required PatternsController controller,
  required Metric metric,
  required String dayKey,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) =>
      _MarkerDaySheet(controller: controller, metric: metric, dayKey: dayKey),
);

class _MarkerDaySheet extends StatelessWidget {
  const _MarkerDaySheet({
    required this.controller,
    required this.metric,
    required this.dayKey,
  });

  final PatternsController controller;
  final Metric metric;
  final String dayKey;

  Future<({List<Observation> readings, List<StoredPhoto> photos})>
  _load() async {
    final readings = [
      for (final reading in await controller.readingsOn(dayKey))
        if (reading.metricId == metric.id && !reading.isDeleted) reading,
    ]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final photos = [
      for (final photo in await controller.photosOn(dayKey))
        if (photo.metricId == metric.id) photo,
    ];
    return (readings: readings, photos: photos);
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
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
        child: FutureBuilder(
          future: _load(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            return SingleChildScrollView(
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
                  Text(
                    context.s.humanDate(dayKey, withYear: true),
                    style: theme.typography.caption.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: VitalsSpacing.lg),
                  if (data == null)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if (data.readings.isEmpty)
                      Text(
                        context.s.nothingLogged,
                        style: theme.typography.body.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    for (final reading in data.readings)
                      _Reading(metric: metric, observation: reading),
                    if (data.photos.isNotEmpty) ...[
                      const SizedBox(height: VitalsSpacing.md),
                      DayPhotoStrip(
                        controller: controller,
                        photos: data.photos,
                        onChanged: () {},
                        readOnly: true,
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.metric, required this.observation});

  final Metric metric;
  final Observation observation;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;
    final minute = observation.localMinuteOfDay;
    final clock =
        '${(minute ~/ 60).toString().padLeft(2, '0')}:'
        '${(minute % 60).toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: VitalsSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              clock,
              style: theme.typography.caption.copyWith(color: colors.inkMuted),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  describeValue(observation.value, metric, context.s),
                  style: theme.typography.body,
                ),
                if (observation.note case final note?)
                  Padding(
                    padding: const EdgeInsets.only(top: VitalsSpacing.xs),
                    child: Text(
                      note,
                      style: theme.typography.caption.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
