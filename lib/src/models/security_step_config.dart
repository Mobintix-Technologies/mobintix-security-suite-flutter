import 'package:equatable/equatable.dart';
import 'package:mobintix_ui_kit/mobintix_ui_kit.dart';

import 'security_flow_step_id.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum BiometricType {
  fingerprint,
  face,
  iris;

  static BiometricType parse(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'face':
      case 'face_id':
      case 'faceid':
        return BiometricType.face;
      case 'iris':
        return BiometricType.iris;
      default:
        return BiometricType.fingerprint;
    }
  }
}

enum FaceDetectionStatus {
  ready,
  scanning,
  aligning,
  captured,
  error,
}

enum OtpTimerStyle {
  /// Circular ring countdown (default).
  circular,

  /// Inline text countdown: "Code expires in 04:58".
  text,
}

enum PinInputMode {
  /// Visual dots + custom numeric keypad (default).
  keypad,

  /// Individual text fields with the system keyboard.
  textField,
}

enum FaceRegistrationStatus {
  notRegistered,
  scanning,
  registering,
  registered,
  error,
}

enum BiometricEnrollmentStatus {
  notEnrolled,

  /// Waiting for user to place finger / look at sensor.
  awaitingScan,

  /// Sensor detected input — scanning in progress.
  scanning,

  /// Processing/saving the enrolled data.
  enrolling,

  enrolled,
  error,
}

// ---------------------------------------------------------------------------
// JSON → enum helpers (private)
// ---------------------------------------------------------------------------

PinDotShape _parsePinDotShape(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'rounded_rect':
    case 'roundedrect':
    case 'rect':
    case 'box':
      return PinDotShape.roundedRect;
    case 'underline':
    case 'line':
      return PinDotShape.underline;
    default:
      return PinDotShape.circle;
  }
}

PinInputMode _parseInputMode(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'text_field':
    case 'textfield':
    case 'text':
    case 'keyboard':
      return PinInputMode.textField;
    default:
      return PinInputMode.keypad;
  }
}

OtpTimerStyle _parseTimerStyle(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'text':
    case 'inline':
      return OtpTimerStyle.text;
    default:
      return OtpTimerStyle.circular;
  }
}

KeypadButtonShape _parseKeypadShape(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'circle':
      return KeypadButtonShape.circle;
    case 'stadium':
    case 'pill':
      return KeypadButtonShape.stadium;
    case 'square':
      return KeypadButtonShape.square;
    default:
      return KeypadButtonShape.roundedRect;
  }
}

List<Duration> _parseDurationList(dynamic raw, List<Duration> fallback) {
  if (raw is List && raw.isNotEmpty) {
    return raw
        .whereType<num>()
        .map((e) => Duration(seconds: e.toInt()))
        .toList();
  }
  return fallback;
}

