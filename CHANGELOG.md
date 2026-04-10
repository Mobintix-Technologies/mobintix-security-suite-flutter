# Changelog

## 0.0.1

- Publishable on pub.dev: `mobintix_ui_kit` is a semver dependency (no path/git).
- `SecurityFlowResponse` — JSON model with `fromJson` / `toJson`.
- Typed step configs (`MpinConfig`, `OtpConfig`, `BiometricConfig`, `FaceDetectionConfig`, `CustomStepConfig`) and `SecurityFlowStepId` including `face_detection`.
- `SecurityFlowHost` — maps step to UI; `customStepBuilder` for `device_binding`, `session_warning`, `done`, `unknown`; `cameraPreviewBuilder` for face detection.
- `SecurityFlowActions` — host-injected callbacks; biometric enroll, face capture/register, alternate method.
- Standalone widgets: `MpinView`, `OtpView`, `BiometricView`, `FaceDetectionView`, plus enrollment/registration views where applicable.
- `SecuritySuiteTheme` (`ThemeExtension`) for host-controlled security UI tokens.
- Widgets themed via `mobintix_ui_kit`; README and publishing docs; issues tracked on public demo repo.
- Pub.dev **`screenshots/`** assets documented like **mobintix_ui_kit**: package README + public **mobintix_security_suite_demo** `screenshots/` folder and demo README (*Screenshot reference*).
