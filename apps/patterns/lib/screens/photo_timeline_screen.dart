import 'dart:io';

import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';
import 'day_detail_screen.dart';
import '../l10n/app_language.dart';

/// Every photo of one marker, month by month.
///
/// **Shown, never judged.** In date order and nothing else: no comparison, no
/// "then and now", no missing-day gaps drawn as failures. Each thumbnail opens
/// its day, because a photo means most next to what else was logged.
class PhotoTimelineScreen extends StatefulWidget {
  const PhotoTimelineScreen({
    required this.controller,
    required this.metric,
    super.key,
  });

  final PatternsController controller;
  final Metric metric;

  @override
  State<PhotoTimelineScreen> createState() => _PhotoTimelineScreenState();
}

class _PhotoTimelineScreenState extends State<PhotoTimelineScreen> {
  late Future<List<StoredPhoto>> _photos =
      widget.controller.photos.forMetric(widget.metric.id);


  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final store = widget.controller.photoStore;

    return Scaffold(
      appBar: AppBar(title: Text(widget.metric.name)),
      body: SafeArea(
        child: FutureBuilder<List<StoredPhoto>>(
          future: _photos,
          builder: (context, snapshot) {
            final photos = snapshot.data;
            if (photos == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (photos.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(VitalsSpacing.screenH),
                child: Text(
                  context.s.noPhotosYet,
                  style: theme.typography.body
                      .copyWith(color: theme.colors.inkMuted),
                ),
              );
            }

            // Newest month first; oldest-first inside a month, as taken.
            final byMonth = <String, List<StoredPhoto>>{};
            for (final photo in photos) {
              byMonth.putIfAbsent(photo.dayKey.substring(0, 7), () => [])
                  .add(photo);
            }
            final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

            return ListView(
              padding: const EdgeInsets.all(VitalsSpacing.screenH),
              children: [
                for (final month in months) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: VitalsSpacing.lg,
                      bottom: VitalsSpacing.sm,
                    ),
                    child: Text(
                      context.s.monthYear(month),
                      style: theme.typography.label,
                    ),
                  ),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: VitalsSpacing.xs,
                    crossAxisSpacing: VitalsSpacing.xs,
                    children: [
                      for (final photo in byMonth[month]!)
                        _Thumb(
                          photo: photo,
                          path: store?.pathFor(photo.thumbFileName),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DayDetailScreen(
                                  controller: widget.controller,
                                  dayKey: photo.dayKey,
                                ),
                              ),
                            );
                            if (mounted) {
                              setState(() => _photos = widget.controller
                                  .photos
                                  .forMetric(widget.metric.id));
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.path, required this.onTap});

  final StoredPhoto photo;
  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final file = path == null ? null : File(path!);
    return Semantics(
      button: true,
      label: '${context.s.humanDate(photo.dayKey, withYear: true)}'
          '${photo.caption == null ? '' : ', ${photo.caption}'}',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: VitalsRadius.nestedAll,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (file != null && file.existsSync())
                Image.file(file, fit: BoxFit.cover)
              else
                // Gone after a restore without its bytes: said, not hidden.
                ColoredBox(
                  color: theme.colors.stroke,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              Positioned(
                left: 4,
                bottom: 2,
                child: Text(
                  photo.dayKey.substring(8).replaceFirst(RegExp('^0'), ''),
                  style: theme.typography.caption.copyWith(
                    color: Colors.white,
                    shadows: const [Shadow(blurRadius: 3)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
