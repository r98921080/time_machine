import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/character.dart';

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

class _DollPainter extends CustomPainter {
  final CharacterAppearance appearance;
  final bool isFemale;
  final bool isMirror;

  const _DollPainter({
    required this.appearance,
    required this.isFemale,
    this.isMirror = false,
  });

  // ── colours ───────────────────────────────────────────────────────────────

  Color get _skin => const {
    SkinTone.light:  Color(0xFFFCE4D2),
    SkinTone.medium: Color(0xFFF0B98A),
    SkinTone.tan:    Color(0xFFCC8050),
    SkinTone.dark:   Color(0xFF7A4020),
  }[appearance.skinTone]!;

  Color get _hairBase => const {
    HairColor.black:   Color(0xFF1C1C2E),
    HairColor.brown:   Color(0xFF5C3010),
    HairColor.blonde:  Color(0xFFE8C040),
    HairColor.red:     Color(0xFFA82020),
    HairColor.gray:    Color(0xFF909090),
    HairColor.fantasy: Color(0xFF7C3AED),
  }[appearance.hairColor]!;

  ({Color top, Color bot, Color shoe, Color trim, Color accent}) get _outfit {
    switch (appearance.outfitId) {
      case 'outfit_formal_suit':
      case 'suit':
        return (top: const Color(0xFF1E293B), bot: const Color(0xFF334155),
                shoe: const Color(0xFF0F172A), trim: const Color(0xFFCBD5E1),
                accent: const Color(0xFFE2E8F0));
      case 'outfit_sundress':
      case 'dress':
        return (top: const Color(0xFFEC4899), bot: const Color(0xFFFBCFE8),
                shoe: const Color(0xFFDB2777), trim: const Color(0xFFFFF0F7),
                accent: const Color(0xFFFDA4D4));
      case 'outfit_sport_set':
      case 'sporty':
        return (top: const Color(0xFF1D4ED8), bot: const Color(0xFF1E40AF),
                shoe: const Color(0xFFEF4444), trim: const Color(0xFFBFDBFE),
                accent: const Color(0xFFDCEFFD));
      case 'outfit_kimono':
        return (top: const Color(0xFFD946EF), bot: const Color(0xFFF0ABFC),
                shoe: const Color(0xFF701A75), trim: const Color(0xFFFDF4FF),
                accent: const Color(0xFFF5D0FE));
      case 'outfit_hanfu':
        return (top: const Color(0xFF059669), bot: const Color(0xFF6EE7B7),
                shoe: const Color(0xFF064E3B), trim: const Color(0xFFECFDF5),
                accent: const Color(0xFFA7F3D0));
      case 'outfit_school_uniform':
      case 'school_uniform':
        return (top: const Color(0xFFF8FAFC), bot: const Color(0xFF1E3A5F),
                shoe: const Color(0xFF0F172A), trim: const Color(0xFF0EA5E9),
                accent: const Color(0xFFBAE6FD));
      case 'outfit_casual_hoodie':
      case 'hoodie':
        return (top: const Color(0xFF60A5FA), bot: const Color(0xFF475569),
                shoe: const Color(0xFF1E293B), trim: const Color(0xFFDBEAFE),
                accent: const Color(0xFF93C5FD));
      case 'outfit_tshirt_white':
      case 'casual_tshirt':
        return (top: const Color(0xFFF0F9FF), bot: const Color(0xFF2563EB),
                shoe: const Color(0xFF1E3A5F), trim: const Color(0xFFBAE6FD),
                accent: const Color(0xFFE0F2FE));
      case 'outfit_mage_robe':
        return (top: const Color(0xFF4C1D95), bot: const Color(0xFF6D28D9),
                shoe: const Color(0xFF2E1065), trim: const Color(0xFFC4B5FD),
                accent: const Color(0xFFEDE9FE));
      case 'outfit_cyberpunk':
        return (top: const Color(0xFF0F172A), bot: const Color(0xFF1E293B),
                shoe: const Color(0xFF000000), trim: const Color(0xFF06B6D4),
                accent: const Color(0xFF22D3EE));
      case 'outfit_knight_armor':
        return (top: const Color(0xFFCBD5E1), bot: const Color(0xFF94A3B8),
                shoe: const Color(0xFF334155), trim: const Color(0xFFF59E0B),
                accent: const Color(0xFFFEF3C7));
      case 'outfit_shrine_maiden':
        return (top: const Color(0xFFDC2626), bot: const Color(0xFFFEF2F2),
                shoe: const Color(0xFF1E293B), trim: const Color(0xFF7F1D1D),
                accent: const Color(0xFFFEE2E2));
      case 'outfit_ninja':
        return (top: const Color(0xFF0F172A), bot: const Color(0xFF0F172A),
                shoe: const Color(0xFF0F172A), trim: const Color(0xFF64748B),
                accent: const Color(0xFF475569));
      case 'outfit_pirate':
        return (top: const Color(0xFF7C3AED), bot: const Color(0xFF1E293B),
                shoe: const Color(0xFF292524), trim: const Color(0xFFEFB839),
                accent: const Color(0xFFFDE68A));
      case 'outfit_chef':
        return (top: const Color(0xFFF8FAFC), bot: const Color(0xFF334155),
                shoe: const Color(0xFF1E293B), trim: const Color(0xFFCBD5E1),
                accent: const Color(0xFFE2E8F0));
      case 'outfit_space_suit':
        return (top: const Color(0xFFF8FAFC), bot: const Color(0xFFCBD5E1),
                shoe: const Color(0xFF334155), trim: const Color(0xFF0EA5E9),
                accent: const Color(0xFFBAE6FD));
      case 'outfit_denim_jacket':
        return (top: const Color(0xFF2563EB), bot: const Color(0xFF1D4ED8),
                shoe: const Color(0xFF1E293B), trim: const Color(0xFFBFDBFE),
                accent: const Color(0xFF93C5FD));
      case 'outfit_tracksuit':
        return (top: const Color(0xFF7C3AED), bot: const Color(0xFF6D28D9),
                shoe: const Color(0xFF2E1065), trim: const Color(0xFFEDE9FE),
                accent: const Color(0xFFC4B5FD));
      case 'outfit_lab_coat':
        return (top: const Color(0xFFF8FAFC), bot: const Color(0xFF475569),
                shoe: const Color(0xFF1E293B), trim: const Color(0xFF0EA5E9),
                accent: const Color(0xFFE0F2FE));
      case 'outfit_detective':
        return (top: const Color(0xFF78350F), bot: const Color(0xFF451A03),
                shoe: const Color(0xFF1C0A00), trim: const Color(0xFFFCD34D),
                accent: const Color(0xFFFDE68A));
      case 'outfit_egyptian':
        return (top: const Color(0xFFFBBF24), bot: const Color(0xFFF59E0B),
                shoe: const Color(0xFF92400E), trim: const Color(0xFFFEF9C3),
                accent: const Color(0xFFFFF7CD));
      default:
        return isMirror
            ? (top: const Color(0xFFDB2777), bot: const Color(0xFF9D174D),
               shoe: const Color(0xFF831843), trim: const Color(0xFFFCE7F3),
               accent: const Color(0xFFFDA4D4))
            : (top: const Color(0xFF4F46E5), bot: const Color(0xFF3730A3),
               shoe: const Color(0xFF1E1B4B), trim: const Color(0xFFE0E7FF),
               accent: const Color(0xFFC7D2FE));
    }
  }

