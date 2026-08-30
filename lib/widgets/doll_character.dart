import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/character.dart';

/// Layered paper-doll character widget.
/// Architecture: each logical layer (body → outfit → hair → face → accessories)
/// is painted in order by _DollPainter. Swap any layer for a real PNG asset
/// later by wrapping in Image.asset with errorBuilder fallback.
class DollCharacterWidget extends StatelessWidget {
  final CharacterAppearance appearance;
  final String gender;
  final bool isMirror;
  final double width;
  final double height;

  const DollCharacterWidget({
    super.key,
    required this.appearance,
    required this.gender,
    this.isMirror = false,
    this.width = 180,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _DollPainter(
            appearance: appearance,
            isFemale: gender == '她' || gender == '女',
            isMirror: isMirror,
          ),
          isComplex: true,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
class _DollPainter extends CustomPainter {
  final CharacterAppearance appearance;
  final bool isFemale;
  final bool isMirror;

  const _DollPainter({
    required this.appearance,
    required this.isFemale,
    this.isMirror = false,
  });

  // ── colour helpers ────────────────────────────────────────────────────────

  Color get _skin => const {
    SkinTone.light:  Color(0xFFFAE0CC),
    SkinTone.medium: Color(0xFFF0B98A),
    SkinTone.tan:    Color(0xFFCC8050),
    SkinTone.dark:   Color(0xFF7A4020),
  }[appearance.skinTone]!;

  Color get _skinDark => _darken(_skin, 0.12);

  Color get _hairBase => const {
    HairColor.black:   Color(0xFF1C1C2E),
    HairColor.brown:   Color(0xFF5C3010),
    HairColor.blonde:  Color(0xFFE8C040),
    HairColor.red:     Color(0xFFA01010),
    HairColor.gray:    Color(0xFF909090),
    HairColor.fantasy: Color(0xFF7C3AED),
  }[appearance.hairColor]!;

  Color get _hairLight => _lighten(_hairBase, 0.18);

  // ── outfit palette ────────────────────────────────────────────────────────

  ({Color top, Color bot, Color shoe, Color trim}) get _outfit {
    switch (appearance.outfitId) {
      case 'outfit_formal_suit':
      case 'suit':
        return (top: const Color(0xFF1E293B), bot: const Color(0xFF334155),
                shoe: const Color(0xFF0F172A), trim: const Color(0xFFCBD5E1));
      case 'outfit_sundress':
      case 'dress':
        return (top: const Color(0xFFEC4899), bot: const Color(0xFFFBCFE8),
                shoe: const Color(0xFFDB2777), trim: const Color(0xFFFFF0F7));
      case 'outfit_sport_set':
      case 'sporty':
        return (top: const Color(0xFF1D4ED8), bot: const Color(0xFF1E40AF),
                shoe: const Color(0xFFEF4444), trim: const Color(0xFFBFDBFE));
      case 'outfit_kimono':
        return (top: const Color(0xFFD946EF), bot: const Color(0xFFF0ABFC),
                shoe: const Color(0xFF701A75), trim: const Color(0xFFFDF4FF));
      case 'outfit_hanfu':
        return (top: const Color(0xFF059669), bot: const Color(0xFF6EE7B7),
                shoe: const Color(0xFF064E3B), trim: const Color(0xFFECFDF5));
      case 'outfit_school_uniform':
      case 'school_uniform':
        return (top: const Color(0xFFF8FAFC), bot: const Color(0xFF1E3A5F),
                shoe: const Color(0xFF0F172A), trim: const Color(0xFF0EA5E9));
      case 'outfit_casual_hoodie':
      case 'hoodie':
        return (top: const Color(0xFF60A5FA), bot: const Color(0xFF475569),
                shoe: const Color(0xFF1E293B), trim: const Color(0xFFDBEAFE));
      case 'outfit_tshirt_white':
      case 'casual_tshirt':
        return (top: const Color(0xFFF0F9FF), bot: const Color(0xFF2563EB),
                shoe: const Color(0xFF1E3A5F), trim: const Color(0xFFBAE6FD));
      case 'outfit_mage_robe':
        return (top: const Color(0xFF4C1D95), bot: const Color(0xFF6D28D9),
                shoe: const Color(0xFF2E1065), trim: const Color(0xFFC4B5FD));
      case 'outfit_cyberpunk':
        return (top: const Color(0xFF0F172A), bot: const Color(0xFF1E293B),
                shoe: const Color(0xFF000000), trim: const Color(0xFF06B6D4));
      case 'outfit_knight_armor':
        return (top: const Color(0xFFCBD5E1), bot: const Color(0xFF94A3B8),
                shoe: const Color(0xFF334155), trim: const Color(0xFFF59E0B));
      case 'outfit_shrine_maiden':
        return (top: const Color(0xFFDC2626), bot: const Color(0xFFFEF2F2),
                shoe: const Color(0xFF1E293B), trim: const Color(0xFF7F1D1D));
      case 'outfit_ninja':
        return (top: const Color(0xFF0F172A), bot: const Color(0xFF0F172A),
                shoe: const Color(0xFF0F172A), trim: const Color(0xFF64748B));
      case 'outfit_pirate':
        return (top: const Color(0xFF7C3AED), bot: const Color(0xFF1E293B),
                shoe: const Color(0xFF292524), trim: const Color(0xFFEFB839));
      case 'outfit_chef':
        return (top: const Color(0xFFF8FAFC), bot: const Color(0xFF334155),
                shoe: const Color(0xFF1E293B), trim: const Color(0xFFCBD5E1));
      case 'outfit_space_suit':
        return (top: const Color(0xFFF8FAFC), bot: const Color(0xFFCBD5E1),
                shoe: const Color(0xFF334155), trim: const Color(0xFF0EA5E9));
      case 'outfit_denim_jacket':
        return (top: const Color(0xFF2563EB), bot: const Color(0xFF1D4ED8),
                shoe: const Color(0xFF1E293B), trim: const Color(0xFFBFDBFE));
      case 'outfit_tracksuit':
        return (top: const Color(0xFF7C3AED), bot: const Color(0xFF6D28D9),
                shoe: const Color(0xFF2E1065), trim: const Color(0xFFEDE9FE));
      case 'outfit_lab_coat':
        return (top: const Color(0xFFF8FAFC), bot: const Color(0xFF475569),
                shoe: const Color(0xFF1E293B), trim: const Color(0xFF0EA5E9));
      case 'outfit_detective':
        return (top: const Color(0xFF78350F), bot: const Color(0xFF451A03),
                shoe: const Color(0xFF1C0A00), trim: const Color(0xFFFCD34D));
      case 'outfit_egyptian':
        return (top: const Color(0xFFFBBF24), bot: const Color(0xFFF59E0B),
                shoe: const Color(0xFF92400E), trim: const Color(0xFFFEF9C3));
      default:
        return isMirror
          ? (top: const Color(0xFFDB2777), bot: const Color(0xFF9D174D),
             shoe: const Color(0xFF831843), trim: const Color(0xFFFCE7F3))
          : (top: const Color(0xFF4F46E5), bot: const Color(0xFF3730A3),
             shoe: const Color(0xFF1E1B4B), trim: const Color(0xFFE0E7FF));
    }
  }

  bool get _isDress => const {
    'outfit_sundress', 'dress', 'outfit_kimono', 'outfit_hanfu',
    'outfit_mage_robe', 'outfit_shrine_maiden', 'outfit_egyptian',
  }.contains(appearance.outfitId);

  // ─── main paint ───────────────────────────────────────────────────────────
  @override
  void paint(Canvas canvas, Size size) {
    final cx  = size.width / 2;
    final sw  = size.width;
    final sh  = size.height;
    final fat = 0.85 + appearance.fatLevel * 0.35;

    // ── layout landmarks ──────────────────────────────────────────────────
    final headCy    = sh * 0.100;
    final headW     = sw * 0.340;
    final headH     = sh * 0.186;
    final neckMidY  = sh * 0.196;
    final shoulderY = sh * 0.237;
    final waistY    = sh * 0.468;
    final hipY      = sh * 0.538;
    final crotchY   = sh * 0.568;
    final kneeY     = sh * 0.740;
    final ankleY    = sh * 0.904;
    final footBotY  = sh * 0.960;

    final sholW  = (isFemale ? 0.390 : 0.490) * sw * fat;
    final waistW = (isFemale ? 0.260 : 0.360) * sw * fat;
    final hipW   = (isFemale ? 0.440 : 0.380) * sw * fat;
    final armW   = (isFemale ? 0.090 : 0.108) * sw * fat;
    final legW   = (isFemale ? 0.192 : 0.198) * sw * fat;

    // ── layers in order ───────────────────────────────────────────────────
    _paintBodyBase(canvas, cx, sh, sw,
        headCy: headCy, headW: headW, headH: headH,
        neckMidY: neckMidY, shoulderY: shoulderY,
        waistY: waistY, hipY: hipY, crotchY: crotchY,
        kneeY: kneeY, ankleY: ankleY, footBotY: footBotY,
        sholW: sholW, waistW: waistW, hipW: hipW,
        armW: armW, legW: legW);

    _paintOutfit(canvas, cx, sh, sw,
        shoulderY: shoulderY, waistY: waistY,
        hipY: hipY, crotchY: crotchY,
        kneeY: kneeY, ankleY: ankleY, footBotY: footBotY,
        sholW: sholW, waistW: waistW, hipW: hipW,
        armW: armW, legW: legW);

    _paintHairBack(canvas, cx, headCy, headW, headH, sh);
    _paintHead(canvas, cx, headCy, headW, headH);
    _paintHairFront(canvas, cx, headCy, headW, headH, sh, sw);
    _paintFace(canvas, cx, headCy, headH);

    _paintAccessories(canvas, cx, headCy, headH, sh, sw,
        shoulderY: shoulderY, sholW: sholW);
  }

  // ── body base (skin) ──────────────────────────────────────────────────────
  void _paintBodyBase(Canvas canvas, double cx, double sh, double sw, {
    required double headCy, required double headW, required double headH,
    required double neckMidY, required double shoulderY,
    required double waistY, required double hipY, required double crotchY,
    required double kneeY, required double ankleY, required double footBotY,
    required double sholW, required double waistW, required double hipW,
    required double armW, required double legW,
  }) {
    final skin  = _skin;
    final skinD = _skinDark;

    // Torso
    final torso = Path()
      ..moveTo(cx - sholW / 2, shoulderY)
      ..cubicTo(cx - waistW / 2 - 8, shoulderY + (waistY - shoulderY) * 0.4,
                cx - waistW / 2 - 4, shoulderY + (waistY - shoulderY) * 0.75,
                cx - waistW / 2, waistY)
      ..cubicTo(cx - hipW / 2 + 4, waistY + (hipY - waistY) * 0.4,
                cx - hipW / 2 + 2, waistY + (hipY - waistY) * 0.75,
                cx - hipW / 2, hipY)
      ..lineTo(cx - hipW / 2, crotchY)
      ..lineTo(cx + hipW / 2, crotchY)
      ..lineTo(cx + hipW / 2, hipY)
      ..cubicTo(cx + hipW / 2 - 2, waistY + (hipY - waistY) * 0.75,
                cx + hipW / 2 - 4, waistY + (hipY - waistY) * 0.4,
                cx + waistW / 2, waistY)
      ..cubicTo(cx + waistW / 2 + 4, shoulderY + (waistY - shoulderY) * 0.75,
                cx + waistW / 2 + 8, shoulderY + (waistY - shoulderY) * 0.4,
                cx + sholW / 2, shoulderY)
      ..close();

    canvas.drawPath(torso, Paint()
      ..shader = LinearGradient(
        colors: [skinD, skin, skinD],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(cx - sholW / 2, shoulderY, sholW, crotchY - shoulderY)));

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, neckMidY), width: 22, height: sh * 0.072),
        const Radius.circular(11)),
      Paint()..color = skin);

