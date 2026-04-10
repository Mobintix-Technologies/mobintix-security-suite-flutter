import 'dart:math' show pi;

import 'package:flutter/material.dart';

class TimerRingPainter extends CustomPainter {
  TimerRingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(TimerRingPainter old) =>
      progress != old.progress || activeColor != old.activeColor;
}

class ScanRingPainter extends CustomPainter {
  ScanRingPainter({
    required this.progress,
    required this.ringColor,
  });

  final double progress;
  final Color ringColor;

  static const _baseRadius = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center,
      44,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24)
        ..color = ringColor.withValues(alpha: 0.10 + 0.06 * progress),
    );

    _ring(canvas, center, _baseRadius + 8 + 3 * progress, 2.0,
        0.22 + 0.13 * progress);
    _ring(canvas, center, _baseRadius + 18 + 5 * progress, 1.5,
        0.11 + 0.07 * progress);
    _ring(canvas, center, _baseRadius + 28 + 7 * progress, 1.0,
        0.05 + 0.04 * progress);
  }

  void _ring(Canvas canvas, Offset c, double r, double w, double o) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = ringColor.withValues(alpha: o.clamp(0.0, 1.0)),
    );
  }

  @override
  bool shouldRepaint(ScanRingPainter old) =>
      progress != old.progress || ringColor != old.ringColor;
}

class FaceGuideOverlayPainter extends CustomPainter {
  FaceGuideOverlayPainter({
    required this.guideColor,
    required this.overlayColor,
    this.strokeWidth = 3.0,
  });

  final Color guideColor;
  final Color overlayColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.7,
      height: size.height * 0.6,
    );

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = guideColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(FaceGuideOverlayPainter old) =>
      guideColor != old.guideColor || overlayColor != old.overlayColor;
}
