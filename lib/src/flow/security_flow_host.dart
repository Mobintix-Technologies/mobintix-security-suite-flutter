import 'package:flutter/material.dart';
import 'package:mobintix_ui_kit/mobintix_ui_kit.dart';

import '../biometric/biometric_view.dart';
import '../face_detection/face_detection_view.dart';
import '../models/security_flow_step_id.dart';
import '../models/security_step_config.dart';
import '../mpin/mpin_view.dart';
import '../otp/otp_view.dart';
import 'security_flow_actions.dart';
import 'security_flow_response.dart';

class SecurityFlowHost extends StatelessWidget {
  const SecurityFlowHost({
    super.key,
    required this.flow,
    required this.actions,
    this.cameraPreviewBuilder,
    this.customStepBuilder,
  });

  final SecurityFlowResponse flow;
  final SecurityFlowActions actions;

  /// Provides a camera preview widget for face detection steps.
  final Widget Function(BuildContext context)? cameraPreviewBuilder;

  /// Builds UI for steps the library doesn't own
  /// (deviceBinding, sessionWarning, done, or any unknown step).
  final Widget Function(SecurityFlowResponse flow)? customStepBuilder;

  @override
  Widget build(BuildContext context) {
    switch (flow.step) {
      case SecurityFlowStepId.mpin:
        final c = flow.config as MpinConfig;
        return MpinView(
          key: ValueKey('${flow.flowId}_mpin_${c.isCreate}'),
          config: c,
          onComplete: actions.onMpinComplete,
          onForgotPin: actions.onForgotPin,
          // Biometric shortcut is for verify MPIN only; it must not hijack create+confirm.
          onBiometric:
              c.showBiometricButton && !c.isCreate ? actions.onBiometric : null,
        );
      case SecurityFlowStepId.otp:
        return OtpView(
          key: ValueKey('${flow.flowId}_otp'),
          config: flow.config as OtpConfig,
          onComplete: actions.onOtpComplete,
          onResend: actions.onOtpResend,
          onAlternate: actions.onAlternate,
        );
      case SecurityFlowStepId.biometric:
        return BiometricView(
          key: ValueKey('${flow.flowId}_bio'),
          config: flow.config as BiometricConfig,
          onPrimary: actions.onBiometric,
          onAlternate: actions.onAlternate,
        );
      case SecurityFlowStepId.faceDetection:
        return FaceDetectionView(
          key: ValueKey('${flow.flowId}_face'),
          config: flow.config as FaceDetectionConfig,
          cameraPreview:
              cameraPreviewBuilder?.call(context) ?? const SizedBox.shrink(),
          onCapture: actions.onFaceCapture,
          onAlternate: actions.onAlternate,
        );
      case SecurityFlowStepId.deviceBinding:
      case SecurityFlowStepId.sessionWarning:
      case SecurityFlowStepId.done:
      case SecurityFlowStepId.unknown:
        if (customStepBuilder != null) {
          return customStepBuilder!(flow);
        }
        return ErrorState(
          title: 'Unsupported step',
          description:
              'Provide a customStepBuilder for step "${flow.step.toApiValue()}".',
        );
    }
  }
}