  bool get _isDress => const {
    'outfit_sundress', 'dress', 'outfit_kimono', 'outfit_hanfu',
    'outfit_mage_robe', 'outfit_shrine_maiden', 'outfit_egyptian',
  }.contains(appearance.outfitId);

  // ── paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final fat = 0.88 + appearance.fatLevel * 0.30;
    final cx  = size.width  / 2;
    final sw  = size.width;
    final sh  = size.height;

    // Vertical landmarks
    final headCy    = sh * 0.090;
    final headRx    = sw * 0.168;
    final headRy    = sh * 0.088;
    final neckTopY  = sh * 0.162;
    final neckBotY  = sh * 0.202;
    final shoulderY = neckBotY;
    final waistY    = sh * 0.440;
    final hipY      = sh * 0.508;
    final crotchY   = sh * 0.546;
    final kneeY     = sh * 0.718;
    final ankleY    = sh * 0.885;
    final footBotY  = sh * 0.950;

    // Horizontal half-widths – all derived consistently
    final sholHW = (isFemale ? 0.192 : 0.242) * sw * fat;
    final waistHW= (isFemale ? 0.120 : 0.164) * sw * fat;
    final hipHW  = (isFemale ? 0.212 : 0.184) * sw * fat;
    final armHW  = (isFemale ? 0.038 : 0.048) * sw * fat;
    final legHW  = (isFemale ? 0.082 : 0.090) * sw * fat;
    final neckHW = sw * 0.048;

    // Leg centers derived from hip width (fixes alignment)
    final leftLegCx  = cx - hipHW * 0.52;
    final rightLegCx = cx + hipHW * 0.52;

    final skin     = _skin;
    final skinSide = _darken(skin, 0.10);
    final skinShad = _darken(skin, 0.18);

