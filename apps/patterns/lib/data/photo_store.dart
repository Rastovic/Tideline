import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:vitals_core/vitals_core.dart';

/// A photo written to disk, ready to be recorded.
final class SavedPhoto {
  const SavedPhoto({
    required this.fileName,
    required this.thumbFileName,
    required this.byteSize,
  });

  final String fileName;
  final String thumbFileName;

  /// Full size plus thumbnail. What the size budget in Settings counts.
  final int byteSize;
}

/// Photos on disk, in the app's own private directory.
///
/// **Never the gallery.** These are body photos in an app that also holds
/// weight, appetite and mood; they stay behind the app lock and out of every
/// other app's reach.
///
/// **Storage is decided at capture and cannot be deferred.** A raw phone photo
/// is around 4MB, and daily for a year is 1.5GB - an app people uninstall to
/// reclaim space. Every photo is resized to 1440px on its long edge at JPEG
/// q80, with a 160px thumbnail beside it, which is about 110MB a year for a
/// daily marker. **The original is never kept**, because quality you never
/// stored cannot be recovered, and because a photo the user already holds
/// cannot be shrunk later without a migration over their whole library.
final class PhotoStore {
  PhotoStore(this._directory, {this.useIsolate = true});

  /// Opens (and creates) the private photo directory.
  static Future<PhotoStore> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/photos');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return PhotoStore(dir);
  }

  final Directory _directory;

  /// Whether the resize runs on a background isolate.
  ///
  /// True on a device, because a 12MP decode on the UI thread drops frames on
  /// exactly the phones where photos matter most. False in tests: spawning an
  /// isolate from `flutter test` is slow enough to look like a hang, and the
  /// thing under test is the resize, not where it ran.
  final bool useIsolate;

  static const longEdge = 1440;
  static const thumbEdge = 160;
  static const quality = 80;

  String pathFor(String fileName) => '${_directory.path}/$fileName';

  File fileFor(String fileName) => File(pathFor(fileName));

  /// Resizes, encodes and writes one photo.
  ///
  /// The work happens on a background isolate: a 12MP decode on the UI thread
  /// drops frames on exactly the phones where photos matter most.
  Future<SavedPhoto?> save(Uint8List original) async {
    final encoded =
        useIsolate ? await compute(_resize, original) : _resize(original);
    if (encoded == null) return null;

    final id = Ids.newId();
    final fileName = '$id.jpg';
    final thumbFileName = '${id}_t.jpg';
    await fileFor(fileName).writeAsBytes(encoded.full, flush: true);
    await fileFor(thumbFileName).writeAsBytes(encoded.thumb, flush: true);

    return SavedPhoto(
      fileName: fileName,
      thumbFileName: thumbFileName,
      byteSize: encoded.full.length + encoded.thumb.length,
    );
  }

  Future<List<int>?> read(String fileName) async {
    final file = fileFor(fileName);
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }

  /// Writes a photo back during a restore.
  Future<void> write(String fileName, List<int> bytes) =>
      fileFor(fileName).writeAsBytes(bytes, flush: true);

  /// Removes the files of a photo the user chose to delete.
  ///
  /// Only ever called from an explicit action. **Nothing in this app deletes a
  /// photo on its own**, however tight storage gets - it can show what the
  /// oldest ones are and let the person decide.
  Future<void> deleteFiles(String fileName, String thumbFileName) async {
    for (final name in [fileName, thumbFileName]) {
      final file = fileFor(name);
      if (file.existsSync()) await file.delete();
    }
  }

  /// Bytes currently on disk, which is the number Settings shows.
  ///
  /// Measured from the directory rather than summed from the table, so a file
  /// left behind by an interrupted delete is visible instead of invisible.
  int bytesOnDisk() {
    var total = 0;
    for (final entity in _directory.listSync()) {
      if (entity is File) total += entity.lengthSync();
    }
    return total;
  }
}

final class _Encoded {
  const _Encoded(this.full, this.thumb);

  final Uint8List full;
  final Uint8List thumb;
}

/// Runs on a background isolate. Top-level because [compute] requires it.
_Encoded? _resize(Uint8List original) {
  final decoded = img.decodeImage(original);
  if (decoded == null) return null;

  final full = decoded.width >= decoded.height
      ? img.copyResize(decoded, width: PhotoStore.longEdge)
      : img.copyResize(decoded, height: PhotoStore.longEdge);
  final thumb = decoded.width >= decoded.height
      ? img.copyResize(decoded, width: PhotoStore.thumbEdge)
      : img.copyResize(decoded, height: PhotoStore.thumbEdge);

  return _Encoded(
    img.encodeJpg(full, quality: PhotoStore.quality),
    img.encodeJpg(thumb, quality: PhotoStore.quality),
  );
}