bool _boolFromJson(Map<String, dynamic> json, String camel, String snake) {
  final v = json[camel] ?? json[snake];
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

int? _intFromJson(Map<String, dynamic> json, String camel, String snake) {
  final v = json[camel] ?? json[snake];
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

String? _strFromJson(Map<String, dynamic> json, String camel, String snake) =>
    json[camel] as String? ?? json[snake] as String?;

// ---------------------------------------------------------------------------
// Sealed base
// ---------------------------------------------------------------------------

sealed class SecurityStepConfig extends Equatable {
  const SecurityStepConfig();

  factory SecurityStepConfig.fromJson(
    SecurityFlowStepId step,
    Map<String, dynamic> json,
  ) {
    return switch (step) {
      SecurityFlowStepId.mpin => MpinConfig.fromJson(json),
      SecurityFlowStepId.otp => OtpConfig.fromJson(json),
      SecurityFlowStepId.biometric => BiometricConfig.fromJson(json),
      SecurityFlowStepId.faceDetection => FaceDetectionConfig.fromJson(json),
      SecurityFlowStepId.deviceBinding ||
      SecurityFlowStepId.sessionWarning ||
      SecurityFlowStepId.done ||
      SecurityFlowStepId.unknown =>
        CustomStepConfig.fromJson(json),
    };
  }

  Map<String, dynamic> toJson();
}

// ---------------------------------------------------------------------------
// MPIN
// ---------------------------------------------------------------------------

class MpinConfig extends SecurityStepConfig {
  const MpinConfig({
    this.isCreate = false,
    this.mpinLength = 4,
    this.title,
    this.subtitle,
    this.pinLabel,
    this.confirmLabel,
    this.forgotLabel,
    this.noteText,
    this.errorText,
    this.pinDotShape = PinDotShape.circle,
    this.keypadButtonShape = KeypadButtonShape.roundedRect,
    this.keypadStyle,
    this.showBiometricButton = false,
    this.inputMode = PinInputMode.keypad,
  });

  final bool isCreate;
  final int mpinLength;
  final String? title;
  final String? subtitle;
  final String? pinLabel;
  final String? confirmLabel;
  final String? forgotLabel;
  final String? noteText;
  final String? errorText;
  final PinDotShape pinDotShape;
  final KeypadButtonShape keypadButtonShape;

  /// Full keypad style override. When provided, [keypadButtonShape] is ignored
  /// and the shape from this style is used instead.
  final KeypadStyle? keypadStyle;
  final bool showBiometricButton;

  /// [PinInputMode.keypad] shows PinDots + NumericKeypad (default).
  /// [PinInputMode.textField] shows PinInput text fields + system keyboard.
  final PinInputMode inputMode;

  factory MpinConfig.fromJson(Map<String, dynamic> json) {
    return MpinConfig(
      isCreate: _boolFromJson(json, 'isCreate', 'is_create'),
      mpinLength: _intFromJson(json, 'mpinLength', 'mpin_length') ?? 4,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      pinLabel: _strFromJson(json, 'pinLabel', 'pin_label'),
      confirmLabel: _strFromJson(json, 'confirmLabel', 'confirm_label'),
      forgotLabel: _strFromJson(json, 'forgotLabel', 'forgot_label'),
      noteText: _strFromJson(json, 'noteText', 'note_text'),
      errorText: _strFromJson(json, 'errorText', 'error_text'),
      pinDotShape: _parsePinDotShape(
        json['pinDotShape'] as String? ?? json['pin_dot_shape'] as String?,
      ),
      keypadButtonShape: _parseKeypadShape(
        json['keypadShape'] as String? ?? json['keypad_shape'] as String?,
      ),
      showBiometricButton:
          _boolFromJson(json, 'showBiometricButton', 'show_biometric_button'),
      inputMode: _parseInputMode(
        json['inputMode'] as String? ?? json['input_mode'] as String?,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'isCreate': isCreate,
        'mpinLength': mpinLength,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (pinLabel != null) 'pinLabel': pinLabel,
        if (confirmLabel != null) 'confirmLabel': confirmLabel,
        if (forgotLabel != null) 'forgotLabel': forgotLabel,
        if (noteText != null) 'noteText': noteText,
        if (errorText != null) 'errorText': errorText,
        'pinDotShape': pinDotShape.name,
        'keypadShape': keypadButtonShape.name,
        'showBiometricButton': showBiometricButton,
        'inputMode': inputMode.name,
      };

  @override
  List<Object?> get props => [
        isCreate,
        mpinLength,
        title,
        subtitle,
        pinLabel,
        confirmLabel,
        forgotLabel,
        noteText,
        errorText,
        pinDotShape,
        keypadButtonShape,
        showBiometricButton,
        inputMode,
      ];
}

// ---------------------------------------------------------------------------
// OTP
// ---------------------------------------------------------------------------

class OtpConfig extends SecurityStepConfig {
  const OtpConfig({
    this.otpLength = 6,
    this.title,
    this.subtitle,
    this.channel,
    this.cooldownEscalation = const [
      Duration(seconds: 30),
      Duration(minutes: 3),
      Duration(minutes: 8),
    ],
    this.maxResendCount = 3,
    this.errorText,
    this.alternateLabel,
    this.pinDotShape = PinDotShape.roundedRect,
    this.keypadButtonShape = KeypadButtonShape.roundedRect,
    this.resendPromptText,
    this.resendActionText,
    this.maxReachedText,
    this.noteText,
    this.timerStyle = OtpTimerStyle.circular,
    this.timerPrefix,
    this.inputMode = PinInputMode.keypad,
  });

  final int otpLength;
  final String? title;
  final String? subtitle;
  final String? channel;
  final List<Duration> cooldownEscalation;
  final int maxResendCount;
  final String? errorText;
  final String? alternateLabel;
  final PinDotShape pinDotShape;
  final KeypadButtonShape keypadButtonShape;
  final String? resendPromptText;
  final String? resendActionText;
  final String? maxReachedText;

  /// Informational note shown above the keypad (e.g. security advice).
  final String? noteText;

  /// Timer display style: [OtpTimerStyle.circular] (ring) or
  /// [OtpTimerStyle.text] (inline "Code expires in MM:SS").
  final OtpTimerStyle timerStyle;

  /// Custom prefix for the text timer (defaults to "Code expires in").
  final String? timerPrefix;

  /// [PinInputMode.keypad] shows PinDots + NumericKeypad (default).
  /// [PinInputMode.textField] shows PinInput text fields + system keyboard.
  final PinInputMode inputMode;

  factory OtpConfig.fromJson(Map<String, dynamic> json) {
    final resendCooldownSec = _intFromJson(
          json,
          'resendCooldownSec',
          'resend_cooldown_sec',
        ) ??
        30;
    return OtpConfig(
      otpLength: _intFromJson(json, 'otpLength', 'otp_length') ?? 6,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      channel: json['channel'] as String?,
      cooldownEscalation: _parseDurationList(
        json['cooldownEscalation'],
        [
          Duration(seconds: resendCooldownSec),
          const Duration(minutes: 3),
          const Duration(minutes: 8),
        ],
      ),
      maxResendCount:
          _intFromJson(json, 'maxResendCount', 'max_resend_count') ?? 3,
      errorText: _strFromJson(json, 'errorText', 'error_text'),
      alternateLabel:
          _strFromJson(json, 'alternateLabel', 'alternate_label'),
      pinDotShape: _parsePinDotShape(
        json['otpDotShape'] as String? ?? json['otp_dot_shape'] as String?,
      ),
      keypadButtonShape: _parseKeypadShape(
        json['keypadShape'] as String? ?? json['keypad_shape'] as String?,
      ),
      resendPromptText: json['resendPromptText'] as String?,
      resendActionText: json['resendActionText'] as String?,
      maxReachedText: json['maxReachedText'] as String?,
      noteText: _strFromJson(json, 'noteText', 'note_text'),
      timerStyle: _parseTimerStyle(
        json['timerStyle'] as String? ?? json['timer_style'] as String?,
      ),
      timerPrefix: _strFromJson(json, 'timerPrefix', 'timer_prefix'),
      inputMode: _parseInputMode(
        json['inputMode'] as String? ?? json['input_mode'] as String?,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'otpLength': otpLength,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (channel != null) 'channel': channel,
        'cooldownEscalation':
            cooldownEscalation.map((d) => d.inSeconds).toList(),
        'maxResendCount': maxResendCount,
        if (errorText != null) 'errorText': errorText,
        if (alternateLabel != null) 'alternateLabel': alternateLabel,
        'otpDotShape': pinDotShape.name,
        'keypadShape': keypadButtonShape.name,
        if (resendPromptText != null) 'resendPromptText': resendPromptText,
        if (resendActionText != null) 'resendActionText': resendActionText,
        if (maxReachedText != null) 'maxReachedText': maxReachedText,
        if (noteText != null) 'noteText': noteText,
        'timerStyle': timerStyle.name,
        if (timerPrefix != null) 'timerPrefix': timerPrefix,
        'inputMode': inputMode.name,
      };

  @override
  List<Object?> get props => [
        otpLength,
        title,
        subtitle,
        channel,
        cooldownEscalation,
        maxResendCount,
        errorText,
        alternateLabel,
        pinDotShape,
        keypadButtonShape,
        resendPromptText,
        resendActionText,
        maxReachedText,
        noteText,
        timerStyle,
        timerPrefix,
        inputMode,
      ];
}

// ---------------------------------------------------------------------------
// Biometric
// ---------------------------------------------------------------------------

class BiometricConfig extends SecurityStepConfig {
  const BiometricConfig({
    this.title,
    this.subtitle,
    this.errorText,
    this.biometricType = BiometricType.fingerprint,
    this.primaryLabel,
    this.autoTrigger = false,
    this.alternateLabel,
  });

  final String? title;
  final String? subtitle;
  final String? errorText;
  final BiometricType biometricType;
  final String? primaryLabel;
  final bool autoTrigger;
  final String? alternateLabel;

  factory BiometricConfig.fromJson(Map<String, dynamic> json) {
    return BiometricConfig(
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      errorText: json['errorText'] as String?,
      biometricType: BiometricType.parse(json['biometricType'] as String?),
      primaryLabel: json['primaryLabel'] as String?,
      autoTrigger: json['autoTrigger'] as bool? ?? false,
      alternateLabel: json['alternateLabel'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (errorText != null) 'errorText': errorText,
        'biometricType': biometricType.name,
        if (primaryLabel != null) 'primaryLabel': primaryLabel,
        'autoTrigger': autoTrigger,
        if (alternateLabel != null) 'alternateLabel': alternateLabel,
      };

  @override
  List<Object?> get props => [
        title,
        subtitle,
        errorText,
        biometricType,
        primaryLabel,
        autoTrigger,
        alternateLabel,
      ];
}

// ---------------------------------------------------------------------------
// Biometric enrollment
// ---------------------------------------------------------------------------

class BiometricEnrollmentConfig extends SecurityStepConfig {
  const BiometricEnrollmentConfig({
    this.biometricType = BiometricType.fingerprint,
    this.title,
    this.subtitle,
    this.enrollingText,
    this.successTitle,
    this.successSubtitle,
    this.errorText,
    this.enrollLabel,
    this.retryLabel,
    this.continueLabel,
    this.cancelLabel,
    this.settingsLabel,
  });

  final BiometricType biometricType;
  final String? title;
  final String? subtitle;
  final String? enrollingText;
  final String? successTitle;
  final String? successSubtitle;
  final String? errorText;
  final String? enrollLabel;
  final String? retryLabel;
  final String? continueLabel;
  final String? cancelLabel;

  /// Label for the "Open Settings" action when user needs to enable
  /// biometrics at the OS level.
  final String? settingsLabel;

  factory BiometricEnrollmentConfig.fromJson(Map<String, dynamic> json) {
    return BiometricEnrollmentConfig(
      biometricType: BiometricType.parse(json['biometricType'] as String?),
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      enrollingText: json['enrollingText'] as String?,
      successTitle: json['successTitle'] as String?,
      successSubtitle: json['successSubtitle'] as String?,
      errorText: json['errorText'] as String?,
      enrollLabel: json['enrollLabel'] as String?,
      retryLabel: json['retryLabel'] as String?,
      continueLabel: json['continueLabel'] as String?,
      cancelLabel: json['cancelLabel'] as String?,
      settingsLabel: json['settingsLabel'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'biometricType': biometricType.name,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (enrollingText != null) 'enrollingText': enrollingText,
        if (successTitle != null) 'successTitle': successTitle,
        if (successSubtitle != null) 'successSubtitle': successSubtitle,
        if (errorText != null) 'errorText': errorText,
        if (enrollLabel != null) 'enrollLabel': enrollLabel,
        if (retryLabel != null) 'retryLabel': retryLabel,
        if (continueLabel != null) 'continueLabel': continueLabel,
        if (cancelLabel != null) 'cancelLabel': cancelLabel,
        if (settingsLabel != null) 'settingsLabel': settingsLabel,
      };

  @override
  List<Object?> get props => [
        biometricType,
        title,
        subtitle,
        enrollingText,
        successTitle,
        successSubtitle,
        errorText,
        enrollLabel,
        retryLabel,
        continueLabel,
        cancelLabel,
        settingsLabel,
      ];
}

// ---------------------------------------------------------------------------
// Face detection
// ---------------------------------------------------------------------------

class FaceDetectionConfig extends SecurityStepConfig {
  const FaceDetectionConfig({
    this.title,
    this.subtitle,
    this.instructionText,
    this.capturedText,
    this.errorText,
    this.primaryLabel,
    this.retryLabel,
    this.alternateLabel,
  });

  final String? title;
  final String? subtitle;
  final String? instructionText;
  final String? capturedText;
  final String? errorText;
  final String? primaryLabel;
  final String? retryLabel;
  final String? alternateLabel;

  factory FaceDetectionConfig.fromJson(Map<String, dynamic> json) {
    return FaceDetectionConfig(
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      instructionText: json['instructionText'] as String?,
      capturedText: json['capturedText'] as String?,
      errorText: json['errorText'] as String?,
      primaryLabel: json['primaryLabel'] as String?,
      retryLabel: json['retryLabel'] as String?,
      alternateLabel: json['alternateLabel'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (instructionText != null) 'instructionText': instructionText,
        if (capturedText != null) 'capturedText': capturedText,
        if (errorText != null) 'errorText': errorText,
        if (primaryLabel != null) 'primaryLabel': primaryLabel,
        if (retryLabel != null) 'retryLabel': retryLabel,
        if (alternateLabel != null) 'alternateLabel': alternateLabel,
      };

  @override
  List<Object?> get props => [
        title,
        subtitle,
        instructionText,
        capturedText,
        errorText,
        primaryLabel,
        retryLabel,
        alternateLabel,
      ];
}

// ---------------------------------------------------------------------------
// Face registration
// ---------------------------------------------------------------------------

class FaceRegistrationConfig extends SecurityStepConfig {
  const FaceRegistrationConfig({
    this.title,
    this.subtitle,
    this.scanningText,
    this.registeringText,
    this.successTitle,
    this.successSubtitle,
    this.errorText,
    this.registerLabel,
    this.retryLabel,
    this.continueLabel,
    this.cancelLabel,
  });

  final String? title;
  final String? subtitle;
  final String? scanningText;
  final String? registeringText;
  final String? successTitle;
  final String? successSubtitle;
  final String? errorText;
  final String? registerLabel;
  final String? retryLabel;
  final String? continueLabel;
  final String? cancelLabel;

  factory FaceRegistrationConfig.fromJson(Map<String, dynamic> json) {
    return FaceRegistrationConfig(
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      scanningText: json['scanningText'] as String?,
      registeringText: json['registeringText'] as String?,
      successTitle: json['successTitle'] as String?,
      successSubtitle: json['successSubtitle'] as String?,
      errorText: json['errorText'] as String?,
      registerLabel: json['registerLabel'] as String?,
      retryLabel: json['retryLabel'] as String?,
      continueLabel: json['continueLabel'] as String?,
      cancelLabel: json['cancelLabel'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (scanningText != null) 'scanningText': scanningText,
        if (registeringText != null) 'registeringText': registeringText,
        if (successTitle != null) 'successTitle': successTitle,
        if (successSubtitle != null) 'successSubtitle': successSubtitle,
        if (errorText != null) 'errorText': errorText,
        if (registerLabel != null) 'registerLabel': registerLabel,
        if (retryLabel != null) 'retryLabel': retryLabel,
        if (continueLabel != null) 'continueLabel': continueLabel,
        if (cancelLabel != null) 'cancelLabel': cancelLabel,
      };

  @override
  List<Object?> get props => [
        title,
        subtitle,
        scanningText,
        registeringText,
        successTitle,
        successSubtitle,
        errorText,
        registerLabel,
        retryLabel,
        continueLabel,
        cancelLabel,
      ];
}

// ---------------------------------------------------------------------------
// Custom (catch-all for host-app-owned steps like deviceBinding, done, etc.)
// ---------------------------------------------------------------------------

class CustomStepConfig extends SecurityStepConfig {
  const CustomStepConfig({this.data = const {}});

  final Map<String, dynamic> data;

  factory CustomStepConfig.fromJson(Map<String, dynamic> json) =>
      CustomStepConfig(data: json);

  @override
  Map<String, dynamic> toJson() => data;

  @override
  List<Object?> get props => [data];
}
