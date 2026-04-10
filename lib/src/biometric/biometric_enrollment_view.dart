import 'package:flutter/material.dart';
import 'package:mobintix_ui_kit/mobintix_ui_kit.dart';

import '../models/security_step_config.dart';
import '../shared/painters.dart';
import '../shared/security_badge.dart';
import '../theme/security_suite_theme.dart';

class BiometricEnrollmentView extends StatefulWidget {
  const BiometricEnrollmentView({
    super.key,
    this.config = const BiometricEnrollmentConfig(),
    this.status = BiometricEnrollmentStatus.notEnrolled,
    this.scanProgress = 0,
    this.totalScans = 3,
    this.onEnroll,
    this.onRetry,
    this.onContinue,
    this.onCancel,
    this.onOpenSettings,
  });

  final BiometricEnrollmentConfig config;
  final BiometricEnrollmentStatus status;

  /// Current scan count (e.g. 1, 2, 3) during enrollment.
  final int scanProgress;

  /// Total scans required.
  final int totalScans;

  final Future<void> Function()? onEnroll;
  final Future<void> Function()? onRetry;
  final Future<void> Function()? onContinue;
  final VoidCallback? onCancel;
  final VoidCallback? onOpenSettings;

  @override
  State<BiometricEnrollmentView> createState() =>
      _BiometricEnrollmentViewState();
}

