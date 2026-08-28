import 'package:flutter/material.dart';
import '../../models/character.dart';

class CharacterPainter extends CustomPainter {
  final CharacterAppearance appearance;
  final bool isMirror;

  const CharacterPainter({required this.appearance, this.isMirror = false});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final skinColor = _skinColor(appearance.skinTone);
    final hairColor = _hairColor(appearance.hairColor);
    final accentColor = isMirror ? const Color(0xFFEC4899) : const Color(0xFF6366F1);

    _drawBody(canvas, size, cx, skinColor, accentColor);
    _drawHead(canvas, cx, skinColor);
    _drawHair(canvas, cx, hairColor, appearance.hairStyle);
    _drawFace(canvas, cx, skinColor);

    if (appearance.muscleLevel > 0.3) {
      _drawMuscleLines(canvas, size, cx, skinColor, appearance.muscleLevel);
    }
  }

  void _drawBody(Canvas canvas, Size size, double cx, Color skin, Color accent) {
    final bodyPaint = Paint()..color = skin;
    final outfitPaint = Paint()..color = accent;

    // Body shape varies with fat/muscle
    final fatScale = 0.8 + appearance.fatLevel * 0.4;
    final bodyW = 50.0 * fatScale;

    // Torso
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, size.height * 0.62),
          width: bodyW,
          height: size.height * 0.28),
      const Radius.circular(16),
    );
    canvas.drawRRect(torsoRect, outfitPaint);

    // Arms
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - bodyW / 2 - 14, size.height * 0.5, 14, size.height * 0.22),
          const Radius.circular(7)),
      Paint()..color = skin,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + bodyW / 2, size.height * 0.5, 14, size.height * 0.22),
          const Radius.circular(7)),
      Paint()..color = skin,
    );

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 20, size.height * 0.75, 18, size.height * 0.23),
          const Radius.circular(9)),
      Paint()..color = const Color(0xFF374151),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 2, size.height * 0.75, 18, size.height * 0.23),
          const Radius.circular(9)),
      Paint()..color = const Color(0xFF374151),
    );

    // Neck
    canvas.drawRect(
      Rect.fromLTWH(cx - 8, size.height * 0.45, 16, size.height * 0.07),
      bodyPaint,
    );
  }

  void _drawHead(Canvas canvas, double cx, Color skin) {
    final headPaint = Paint()..color = skin;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 60), width: 76, height: 84),
      headPaint,
    );
  }

  void _drawHair(Canvas canvas, double cx, Color color, HairStyle style) {
    final paint = Paint()..color = color;
    switch (style) {
      case HairStyle.short:
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, 45), width: 80, height: 50),
            paint);
      case HairStyle.medium:
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, 48), width: 84, height: 60),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(cx - 42, 60, 14, 30), paint);
        canvas.drawRect(
            Rect.fromLTWH(cx + 28, 60, 14, 30), paint);
      case HairStyle.long:
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, 50), width: 84, height: 60),
            paint);
        canvas.drawRect(
            Rect.fromLTWH(cx - 42, 55, 14, 80), paint);
        canvas.drawRect(
            Rect.fromLTWH(cx + 28, 55, 14, 80), paint);
      case HairStyle.bun:
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, 50), width: 80, height: 50),
            paint);
        canvas.drawCircle(Offset(cx, 18), 18, paint);
      case HairStyle.ponytail:
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, 50), width: 80, height: 50),
            paint);
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + 40, 60), width: 12, height: 40),
            paint);
      case HairStyle.curly:
        final curlyPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round;
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, 50), width: 88, height: 58),
            paint);
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(Offset(cx - 36 + i * 18.0, 38), 8, curlyPaint);
        }
    }
  }

  void _drawFace(Canvas canvas, double cx, Color skin) {
    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1F2937);
    canvas.drawCircle(Offset(cx - 14, 62), 5, eyePaint);
    canvas.drawCircle(Offset(cx + 14, 62), 5, eyePaint);

    // Eye shine
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - 12, 60), 2, shinePaint);
    canvas.drawCircle(Offset(cx + 16, 60), 2, shinePaint);

    // Mouth
    final mouthPath = Path()
      ..moveTo(cx - 10, 76)
      ..quadraticBezierTo(cx, 84, cx + 10, 76);
    canvas.drawPath(
        mouthPath,
        Paint()
          ..color = const Color(0xFF1F2937)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);

    // Blush
    final blushPaint = Paint()
      ..color = const Color(0xFFFFB3C1).withOpacity(0.6);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 24, 72), width: 18, height: 10), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 24, 72), width: 18, height: 10), blushPaint);
  }

  void _drawMuscleLines(Canvas canvas, Size size, double cx, Color skin,
      double level) {
    final linePaint = Paint()
      ..color = skin.withOpacity(0.4 + level * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // Simple abs lines
    for (var i = 0; i < 3; i++) {
      final y = size.height * 0.55 + i * 12.0;
      canvas.drawLine(Offset(cx - 15, y), Offset(cx + 15, y), linePaint);
      canvas.drawLine(Offset(cx, y), Offset(cx, y + 10), linePaint);
    }
  }

  Color _skinColor(SkinTone tone) {
    switch (tone) {
      case SkinTone.light: return const Color(0xFFFDE8D8);
      case SkinTone.medium: return const Color(0xFFF5C5A3);
      case SkinTone.tan: return const Color(0xFFD4956A);
      case SkinTone.dark: return const Color(0xFF8D5524);
    }
  }

  Color _hairColor(HairColor color) {
    switch (color) {
      case HairColor.black: return const Color(0xFF1A1A1A);
      case HairColor.brown: return const Color(0xFF6B3A2A);
      case HairColor.blonde: return const Color(0xFFE8C46A);
      case HairColor.red: return const Color(0xFFB22222);
      case HairColor.gray: return const Color(0xFF9E9E9E);
      case HairColor.fantasy: return const Color(0xFF8B5CF6);
    }
  }

  @override
  bool shouldRepaint(CharacterPainter old) =>
      old.appearance != appearance || old.isMirror != isMirror;
}
