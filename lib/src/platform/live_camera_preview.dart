import 'dart:async' show unawaited;
import 'dart:math' show Point, sqrt;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../theme/security_suite_theme.dart';
import 'face_ml_platform.dart';
import 'ml_kit_input_image.dart';

/// Self-contained live camera widget with optional ML Kit face detection.
///
/// Manages camera lifecycle, image streaming, and face detection internally.
/// The host app only needs to provide an optional [facePresent] notifier
/// to react to face detection state.
///
/// When [faceLandmarks] is provided, ML Kit runs with landmark detection
/// enabled and publishes normalized face ratios that can be used as a
/// simple face signature for registration / verification.
class LiveCameraPreview extends StatefulWidget {
  const LiveCameraPreview({
    super.key,
    this.facePresent,
    this.faceLandmarks,
  });

  /// When non-null and [isFaceMlKitSupported], ML Kit updates this from
  /// the image stream.
  final ValueNotifier<bool>? facePresent;

  /// When non-null, the latest detected face's landmark-based signature
  /// is written here as a `Map<String, double>` with normalized ratios.
  /// Returns `null` when no face is detected.
  final ValueNotifier<Map<String, double>?>? faceLandmarks;

  @override
  State<LiveCameraPreview> createState() => _LiveCameraPreviewState();
}

