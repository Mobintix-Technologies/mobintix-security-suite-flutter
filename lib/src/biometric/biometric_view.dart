import 'package:flutter/material.dart';
import 'package:mobintix_ui_kit/mobintix_ui_kit.dart';

import '../models/security_step_config.dart';
import '../shared/painters.dart';
import '../shared/security_badge.dart';
import '../theme/security_suite_theme.dart';

IconData _biometricIconData(BiometricType type) {
  switch (type) {
    case BiometricType.fingerprint:
      return Icons.fingerprint;
    case BiometricType.face:
      return Icons.face;
    case BiometricType.iris:
      return Icons.visibility_outlined;
  }
}

class BiometricView extends StatefulWidget {
  const BiometricView({
    super.key,
    this.config = const BiometricConfig(),
    this.onPrimary,
    this.onAlternate,
  });

  final BiometricConfig config;
  final Future<void> Function()? onPrimary;
  final Future<void> Function()? onAlternate;

  @override
  State<BiometricView> createState() => _BiometricViewState();
}

class _BiometricViewState extends State<BiometricView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  var _busy = false;

  BiometricConfig get _c => widget.config;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (_c.autoTrigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _authenticate();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = Responsive.shouldReduceMotion(context);
    final runPulse = !_busy && !reduce;
    if (runPulse && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!runPulse && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
    if (!runPulse) {
      _pulseCtrl.value = _busy ? 0.45 : 0.5;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final cb = widget.onPrimary;
    if (cb == null || _busy) return;
    setState(() => _busy = true);
    _pulseCtrl.stop();
    _pulseCtrl.value = 0.45;
    try {
      await cb();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final reduce = Responsive.shouldReduceMotion(context);
          if (!reduce && !_pulseCtrl.isAnimating) {
            _pulseCtrl.repeat(reverse: true);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final theme = context.securitySuiteTheme;

    final title = _c.title ?? 'Biometric sign-in';
    final subtitle = _c.subtitle ??
        'Tap Authenticate below. Your phone will open its own security '
            'window—that prompt is the real fingerprint or Face ID check. '
            'This screen only starts that flow.';
    final hasError = _c.errorText != null;
    final iconData = _biometricIconData(_c.biometricType);
    final ringColor =
        hasError ? colors.error : (theme?.scanRingColor ?? colors.primary);
    final outerSize = theme?.scanRingOuterSize ??
        Responsive.value<double>(context, xs: 160, md: 180, lg: 200);
    final innerSize = theme?.scanRingInnerSize ??
        Responsive.value<double>(context, xs: 80, md: 96, lg: 110);
    final iconSize = theme?.scanRingIconSize ??
        Responsive.value<double>(context, xs: 36, md: 44, lg: 52);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const SecurityBadge(),
          SizedBox(height: spacing.lg),
          AppText.headlineMedium(title, textAlign: TextAlign.center),
          const VSpace.sm(),
          AppText.bodyMedium(
            subtitle,
            textAlign: TextAlign.center,
            color: colors.textSecondary,
          ),
          if (_busy) ...[
            const VSpace.sm(),
            AppText.bodySmall(
              'Complete the system security prompt when it appears. '
              'You can dismiss this message by finishing that step.',
              textAlign: TextAlign.center,
              color: colors.primary,
            ),
          ],
          if (hasError) ...[
            const VSpace.sm(),
            AppText.bodySmall(
              _c.errorText!,
              textAlign: TextAlign.center,
              color: colors.error,
            ),
          ],
          SizedBox(height: spacing.xl),
          GestureDetector(
            onTap: widget.onPrimary == null || _busy ? null : _authenticate,
            child: Semantics(
              label: 'Start device biometric prompt',
              button: true,
              excludeSemantics: true,
              child: SizedBox(
                width: outerSize,
                height: outerSize,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) => CustomPaint(
                    painter: ScanRingPainter(
                      progress: _pulseCtrl.value,
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
                          alpha: _busy ? 0.05 : 0.07,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ringColor.withValues(
                            alpha: _busy ? 0.12 : 0.18,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (!_busy)
                            BoxShadow(
                              color: ringColor.withValues(alpha: 0.12),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Icon(
                        _busy ? Icons.shield_outlined : iconData,
                        size: iconSize,
                        color: ringColor.withValues(alpha: _busy ? 0.7 : 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: spacing.sm),
          AppText.labelSmall(
            _busy
                ? 'Waiting for system biometric…'
                : 'Or tap the circle — same as the button.',
            textAlign: TextAlign.center,
            color: colors.textSecondary,
          ),
          const Spacer(flex: 3),
          AppButton.primary(
            text: _c.primaryLabel ?? 'Authenticate',
            leadingIcon: iconData,
            isLoading: _busy,
            isFullWidth: true,
            onPressed: widget.onPrimary == null ? null : _authenticate,
          ),
          if (_c.alternateLabel != null && widget.onAlternate != null) ...[
            const VSpace.md(),
            AppButton.ghost(
              text: _c.alternateLabel!,
              onPressed: _busy ? null : () async => widget.onAlternate!(),
            ),
          ],
          SizedBox(height: spacing.xl),
        ],
      ),
    );
  }
}
