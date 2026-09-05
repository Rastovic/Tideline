import 'dart:io';

import 'package:flutter/material.dart';
import 'package:patterns_data/patterns_data.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/patterns_controller.dart';

/// The photos of one day, as a row of thumbnails.
///
/// **Shown, never judged.** No comparison score, no before-and-after verdict,
/// no beautification, no streak on photo days and no nudge for a missing one.
/// This app already holds weight, appetite and mood; a judged photo completes
/// that set.
class DayPhotoStrip extends StatelessWidget {
  const DayPhotoStrip({
    required this.controller,
    required this.photos,
    required this.onChanged,
    super.key,
  });

  final PatternsController controller;
  final List<StoredPhoto> photos;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    final store = controller.photoStore;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: VitalsSpacing.sm),
        itemBuilder: (context, index) {
          final photo = photos[index];
          final path = store?.pathFor(photo.thumbFileName);
          return GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PhotoViewerScreen(
                    controller: controller,
                    photo: photo,
                  ),
                ),
              );
              onChanged();
            },
            child: ClipRRect(
              borderRadius: VitalsRadius.nestedAll,
              child: SizedBox(
                width: 96,
                height: 96,
                child: path == null || !File(path).existsSync()
                    // A file that is gone is said plainly rather than drawn as
                    // a broken image: the row survived a restore, the bytes
                    // did not, and that is worth seeing.
                    ? _Missing(caption: photo.caption)
                    : Image.file(File(path), fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({this.caption});

  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    return Container(
      color: theme.colors.surfaceAlt,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(VitalsSpacing.sm),
      child: Text(
        caption ?? 'fajl nedostaje',
        textAlign: TextAlign.center,
        style: theme.typography.caption.copyWith(color: theme.colors.inkMuted),
      ),
    );
  }
}

/// One photo, full size, with its caption.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    required this.controller,
    required this.photo,
    super.key,
  });

  final PatternsController controller;
  final StoredPhoto photo;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final TextEditingController _caption =
      TextEditingController(text: widget.photo.caption ?? '');

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obrisati fotografiju?'),
        content: const Text('Fajl se brise sa telefona. Ovo se ne vraca.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Obrisi'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.controller.deletePhoto(widget.photo);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final path = widget.controller.photoStore?.pathFor(widget.photo.fileName);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.photo.dayKey),
        actions: [
          IconButton(
            tooltip: 'Obrisi',
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(VitalsSpacing.screenH),
        children: [
          if (path != null && File(path).existsSync())
            ClipRRect(
              borderRadius: VitalsRadius.cardAll,
              child: Image.file(File(path)),
            )
          else
            _Missing(caption: widget.photo.caption),
          const SizedBox(height: VitalsSpacing.lg),
          TextField(
            controller: _caption,
            style: theme.typography.body,
            decoration: const InputDecoration(
              labelText: 'Opis',
              hintText: 'npr. poslije treninga',
            ),
            onSubmitted: (text) => widget.controller.photos.setCaption(
              widget.photo.id,
              text.trim().isEmpty ? null : text.trim(),
            ),
          ),
          const SizedBox(height: VitalsSpacing.md),
          Text(
            '${(widget.photo.byteSize / 1024).round()} KB',
            style: theme.typography.caption.copyWith(
              color: theme.colors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}
