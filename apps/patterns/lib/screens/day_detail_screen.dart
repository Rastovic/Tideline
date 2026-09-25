import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_core/vitals_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';
import '../data/photo_picker.dart';
import 'day_photos.dart';
import 'log_sheet.dart';
import 'metric_labels.dart';
import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';

/// Everything recorded on one day, in the order it happened.
///
/// This is where the *why* lives: the diary entry, the readings with their
/// times, and - once capture ships - the photos with their captions. Reports
/// stay clean because this screen exists; nothing has to be crammed into a row
/// of squares.
class DayDetailScreen extends StatefulWidget {
  const DayDetailScreen({
    required this.controller,
    required this.dayKey,
    this.picker = const PhotoPicker(),
    super.key,
  });

  final PatternsController controller;
  final String dayKey;

  /// Injected so a widget test can hand back bytes without a camera.
  final PhotoPicker picker;

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late String _dayKey = widget.dayKey;
  late Future<List<Observation>> _readings = _load();
  late Future<List<StoredPhoto>> _photos = _loadPhotos();
  late Future<int?> _cycleDay = widget.controller.cycleDayOn(_dayKey);

  Future<List<Observation>> _load() => widget.controller.readingsOn(_dayKey);

  Future<List<StoredPhoto>> _loadPhotos() =>
      widget.controller.photosOn(_dayKey);

  /// Guarded, because a capture finishes after the camera returns and the
  /// screen may be gone by then.
  void _reload() {
    if (!mounted) return;
    setState(() {
      _readings = _load();
      _photos = _loadPhotos();
      _cycleDay = widget.controller.cycleDayOn(_dayKey);
    });
  }

  bool get _isToday => _dayKey.compareTo(widget.controller.today) >= 0;

  /// Moves to another day. **Never past today**: a day that has not happened
  /// has nothing to show, and logging into it would be a reading from the
  /// future.
  void _show(String dayKey) {
    if (dayKey.compareTo(widget.controller.today) > 0) return;
    _dayKey = dayKey;
    _reload();
  }

