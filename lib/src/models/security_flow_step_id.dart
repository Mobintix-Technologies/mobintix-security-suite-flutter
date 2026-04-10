enum SecurityFlowStepId {
  mpin,
  otp,
  biometric,
  faceDetection,
  deviceBinding,
  sessionWarning,
  done,
  unknown;

  static const _byApi = {
    'mpin': SecurityFlowStepId.mpin,
    'otp': SecurityFlowStepId.otp,
    'biometric': SecurityFlowStepId.biometric,
    'face_detection': SecurityFlowStepId.faceDetection,
    'device_binding': SecurityFlowStepId.deviceBinding,
    'session_warning': SecurityFlowStepId.sessionWarning,
    'done': SecurityFlowStepId.done,
  };

  static SecurityFlowStepId parse(String raw) {
    final s = raw.trim().toLowerCase().replaceAll('-', '_');
    return _byApi[s] ?? SecurityFlowStepId.unknown;
  }

  String toApiValue() {
    switch (this) {
      case SecurityFlowStepId.mpin:
        return 'mpin';
      case SecurityFlowStepId.otp:
        return 'otp';
      case SecurityFlowStepId.biometric:
        return 'biometric';
      case SecurityFlowStepId.faceDetection:
        return 'face_detection';
      case SecurityFlowStepId.deviceBinding:
        return 'device_binding';
      case SecurityFlowStepId.sessionWarning:
        return 'session_warning';
      case SecurityFlowStepId.done:
        return 'done';
      case SecurityFlowStepId.unknown:
        return 'unknown';
    }
  }
}
