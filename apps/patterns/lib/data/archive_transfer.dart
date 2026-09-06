import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Getting an archive off the phone, and back on.
///
/// A thin seam over `file_picker` and `share_plus`, in the same shape as
/// `PhotoPicker`: the screens never import either, and a widget test can hand
/// back bytes without a platform channel. That matters more here than anywhere
/// else in the app, because restore is the one path where a bug costs data that
/// cannot be typed again, and it has to be testable end to end.
abstract interface class ArchiveTransfer {
  /// The archive the user chose, or null if they backed out.
  Future<Uint8List?> pick();

  /// Hands the archive to the system share sheet.
  Future<void> send(Uint8List bytes, String fileName);
}

/// The real one.
final class PlatformArchiveTransfer implements ArchiveTransfer {
  const PlatformArchiveTransfer();

  @override
  Future<Uint8List?> pick() async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    return picked?.files.singleOrNull?.bytes;
  }

  /// Shares rather than saving to a fixed folder.
  ///
  /// The user picks Drive, email or a file manager, so the backup lands
  /// somewhere they will actually look for it - and no storage permission is
  /// needed, which is one fewer thing to grant and one fewer thing to explain.
  @override
  Future<void> send(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], fileNameOverrides: [fileName]),
    );
  }
}
