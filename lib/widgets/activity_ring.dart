import 'dart:math' as math;
import 'package:flutter/material.dart';

class ActivityRing extends StatelessWidget {
  final double caloriesProgress; // 0.0-1.0+
  final double goalsProgress;    // 0.0-1.0
  final double streakProgress;   // 0.0-1.0
  final double size;

  const ActivityRing({
    super.key,
    required this.caloriesProgress,
    required this.goalsProgress,
    required this.streakProgress,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ActivityRingPainter(
          caloriesProgress: caloriesProgress.clamp(0.0, 1.2),
          goalsProgress: goalsProgress.clamp(0.0, 1.0),
          streakProgress: streakProgress.clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

class _ActivityRingPainter extends CustomPainter {
  final double caloriesProgress;
  final double goalsProgress;
  final double streakProgress;

  const _ActivityRingPainter({
    required this.caloriesProgress,
    required this.goalsProgress,
    required this.streakProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.085;
    final gap = strokeWidth * 0.7;

    _drawRing(canvas, center,
        radius: size.width / 2 - strokeWidth / 2,
        progress: caloriesProgress,
        color: const Color(0xFFFF375F),
        strokeWidth: strokeWidth);

    _drawRing(canvas, center,
        radius: size.width / 2 - strokeWidth / 2 - strokeWidth - gap,
        progress: goalsProgress,
        color: const Color(0xFF30D158),
        strokeWidth: strokeWidth);

    _drawRing(canvas, center,
        radius: size.width / 2 - strokeWidth / 2 - (strokeWidth + gap) * 2,
        progress: streakProgress,
        color: const Color(0xFF0A84FF),
        strokeWidth: strokeWidth);
  }

  void _drawRing(Canvas canvas, Offset center,
      {required double radius,
      required double progress,
      required Color color,
      required double strokeWidth}) {
    // Track
    final trackPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      glowPaint,
    );

    // Ring
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      ringPaint,
    );

    // Overshoot shimmer (when > 100%)
    if (progress > 1.0) {
      final overPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * (progress - 1.0),
        false,
        overPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ActivityRingPainter old) =>
      old.caloriesProgress != caloriesProgress ||
      old.goalsProgress != goalsProgress ||
      old.streakProgress != streakProgress;
}
