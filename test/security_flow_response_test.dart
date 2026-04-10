import 'package:flutter_test/flutter_test.dart';
import 'package:mobintix_security_suite/mobintix_security_suite.dart';

void main() {
  group('SecurityFlowResponse', () {
    test('parses step aliases and params into typed config', () {
      final r = SecurityFlowResponse.fromJson(const {
        'schemaVersion': 2,
        'flowId': 'login',
        'currentStep': 'device_binding',
        'params': {'title': 'Bind'},
        'theme': {'isDark': true},
      });
      expect(r.schemaVersion, 2);
      expect(r.flowId, 'login');
      expect(r.step, SecurityFlowStepId.deviceBinding);
      expect(r.config, isA<CustomStepConfig>());
      expect((r.config as CustomStepConfig).data['title'], 'Bind');
      expect(r.themeJson?['isDark'], true);
    });

    test('toJson round trip for otp', () {
      const original = SecurityFlowResponse(
        schemaVersion: 1,
        flowId: 'x',
        step: SecurityFlowStepId.otp,
        config: OtpConfig(otpLength: 8),
      );
      final again = SecurityFlowResponse.fromJson(original.toJson());
      expect(again, original);
    });

    test('parse unknown step', () {
      final r = SecurityFlowResponse.fromJson(const {'step': 'nope'});
      expect(r.step, SecurityFlowStepId.unknown);
      expect(r.config, isA<CustomStepConfig>());
    });

    test('fromJson string helper', () {
      final r = securityFlowResponseFromJsonString(
        '{"step":"otp","params":{"otpLength":5}}',
      );
      expect(r.step, SecurityFlowStepId.otp);
      expect(r.config, isA<OtpConfig>());
      expect((r.config as OtpConfig).otpLength, 5);
    });

    test('parse face_detection step', () {
      final r = SecurityFlowResponse.fromJson(const {
        'step': 'face_detection',
        'params': {'title': 'Verify face'},
      });
      expect(r.step, SecurityFlowStepId.faceDetection);
      expect(r.config, isA<FaceDetectionConfig>());
      expect((r.config as FaceDetectionConfig).title, 'Verify face');
    });

    test('MpinConfig fromJson with defaults', () {
      final config = MpinConfig.fromJson(const {});
      expect(config.isCreate, false);
      expect(config.mpinLength, 4);
      expect(config.showBiometricButton, false);
    });

    test('MpinConfig accepts snake_case create + length from API/Firestore',
        () {
      final config = MpinConfig.fromJson(const {
        'is_create': true,
        'mpin_length': 6,
        'show_biometric_button': true,
        'confirm_label': 'Re-enter PIN',
      });
      expect(config.isCreate, true);
      expect(config.mpinLength, 6);
      expect(config.showBiometricButton, true);
      expect(config.confirmLabel, 'Re-enter PIN');
    });

    test('OtpConfig accepts snake_case length', () {
      final config = OtpConfig.fromJson(const {
        'otp_length': 8,
        'resend_cooldown_sec': 45,
      });
      expect(config.otpLength, 8);
      expect(config.cooldownEscalation.first, const Duration(seconds: 45));
    });

    test('BiometricConfig parses biometric type', () {
      final config =
          BiometricConfig.fromJson(const {'biometricType': 'face_id'});
      expect(config.biometricType, BiometricType.face);
    });

    test('deviceBinding routes to CustomStepConfig', () {
      final r = SecurityFlowResponse.fromJson(const {
        'step': 'device_binding',
        'params': {'title': 'Trust device', 'body': 'Bind now'},
      });
      expect(r.step, SecurityFlowStepId.deviceBinding);
      expect(r.config, isA<CustomStepConfig>());
      final c = r.config as CustomStepConfig;
      expect(c.data['title'], 'Trust device');
      expect(c.data['body'], 'Bind now');
    });
  });
}