class _BiometricEnrollmentViewState extends State<BiometricEnrollmentView>
    with SingleTickerProviderStateMixin {
  var _busy = false;
  late final AnimationController _pulseCtrl;

  BiometricEnrollmentConfig get _c => widget.config;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _syncPulseAnimation(BuildContext context) {
    final reduce = Responsive.shouldReduceMotion(context);
    final runPulse = _isActive && !reduce;
    if (runPulse && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!runPulse && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
    if (!runPulse) {
      _pulseCtrl.value = 0.5;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulseAnimation(context);
  }

  @override
  void didUpdateWidget(covariant BiometricEnrollmentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _syncPulseAnimation(context);
    }
  }

  Future<void> _handleAction(Future<void> Function()? cb) async {
    if (cb == null || _busy) return;
    setState(() => _busy = true);
    try {
      await cb();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  IconData get _biometricIcon => switch (_c.biometricType) {
        BiometricType.fingerprint => Icons.fingerprint,
        BiometricType.face => Icons.face,
        BiometricType.iris => Icons.visibility_outlined,
      };

  String get _biometricLabel => switch (_c.biometricType) {
        BiometricType.fingerprint => 'Fingerprint',
        BiometricType.face => 'Face ID',
        BiometricType.iris => 'Iris',
      };

  String get _titleText => switch (widget.status) {
        BiometricEnrollmentStatus.notEnrolled =>
          _c.title ?? '$_biometricLabel Not Enabled',
        BiometricEnrollmentStatus.awaitingScan =>
            'Use your device security prompt',
        BiometricEnrollmentStatus.scanning => 'Sample saved',
        BiometricEnrollmentStatus.enrolling => 'Saving…',
        BiometricEnrollmentStatus.enrolled =>
          _c.successTitle ?? '$_biometricLabel Enabled',
        BiometricEnrollmentStatus.error => 'Enrollment Failed',
      };

  String get _subtitleText => switch (widget.status) {
        BiometricEnrollmentStatus.notEnrolled =>
          _c.subtitle ??
              '$_biometricLabel is not enabled on this device. '
                  'Enable it to use biometric authentication.',
        BiometricEnrollmentStatus.awaitingScan =>
            'A secure system window will appear. Follow the instructions '
            'there; this screen only shows progress '
            '(step ${widget.scanProgress + 1} of ${widget.totalScans}).',
        BiometricEnrollmentStatus.scanning =>
          _c.enrollingText ??
              'Finishing this step before the next prompt…',
        BiometricEnrollmentStatus.enrolling =>
          'Saving enrollment…',
        BiometricEnrollmentStatus.enrolled =>
          _c.successSubtitle ??
              '$_biometricLabel has been enabled successfully. '
                  'You can now proceed with biometric verification.',
        BiometricEnrollmentStatus.error =>
          _c.errorText ??
              'Failed to enable $_biometricLabel. '
                  'Please try again or open device settings.',
      };

  bool get _isActive =>
      widget.status == BiometricEnrollmentStatus.scanning ||
      widget.status == BiometricEnrollmentStatus.enrolling;

  bool get _awaitingSystemPrompt =>
      widget.status == BiometricEnrollmentStatus.awaitingScan;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final theme = context.securitySuiteTheme;

    final isError = widget.status == BiometricEnrollmentStatus.error;
    final isEnrolled = widget.status == BiometricEnrollmentStatus.enrolled;
    final isScanning = widget.status == BiometricEnrollmentStatus.scanning;
    final ringColor = isError
        ? colors.error
        : isEnrolled
            ? colors.success
            : (theme?.scanRingColor ?? colors.primary);
    final outerSize = theme?.scanRingOuterSize ??
        Responsive.value<double>(context, xs: 172, md: 200, lg: 224);
    final innerSize = theme?.scanRingInnerSize ??
        Responsive.value<double>(context, xs: 92, md: 110, lg: 124);
    final iconSize = theme?.scanRingIconSize ??
        Responsive.value<double>(context, xs: 42, md: 52, lg: 60);
    final ringProgress = _awaitingSystemPrompt
        ? 0.45
        : (_isActive ? _pulseCtrl.value : 0.5);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Column(
        children: [
          SizedBox(height: spacing.md),

          const SecurityBadge(),
          SizedBox(height: spacing.lg),

          AppText.headlineMedium(
            _titleText,
            textAlign: TextAlign.center,
          ),
          const VSpace.sm(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.sm),
            child: AppText.bodyMedium(
              _subtitleText,
              textAlign: TextAlign.center,
              color: isError ? colors.error : colors.textSecondary,
            ),
          ),

          const Spacer(flex: 2),

          SizedBox(
            width: outerSize,
            height: outerSize,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) => CustomPaint(
                painter: ScanRingPainter(
                  progress: ringProgress,
                  ringColor: ringColor,
                ),
                child: child,
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    color: ringColor.withValues(
                      alpha: isScanning
                          ? 0.15
                          : _awaitingSystemPrompt
                              ? 0.05
                              : 0.07,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ringColor.withValues(
                        alpha: _awaitingSystemPrompt ? 0.15 : 0.25,
                      ),
                      width: 2,
                    ),
                    boxShadow: [
                      if (_isActive)
                        BoxShadow(
                          color: ringColor.withValues(alpha: 0.2),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                    ],
                  ),
                  child: Icon(
                    isEnrolled
                        ? Icons.check
                        : _awaitingSystemPrompt
                            ? Icons.shield_outlined
                            : _biometricIcon,
                    size: iconSize,
                    color: ringColor.withValues(
                      alpha: _awaitingSystemPrompt ? 0.65 : 1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_awaitingSystemPrompt) ...[
            SizedBox(height: spacing.md),
            AppText.bodySmall(
              'The fingerprint or face icon in the system dialog is the real check, not the ring above.',
              textAlign: TextAlign.center,
              color: colors.textSecondary,
            ),
          ],

          if (_isActive || isEnrolled || _awaitingSystemPrompt) ...[
            SizedBox(height: spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.totalScans, (i) {
                final done = i < widget.scanProgress ||
                    isEnrolled ||
                    widget.status == BiometricEnrollmentStatus.enrolling;
                final active = i == widget.scanProgress &&
                    (isScanning || _awaitingSystemPrompt);
                return Container(
                  width: active ? 24 : 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: done
                        ? ringColor
                        : active
                            ? ringColor.withValues(alpha: 0.6)
                            : ringColor.withValues(alpha: 0.15),
                  ),
                );
              }),
            ),
          ],

          const Spacer(flex: 3),

          if (widget.status == BiometricEnrollmentStatus.notEnrolled) ...[
            AppButton.primary(
              text: _c.enrollLabel ?? 'Enable $_biometricLabel',
              leadingIcon: _biometricIcon,
              isLoading: _busy,
              isFullWidth: true,
              onPressed: widget.onEnroll == null
                  ? null
                  : () => _handleAction(widget.onEnroll),
            ),
            if (widget.onOpenSettings != null) ...[
              const VSpace.sm(),
              AppButton.ghost(
                text: _c.settingsLabel ?? 'Open Device Settings',
                onPressed: _busy ? null : widget.onOpenSettings,
              ),
            ],
            if (widget.onCancel != null) ...[
              const VSpace.sm(),
              AppButton.ghost(
                text: _c.cancelLabel ?? 'Cancel',
                onPressed: _busy ? null : widget.onCancel,
              ),
            ],
          ],

          if (_isActive)
            Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.sm),
              child: LinearProgressIndicator(
                value: widget.status == BiometricEnrollmentStatus.enrolling
                    ? null
                    : widget.scanProgress / widget.totalScans,
              ),
            ),

          if (isError) ...[
            AppButton.primary(
              text: _c.retryLabel ?? 'Retry',
              leadingIcon: _biometricIcon,
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

          if (isEnrolled) ...[
            AppButton.primary(
              text: _c.continueLabel ?? 'Continue to Verification',
              isFullWidth: true,
              onPressed: widget.onContinue == null
                  ? null
                  : () => _handleAction(widget.onContinue),
            ),
          ],

          SizedBox(height: spacing.xl),
        ],
      ),
    );
  }
}