    // Arms
    _paintArm(canvas, cx - sholW / 2 - armW, shoulderY, waistY + sh * 0.045, armW, skin, skinD, true);
    _paintArm(canvas, cx + sholW / 2, shoulderY, waistY + sh * 0.045, armW, skin, skinD, false);

    // Shin (below pants/skirt, may be hidden by outfit)
    _paintLeg(canvas, cx - legW - 3, kneeY, ankleY, legW, skin, skinD);
    _paintLeg(canvas, cx + 3, kneeY, ankleY, legW, skin, skinD);
  }

  void _paintArm(Canvas canvas, double x, double topY, double botY,
                 double w, Color skin, Color skinDark, bool isLeft) {
    final path = Path()
      ..moveTo(x, topY)
      ..lineTo(x + w, topY)
      ..lineTo(x + w * (isLeft ? 0.88 : 0.78), botY)
      ..lineTo(x + w * (isLeft ? 0.12 : 0.22), botY)
      ..close();
    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        colors: isLeft ? [skin, skinDark] : [skinDark, skin],
        begin: Alignment.centerLeft, end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(x, topY, w, botY - topY)));
    // Hand
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + w / 2, botY + 10), width: w + 4, height: 16),
      Paint()..color = skin);
  }

  void _paintLeg(Canvas canvas, double x, double topY, double botY,
                 double w, Color skin, Color skinDark) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, topY, w, botY - topY),
        const Radius.circular(10)),
      Paint()..shader = LinearGradient(
        colors: [skin, skinDark],
        begin: Alignment.centerLeft, end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(x, topY, w, botY - topY)));
  }

  // ── outfit ────────────────────────────────────────────────────────────────
  void _paintOutfit(Canvas canvas, double cx, double sh, double sw, {
    required double shoulderY, required double waistY,
    required double hipY, required double crotchY,
    required double kneeY, required double ankleY, required double footBotY,
    required double sholW, required double waistW, required double hipW,
    required double armW, required double legW,
  }) {
    final c = _outfit;

    // Top garment (shirt / bodice)
    final topPath = Path()
      ..moveTo(cx - sholW / 2 - armW * 0.55, shoulderY)
      ..cubicTo(cx - waistW / 2 - 6, shoulderY + (waistY - shoulderY) * 0.45,
                cx - waistW / 2 - 2, shoulderY + (waistY - shoulderY) * 0.78,
                cx - waistW / 2, waistY)
      ..lineTo(cx + waistW / 2, waistY)
      ..cubicTo(cx + waistW / 2 + 2, shoulderY + (waistY - shoulderY) * 0.78,
                cx + waistW / 2 + 6, shoulderY + (waistY - shoulderY) * 0.45,
                cx + sholW / 2 + armW * 0.55, shoulderY)
      ..close();

    canvas.drawPath(topPath, Paint()
      ..shader = LinearGradient(
        colors: [c.top, _lighten(c.top, 0.12)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(
          cx - sholW / 2 - armW, shoulderY, sholW + armW * 2, waistY - shoulderY)));

    _paintCollar(canvas, cx, shoulderY, c.trim, c.top);
    _paintSleeve(canvas, cx - sholW / 2 - armW, shoulderY, waistY, armW, c.top, c.trim, isLeft: true);
    _paintSleeve(canvas, cx + sholW / 2, shoulderY, waistY, armW, c.top, c.trim, isLeft: false);

    // Bottom half
    if (_isDress) {
      _paintSkirt(canvas, cx, hipY, ankleY, hipW * 1.05, c.top, c.bot, c.trim);
    } else {
      _paintPants(canvas, cx, crotchY, kneeY, ankleY, legW, c.bot, c.trim);
    }

    _paintShoes(canvas, cx, ankleY, footBotY, legW, c.shoe, c.trim);
  }

  void _paintCollar(Canvas canvas, double cx, double shoulderY, Color trim, Color top) {
    if (_isDress) {
      final v = Path()
        ..moveTo(cx - 14, shoulderY + 4)
        ..lineTo(cx, shoulderY + 28)
        ..lineTo(cx + 14, shoulderY + 4);
      canvas.drawPath(v, Paint()
        ..color = trim.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, shoulderY + 12), width: 26, height: 18),
          const Radius.circular(3)),
        Paint()..color = trim.withOpacity(0.8));
    }
  }

  void _paintSleeve(Canvas canvas, double x, double topY, double botY,
                    double armW, Color top, Color trim, {required bool isLeft}) {
    final sleeveH = (botY - topY) * 0.22;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, topY, armW, sleeveH + 4), const Radius.circular(5)),
      Paint()..color = top);
    canvas.drawLine(
      Offset(x + 2, topY + sleeveH + 2),
      Offset(x + armW - 2, topY + sleeveH + 2),
      Paint()..color = trim.withOpacity(0.6)..strokeWidth = 2);
  }

  void _paintSkirt(Canvas canvas, double cx, double topY, double botY,
                   double topW, Color top, Color bot, Color trim) {
    final botW = topW * 1.50;
    final midW = topW * 1.25;
    final skirt = Path()
      ..moveTo(cx - topW / 2, topY)
      ..quadraticBezierTo(cx - midW / 2, (topY + botY) / 2, cx - botW / 2, botY)
      ..lineTo(cx + botW / 2, botY)
      ..quadraticBezierTo(cx + midW / 2, (topY + botY) / 2, cx + topW / 2, topY)
      ..close();

    canvas.drawPath(skirt, Paint()
      ..shader = LinearGradient(
        colors: [top, bot, _lighten(bot, 0.15)],
        stops: const [0.0, 0.55, 1.0],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - botW / 2, topY, botW, botY - topY)));

    // Hem accent
    canvas.drawLine(
      Offset(cx - botW / 2 + 8, botY - 4),
      Offset(cx + botW / 2 - 8, botY - 4),
      Paint()..color = trim.withOpacity(0.5)..strokeWidth = 2);
  }

  void _paintPants(Canvas canvas, double cx, double topY, double kneeY,
                   double ankleY, double legW, Color bot, Color trim) {
    // Waistband
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, topY + 8), width: legW * 2 + 14, height: 16),
        const Radius.circular(4)),
      Paint()..color = _lighten(bot, 0.09));

    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - legW * 2 - 3, topY + 8, legW + 3, ankleY - topY - 8),
        const Radius.circular(8)),
      Paint()..shader = LinearGradient(
        colors: [bot, _lighten(bot, 0.10)],
        begin: Alignment.centerLeft, end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(cx - legW * 2, topY, legW * 2, ankleY - topY)));

    // Right leg (slightly different shade)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 3, topY + 8, legW + 3, ankleY - topY - 8),
        const Radius.circular(8)),
      Paint()..color = _darken(bot, 0.05));
  }

  void _paintShoes(Canvas canvas, double cx, double topY, double botY,
                   double legW, Color shoe, Color trim) {
    final h = botY - topY;
    // Left shoe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - legW * 2 - 6, topY, legW + 6, h),
        const Radius.circular(6)),
      Paint()..color = shoe);
    // Right shoe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 3, topY, legW + 6, h),
        const Radius.circular(6)),
      Paint()..color = shoe);
    // Sole line
    canvas.drawLine(Offset(cx - legW * 2 - 4, topY + h * 0.7),
                    Offset(cx - 2, topY + h * 0.7),
                    Paint()..color = trim.withOpacity(0.45)..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx + 5, topY + h * 0.7),
                    Offset(cx + legW + 7, topY + h * 0.7),
                    Paint()..color = trim.withOpacity(0.45)..strokeWidth = 1.5);
  }

  // ── hair back ─────────────────────────────────────────────────────────────
  void _paintHairBack(Canvas canvas, double cx, double headCy,
                      double headW, double headH, double sh) {
    if (appearance.hairStyle == HairStyle.short ||
        appearance.hairStyle == HairStyle.bun) return;

    final hair = _hairBase;
    final tailH = {
      HairStyle.medium:   sh * 0.18,
      HairStyle.long:     sh * 0.42,
      HairStyle.curly:    sh * 0.12,
    }[appearance.hairStyle];

    if (tailH != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - headW / 2 - 4, headCy + 16, 14, tailH),
          const Radius.circular(7)),
        Paint()..color = hair);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + headW / 2 - 10, headCy + 16, 14, tailH),
          const Radius.circular(7)),
        Paint()..color = hair);
    }

    if (appearance.hairStyle == HairStyle.ponytail) {
      final pt = Path()
        ..moveTo(cx + headW / 2, headCy)
        ..cubicTo(
            cx + headW / 2 + sh * 0.10, headCy + sh * 0.06,
            cx + headW / 2 + sh * 0.14, headCy + sh * 0.14,
            cx + headW / 2 + sh * 0.04, headCy + sh * 0.30);
      canvas.drawPath(pt, Paint()
        ..color = hair
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round);
    }
  }

  // ── head ─────────────────────────────────────────────────────────────────
  void _paintHead(Canvas canvas, double cx, double headCy, double headW, double headH) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, headCy), width: headW, height: headH),
      Paint()..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.85,
        colors: [_skin, _skinDark.withOpacity(0.85)],
      ).createShader(Rect.fromCenter(center: Offset(cx, headCy), width: headW, height: headH)));
  }

  // ── hair front ────────────────────────────────────────────────────────────
  void _paintHairFront(Canvas canvas, double cx, double headCy,
                       double headW, double headH, double sh, double sw) {
    final hair  = _hairBase;
    final hairL = _hairLight;
    final hairP = Paint()..shader = LinearGradient(
      colors: [hair, hairL, hair],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ).createShader(Rect.fromCenter(
        center: Offset(cx, headCy - headH * 0.2), width: headW + 20, height: headH * 0.7));

    switch (appearance.hairStyle) {
      case HairStyle.short:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, headCy - headH * 0.17),
                          width: headW + 10, height: headH * 0.56), hairP);
        canvas.drawOval(Rect.fromLTWH(cx - headW / 2 - 6, headCy - headH * 0.24, 13, 32), hairP);
        canvas.drawOval(Rect.fromLTWH(cx + headW / 2 - 7, headCy - headH * 0.24, 13, 32), hairP);

      case HairStyle.medium:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, headCy - headH * 0.19),
                          width: headW + 12, height: headH * 0.62), hairP);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - headW / 2 - 7, headCy - headH * 0.24, 14, headH * 0.82),
            const Radius.circular(7)), hairP);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + headW / 2 - 7, headCy - headH * 0.24, 14, headH * 0.82),
            const Radius.circular(7)), hairP);

      case HairStyle.long:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, headCy - headH * 0.19),
                          width: headW + 12, height: headH * 0.65), hairP);

      case HairStyle.bun:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, headCy - headH * 0.17),
                          width: headW + 8, height: headH * 0.56), hairP);
        canvas.drawCircle(Offset(cx, headCy - headH * 0.52), 20, hairP);
        // bun ring
        canvas.drawCircle(Offset(cx, headCy - headH * 0.52), 20, Paint()
          ..color = _darken(hair, 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

      case HairStyle.ponytail:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, headCy - headH * 0.17),
                          width: headW + 8, height: headH * 0.58), hairP);
        canvas.drawCircle(
          Offset(cx + headW / 2, headCy - headH * 0.09), 6,
          Paint()..color = _darken(hair, 0.22));

      case HairStyle.curly:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, headCy - headH * 0.15),
                          width: headW + 18, height: headH * 0.68), hairP);
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(
            Offset(cx - headW * 0.38 + i * headW * 0.19, headCy - headH * 0.36),
            10, Paint()..color = hair);
        }
    }

    // Bangs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - headW * 0.37, headCy - headH * 0.27,
                      headW * 0.74, headH * 0.175),
        const Radius.circular(4)),
      Paint()..color = hair);
  }

  // ── face ─────────────────────────────────────────────────────────────────
  void _paintFace(Canvas canvas, double cx, double headCy, double headH) {
    final eyeY   = headCy + headH * 0.09;
    final noseY  = headCy + headH * 0.21;
    final mouthY = headCy + headH * 0.33;

    // Eyebrows
    final browP = Paint()
      ..color = _darken(_hairBase, 0.05).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 19, eyeY - 12), Offset(cx - 7, eyeY - 14), browP);
    canvas.drawLine(Offset(cx + 7, eyeY - 14), Offset(cx + 19, eyeY - 12), browP);

    _paintEye(canvas, Offset(cx - 13.5, eyeY), false);
    _paintEye(canvas, Offset(cx + 13.5, eyeY), true);

    // Nose
    canvas.drawCircle(Offset(cx, noseY), 2.5,
        Paint()..color = _skinDark.withOpacity(0.40));

    // Smile
    final smile = Path()
      ..moveTo(cx - 10, mouthY)
      ..quadraticBezierTo(cx, mouthY + 8, cx + 10, mouthY);
    canvas.drawPath(smile, Paint()
      ..color = _skinDark.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round);

    // Blush
    final blush = Paint()..color = const Color(0xFFFCA5A5).withOpacity(0.55);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 23, eyeY + 9), width: 20, height: 9), blush);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 23, eyeY + 9), width: 20, height: 9), blush);
  }

  void _paintEye(Canvas canvas, Offset center, bool isRight) {
    final accent = isMirror ? const Color(0xFFDB2777) : const Color(0xFF4F46E5);

    // White sclera
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 18, height: 15),
      Paint()..color = const Color(0xFFFAFAFA));

    // Iris with gradient
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 12, height: 13),
      Paint()..shader = RadialGradient(
        colors: [_lighten(accent, 0.25), accent],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCenter(center: center, width: 12, height: 13)));

    // Pupil
    canvas.drawCircle(center, 3.8, Paint()..color = const Color(0xFF0C0C1A));

    // Primary highlight
    canvas.drawCircle(
      Offset(center.dx - (isRight ? 2.5 : -2.5), center.dy - 3.5),
      2.8, Paint()..color = Colors.white);

    // Secondary highlight
    canvas.drawCircle(
      Offset(center.dx + (isRight ? -4.0 : 4.0), center.dy + 2.0),
      1.2, Paint()..color = Colors.white.withOpacity(0.7));

    // Upper lash arc
    canvas.drawArc(
      Rect.fromCenter(center: center, width: 18, height: 16),
      math.pi * 1.05, math.pi * 0.9, false,
      Paint()
        ..color = const Color(0xFF0C0C1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round);
  }

  // ── accessories ───────────────────────────────────────────────────────────
  void _paintAccessories(Canvas canvas, double cx, double headCy, double headH,
                          double sh, double sw, {
    required double shoulderY, required double sholW,
  }) {
    final eyeY = headCy + headH * 0.09;

    for (final acc in appearance.accessories) {
      switch (acc) {
        case 'round_glasses':
        case 'sunglasses':
          final isDark  = acc == 'sunglasses';
          final lensC   = isDark ? const Color(0xFF1E293B).withOpacity(0.55) : Colors.transparent;
          final frameC  = isDark ? const Color(0xFF1E293B) : const Color(0xFF64748B);
          final frameP  = Paint()..color = frameC..style = PaintingStyle.stroke..strokeWidth = 2;
          final lensP   = Paint()..color = lensC;
          canvas.drawOval(Rect.fromCenter(center: Offset(cx - 13.5, eyeY), width: 20, height: 15), lensP);
          canvas.drawOval(Rect.fromCenter(center: Offset(cx + 13.5, eyeY), width: 20, height: 15), lensP);
          canvas.drawOval(Rect.fromCenter(center: Offset(cx - 13.5, eyeY), width: 20, height: 15), frameP);
          canvas.drawOval(Rect.fromCenter(center: Offset(cx + 13.5, eyeY), width: 20, height: 15), frameP);
          canvas.drawLine(Offset(cx - 3.5, eyeY), Offset(cx + 3.5, eyeY), frameP);

        case 'headband':
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, headCy - headH * 0.20),
                              width: sw * 0.38, height: 10),
              const Radius.circular(5)),
            Paint()..color = const Color(0xFFEC4899));

        case 'cap':
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, headCy - headH * 0.20),
                            width: sw * 0.46, height: 14),
            Paint()..color = const Color(0xFF334155));
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, headCy - headH * 0.33),
                              width: sw * 0.36, height: headH * 0.38),
              const Radius.circular(10)),
            Paint()..color = const Color(0xFF475569));

        case 'beanie':
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, headCy - headH * 0.25),
                              width: sw * 0.38, height: headH * 0.40),
              const Radius.circular(12)),
            Paint()..color = const Color(0xFFDC2626));
          canvas.drawCircle(Offset(cx, headCy - headH * 0.46), 10,
              Paint()..color = const Color(0xFFFEF2F2));

        case 'scarf':
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, shoulderY + 8),
                              width: sholW + 14, height: 18),
              const Radius.circular(9)),
            Paint()..color = const Color(0xFFDC2626));

        case 'necklace':
          canvas.drawArc(
            Rect.fromCenter(center: Offset(cx, shoulderY + 14), width: 30, height: 20),
            0, math.pi, false,
            Paint()
              ..color = const Color(0xFFD4AF37)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);

        case 'earrings':
          canvas.drawCircle(
            Offset(cx - sw * 0.165, headCy + headH * 0.18), 4.5,
            Paint()..color = const Color(0xFFD4AF37));
          canvas.drawCircle(
            Offset(cx + sw * 0.165, headCy + headH * 0.18), 4.5,
            Paint()..color = const Color(0xFFD4AF37));

        case 'watch':
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx - sholW / 2 - sw * 0.095,
                                             shoulderY + sh * 0.18),
                              width: 14, height: 10),
              const Radius.circular(3)),
            Paint()..color = const Color(0xFF94A3B8));

        default:
          break;
      }
    }
  }

  // ── utility ───────────────────────────────────────────────────────────────
  Color _lighten(Color c, double amt) => HSLColor.fromColor(c)
      .withLightness((HSLColor.fromColor(c).lightness + amt).clamp(0, 1))
      .toColor();

  Color _darken(Color c, double amt) => HSLColor.fromColor(c)
      .withLightness((HSLColor.fromColor(c).lightness - amt).clamp(0, 1))
      .toColor();

  @override
  bool shouldRepaint(_DollPainter old) =>
      old.appearance != appearance ||
      old.isFemale != isFemale ||
      old.isMirror != isMirror;
}
