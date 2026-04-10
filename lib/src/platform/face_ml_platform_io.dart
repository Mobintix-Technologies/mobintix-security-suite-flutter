import 'dart:io' show Platform;

bool get isFaceMlKitSupported => Platform.isAndroid || Platform.isIOS;

bool get isAndroidCameraFormatNv21 => Platform.isAndroid;
