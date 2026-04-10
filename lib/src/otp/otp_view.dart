import 'package:flutter/material.dart';
import 'package:mobintix_ui_kit/mobintix_ui_kit.dart';

import '../models/security_step_config.dart';
import '../shared/painters.dart';
import '../theme/security_suite_theme.dart';

class OtpView extends StatefulWidget {
  const OtpView({
    super.key,
    this.config = const OtpConfig(),
    this.onComplete,
    this.onResend,
    this.onAlternate,
  });

  final OtpConfig config;
  final Future<void> Function(String otp)? onComplete;
  final Future<void> Function()? onResend;
  final Future<void> Function()? onAlternate;

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView>
    with SingleTickerProviderStateMixin {
  var _otp = '';
  var _busy = false;
  var _canResend = false;
  var _resendCount = 0;
  late AnimationController _timerController;

  OtpConfig get _c => widget.config;
  bool get _useTextField => _c.inputMode == PinInputMode.textField;

  Duration get _currentCooldown {
    final idx = _resendCount.clamp(0, _c.cooldownEscalation.length - 1);
    return _c.cooldownEscalation[idx];
  }

  bool get _maxResendReached => _resendCount >= _c.maxResendCount;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: _currentCooldown,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_maxResendReached) {
          setState(() => _canResend = true);
        }
      });
    _timerController.forward();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_otp.length >= _c.otpLength || _busy) return;
    setState(() => _otp += digit);
    if (_otp.length == _c.otpLength) {
      _submit(_otp);
    }
  }

  void _onBackspace() {
    if (_otp.isEmpty || _busy) return;
    setState(() => _otp = _otp.substring(0, _otp.length - 1));
  }

  Future<void> _submit(String otp) async {
    final cb = widget.onComplete;
    if (cb == null || _busy) return;
    setState(() => _busy = true);
    try {
      await cb(otp);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _otp = '';
        });
      }
    }
  }

  Future<void> _resend() async {
    final cb = widget.onResend;
    if (cb == null || _busy || !_canResend || _maxResendReached) return;
    setState(() {
      _busy = true;
      _canResend = false;
      _resendCount++;
    });
    try {
      await cb();
      setState(() => _otp = '');
      final newCooldown = _currentCooldown;
      _timerController
        ..duration = newCooldown
        ..forward(from: 0.0);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final title = _c.title ?? 'Verification code';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: spacing.lg),
            child: Column(
              children: [
                SizedBox(height: spacing.xxxl),
                AppText.headlineMedium(title, textAlign: TextAlign.center),
                if (_c.subtitle != null) ...[
                  const VSpace.sm(),
                  AppText.bodyMedium(
                    _c.subtitle!,
                    textAlign: TextAlign.center,
                    color: colors.textSecondary,
                  ),
                ],
                if (_c.channel != null) ...[
                  const VSpace.xs(),
                  AppText.bodySmall(
                    'Sent via ${_c.channel}',
                    textAlign: TextAlign.center,
                    color: colors.textDisabled,
                  ),
                ],
                SizedBox(height: spacing.xxl),
                if (_useTextField)
                  PinInput(
                    key: const ValueKey('otp_text_input'),
                    length: _c.otpLength,
                    obscureText: false,
                    autofocus: true,
                    errorText: _c.errorText,
                    onCompleted: _submit,
                  )
                else ...[
                  PinDots(
                    length: _c.otpLength,
                    filledCount: _otp.length,
                    hasError: _c.errorText != null,
                    shape: _c.pinDotShape,
                  ),
                  if (_c.errorText != null) ...[
                    const VSpace.sm(),
                    AppText.bodySmall(
                      _c.errorText!,
                      textAlign: TextAlign.center,
                      color: colors.error,
                    ),
                  ],
                ],
                const VSpace.xl(),
                AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, _) {
                    final progress = 1.0 - _timerController.value;
                    final remainingMs =
                        (_currentCooldown.inMilliseconds * progress).round();
                    final remaining = Duration(milliseconds: remainingMs);
                    return _c.timerStyle == OtpTimerStyle.text
                        ? _OtpTextTimer(
                            remaining: remaining,
                            prefix: _c.timerPrefix,
                          )
                        : _OtpCircularTimer(
                            progress: progress,
                            remaining: remaining,
                          );
                  },
                ),
                const VSpace.md(),
                _buildResendRow(colors),
                if (_c.alternateLabel != null &&
                    widget.onAlternate != null) ...[
                  const VSpace.md(),
                  GestureDetector(
                    onTap: _busy ? null : () async => widget.onAlternate!(),
                    child: AppText.bodyMedium(
                      _c.alternateLabel!,
                      textAlign: TextAlign.center,
                      color: _busy ? colors.textDisabled : colors.primary,
                    ),
                  ),
                ],
                if (_busy) ...[
                  const VSpace.lg(),
                  const Center(child: LoadingIndicator()),
                ],
              ],
            ),
          ),
        ),
        if (_c.noteText != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.xl,
              vertical: spacing.xs,
            ),
            child: AppText.bodySmall(
              _c.noteText!,
              textAlign: TextAlign.center,
              color: colors.textSecondary,
            ),
          ),
        if (!_useTextField)
          Padding(
            padding: EdgeInsets.only(
              left: spacing.lg,
              right: spacing.lg,
              bottom: spacing.md,
            ),
            child: NumericKeypad(
              onDigit: _onDigit,
              onBackspace: _onBackspace,
              style: KeypadStyle(buttonShape: _c.keypadButtonShape),
            ),
          ),
      ],
    );
  }

  Widget _buildResendRow(AppColors colors) {
    if (_maxResendReached) {
      return Semantics(
        label: _c.maxReachedText ?? 'Maximum resend attempts reached',
        child: AppText.bodySmall(
          _c.maxReachedText ?? 'Maximum resend attempts reached',
          textAlign: TextAlign.center,
          color: colors.textDisabled,
        ),
      );
    }

    final prompt = _c.resendPromptText ?? "Didn't receive OTP yet? ";
    final action = _c.resendActionText ?? 'Resend now';
    final canTap = _canResend && !_busy;

    return Semantics(
      label: canTap ? '$prompt$action' : prompt,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodySmall(prompt, color: colors.textSecondary),
          GestureDetector(
            onTap: canTap ? _resend : null,
            child: AppText.bodySmall(
              action,
              color: canTap ? colors.primary : colors.textDisabled,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OTP circular countdown (ring)
// ---------------------------------------------------------------------------

class _OtpCircularTimer extends StatelessWidget {
  const _OtpCircularTimer({
    required this.progress,
    required this.remaining,
  });

  final double progress;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = context.securitySuiteTheme;
    final totalSeconds = (remaining.inMilliseconds / 1000).ceil();
    final isUrgent = totalSeconds <= 10 && totalSeconds > 0;

    final activeColor = isUrgent
        ? (theme?.timerUrgentColor ?? colors.error)
        : (theme?.timerActiveColor ?? colors.primary);
    final trackColor = theme?.timerTrackColor ?? colors.border;

    final timerSize = Responsive.value<double>(
      context,
      xs: 80.0,
      md: 96.0,
      lg: 112.0,
    );
    final strokeWidth = Responsive.value<double>(
      context,
      xs: 3.5,
      md: 4.0,
      lg: 4.5,
    );

    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    final timeText = '$m:$s';

    return Semantics(
      label: 'Time remaining: $timeText',
      child: SizedBox(
        width: timerSize,
        height: timerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(timerSize, timerSize),
              painter: TimerRingPainter(
                progress: progress,
                activeColor: activeColor,
                trackColor: trackColor,
                strokeWidth: strokeWidth,
              ),
            ),
            Text(
              timeText,
              style: TextStyle(
                fontSize: timerSize * 0.22,
                fontWeight: FontWeight.w700,
                color: activeColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OTP inline text countdown
// ---------------------------------------------------------------------------

class _OtpTextTimer extends StatelessWidget {
  const _OtpTextTimer({
    required this.remaining,
    this.prefix,
  });

  final Duration remaining;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = context.securitySuiteTheme;
    final bodyStyle = context.bodyMediumStyle;
    final totalSeconds = (remaining.inMilliseconds / 1000).ceil();
    final isUrgent = totalSeconds <= 10 && totalSeconds > 0;

    final activeColor = isUrgent
        ? (theme?.timerUrgentColor ?? colors.error)
        : (theme?.timerActiveColor ?? colors.textSecondary);

    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    final label = prefix ?? 'Code expires in';

    return Semantics(
      label: '$label $m:$s',
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: bodyStyle.copyWith(color: colors.textSecondary),
            ),
            TextSpan(
              text: '$m:$s',
              style: bodyStyle.copyWith(
                color: activeColor,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
