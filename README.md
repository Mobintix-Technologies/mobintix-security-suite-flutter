[![pub package](https://img.shields.io/pub/v/mobintix_security_suite.svg)](https://pub.dev/packages/mobintix_security_suite)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

# Mobintix Security Suite

Flutter widgets and models for **MPIN**, **OTP**, **device biometrics**, and **face** flows—styled with [mobintix_ui_kit](https://pub.dev/packages/mobintix_ui_kit). Use **JSON-driven** steps via `SecurityFlowHost`, or drop in **standalone** views with typed configs.

**Install from [pub.dev](https://pub.dev/packages/mobintix_security_suite).** The canonical GitHub repository for this package may be **private**; **bugs, questions, and feature requests** from integrators should go to [**Issues on the public demo app**](https://github.com/Mobintix-Package/mobintix_security_suite_demo/issues).

**Reference implementation:** clone the public **[mobintix_security_suite_demo](https://github.com/Mobintix-Package/mobintix_security_suite_demo)** — Firestore-driven multi-step challenges, `SecuritySuiteTheme`, camera / ML Kit face preview, and `local_auth`. Its `pubspec.yaml` pins the same major package lines as below.

---

## Features

- **Flow orchestration** — Parse `SecurityFlowResponse.fromJson`, render with `SecurityFlowHost` and `SecurityFlowActions`.
- **Standalone widgets** — `MpinView`, `OtpView`, `BiometricView`, `FaceDetectionView` (and enrollment/registration views) without the flow host.
- **Typed configs** — `MpinConfig`, `OtpConfig`, `BiometricConfig`, `FaceDetectionConfig`; host-owned steps use `CustomStepConfig` + `customStepBuilder`.
- **Theming** — No hard-coded branding: tokens from `mobintix_ui_kit` plus optional `SecuritySuiteTheme` on `ThemeData.extensions`.
- **Platform helpers** — Camera preview and ML Kit wiring exports for face flows (see **Dependencies** and platform notes).

---

## Compatibility

| Item | Version |
|------|---------|
| Dart SDK | `^3.2.0` |
| Flutter | `>=3.16.0` |
| mobintix_ui_kit (peer) | `^0.0.4` (declared in this package’s dependencies) |

---

## Installation

```yaml
dependencies:
  mobintix_security_suite: ^0.0.1
```

Then:

```bash
flutter pub get
```

You do **not** need to add `mobintix_ui_kit` separately for compilation—it is pulled in as a **direct dependency** of this package. You **do** need `AppThemeScope` (from `mobintix_ui_kit`) around your app so suite widgets can read design tokens.

---

## Dependencies (direct)

| Package | Purpose |
|---------|---------|
| [mobintix_ui_kit](https://pub.dev/packages/mobintix_ui_kit) | Design tokens, `AppThemeScope`, shared widgets (`PinDots`, `NumericKeypad`, buttons, etc.). |
| [equatable](https://pub.dev/packages/equatable) | Value equality for models. |
| [uuid](https://pub.dev/packages/uuid) | Re-exported for convenience (`Uuid`); use in host/session code if useful. |
| [camera](https://pub.dev/packages/camera) | Live camera preview for face flows. |
| [google_mlkit_commons](https://pub.dev/packages/google_mlkit_commons) / [google_mlkit_face_detection](https://pub.dev/packages/google_mlkit_face_detection) | Face detection pipeline helpers (mobile-focused). |
| [local_auth](https://pub.dev/packages/local_auth) | Re-exported (with `BiometricType` hidden to avoid clashing with suite enum); device biometric prompts. |

**Platform notes:** Camera and ML Kit face detection are aimed at **iOS/Android**. Web/desktop behavior depends on your integration; the demo documents fallbacks. Configure platform permissions (camera, Face ID usage strings) in the host app.

---

## Re-exports

This library exports selected symbols so you can import one package:

- `package:uuid/uuid.dart` → `Uuid`
- `package:local_auth/local_auth.dart` → hide `BiometricType` (suite defines its own `BiometricType` for UI config)

---

## Getting started

### 1. Theme

```dart
import 'package:flutter/material.dart';
import 'package:mobintix_security_suite/mobintix_security_suite.dart';
import 'package:mobintix_ui_kit/mobintix_ui_kit.dart';

void main() {
  final appTheme = AppTheme.light();
  runApp(
    AppThemeScope(
      theme: appTheme,
      child: MaterialApp(
        theme: appTheme.toThemeData().copyWith(
          extensions: const <ThemeExtension<dynamic>>[
            SecuritySuiteTheme(
              scanRingColor: Color(0xFF1565C0),
              timerActiveColor: Color(0xFF1565C0),
            ),
          ],
        ),
        home: const YourSecurityScreen(),
      ),
    ),
  );
}
```

### 2. JSON-driven flow

```json
{
  "schemaVersion": 1,
  "flowId": "login_abc",
  "step": "otp",
  "params": {
    "title": "Verification code",
    "otpLength": 6,
    "channel": "sms",
    "resendCooldownSec": 30
  }
}
```

```dart
final flow = SecurityFlowResponse.fromJson(jsonMap);

SecurityFlowHost(
  flow: flow,
  actions: SecurityFlowActions(
    onMpinComplete: (pin) async => api.verifyMpin(pin),
    onForgotPin: () async { /* … */ },
    onOtpComplete: (otp) async => api.verifyOtp(otp),
    onOtpResend: () async => api.resendOtp(),
    onBiometric: () async => localAuth.authenticate(),
    onBiometricEnroll: () async { /* enrollment flow */ },
    onFaceCapture: () async { /* face verify */ },
    onFaceRegister: () async { /* face enroll */ },
    onAlternate: () async => api.switchMethod(),
  ),
  cameraPreviewBuilder: (context) => YourCameraPreview(),
  customStepBuilder: (flow) {
    // device_binding, session_warning, done, unknown
    final data = (flow.config as CustomStepConfig).data;
    return YourHostStepWidget(title: data['title'] as String?);
  },
);
```

### 3. Standalone widget (no JSON)

```dart
MpinView(
  config: const MpinConfig(mpinLength: 6, isCreate: true),
  onComplete: (pin) async => verify(pin),
);
```

---

## Step IDs (`step` in JSON)

| `step` value | Built-in UI | Notes |
|--------------|-------------|--------|
| `mpin` | Yes | `MpinConfig` from `params`. |
| `otp` | Yes | `OtpConfig`. |
| `biometric` | Yes | `BiometricConfig`. |
| `face_detection` | Yes | `FaceDetectionConfig`; supply `cameraPreviewBuilder` on `SecurityFlowHost`. |
| `device_binding`, `session_warning`, `done`, unknown | No | Provide `customStepBuilder`; params map to `CustomStepConfig`. |

Aliases: `step` accepts hyphen or underscore (e.g. `face_detection`).

---

## Development (monorepo)

If you clone the Mobintix monorepo and develop this package next to `mobintix_ui_kit`, use a **dependency override** in a consuming app (see the demo’s `pubspec_overrides.yaml.example`). The **published** `pubspec.yaml` must not use `path:` or `git:` dependencies.

---

## Testing

```bash
flutter pub get
flutter analyze
flutter test
```

---

## Documentation

- **[Publishing guide](doc/PUBLISHING_GUIDE.md)** — pub.dev, trusted publishing, private repo notes.
- **Demo app** — [mobintix_security_suite_demo](https://github.com/Mobintix-Package/mobintix_security_suite_demo)

---

## License

MIT