  Future<void> _pickDay() async {
    final today = parseDayKey(widget.controller.today)!;
    final current = parseDayKey(_dayKey) ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
      helpText: context.s.goToDay,
    );
    if (picked == null) return;
    _show(formatDayKey(picked.year, picked.month, picked.day));
  }

  /// Adds a reading to this day, whichever day it is.
  ///
  /// The way to fill in a day that was missed - last night's mood remembered
  /// this morning, or a period that started yesterday. A reading added to a
  /// past day is marked as entered late rather than passed off as noticed.
  Future<void> _addEntry() async {
    final markers = widget.controller.allMarkers
        .where((m) => m.isActive)
        .toList();
    final choice = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.add_a_photo_outlined),
                title: Text(context.s.photoOfTheDay),
                onTap: () => Navigator.of(context).pop('free-photo'),
              ),
              const Divider(height: 1),
              for (final metric in markers)
                ListTile(
                  leading: Icon(
                    Icons.circle,
                    size: 12,
                    color: markerColor(metric.colorHex),
                  ),
                  title: Text(metric.name),
                  onTap: () => Navigator.of(context).pop(metric),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'free-photo') {
      await _pickSource();
      return;
    }
    final metric = choice as Metric;
    final entry = await showLogSheet(
      context,
      metric: metric,
      pickPhoto: metric.kind == MetricKind.photo
          ? null
          : (source) => widget.picker.pick(source, context: context),
      onCapture: metric.kind == MetricKind.photo
          ? (source) async {
              final ghost = await widget.controller.ghostPathFor(metric.id);
              if (!mounted) return;
              final bytes = await widget.picker.pick(
                source,
                context: context,
                ghostPath: ghost,
              );
              if (bytes == null) return;
              await widget.controller.capturePhoto(
                bytes,
                metricId: metric.id,
                dayKey: _dayKey,
              );
              _reload();
            }
          : null,
    );
    if (entry == null) return;
    await widget.controller.logOn(
      _dayKey,
      metric.id,
      entry.value,
      note: entry.note,
    );
    if (entry.photo case final bytes?) {
      await widget.controller.attachPhoto(
        bytes,
        metricId: metric.id,
        dayKey: _dayKey,
      );
    }
    _reload();
  }

  /// A photo that belongs to the day rather than to any marker.
  ///
  /// "Ovo je poslije treninga" needs nothing to be tracked against, and forcing
  /// it into a marker would make the marker list a filing system instead of a
  /// list of what is being tracked.
  Future<void> _addFreePhoto(PhotoSource source) async {
    final bytes = await widget.picker.pick(source, context: context);
    if (bytes == null) return;
    await widget.controller.capturePhoto(bytes, dayKey: _dayKey);
    _reload();
  }

  Future<void> _pickSource() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.s.takePhoto),
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.s.fromGallery),
              onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _addFreePhoto(source);
  }

  Future<void> _edit(Observation observation) async {
    final metric = widget.controller.byId(observation.metricId);
    if (metric == null) return;
    final photos = [
      for (final photo in await widget.controller.photosOn(_dayKey))
        if (photo.metricId == metric.id) photo,
    ];
    if (!mounted) return;
    final entry = await showLogSheet(
      context,
      metric: metric,
      initial: observation.value,
      initialNote: observation.note,
      photos: photos.isEmpty
          ? null
          : DayPhotoStrip(
              controller: widget.controller,
              photos: photos,
              onChanged: _reload,
            ),
      pickPhoto: metric.kind == MetricKind.photo
          ? null
          : (source) => widget.picker.pick(source, context: context),
    );
    if (entry == null) return;
    await widget.controller.updateValue(
      observation.id,
      entry.value,
      note: entry.note,
    );
    if (entry.photo case final bytes?) {
      await widget.controller.attachPhoto(
        bytes,
        metricId: observation.metricId,
        dayKey: _dayKey,
      );
    }
    _reload();
  }

  /// Asked first. A long-press is easy to make by accident while scrolling,
  /// and a reading deleted from a day months ago cannot be remembered back.
  Future<void> _delete(Observation observation) async {
    final metric = widget.controller.byId(observation.metricId);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s.deleteEntryQuestion),
        content: Text(
          '${metric?.name ?? context.s.entry}: '
          '${describeValue(observation.value, metric, context.s)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.s.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.controller.deleteReading(observation.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _pickDay,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.s.humanDate(_dayKey, withYear: true)),
              FutureBuilder<int?>(
                future: _cycleDay,
                builder: (context, snapshot) => snapshot.data == null
                    ? const SizedBox.shrink()
                    : Text(
                        context.s.cycleDay(snapshot.data!),
                        style: theme.typography.caption.copyWith(
                          color: theme.colors.inkMuted,
                        ),
                      ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.s.previousDay,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _show(addDays(_dayKey, -1)),
          ),
          IconButton(
            tooltip: context.s.goToDay,
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDay,
          ),
          IconButton(
            tooltip: context.s.nextDay,
            icon: const Icon(Icons.chevron_right),
            onPressed: _isToday ? null : () => _show(addDays(_dayKey, 1)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        tooltip: context.s.addEntry,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Observation>>(
        future: _readings,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final readings = snapshot.data!;

          final photoStrip = FutureBuilder<List<StoredPhoto>>(
            future: _photos,
            builder: (context, snapshot) => Padding(
              padding: const EdgeInsets.only(bottom: VitalsSpacing.lg),
              child: DayPhotoStrip(
                controller: widget.controller,
                photos: snapshot.data ?? const [],
                onChanged: _reload,
              ),
            ),
          );

          if (readings.isEmpty) {
            // An empty day is stated plainly and never scolded.
            return ListView(
              padding: const EdgeInsets.all(VitalsSpacing.screenH),
              children: [
                photoStrip,
                Center(
                  child: Text(
                    context.s.nothingLogged,
                    style: theme.typography.body.copyWith(
                      color: theme.colors.inkMuted,
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(VitalsSpacing.screenH),
            itemCount: readings.length + 1,
            separatorBuilder: (_, __) =>
                const SizedBox(height: VitalsSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) return photoStrip;
              final observation = readings[index - 1];
              final metric = widget.controller.byId(observation.metricId);
              return _ReadingCard(
                metric: metric,
                observation: observation,
                onEdit: () => _edit(observation),
                onDelete: () => _delete(observation),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.metric,
    required this.observation,
    required this.onEdit,
    required this.onDelete,
  });

  final Metric? metric;
  final Observation observation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final colors = theme.colors;
    final minute = observation.localMinuteOfDay;
    final clock =
        '${(minute ~/ 60).toString().padLeft(2, '0')}:'
        '${(minute % 60).toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onEdit,
      onLongPress: onDelete,
      borderRadius: VitalsRadius.nestedAll,
      child: Container(
        padding: const EdgeInsets.all(VitalsSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: VitalsRadius.nestedAll,
          border: Border.all(color: colors.stroke),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Text(
                clock,
                style: theme.typography.caption.copyWith(
                  color: colors.inkMuted,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric?.name ?? context.s.unknownMarker,
                    style: theme.typography.label,
                  ),
                  const SizedBox(height: VitalsSpacing.xs),
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
                  if (observation.value case TextValue(isPrivate: true))
                    Padding(
                      padding: const EdgeInsets.only(top: VitalsSpacing.xs),
                      child: Text(
                        context.s.privateLower,
                        style: theme.typography.caption.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                    ),
                  if (observation.enteredLate)
                    Padding(
                      padding: const EdgeInsets.only(top: VitalsSpacing.xs),
                      child: Text(
                        context.s.enteredLate,
                        style: theme.typography.caption.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A reading in words, for a screen that shows rather than charts.
///
/// Tags are named rather than counted, because "tuga, overthink" is the thing
/// worth reading back and "2 tags" is not.
String describeValue(
  MetricValue value,
  Metric? metric,
  AppStrings s,
) => switch (value) {
  NumberValue(:final number) =>
    '$number${metric?.unit == null ? '' : ' ${metric!.unit}'}',
  BooleanValue(value: final flag) => flag ? s.yes : s.no,
  TextValue(:final text) => text,
  TimeOfDayValue() =>
    value.toString().replaceAll('TimeOfDayValue(', '').replaceAll(')', ''),
  ChoiceValue(:final optionId) => _labelFor(metric, optionId),
  TagsValue(:final optionIds) =>
    optionIds.isEmpty
        // The recorded answer, spelled out. An empty line here would read as
        // a bug, and worse, as a day that was never filled in.
        ? s.noneOfThese
        : optionIds.map((id) => _labelFor(metric, id)).join(', '),
  PhotoValue(:final caption) => caption ?? s.photoLower,
};

String _labelFor(Metric? metric, String optionId) {
  for (final option in metric?.options ?? const []) {
    if (option.id == optionId) return option.label;
  }
  return optionId;
}
