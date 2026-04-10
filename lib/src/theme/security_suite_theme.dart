import 'package:flutter/material.dart';

/// Host-app-configurable theme tokens for security suite widgets.
///
/// Add to your [ThemeData]:
/// ```dart
/// ThemeData(
///   extensions: [
///     SecuritySuiteTheme(
///       pinActiveColor: colorScheme.primary,
///       scanRingColor: colorScheme.tertiary,
///       cameraPlaceholderColor: colorScheme.surfaceContainerHighest,
///     ),
///   ],
/// )
/// ```
@immutable
class SecuritySuiteTheme extends ThemeExtension<SecuritySuiteTheme> {
  const SecuritySuiteTheme({
    this.pinActiveColor,
    this.pinErrorColor,
    this.timerActiveColor,
    this.timerUrgentColor,
    this.timerTrackColor,
    this.scanRingColor,
    this.badgeColor,
    this.faceGuideColor,
    this.faceOverlayColor,
    this.cameraPlaceholderColor,
    this.cameraLiveIndicatorColor,
    this.cameraFaceDetectedColor,
    this.cameraFaceMissingColor,
    this.cameraOverlayTextColor,
    this.processingOverlayColor,
    this.successCheckColor,
    this.cameraViewRadius,
    this.scanRingOuterSize,
    this.scanRingInnerSize,
    this.scanRingIconSize,
  });

  // --- PIN & OTP ---
  final Color? pinActiveColor;
  final Color? pinErrorColor;
  final Color? timerActiveColor;
  final Color? timerUrgentColor;
  final Color? timerTrackColor;

  // --- Biometric scan ring ---
  final Color? scanRingColor;

  // --- Badge ---
  final Color? badgeColor;

  // --- Face guide ---
  final Color? faceGuideColor;
  final Color? faceOverlayColor;

  // --- Camera UI ---
  final Color? cameraPlaceholderColor;
  final Color? cameraLiveIndicatorColor;
  final Color? cameraFaceDetectedColor;
  final Color? cameraFaceMissingColor;
  final Color? cameraOverlayTextColor;

  // --- Processing overlays ---
  final Color? processingOverlayColor;
  final Color? successCheckColor;

  // --- Sizing ---
  final double? cameraViewRadius;
  final double? scanRingOuterSize;
  final double? scanRingInnerSize;
  final double? scanRingIconSize;

  @override
  SecuritySuiteTheme copyWith({
    Color? pinActiveColor,
    Color? pinErrorColor,
    Color? timerActiveColor,
    Color? timerUrgentColor,
    Color? timerTrackColor,
    Color? scanRingColor,
    Color? badgeColor,
    Color? faceGuideColor,
    Color? faceOverlayColor,
    Color? cameraPlaceholderColor,
    Color? cameraLiveIndicatorColor,
    Color? cameraFaceDetectedColor,
    Color? cameraFaceMissingColor,
    Color? cameraOverlayTextColor,
    Color? processingOverlayColor,
    Color? successCheckColor,
    double? cameraViewRadius,
    double? scanRingOuterSize,
    double? scanRingInnerSize,
    double? scanRingIconSize,
  }) {
    return SecuritySuiteTheme(
      pinActiveColor: pinActiveColor ?? this.pinActiveColor,
      pinErrorColor: pinErrorColor ?? this.pinErrorColor,
      timerActiveColor: timerActiveColor ?? this.timerActiveColor,
      timerUrgentColor: timerUrgentColor ?? this.timerUrgentColor,
      timerTrackColor: timerTrackColor ?? this.timerTrackColor,
      scanRingColor: scanRingColor ?? this.scanRingColor,
      badgeColor: badgeColor ?? this.badgeColor,
      faceGuideColor: faceGuideColor ?? this.faceGuideColor,
      faceOverlayColor: faceOverlayColor ?? this.faceOverlayColor,
      cameraPlaceholderColor:
          cameraPlaceholderColor ?? this.cameraPlaceholderColor,
      cameraLiveIndicatorColor:
          cameraLiveIndicatorColor ?? this.cameraLiveIndicatorColor,
      cameraFaceDetectedColor:
          cameraFaceDetectedColor ?? this.cameraFaceDetectedColor,
      cameraFaceMissingColor:
          cameraFaceMissingColor ?? this.cameraFaceMissingColor,
      cameraOverlayTextColor:
          cameraOverlayTextColor ?? this.cameraOverlayTextColor,
      processingOverlayColor:
          processingOverlayColor ?? this.processingOverlayColor,
      successCheckColor: successCheckColor ?? this.successCheckColor,
      cameraViewRadius: cameraViewRadius ?? this.cameraViewRadius,
      scanRingOuterSize: scanRingOuterSize ?? this.scanRingOuterSize,
      scanRingInnerSize: scanRingInnerSize ?? this.scanRingInnerSize,
      scanRingIconSize: scanRingIconSize ?? this.scanRingIconSize,
    );
  }

  @override
  SecuritySuiteTheme lerp(SecuritySuiteTheme? other, double t) {
    if (other is! SecuritySuiteTheme) return this;
    return SecuritySuiteTheme(
      pinActiveColor: Color.lerp(pinActiveColor, other.pinActiveColor, t),
      pinErrorColor: Color.lerp(pinErrorColor, other.pinErrorColor, t),
      timerActiveColor:
          Color.lerp(timerActiveColor, other.timerActiveColor, t),
      timerUrgentColor:
          Color.lerp(timerUrgentColor, other.timerUrgentColor, t),
      timerTrackColor: Color.lerp(timerTrackColor, other.timerTrackColor, t),
      scanRingColor: Color.lerp(scanRingColor, other.scanRingColor, t),
      badgeColor: Color.lerp(badgeColor, other.badgeColor, t),
      faceGuideColor: Color.lerp(faceGuideColor, other.faceGuideColor, t),
      faceOverlayColor:
          Color.lerp(faceOverlayColor, other.faceOverlayColor, t),
      cameraPlaceholderColor:
          Color.lerp(cameraPlaceholderColor, other.cameraPlaceholderColor, t),
      cameraLiveIndicatorColor: Color.lerp(
          cameraLiveIndicatorColor, other.cameraLiveIndicatorColor, t),
      cameraFaceDetectedColor: Color.lerp(
          cameraFaceDetectedColor, other.cameraFaceDetectedColor, t),
      cameraFaceMissingColor:
          Color.lerp(cameraFaceMissingColor, other.cameraFaceMissingColor, t),
      cameraOverlayTextColor:
          Color.lerp(cameraOverlayTextColor, other.cameraOverlayTextColor, t),
      processingOverlayColor:
          Color.lerp(processingOverlayColor, other.processingOverlayColor, t),
      successCheckColor:
          Color.lerp(successCheckColor, other.successCheckColor, t),
      cameraViewRadius:
          _lerpDouble(cameraViewRadius, other.cameraViewRadius, t),
      scanRingOuterSize:
          _lerpDouble(scanRingOuterSize, other.scanRingOuterSize, t),
      scanRingInnerSize:
          _lerpDouble(scanRingInnerSize, other.scanRingInnerSize, t),
      scanRingIconSize:
          _lerpDouble(scanRingIconSize, other.scanRingIconSize, t),
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b)! * (1.0 - t) + (b ?? a)! * t;
  }
}

extension SecuritySuiteThemeContext on BuildContext {
  SecuritySuiteTheme? get securitySuiteTheme =>
      Theme.of(this).extension<SecuritySuiteTheme>();
}
