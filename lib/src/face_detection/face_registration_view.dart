import 'package:flutter/material.dart';
import 'package:mobintix_ui_kit/mobintix_ui_kit.dart';

import '../models/security_step_config.dart';
import '../shared/painters.dart';
import '../shared/security_badge.dart';
import '../theme/security_suite_theme.dart';

class FaceRegistrationView extends StatefulWidget {
  const FaceRegistrationView({
    super.key,
    this.config = const FaceRegistrationConfig(),
    required this.cameraPreview,
    this.status = FaceRegistrationStatus.notRegistered,
    this.onRegister,
    this.onRetry,
    this.onContinue,
    this.onCancel,
  });

  final FaceRegistrationConfig config;
  final Widget cameraPreview;
  final FaceRegistrationStatus status;

  final Future<void> Function()? onRegister;
  final Future<void> Function()? onRetry;
  final Future<void> Function()? onContinue;
  final VoidCallback? onCancel;

  @override
  State<FaceRegistrationView> createState() => _FaceRegistrationViewState();
}

class _FaceRegistrationViewState extends State<FaceRegistrationView> {
  var _busy = false;

  FaceRegistrationConfig get _c => widget.config;

  Future<void> _handleAction(Future<void> Function()? cb) async {
    if (cb == null || _busy) return;
    setState(() => _busy = true);
    try {
      await cb();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _statusText => switch (widget.status) {
        FaceRegistrationStatus.notRegistered =>
          _c.subtitle ?? 'Position your face in the frame and tap Register.',
        FaceRegistrationStatus.scanning =>
          _c.scanningText ?? 'Scanning your face — hold still…',
        FaceRegistrationStatus.registering =>
          _c.registeringText ?? 'Registering — almost done…',
        FaceRegistrationStatus.registered =>
          _c.successSubtitle ?? 'Face registered successfully!',
        FaceRegistrationStatus.error =>
          _c.errorText ?? 'Registration failed. Please try again.',
      };

  String get _titleText => switch (widget.status) {
        FaceRegistrationStatus.notRegistered =>
          _c.title ?? 'Register Your Face',
        FaceRegistrationStatus.scanning => 'Scanning…',
        FaceRegistrationStatus.registering => 'Registering…',
        FaceRegistrationStatus.registered =>
          _c.successTitle ?? 'Registration Complete',
        FaceRegistrationStatus.error => 'Registration Failed',
      };

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final theme = context.securitySuiteTheme;

    final guideColor = theme?.faceGuideColor ?? colors.primary;
    final overlayColor = theme?.faceOverlayColor ?? Colors.black54;
    final cameraRadius = theme?.cameraViewRadius ?? 16.0;
    final processingBgColor = theme?.processingOverlayColor ?? Colors.black54;
    final checkColor = theme?.successCheckColor ?? Colors.white;
    final isError = widget.status == FaceRegistrationStatus.error;
    final isRegistered = widget.status == FaceRegistrationStatus.registered;
    final isProcessing = widget.status == FaceRegistrationStatus.scanning ||
        widget.status == FaceRegistrationStatus.registering;

    final statusColor = isError
        ? colors.error
        : isRegistered
            ? colors.success
            : guideColor;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Column(
        children: [
          SizedBox(height: spacing.md),

          const SecurityBadge(),
          SizedBox(height: spacing.sm),

          AppText.headlineMedium(
            _titleText,
            textAlign: TextAlign.center,
          ),
          const VSpace.xs(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.sm),
            child: AppText.bodyMedium(
              _statusText,
              textAlign: TextAlign.center,
              color: isError ? colors.error : colors.textSecondary,
            ),
          ),

          SizedBox(height: spacing.md),

          // Camera preview — always visible
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
                      if (isRegistered)
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.success.withValues(alpha: 0.85),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 40,
                              color: checkColor,
                            ),
                          ),
                        ),
                      if (isProcessing)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            color: processingBgColor,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: checkColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _statusText,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: checkColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: spacing.md),

          if (widget.status == FaceRegistrationStatus.notRegistered) ...[
            AppButton.primary(
              text: _c.registerLabel ?? 'Register My Face',
              leadingIcon: Icons.camera_alt,
              isLoading: _busy,
              isFullWidth: true,
              onPressed: widget.onRegister == null
                  ? null
                  : () => _handleAction(widget.onRegister),
            ),
            if (widget.onCancel != null) ...[
              const VSpace.sm(),
              AppButton.ghost(
                text: _c.cancelLabel ?? 'Cancel',
                onPressed: _busy ? null : widget.onCancel,
              ),
            ],
          ],

          if (isError) ...[
            AppButton.primary(
              text: _c.retryLabel ?? 'Retry',
              leadingIcon: Icons.refresh,
              isLoading: _busy,
              isFullWidth: true,
              onPressed: widget.onRetry == null
                  ? null
                  : () => _handleAction(widget.onRetry),
            ),
            if (widget.onCancel != null) ...[
              const VSpace.sm(),
              AppButton.ghost(
                text: _c.cancelLabel ?? 'Cancel',
                onPressed: _busy ? null : widget.onCancel,
              ),
            ],
          ],

          if (isRegistered) ...[
            AppButton.primary(
              text: _c.continueLabel ?? 'Continue to Verification',
              isFullWidth: true,
              onPressed: widget.onContinue == null
                  ? null
                  : () => _handleAction(widget.onContinue),
            ),
          ],

          SizedBox(height: spacing.lg),
        ],
      ),
    );
  }
}