class _LiveCameraPreviewState extends State<LiveCameraPreview>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = -1;
  FaceDetector? _faceDetector;
  bool _hasError = false;
  bool _streamStarting = false;
  DateTime? _lastProcessTime;
  bool _frameInFlight = false;
  Future<void>? _lifecycleTeardown;
  late final AnimationController _blink;

  static const _defaultPlaceholder = Color(0xFF1A1A2E);
  static const _defaultOverlayText = Colors.white54;
  static const _defaultFaceDetected = Colors.greenAccent;
  static const _defaultFaceMissing = Colors.redAccent;
  static const _defaultLiveIndicator = Colors.red;

  bool get _mlDetectionEnabled =>
      widget.facePresent != null && isFaceMlKitSupported;

  bool get _landmarksEnabled => widget.faceLandmarks != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    if (_mlDetectionEnabled) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableContours: false,
          enableLandmarks: _landmarksEnabled,
          enableClassification: false,
          enableTracking: true,
        ),
      );
    }
    _initCamera();
  }

  Future<void> _startImageStreamIfNeeded() async {
    final ctrl = _controller;
    final detector = _faceDetector;
    if (!_mlDetectionEnabled ||
        ctrl == null ||
        !ctrl.value.isInitialized ||
        detector == null ||
        _streamStarting) {
      return;
    }
    if (ctrl.value.isStreamingImages) return;
    _streamStarting = true;
    widget.facePresent!.value = false;
    try {
      await ctrl.startImageStream(_onCameraImage);
    } catch (_) {
      if (mounted) widget.facePresent!.value = false;
    } finally {
      _streamStarting = false;
    }
  }

  void _onCameraImage(CameraImage image) {
    if (!mounted || !_mlDetectionEnabled || _faceDetector == null) return;
    final now = DateTime.now();
    if (_lastProcessTime != null &&
        now.difference(_lastProcessTime!) <
            const Duration(milliseconds: 220)) {
      return;
    }
    if (_frameInFlight) return;

    final input = buildMlKitInputImage(
      image: image,
      controller: _controller,
      cameras: _cameras,
      cameraIndex: _cameraIndex,
    );
    if (input == null) return;

    _frameInFlight = true;
    _lastProcessTime = now;
    _faceDetector!
        .processImage(input)
        .then((faces) {
          _frameInFlight = false;
          if (!mounted) return;
          final hasFace = faces.isNotEmpty;
          widget.facePresent?.value = hasFace;
          if (_landmarksEnabled) {
            widget.faceLandmarks!.value =
                hasFace ? _computeSignature(faces.first) : null;
          }
        })
        .catchError((_) {
          _frameInFlight = false;
        });
  }

  /// Computes normalized ratios from face landmarks that serve as a
  /// simple face signature. Ratios are scale-invariant so they stay
  /// consistent regardless of distance from the camera.
  Map<String, double>? _computeSignature(Face face) {
    final box = face.boundingBox;
    if (box.width <= 0 || box.height <= 0) return null;

    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final mouthLeft = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final mouthRight = face.landmarks[FaceLandmarkType.rightMouth]?.position;
    final mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    if (leftEye == null ||
        rightEye == null ||
        noseBase == null ||
        mouthBottom == null) {
      return null;
    }

    final w = box.width;
    final h = box.height;

    final eyeDist = _dist(leftEye, rightEye);
    final noseToMouth = _dist(noseBase, mouthBottom);
    final leftEyeToNose = _dist(leftEye, noseBase);
    final rightEyeToNose = _dist(rightEye, noseBase);

    final sig = <String, double>{
      'eye_dist': eyeDist / w,
      'nose_mouth': noseToMouth / h,
      'face_aspect': h / w,
      'left_eye_nose': leftEyeToNose / w,
      'right_eye_nose': rightEyeToNose / w,
    };

    if (mouthLeft != null && mouthRight != null) {
      sig['mouth_width'] = _dist(mouthLeft, mouthRight) / w;
    }

    return sig;
  }

  static double _dist(Point<int> a, Point<int> b) {
    final dx = (a.x - b.x).toDouble();
    final dy = (a.y - b.y).toDouble();
    return sqrt(dx * dx + dy * dy);
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (!mounted || _cameras.isEmpty) {
        if (mounted) setState(() => _hasError = true);
        widget.facePresent?.value = false;
        return;
      }
      _cameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_cameraIndex < 0) _cameraIndex = 0;

      final desc = _cameras[_cameraIndex];
      final ctrl = CameraController(
        desc,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: isAndroidCameraFormatNv21
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() => _controller = ctrl);
      await _startImageStreamIfNeeded();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
      widget.facePresent?.value = false;
    }
  }

  Future<void> _tearDownCamera() async {
    final ctrl = _controller;
    _controller = null;
    widget.facePresent?.value = false;
    widget.faceLandmarks?.value = null;
    if (ctrl == null) return;
    try {
      if (ctrl.value.isStreamingImages) {
        await ctrl.stopImageStream();
      }
    } catch (_) {}
    await ctrl.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lifecycleTeardown = _tearDownCamera();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_resumeCameraAfterBackground());
    }
  }

  Future<void> _resumeCameraAfterBackground() async {
    final pending = _lifecycleTeardown;
    if (pending != null) await pending;
    _lifecycleTeardown = null;
    if (mounted) await _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blink.dispose();
    _faceDetector?.close();
    _faceDetector = null;
    final ctrl = _controller;
    _controller = null;
    widget.facePresent?.value = false;
    widget.faceLandmarks?.value = null;
    if (ctrl != null) {
      if (ctrl.value.isStreamingImages) {
        unawaited(
          ctrl.stopImageStream().whenComplete(ctrl.dispose),
        );
      } else {
        unawaited(ctrl.dispose());
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.securitySuiteTheme;
    final ctrl = _controller;
    final bool ready = ctrl != null && ctrl.value.isInitialized;

    final placeholderColor =
        theme?.cameraPlaceholderColor ?? _defaultPlaceholder;
    final overlayTextColor =
        theme?.cameraOverlayTextColor ?? _defaultOverlayText;
    final liveColor =
        theme?.cameraLiveIndicatorColor ?? _defaultLiveIndicator;

    final Widget cameraBody;
    if (_hasError) {
      cameraBody = Container(
        color: placeholderColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off, size: 48, color: overlayTextColor),
              const SizedBox(height: 8),
              Text(
                'Camera unavailable',
                style: TextStyle(color: overlayTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    } else if (!ready) {
      cameraBody = Container(
        color: placeholderColor,
        child: Center(
          child: CircularProgressIndicator(color: overlayTextColor),
        ),
      );
    } else {
      cameraBody = _FittedCameraPreview(controller: ctrl);
    }

    final faceChip = widget.facePresent == null || !isFaceMlKitSupported
        ? null
        : ValueListenableBuilder<bool>(
            valueListenable: widget.facePresent!,
            builder: (context, face, _) {
              final faceDetected =
                  theme?.cameraFaceDetectedColor ?? _defaultFaceDetected;
              final faceMissing =
                  theme?.cameraFaceMissingColor ?? _defaultFaceMissing;
              final color = face ? faceDetected : faceMissing;
              final label = face ? 'Face detected' : 'No face';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: overlayTextColor.withValues(alpha: 0.85),
                          letterSpacing: 0.6,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              );
            },
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        cameraBody,
        Positioned(
          top: 12,
          left: 12,
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _blink,
                builder: (context, _) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: liveColor.withValues(
                        alpha: 0.3 + _blink.value * 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: overlayTextColor,
                      letterSpacing: 1.2,
                      fontSize: 10,
                    ),
              ),
              if (faceChip != null) ...[
                const SizedBox(width: 14),
                faceChip,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FittedCameraPreview extends StatelessWidget {
  const _FittedCameraPreview({required this.controller});
  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final previewSize = controller.value.previewSize!;
          final cameraAspect = previewSize.height / previewSize.width;
          final boxAspect = constraints.maxWidth / constraints.maxHeight;
          return ClipRect(
            child: OverflowBox(
              maxWidth: boxAspect < cameraAspect
                  ? constraints.maxHeight * cameraAspect
                  : constraints.maxWidth,
              maxHeight: boxAspect < cameraAspect
                  ? constraints.maxHeight
                  : constraints.maxWidth / cameraAspect,
              child: CameraPreview(controller),
            ),
          );
        },
      ),
    );
  }
}
