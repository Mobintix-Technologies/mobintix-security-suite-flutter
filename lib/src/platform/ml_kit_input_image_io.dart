import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

InputImage? buildMlKitInputImage({
  required CameraImage image,
  required CameraController? controller,
  required List<CameraDescription> cameras,
  required int cameraIndex,
}) {
  if (controller == null || cameraIndex < 0 || cameraIndex >= cameras.length) {
    return null;
  }

  final camera = cameras[cameraIndex];
  final sensorOrientation = camera.sensorOrientation;

  InputImageRotation? rotation;
  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  } else if (Platform.isAndroid) {
    const orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    var rotationCompensation = orientations[controller.value.deviceOrientation];
    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
  }
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
  if (format == null) return null;

  const androidSupportedFormats = [
    InputImageFormat.nv21,
    InputImageFormat.yv12,
    InputImageFormat.yuv_420_888,
  ];

  if ((Platform.isAndroid && !androidSupportedFormats.contains(format)) ||
      (Platform.isIOS && format != InputImageFormat.bgra8888)) {
    return null;
  }

  InputImageFormat resolvedFormat = format;
  final Uint8List bytes;

  if (image.planes.length == 1) {
    bytes = image.planes.first.bytes;
  } else if (Platform.isAndroid &&
      (format == InputImageFormat.yuv_420_888 ||
          format == InputImageFormat.yv12) &&
      image.planes.length == 3) {
    bytes = _Nv21Buffers.instance.convertYUV420ToNV21(image);
    resolvedFormat = InputImageFormat.nv21;
  } else {
    bytes = _Nv21Buffers.instance.concatenatePlanes(image);
  }

  return InputImage.fromBytes(
    bytes: bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: resolvedFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    ),
  );
}

/// Reusable NV21 / plane buffers to reduce GC during live detection.
final class _Nv21Buffers {
  _Nv21Buffers._();
  static final _Nv21Buffers instance = _Nv21Buffers._();

  Uint8List? _planeBuffer;
  Uint8List? _nv21Buffer;
  int _lastNv21Size = 0;

  Uint8List concatenatePlanes(CameraImage image) {
    final totalBytes = image.planes.fold<int>(
      0,
      (sum, plane) => sum + plane.bytes.length,
    );

    var buffer = _planeBuffer;
    if (buffer == null || buffer.length < totalBytes) {
      buffer = Uint8List(totalBytes);
      _planeBuffer = buffer;
    }
    final buf = buffer;

    var offset = 0;
    for (final plane in image.planes) {
      final bytes = plane.bytes;
      buf.setRange(offset, offset + bytes.length, bytes);
      offset += bytes.length;
    }

    if (totalBytes == buf.length) {
      return buf;
    }
    return Uint8List.sublistView(buf, 0, totalBytes);
  }

  Uint8List convertYUV420ToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final ySize = width * height;
    final uvSize = ySize ~/ 2;
    final requiredSize = ySize + uvSize;

    if (_nv21Buffer == null || _lastNv21Size != requiredSize) {
      _nv21Buffer = Uint8List(requiredSize);
      _lastNv21Size = requiredSize;
    }

    final nv21 = _nv21Buffer!;

    final yPlane = image.planes[0];
    var destIndex = 0;
    for (var row = 0; row < height; row++) {
      final srcRowStart = row * yPlane.bytesPerRow;
      nv21.setRange(destIndex, destIndex + width, yPlane.bytes, srcRowStart);
      destIndex += width;
    }

    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    var uvIndex = ySize;
    for (var row = 0; row < height ~/ 2; row++) {
      final uRowStart = row * uPlane.bytesPerRow;
      final vRowStart = row * vPlane.bytesPerRow;

      for (var col = 0; col < width ~/ 2; col++) {
        final uIndex = uRowStart + col * uvPixelStride;
        final vIndex = vRowStart + col * vPixelStride;

        nv21[uvIndex++] = vPlane.bytes[vIndex];
        nv21[uvIndex++] = uPlane.bytes[uIndex];
      }
    }

    return nv21;
  }
}
