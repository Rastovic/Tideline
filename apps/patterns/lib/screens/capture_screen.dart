import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vitals_ui/vitals_ui.dart';

/// Takes a photo inside the app, with the previous one held faintly over the
/// viewfinder.
///
/// **The ghost is the whole reason this screen exists.** A series of skin or
/// hair photos is only comparable when each is framed like the last, and the
/// system camera cannot draw anything over its preview. A faded copy of the
/// last shot is worth more than any alignment algorithm, and it costs one
/// image. It can be switched off for a shot that should not match.
///
/// Returns the JPEG bytes, or null when the person backs out.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({this.ghostPath, super.key});

  /// The previous photo of this marker, if there is one.
  final String? ghostPath;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  String? _problem;
  bool _showGhost = true;
  bool _taking = false;

  File? get _ghost {
    final path = widget.ghostPath;
    if (path == null) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  /// The camera is released whenever the app leaves the screen, as Android
  /// requires, and opened again on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (state == AppLifecycleState.inactive) {
      _camera = null;
      camera?.dispose();
    } else if (state == AppLifecycleState.resumed && camera == null) {
      _open();
    }
  }

  Future<void> _open() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _problem = 'Telefon nema kameru.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final camera = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await camera.initialize();
      if (!mounted) {
        await camera.dispose();
        return;
      }
      setState(() {
        _camera = camera;
        _problem = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _problem = e.code.contains('Access')
          ? 'Kamera nije dozvoljena. Dozvola se daje u postavkama telefona.'
          : 'Kamera se nije mogla otvoriti.');
    }
  }

  Future<void> _take() async {
    final camera = _camera;
    if (camera == null || _taking) return;
    setState(() => _taking = true);
    try {
      final file = await camera.takePicture();
      final Uint8List bytes = await file.readAsBytes();
      // The camera's own temporary file. The photo that is kept is the
      // downscaled copy PhotoStore writes; this one must not linger.
      await File(file.path).delete().catchError((_) => File(file.path));
      if (mounted) Navigator.of(context).pop(bytes);
    } on CameraException {
      if (mounted) setState(() => _taking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final camera = _camera;
    final ghost = _ghost;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Slikaj'),
        actions: [
          if (ghost != null)
            IconButton(
              tooltip: _showGhost
                  ? 'Sakrij prethodnu fotografiju'
                  : 'Prikazi prethodnu fotografiju',
              icon: Icon(_showGhost ? Icons.layers : Icons.layers_clear),
              onPressed: () => setState(() => _showGhost = !_showGhost),
            ),
        ],
      ),
      body: SafeArea(
        child: _problem != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(VitalsSpacing.screenH),
                  child: Text(
                    _problem!,
                    textAlign: TextAlign.center,
                    style: theme.typography.body.copyWith(color: Colors.white),
                  ),
                ),
              )
            : camera == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            // The preview reports landscape; the phone is
                            // held upright.
                            aspectRatio: 1 / camera.value.aspectRatio,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(camera),
                                if (ghost != null && _showGhost)
                                  IgnorePointer(
                                    child: Opacity(
                                      opacity: 0.35,
                                      child: Image.file(ghost, fit: BoxFit.cover),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(VitalsSpacing.xl),
                        child: Semantics(
                          button: true,
                          label: 'Slikaj',
                          child: GestureDetector(
                            onTap: _take,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                color: _taking ? Colors.white54 : Colors.white24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
