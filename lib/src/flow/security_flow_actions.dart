class SecurityFlowActions {
  const SecurityFlowActions({
    this.onMpinComplete,
    this.onForgotPin,
    this.onOtpComplete,
    this.onOtpResend,
    this.onBiometric,
    this.onBiometricEnroll,
    this.onFaceCapture,
    this.onFaceRegister,
    this.onAlternate,
  });

  final Future<void> Function(String pin)? onMpinComplete;
  final Future<void> Function()? onForgotPin;
  final Future<void> Function(String otp)? onOtpComplete;
  final Future<void> Function()? onOtpResend;
  final Future<void> Function()? onBiometric;

  /// Called when user needs to enroll biometrics before verification.
  final Future<void> Function()? onBiometricEnroll;

  final Future<void> Function()? onFaceCapture;

  /// Called when user needs to register their face before verification.
  final Future<void> Function()? onFaceRegister;

  final Future<void> Function()? onAlternate;
}