    // Render order: back hair → body skin → outfit → head → front hair → face → accessories
    _paintHairBack(canvas, cx, headCy, headRx, headRy, sh);
    _paintBody(canvas, cx, sh, sw, skin, skinSide, skinShad,
        neckTopY: neckTopY, neckBotY: neckBotY, neckHW: neckHW,
        shoulderY: shoulderY, waistY: waistY,
        hipY: hipY, crotchY: crotchY,
        kneeY: kneeY, ankleY: ankleY,
        sholHW: sholHW, waistHW: waistHW, hipHW: hipHW,
        armHW: armHW, legHW: legHW,
        leftLegCx: leftLegCx, rightLegCx: rightLegCx);
    _paintOutfit(canvas, cx, sh, sw,
        shoulderY: shoulderY, waistY: waistY,
        hipY: hipY, crotchY: crotchY,
        kneeY: kneeY, ankleY: ankleY, footBotY: footBotY,
        sholHW: sholHW, waistHW: waistHW, hipHW: hipHW,
        armHW: armHW, legHW: legHW,
        leftLegCx: leftLegCx, rightLegCx: rightLegCx);
    _paintHead(canvas, cx, headCy, headRx, headRy);
    _paintHairFront(canvas, cx, headCy, headRx, headRy);
    _paintFace(canvas, cx, headCy, headRy, sw);
    _paintAccessories(canvas, cx, headCy, headRx, headRy, sh, sw,
        shoulderY: shoulderY, sholHW: sholHW);
  }

  // ── body skin ─────────────────────────────────────────────────────────────

  void _paintBody(Canvas canvas, double cx, double sh, double sw,
      Color skin, Color skinSide, Color skinShad, {
    required double neckTopY, required double neckBotY, required double neckHW,
    required double shoulderY, required double waistY,
    required double hipY, required double crotchY,
    required double kneeY, required double ankleY,
    required double sholHW, required double waistHW, required double hipHW,
    required double armHW, required double legHW,
    required double leftLegCx, required double rightLegCx,
  }) {
    // Neck
    canvas.drawPath(
      Path()
        ..moveTo(cx - neckHW, neckTopY)
        ..lineTo(cx + neckHW, neckTopY)
        ..lineTo(cx + neckHW * 1.15, neckBotY)
        ..lineTo(cx - neckHW * 1.15, neckBotY)
        ..close(),
      Paint()..color = skin);

    // Torso hourglass
    final tl = cx - sholHW; final tr = cx + sholHW;
    final wl = cx - waistHW; final wr = cx + waistHW;
    final hl = cx - hipHW;   final hr = cx + hipHW;
    final t1 = shoulderY + (waistY - shoulderY) * 0.38;
    final t2 = shoulderY + (waistY - shoulderY) * 0.72;
    final t3 = waistY + (hipY - waistY) * 0.35;
    final t4 = waistY + (hipY - waistY) * 0.78;

    final torso = Path()
      ..moveTo(tl, shoulderY)
      ..cubicTo(wl - sw * 0.022, t1, wl - sw * 0.010, t2, wl, waistY)
      ..cubicTo(hl + sw * 0.010, t3, hl + sw * 0.004, t4, hl, hipY)
      ..lineTo(hl, crotchY)
      ..lineTo(hr, crotchY)
      ..lineTo(hr, hipY)
      ..cubicTo(hr - sw * 0.004, t4, hr - sw * 0.010, t3, wr, waistY)
      ..cubicTo(wr + sw * 0.010, t2, wr + sw * 0.022, t1, tr, shoulderY)
      ..close();

    canvas.drawPath(torso, Paint()
      ..shader = LinearGradient(
        colors: [skinShad, skin, skin, skinSide],
        stops: const [0.0, 0.18, 0.70, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(hl, shoulderY, hipHW * 2, crotchY - shoulderY)));

    // Female bust shading
    if (isFemale) {
      final bustY = shoulderY + (waistY - shoulderY) * 0.42;
      for (final side in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + side * sholHW * 0.30, bustY - sh * 0.012),
              width: sholHW * 0.62, height: sh * 0.060),
          Paint()
            ..color = skinShad.withOpacity(0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      }
    }

    // Arms (hanging at sides)
    _paintArm(canvas, true,  cx - sholHW, shoulderY, waistY + sh * 0.038, armHW, skin, skinShad);
    _paintArm(canvas, false, cx + sholHW, shoulderY, waistY + sh * 0.038, armHW, skin, skinShad);

    // Calves (visible below pants/skirt)
    _paintCalf(canvas, leftLegCx,  kneeY, ankleY, legHW, skin, skinSide);
    _paintCalf(canvas, rightLegCx, kneeY, ankleY, legHW, skin, skinSide);
  }

  void _paintArm(Canvas canvas, bool isLeft, double shoulderX, double topY,
                 double botY, double armHW, Color skin, Color skinShad) {
    final sign = isLeft ? -1.0 : 1.0;
    final mid  = topY + (botY - topY) * 0.50;
    // Arm bows slightly outward at elbow
    final elbowX  = shoulderX + sign * armHW * 0.60;

    final path = Path()
      ..moveTo(shoulderX - armHW, topY)
      ..lineTo(shoulderX + armHW, topY)
      ..quadraticBezierTo(elbowX + armHW, mid, shoulderX + armHW * 0.5, botY)
      ..lineTo(shoulderX - armHW * 0.5, botY)
      ..quadraticBezierTo(elbowX - armHW, mid, shoulderX - armHW, topY)
      ..close();

    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        colors: isLeft ? [skin, skinShad] : [skinShad, skin],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(
          shoulderX - armHW * 1.5, topY, armHW * 3.0, botY - topY)));

    // Hand
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(shoulderX, botY + (botY - topY) * 0.040),
          width: armHW * 1.80, height: (botY - topY) * 0.068),
      Paint()..color = skin);
  }

  void _paintCalf(Canvas canvas, double legCx, double topY, double botY,
                  double legHW, Color skin, Color skinSide) {
    final path = Path()
      ..moveTo(legCx - legHW, topY)
      ..lineTo(legCx + legHW, topY)
      ..quadraticBezierTo(legCx + legHW * 0.92, topY + (botY - topY) * 0.55,
                          legCx + legHW * 0.64, botY)
      ..lineTo(legCx - legHW * 0.64, botY)
      ..quadraticBezierTo(legCx - legHW * 0.92, topY + (botY - topY) * 0.55,
                          legCx - legHW, topY)
      ..close();
    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        colors: [skinSide, skin, skin, skinSide],
        stops: const [0.0, 0.18, 0.70, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(legCx - legHW, topY, legHW * 2, botY - topY)));
  }

  // ── outfit ────────────────────────────────────────────────────────────────

  void _paintOutfit(Canvas canvas, double cx, double sh, double sw, {
    required double shoulderY, required double waistY,
    required double hipY, required double crotchY,
    required double kneeY, required double ankleY, required double footBotY,
    required double sholHW, required double waistHW, required double hipHW,
    required double armHW, required double legHW,
    required double leftLegCx, required double rightLegCx,
  }) {
    final c = _outfit;

    _paintTop(canvas, cx, sh, sw, c.top, c.trim,
        shoulderY: shoulderY, waistY: waistY,
        sholHW: sholHW, waistHW: waistHW, armHW: armHW);

    if (_isDress) {
      _paintSkirt(canvas, cx, hipY, ankleY, hipHW * 1.02, c.top, c.bot, c.trim);
    } else {
      _paintPants(canvas, cx, crotchY, ankleY, legHW, c.bot, c.trim,
          leftLegCx: leftLegCx, rightLegCx: rightLegCx, hipHW: hipHW);
    }

    _paintShoes(canvas, ankleY, footBotY, legHW, c.shoe, c.trim,
        leftLegCx: leftLegCx, rightLegCx: rightLegCx);
  }

  void _paintTop(Canvas canvas, double cx, double sh, double sw,
      Color top, Color trim, {
    required double shoulderY, required double waistY,
    required double sholHW, required double waistHW, required double armHW,
  }) {
    final tl = cx - sholHW - armHW * 0.55;
    final tr = cx + sholHW + armHW * 0.55;
    final wl = cx - waistHW;
    final wr = cx + waistHW;
    final mid = shoulderY + (waistY - shoulderY) * 0.50;

    final topPath = Path()
      ..moveTo(tl, shoulderY)
      ..cubicTo(wl - sw * 0.016, mid - (mid - shoulderY) * 0.25,
                wl - sw * 0.006, mid + (waistY - mid) * 0.30, wl, waistY)
      ..lineTo(wr, waistY)
      ..cubicTo(wr + sw * 0.006, mid + (waistY - mid) * 0.30,
                wr + sw * 0.016, mid - (mid - shoulderY) * 0.25, tr, shoulderY)
      ..close();

    canvas.drawPath(topPath, Paint()
      ..shader = LinearGradient(
        colors: [_darken(top, 0.09), top, _lighten(top, 0.09)],
        stops: const [0.0, 0.48, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(tl, shoulderY, tr - tl, waistY - shoulderY)));

    // Collar
    if (_isDress) {
      canvas.drawPath(
        Path()
          ..moveTo(cx - sw * 0.058, shoulderY + 4)
          ..lineTo(cx, shoulderY + sh * 0.044)
          ..lineTo(cx + sw * 0.058, shoulderY + 4),
        Paint()
          ..color = trim.withOpacity(0.80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round);
    } else {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, shoulderY + 5),
                        width: sw * 0.13, height: sh * 0.034),
        0, math.pi, false,
        Paint()
          ..color = trim.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
    }

    // Cap sleeves
    _paintCapSleeve(canvas, cx - sholHW, shoulderY, armHW, top, trim, isLeft: true);
    _paintCapSleeve(canvas, cx + sholHW, shoulderY, armHW, top, trim, isLeft: false);
  }

  void _paintCapSleeve(Canvas canvas, double shoulderX, double shoulderY,
      double armHW, Color top, Color trim, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    final h = armHW * 1.35;
    final path = Path()
      ..moveTo(shoulderX - armHW * 0.18 * sign, shoulderY)
      ..quadraticBezierTo(
          shoulderX + sign * armHW * 1.08, shoulderY + h * 0.30,
          shoulderX + sign * armHW * 0.88, shoulderY + h)
      ..lineTo(shoulderX - sign * armHW * 0.15, shoulderY + h)
      ..quadraticBezierTo(
          shoulderX - sign * armHW * 0.35, shoulderY + h * 0.38,
          shoulderX - armHW * 0.18 * sign, shoulderY)
      ..close();
    canvas.drawPath(path, Paint()..color = _lighten(top, 0.07));
    canvas.drawLine(
      Offset(shoulderX - sign * armHW * 0.15, shoulderY + h),
      Offset(shoulderX + sign * armHW * 0.88, shoulderY + h),
      Paint()..color = trim.withOpacity(0.45)..strokeWidth = 1.4);
  }

  void _paintSkirt(Canvas canvas, double cx, double topY, double botY,
                   double topHW, Color top, Color bot, Color trim) {
    final botHW = topHW * 1.55;
    final midY  = topY + (botY - topY) * 0.50;
    final midHW = topHW * 1.26;

    final skirt = Path()
      ..moveTo(cx - topHW, topY)
      ..cubicTo(cx - midHW * 0.80, topY + (midY - topY) * 0.55,
                cx - midHW,        midY - (midY - topY) * 0.08, cx - midHW, midY)
      ..quadraticBezierTo(cx - botHW * 0.55, midY + (botY - midY) * 0.70,
                          cx - botHW, botY)
      ..lineTo(cx + botHW, botY)
      ..quadraticBezierTo(cx + botHW * 0.55, midY + (botY - midY) * 0.70,
                          cx + midHW, midY)
      ..cubicTo(cx + midHW, midY - (midY - topY) * 0.08,
                cx + midHW * 0.80, topY + (midY - topY) * 0.55, cx + topHW, topY)
      ..close();

    canvas.drawPath(skirt, Paint()
      ..shader = LinearGradient(
        colors: [_darken(top, 0.06), bot, _lighten(bot, 0.12)],
        stops: const [0.0, 0.52, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - botHW, topY, botHW * 2, botY - topY)));

    canvas.drawPath(
      Path()
        ..moveTo(cx - botHW + 6, botY - 4)
        ..quadraticBezierTo(cx, botY - 9, cx + botHW - 6, botY - 4),
      Paint()
        ..color = trim.withOpacity(0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round);
  }

  void _paintPants(Canvas canvas, double cx, double topY, double ankleY,
                   double legHW, Color bot, Color trim, {
    required double leftLegCx, required double rightLegCx,
    required double hipHW,
  }) {
    // Waistband
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - hipHW, topY - 8, cx + hipHW, topY + 10),
        const Radius.circular(5)),
      Paint()..color = _lighten(bot, 0.10));

    // Center crease
    canvas.drawLine(
      Offset(cx, topY + 2), Offset(cx, topY + (ankleY - topY) * 0.20),
      Paint()
        ..color = _darken(bot, 0.14).withOpacity(0.55)
        ..strokeWidth = 1.4);

    _paintTrouserLeg(canvas, leftLegCx,  topY, ankleY, legHW, bot, true);
    _paintTrouserLeg(canvas, rightLegCx, topY, ankleY, legHW, _darken(bot, 0.06), false);
  }

  void _paintTrouserLeg(Canvas canvas, double legCx, double topY, double botY,
                        double legHW, Color color, bool isLeft) {
    final path = Path()
      ..moveTo(legCx - legHW, topY)
      ..lineTo(legCx + legHW, topY)
      ..quadraticBezierTo(legCx + legHW * 0.94, topY + (botY - topY) * 0.58,
                          legCx + legHW * 0.82, botY)
      ..lineTo(legCx - legHW * 0.82, botY)
      ..quadraticBezierTo(legCx - legHW * 0.94, topY + (botY - topY) * 0.58,
                          legCx - legHW, topY)
      ..close();

    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        colors: isLeft
            ? [_darken(color, 0.09), color, _lighten(color, 0.05)]
            : [color, _lighten(color, 0.06), _darken(color, 0.07)],
        stops: const [0.0, 0.38, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(legCx - legHW, topY, legHW * 2, botY - topY)));

    // Knee crease hint
    final kneeY = topY + (botY - topY) * 0.50;
    canvas.drawLine(
      Offset(legCx - legHW * 0.52, kneeY),
      Offset(legCx + legHW * 0.52, kneeY),
      Paint()
        ..color = _darken(color, 0.12).withOpacity(0.44)
        ..strokeWidth = 1.2);
  }

  void _paintShoes(Canvas canvas, double topY, double botY, double legHW,
                   Color shoe, Color trim, {
    required double leftLegCx, required double rightLegCx,
  }) {
    _paintShoe(canvas, leftLegCx,  topY, botY, legHW, shoe, trim, isLeft: true);
    _paintShoe(canvas, rightLegCx, topY, botY, legHW, shoe, trim, isLeft: false);
  }

  void _paintShoe(Canvas canvas, double legCx, double topY, double botY,
                  double legHW, Color shoe, Color trim, {required bool isLeft}) {
    final h    = botY - topY;
    final toeX = legCx + (isLeft ? -legHW * 0.22 : legHW * 0.22);

    final path = Path()
      ..moveTo(legCx - legHW * 0.88, topY)
      ..lineTo(legCx + legHW * 0.88, topY)
      ..lineTo(legCx + legHW * 0.88, topY + h * 0.60)
      ..quadraticBezierTo(toeX + legHW * 0.82, botY, toeX + legHW * 1.08, botY)
      ..lineTo(legCx - legHW * 1.08, botY)
      ..quadraticBezierTo(legCx - legHW * 1.08, topY + h * 0.62,
                          legCx - legHW * 0.88, topY)
      ..close();

    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        colors: [shoe, _lighten(shoe, 0.13)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(legCx - legHW * 1.12, topY, legHW * 2.24, h)));

    // Sole highlight
    canvas.drawLine(
      Offset(legCx - legHW * 1.02, botY - h * 0.17),
      Offset(toeX + legHW * 1.00, botY - h * 0.17),
      Paint()..color = trim.withOpacity(0.32)..strokeWidth = 1.3);
  }

  // ── head ──────────────────────────────────────────────────────────────────

  void _paintHead(Canvas canvas, double cx, double headCy,
                  double headRx, double headRy) {
    final rect = Rect.fromCenter(
        center: Offset(cx, headCy), width: headRx * 2, height: headRy * 2.08);
    canvas.drawOval(rect, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.30),
        radius: 0.92,
        colors: [_lighten(_skin, 0.07), _skin, _darken(_skin, 0.09)],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(rect));

    // Soft chin shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, headCy + headRy * 0.82),
          width: headRx * 0.78, height: headRy * 0.21),
      Paint()
        ..color = _darken(_skin, 0.12).withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  // ── hair back ─────────────────────────────────────────────────────────────

  void _paintHairBack(Canvas canvas, double cx, double headCy,
                      double headRx, double headRy, double sh) {
    if (appearance.hairStyle == HairStyle.short ||
        appearance.hairStyle == HairStyle.bun) return;

    final hair = _hairBase;
    final tailLen = {
      HairStyle.medium: sh * 0.21,
      HairStyle.long:   sh * 0.44,
      HairStyle.curly:  sh * 0.14,
    }[appearance.hairStyle];

    if (tailLen != null) {
      for (final side in [-1.0, 1.0]) {
        final x = cx + side * headRx * 0.70;
        final path = Path()
          ..moveTo(x - 9, headCy + headRy * 0.28)
          ..cubicTo(x - 11, headCy + tailLen * 0.32,
                    x - 7,  headCy + tailLen * 0.70,
                    x - 3,  headCy + tailLen)
          ..lineTo(x + 9,   headCy + tailLen)
          ..cubicTo(x + 7,  headCy + tailLen * 0.70,
                    x + 11, headCy + tailLen * 0.32,
                    x + 9,  headCy + headRy * 0.28)
          ..close();
        canvas.drawPath(path, Paint()
          ..shader = LinearGradient(
            colors: [hair, _lighten(hair, 0.14)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x - 11, headCy, 22, tailLen)));
      }
    }

    if (appearance.hairStyle == HairStyle.ponytail) {
      final startX = cx + headRx * 0.68;
      final pt = Path()
        ..moveTo(startX - 10, headCy - headRy * 0.08)
        ..cubicTo(startX + sh * 0.075, headCy + sh * 0.048,
                  startX + sh * 0.105, headCy + sh * 0.115,
                  startX + sh * 0.028, headCy + sh * 0.275)
        ..lineTo(startX + sh * 0.028 - 10, headCy + sh * 0.275)
        ..cubicTo(startX + sh * 0.005, headCy + sh * 0.115,
                  startX - sh * 0.018, headCy + sh * 0.048,
                  startX - 10, headCy - headRy * 0.08)
        ..close();
      canvas.drawPath(pt, Paint()..color = hair);
    }
  }

  // ── hair front ────────────────────────────────────────────────────────────

  void _paintHairFront(Canvas canvas, double cx, double headCy,
                       double headRx, double headRy) {
    final hair  = _hairBase;
    final hairL = _lighten(hair, 0.22);

    final shRect = Rect.fromCenter(
        center: Offset(cx, headCy - headRy * 0.18),
        width: headRx * 2.4, height: headRy * 1.8);
    final hairP = Paint()
      ..shader = LinearGradient(
        colors: [_darken(hair, 0.05), hairL, hair],
        stops: const [0.0, 0.42, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(shRect);

    switch (appearance.hairStyle) {
      case HairStyle.short:
        _drawHairCap(canvas, cx, headCy, headRx, headRy, hairP, 0.64);
        for (final side in [-1.0, 1.0]) {
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx + side * headRx * 0.90, headCy - headRy * 0.04),
                width: 15, height: 28), hairP);
        }

      case HairStyle.medium:
        _drawHairCap(canvas, cx, headCy, headRx, headRy, hairP, 0.68);
        for (final side in [-1.0, 1.0]) {
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx + side * headRx * 0.92, headCy + headRy * 0.14),
                width: 17, height: headRy * 0.92), hairP);
        }

      case HairStyle.long:
        _drawHairCap(canvas, cx, headCy, headRx, headRy, hairP, 0.72);
        for (final side in [-1.0, 1.0]) {
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx + side * headRx * 0.92, headCy + headRy * 0.32),
                width: 17, height: headRy * 1.42), hairP);
        }

      case HairStyle.bun:
        _drawHairCap(canvas, cx, headCy, headRx, headRy, hairP, 0.64);
        canvas.drawCircle(Offset(cx, headCy - headRy * 0.60), headRy * 0.33, hairP);
        canvas.drawCircle(Offset(cx, headCy - headRy * 0.60), headRy * 0.33,
            Paint()
              ..color = _darken(hair, 0.16)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);

      case HairStyle.ponytail:
        _drawHairCap(canvas, cx, headCy, headRx, headRy, hairP, 0.64);
        canvas.drawCircle(
          Offset(cx + headRx * 0.70, headCy - headRy * 0.08), 5,
          Paint()..color = _darken(hair, 0.22));

      case HairStyle.curly:
        _drawHairCap(canvas, cx, headCy, headRx, headRy, hairP, 0.72);
        for (var i = 0; i < 6; i++) {
          canvas.drawCircle(
            Offset(cx - headRx * 0.90 + i * headRx * 0.36,
                   headCy - headRy * 0.46),
            headRy * 0.19, hairP);
        }
    }

    // Bangs
    final bangPath = Path()
      ..moveTo(cx - headRx * 0.84, headCy - headRy * 0.08)
      ..quadraticBezierTo(cx, headCy - headRy * 0.20, cx + headRx * 0.84, headCy - headRy * 0.08)
      ..lineTo(cx + headRx * 0.66, headCy + headRy * 0.10)
      ..quadraticBezierTo(cx, headCy + headRy * 0.20, cx - headRx * 0.66, headCy + headRy * 0.10)
      ..close();
    canvas.drawPath(bangPath, Paint()..color = hair);

    // Shine strand
    canvas.drawPath(
      Path()
        ..moveTo(cx - headRx * 0.18, headCy - headRy * 0.46)
        ..quadraticBezierTo(cx + headRx * 0.10, headCy - headRy * 0.22,
                            cx + headRx * 0.06, headCy - headRy * 0.02),
      Paint()
        ..color = hairL.withOpacity(0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round);
  }

  void _drawHairCap(Canvas canvas, double cx, double headCy,
                    double headRx, double headRy, Paint p, double topFrac) {
    canvas.drawOval(
      Rect.fromLTRB(
        cx - headRx * 1.10,
        headCy - headRy * (topFrac + 0.30),
        cx + headRx * 1.10,
        headCy + headRy * (1.0 - topFrac)),
      p);
  }

  // ── face ─────────────────────────────────────────────────────────────────

  void _paintFace(Canvas canvas, double cx, double headCy, double headRy, double sw) {
    final eyeY   = headCy + headRy * 0.12;
    final noseY  = headCy + headRy * 0.50;
    final mouthY = headCy + headRy * 0.74;
    final eyeGap = sw * 0.136;

    // Eyebrows
    final browP = Paint()
      ..color = _darken(_hairBase, 0.05).withOpacity(0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(cx + side * eyeGap - 8, eyeY - 12)
          ..quadraticBezierTo(cx + side * eyeGap + side * 2, eyeY - 15,
                              cx + side * eyeGap + 8, eyeY - 12),
        browP);
    }

    _paintEye(canvas, Offset(cx - eyeGap, eyeY), sw, false);
    _paintEye(canvas, Offset(cx + eyeGap, eyeY), sw, true);

    // Nose
    canvas.drawCircle(Offset(cx, noseY), 2.0,
        Paint()..color = _darken(_skin, 0.18).withOpacity(0.36));

    // Smile
    canvas.drawPath(
      Path()
        ..moveTo(cx - sw * 0.060, mouthY)
        ..quadraticBezierTo(cx, mouthY + sw * 0.036, cx + sw * 0.060, mouthY),
      Paint()
        ..color = _darken(_skin, 0.30).withOpacity(0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round);

    // Blush
    final blush = Paint()
      ..color = const Color(0xFFFCA5A5).withOpacity(0.46)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + side * eyeGap * 1.42, eyeY + headRy * 0.22),
            width: eyeGap * 0.92, height: headRy * 0.22),
        blush);
    }
  }

  void _paintEye(Canvas canvas, Offset center, double sw, bool isRight) {
    final accent = isMirror ? const Color(0xFFDB2777) : const Color(0xFF4F46E5);
    final ew = sw * 0.098;
    final eh = sw * 0.085;

    // Sclera
    canvas.drawOval(
      Rect.fromCenter(center: center, width: ew, height: eh),
      Paint()..color = const Color(0xFFF8F8FA));

    // Iris
    canvas.drawOval(
      Rect.fromCenter(center: center, width: ew * 0.68, height: eh * 0.88),
      Paint()..shader = RadialGradient(
        colors: [_lighten(accent, 0.28), accent, _darken(accent, 0.15)],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(
          Rect.fromCenter(center: center, width: ew * 0.68, height: eh * 0.88)));

    // Pupil
    canvas.drawCircle(center, ew * 0.160, Paint()..color = const Color(0xFF080812));

    // Primary highlight
    canvas.drawCircle(
      Offset(center.dx - (isRight ? ew * 0.17 : -ew * 0.17), center.dy - eh * 0.27),
      ew * 0.128, Paint()..color = Colors.white);

    // Secondary highlight
    canvas.drawCircle(
      Offset(center.dx + (isRight ? -ew * 0.24 : ew * 0.24), center.dy + eh * 0.16),
      ew * 0.058, Paint()..color = Colors.white.withOpacity(0.62));

    // Upper lash
    canvas.drawArc(
      Rect.fromCenter(center: center, width: ew, height: eh),
      math.pi * 1.04, math.pi * 0.92, false,
      Paint()
        ..color = const Color(0xFF0C0C1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ew * 0.138
        ..strokeCap = StrokeCap.round);
  }

  // ── accessories ───────────────────────────────────────────────────────────

  void _paintAccessories(Canvas canvas, double cx, double headCy,
                          double headRx, double headRy, double sh, double sw, {
    required double shoulderY, required double sholHW,
  }) {
    final eyeY  = headCy + headRy * 0.12;
    final eyeGap = sw * 0.136;

    for (final acc in appearance.accessories) {
      switch (acc) {
        case 'round_glasses':
        case 'sunglasses':
          final isDark = acc == 'sunglasses';
          final lensC  = isDark ? const Color(0xFF1E293B).withOpacity(0.54) : Colors.transparent;
          final frameC = isDark ? const Color(0xFF1C2434) : const Color(0xFF64748B);
          final ew = sw * 0.098;
          final eh = sw * 0.084;
          for (final side in [-1.0, 1.0]) {
            final oc = Offset(cx + side * eyeGap, eyeY);
            canvas.drawOval(Rect.fromCenter(center: oc, width: ew, height: eh),
                Paint()..color = lensC);
            canvas.drawOval(Rect.fromCenter(center: oc, width: ew, height: eh),
                Paint()..color = frameC..style = PaintingStyle.stroke..strokeWidth = 1.8);
          }
          canvas.drawLine(
            Offset(cx - eyeGap + ew * 0.48, eyeY),
            Offset(cx + eyeGap - ew * 0.48, eyeY),
            Paint()..color = frameC..strokeWidth = 1.5);

        case 'headband':
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, headCy - headRy * 0.18),
                              width: headRx * 2.22, height: 9),
              const Radius.circular(5)),
            Paint()..color = const Color(0xFFEC4899));

        case 'cap':
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, headCy - headRy * 0.20),
                            width: headRx * 2.62, height: 14),
            Paint()..color = const Color(0xFF334155));
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, headCy - headRy * 0.54),
                              width: headRx * 2.02, height: headRy * 0.78),
              const Radius.circular(10)),
            Paint()..color = const Color(0xFF475569));

        case 'beanie':
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, headCy - headRy * 0.28),
                              width: headRx * 2.16, height: headRy * 0.80),
              const Radius.circular(14)),
            Paint()..color = const Color(0xFFDC2626));
          canvas.drawCircle(Offset(cx, headCy - headRy * 0.72), 10,
              Paint()..color = const Color(0xFFFEE2E2));

        case 'scarf':
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, shoulderY + 10),
                              width: sholHW * 2 + 16, height: 18),
              const Radius.circular(9)),
            Paint()..color = const Color(0xFFDC2626));

        case 'necklace':
          canvas.drawArc(
            Rect.fromCenter(center: Offset(cx, shoulderY + 16), width: 32, height: 22),
            0, math.pi, false,
            Paint()
              ..color = const Color(0xFFD4AF37)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);

        case 'earrings':
          for (final side in [-1.0, 1.0]) {
            canvas.drawCircle(
              Offset(cx + side * headRx * 0.96, headCy + headRy * 0.22),
              4.5, Paint()..color = const Color(0xFFD4AF37));
          }

        case 'watch':
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx - sholHW - sw * 0.066, shoulderY + sh * 0.19),
                  width: 14, height: 10),
              const Radius.circular(3)),
            Paint()..color = const Color(0xFF94A3B8));

        default:
          break;
      }
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

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
