import 'package:flutter/material.dart';
import 'package:mobintix_ui_kit/mobintix_ui_kit.dart';

import '../models/security_step_config.dart';
import '../shared/painters.dart';
import '../shared/security_badge.dart';
import '../theme/security_suite_theme.dart';

class FaceDetectionView extends StatefulWidget {
  const FaceDetectionView({
    super.key,
    this.config = const FaceDetectionConfig(),
    required this.cameraPreview,
    this.status = FaceDetectionStatus.ready,
    this.onCapture,
    this.onRetry,
    this.onAlternate,
  });

  final FaceDetectionConfig config;

  /// Camera preview widget provided by the host app.
  final Widget cameraPreview;
  final FaceDetectionStatus status;
  final Future<void> Function()? onCapture;
  final Future<void> Function()? onRetry;
  final Future<void> Function()? onAlternate;

  @override
  State<FaceDetectionView> createState() => _FaceDetectionViewState();
}

class _FaceDetectionViewState extends State<FaceDetectionView> {
  var _busy = false;

  FaceDetectionConfig get _c => widget.config;

  Future<void> _handleAction(Future<void> Function()? cb) async {
    if (cb == null || _busy) return;
    setState(() => _busy = true);
    try {
      await cb();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _statusText {
    if (widget.status == FaceDetectionStatus.error && _c.errorText != null) {
      return _c.errorText!;
    }
    return switch (widget.status) {
      FaceDetectionStatus.ready =>
        _c.instructionText ?? 'Position your face within the oval',
      FaceDetectionStatus.scanning => 'Scanning\u2026',
      FaceDetectionStatus.aligning => 'Aligning \u2014 hold steady',
      FaceDetectionStatus.captured =>
        _c.capturedText ?? 'Face captured successfully',
      FaceDetectionStatus.error =>
        _c.errorText ?? 'Failed to detect face. Please try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final theme = context.securitySuiteTheme;

    final guideColor = theme?.faceGuideColor ?? colors.primary;
    final overlayColor = theme?.faceOverlayColor ?? Colors.black54;
    final cameraRadius = theme?.cameraViewRadius ?? 16.0;

    final isError = widget.status == FaceDetectionStatus.error;
    final isCaptured = widget.status == FaceDetectionStatus.captured;
    final statusColor =
        isError ? colors.error : (isCaptured ? colors.success : guideColor);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Column(
        children: [
          SizedBox(height: spacing.xxl),
          const SecurityBadge(),
          SizedBox(height: spacing.lg),
          AppText.headlineMedium(
            _c.title ?? 'Face Verification',
            textAlign: TextAlign.center,
          ),
          if (_c.subtitle != null) ...[
            const VSpace.sm(),
            AppText.bodyMedium(
              _c.subtitle!,
              textAlign: TextAlign.center,
              color: colors.textSecondary,
            ),
          ],
          SizedBox(height: spacing.lg),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cameraRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.cameraPreview,
                      CustomPaint(
                        painter: FaceGuideOverlayPainter(
                          guideColor: statusColor,
                          overlayColor: overlayColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: spacing.lg),
          AppText.bodyMedium(
            _statusText,
            textAlign: TextAlign.center,
            color: isError ? colors.error : colors.textSecondary,
          ),
          SizedBox(height: spacing.lg),
          if (isError) ...[
            AppButton.primary(
              text: _c.retryLabel ?? 'Retry',
              isFullWidth: true,
              onPressed: widget.onRetry == null
                  ? null
                  : () => _handleAction(widget.onRetry),
            ),
          ] else if (!isCaptured && widget.onCapture != null) ...[
            AppButton.primary(
              text: _c.primaryLabel ?? 'Capture',
              isLoading: _busy,
              isFullWidth: true,
              onPressed: () => _handleAction(widget.onCapture),
            ),
          ],
          if (_c.alternateLabel != null && widget.onAlternate != null) ...[
            const VSpace.md(),
            AppButton.ghost(
              text: _c.alternateLabel!,
              onPressed: _busy ? null : () => _handleAction(widget.onAlternate),
            ),
          ],
          SizedBox(height: spacing.xl),
        ],
      ),
    );
  }
}
