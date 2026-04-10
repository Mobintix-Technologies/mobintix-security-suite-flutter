import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Web: ML Kit input from camera stream is not used.
InputImage? buildMlKitInputImage({
  required CameraImage image,
  required CameraController? controller,
  required List<CameraDescription> cameras,
  required int cameraIndex,
}) =>
    null;
