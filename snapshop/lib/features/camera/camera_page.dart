import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../home/home_provider.dart';

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({super.key});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage>
    with SingleTickerProviderStateMixin {
  bool _isFlashing = false;
  String _flashMode = 'auto';
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;

  final List<String> _flashModes = ['on', 'off', 'always', 'auto'];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      final backCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.max,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_isCameraReady) return;
    setState(() => _isFlashing = true);
    try {
      final XFile photo = await _cameraController!.takePicture();
      if (mounted) {
        setState(() => _isFlashing = false);
        ref.read(homeProvider.notifier).startRecognition();
        context.push('/results', extra: photo.path);
      }
    } catch (e) {
      debugPrint('Take photo error: $e');
      if (mounted) {
        setState(() => _isFlashing = false);
      }
    }
  }

  Future<void> _onTapFocus(TapUpDetails details) async {
    if (_cameraController == null || !_isCameraReady) return;
    final previewSize = _cameraController!.value.previewSize!;
    final screenSize = MediaQuery.of(context).size;
    final scaleX = screenSize.width / previewSize.height;
    final scaleY = screenSize.height / previewSize.width;
    final scale = scaleX > scaleY ? scaleX : scaleY;
    final visibleH = previewSize.width * scale;
    final offsetY = (visibleH - screenSize.height) / 2 / scale;
    final x = details.localPosition.dx / screenSize.width;
    final y = (details.localPosition.dy + offsetY * scale) / visibleH;
    final normalized = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
    try {
      await _cameraController!.setFocusPoint(normalized);
    } catch (_) {}
  }

  Future<void> _toggleFlash() async {
    final nextIndex = (_flashModes.indexOf(_flashMode) + 1) % _flashModes.length;
    final nextMode = _flashModes[nextIndex];
    setState(() {
      _flashMode = nextMode;
    });
    if (_cameraController != null && _isCameraReady) {
      try {
        switch (nextMode) {
          case 'auto':
            await _cameraController!.setFlashMode(FlashMode.auto);
            break;
          case 'on':
            await _cameraController!.setFlashMode(FlashMode.always);
            break;
          case 'off':
            await _cameraController!.setFlashMode(FlashMode.off);
            break;
          case 'always':
            await _cameraController!.setFlashMode(FlashMode.torch);
            break;
        }
      } catch (e) {
        debugPrint('Set flash error: $e');
      }
    }
  }

  String get _flashLabel {
    switch (_flashMode) {
      case 'auto':
        return '自动';
      case 'on':
        return '开';
      case 'off':
        return '关';
      case 'always':
        return '常亮';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraReady && _cameraController != null)
            Positioned.fill(
              child: GestureDetector(
                onTapUp: _onTapFocus,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize!.height,
                      height: _cameraController!.value.previewSize!.width,
                      child: _cameraController!.buildPreview(),
                    ),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          if (_isFlashing)
            Container(color: Colors.white),
          _buildHeader(context),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeaderButton(
              icon: Icons.close,
              onTap: () => context.pop(),
            ),
            GestureDetector(
              onTap: _toggleFlash,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _flashMode == 'auto'
                            ? Colors.amber
                            : _flashMode == 'on'
                                ? Colors.white
                                : Colors.white54,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _flashMode == 'off' ? Icons.flash_off : Icons.bolt,
                      color: _flashMode == 'auto'
                          ? Colors.amber
                          : _flashMode == 'on'
                              ? Colors.white
                              : Colors.white54,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _flashLabel,
                    style: TextStyle(
                      color: _flashMode == 'auto'
                          ? Colors.amber
                          : _flashMode == 'on'
                              ? Colors.white
                              : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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

  Widget _buildHeaderButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomPadding + 40,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _takePhoto,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 5,
              ),
              color: Colors.white.withValues(alpha: 0.2),
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Color(0xFF1E293B),
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
