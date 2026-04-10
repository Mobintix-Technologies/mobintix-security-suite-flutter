library;

// Re-exported deps (so host apps need only depend on this package)
export 'package:local_auth/local_auth.dart' hide BiometricType;
export 'package:uuid/uuid.dart';

// Models
export 'src/models/security_flow_step_id.dart';
export 'src/models/security_step_config.dart';

// Theme
export 'src/theme/security_suite_theme.dart';

// Shared
export 'src/shared/painters.dart';
export 'src/shared/step_indicator.dart';
export 'src/shared/security_badge.dart';

// Platform (camera, ML Kit, biometric helpers)
export 'src/platform/face_ml_platform.dart';
export 'src/platform/ml_kit_input_image.dart';
export 'src/platform/live_camera_preview.dart';

// Features (standalone widgets)
export 'src/mpin/mpin_view.dart';
export 'src/otp/otp_view.dart';
export 'src/biometric/biometric_view.dart';
export 'src/biometric/biometric_enrollment_view.dart';
export 'src/face_detection/face_detection_view.dart';
export 'src/face_detection/face_registration_view.dart';

// Flow orchestrator (optional)
export 'src/flow/security_flow_response.dart';
export 'src/flow/security_flow_actions.dart';
export 'src/flow/security_flow_host.dart';
export 'src/flow/security_flow_json.dart';
