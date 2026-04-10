import 'package:flutter/material.dart';
import 'package:mobintix_ui_kit/mobintix_ui_kit.dart';

import '../models/security_step_config.dart';
import '../shared/step_indicator.dart';

enum _MpinPhase { enter, confirm }

class MpinView extends StatefulWidget {
  const MpinView({
    super.key,
    this.config = const MpinConfig(),
    this.onComplete,
    this.onForgotPin,
    this.onBiometric,
  });

  final MpinConfig config;
  final Future<void> Function(String pin)? onComplete;
  final Future<void> Function()? onForgotPin;
  final Future<void> Function()? onBiometric;

  @override
  State<MpinView> createState() => _MpinViewState();
}

class _MpinViewState extends State<MpinView> {
  var _pin = '';
  var _firstPin = '';
  var _phase = _MpinPhase.enter;
  var _busy = false;
  String? _localError;

  MpinConfig get _c => widget.config;
  bool get _useTextField => _c.inputMode == PinInputMode.textField;

  @override
  void initState() {
    super.initState();
    _phase = _MpinPhase.enter;
  }

  void _onDigit(String digit) {
    if (_pin.length >= _c.mpinLength || _busy) return;
    setState(() => _pin += digit);
    if (_pin.length == _c.mpinLength) {
      _handlePinComplete(_pin);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty || _busy) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _localError = null;
    });
  }

  void _handlePinComplete(String pin) {
    if (!_c.isCreate) {
      _submit(pin);
      return;
    }
    if (_phase == _MpinPhase.enter) {
      setState(() {
        _firstPin = pin;
        _pin = '';
        _phase = _MpinPhase.confirm;
        _localError = null;
      });
    } else {
      if (pin == _firstPin) {
        _submit(pin);
      } else {
        setState(() {
          _pin = '';
          _localError = 'PINs do not match. Try again.';
          _phase = _MpinPhase.enter;
          _firstPin = '';
        });
      }
    }
  }

  Future<void> _submit(String pin) async {
    final cb = widget.onComplete;
    if (cb == null || _busy) return;
    setState(() => _busy = true);
    try {
      await cb(pin);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _pin = '';
          _firstPin = '';
          _phase = _MpinPhase.enter;
        });
      }
    }
  }

  String get _currentLabel {
    if (!_c.isCreate) {
      return _c.pinLabel ?? 'Enter your ${_c.mpinLength}-digit MPIN';
    }
    if (_phase == _MpinPhase.enter) {
      return _c.pinLabel ?? 'Create your ${_c.mpinLength}-digit MPIN';
    }
    return _c.confirmLabel ?? 'Confirm your ${_c.mpinLength}-digit MPIN';
  }

  String? get _displayError => _localError ?? _c.errorText;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final title = _c.title ?? (_c.isCreate ? 'Create MPIN' : 'Verify MPIN');

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: spacing.lg),
            child: Column(
              children: [
                SizedBox(height: spacing.xxxl),
                AppText.headlineMedium(
                  title,
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
                SizedBox(height: spacing.xxl),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: AppText.titleSmall(
                    _currentLabel,
                    key: ValueKey(_currentLabel),
                    textAlign: TextAlign.center,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const VSpace.lg(),
                if (_useTextField)
                  PinInput(
                    key: ValueKey('pin_input_${_phase.name}'),
                    length: _c.mpinLength,
                    obscureText: true,
                    autofocus: true,
                    errorText: _displayError,
                    onCompleted: _handlePinComplete,
                  )
                else ...[
                  PinDots(
                    length: _c.mpinLength,
                    filledCount: _pin.length,
                    hasError: _displayError != null,
                    shape: _c.pinDotShape,
                  ),
                  if (_displayError != null) ...[
                    const VSpace.sm(),
                    AppText.bodySmall(
                      _displayError!,
                      textAlign: TextAlign.center,
                      color: colors.error,
                    ),
                  ],
                ],
                if (_c.isCreate && _phase == _MpinPhase.confirm) ...[
                  const VSpace.sm(),
                  StepIndicator(
                    current: 2,
                    total: 2,
                    activeColor: colors.primary,
                    inactiveColor: colors.border,
                  ),
                ] else if (_c.isCreate) ...[
                  const VSpace.sm(),
                  StepIndicator(
                    current: 1,
                    total: 2,
                    activeColor: colors.primary,
                    inactiveColor: colors.border,
                  ),
                ],
                if (!_c.isCreate && widget.onForgotPin != null) ...[
                  const VSpace.md(),
                  GestureDetector(
                    onTap: _busy ? null : () => widget.onForgotPin!(),
                    child: AppText.bodyMedium(
                      _c.forgotLabel ?? 'Forgot MPIN?',
                      textAlign: TextAlign.center,
                      color: colors.primary,
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
              style: _c.keypadStyle ??
                  KeypadStyle(buttonShape: _c.keypadButtonShape),
              onBiometric: widget.onBiometric != null && !_busy
                  ? () => widget.onBiometric!()
                  : null,
            ),
          ),
      ],
    );
  }
}
