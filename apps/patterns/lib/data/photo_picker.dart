import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/capture_screen.dart';

/// Where a photo came from.
enum PhotoSource { camera, gallery }

/// Gets bytes from the camera or the gallery.
///
/// A thin seam so the screens do not import a plugin directly and a widget
/// test can hand back bytes without a platform channel.
///
/// **The camera is the app's own screen**, not the system camera: only an
/// in-app viewfinder can hold the previous photo over it. The gallery stays
/// the system picker, since a photo already taken has nothing to line up.
class PhotoPicker {
  const PhotoPicker();

  /// [ghostPath] is the previous photo to hold over the viewfinder, if any.
  Future<Uint8List?> pick(
    PhotoSource source, {
    required BuildContext context,
    String? ghostPath,
  }) async {
    if (source == PhotoSource.camera) {
      return Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => CaptureScreen(ghostPath: ghostPath),
        ),
      );
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Full resolution comes back and is downscaled by PhotoStore, in one
      // place, on an isolate. Letting the picker resize would put the rule in
      // two places and give a different result on each platform.
      imageQuality: 100,
    );
    return file?.readAsBytes();
  }
}
