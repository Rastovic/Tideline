import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Where a photo came from.
enum PhotoSource { camera, gallery }

/// Gets bytes from the camera or the gallery.
///
/// A thin seam over `image_picker` so the screens do not import it directly and
/// a widget test can hand back bytes without a platform channel.
class PhotoPicker {
  const PhotoPicker();

  Future<Uint8List?> pick(PhotoSource source) async {
    final file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // Full resolution comes back and is downscaled by PhotoStore, in one
      // place, on an isolate. Letting the picker resize would put the rule in
      // two places and give a different result on each platform.
      imageQuality: 100,
    );
    return file?.readAsBytes();
  }
}
