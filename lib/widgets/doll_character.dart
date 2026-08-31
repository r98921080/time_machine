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

  // ── palette ───────────────────────────────────────────────────────────────

  Color get _skin => const {
    SkinTone.light:  Color(0xFFFDE8D5),
    SkinTone.medium: Color(0xFFF2BA8C),
    SkinTone.tan:    Color(0xFFCF8252),
    SkinTone.dark:   Color(0xFF7C4224),
  }[appearance.skinTone]!;

  // Cel-shade levels
  Color _skinShad1(Color s) => _darken(s, 0.11);
  Color _skinShad2(Color s) => _darken(s, 0.20);
  Color _skinHi(Color s)    => _lighten(s, 0.09);

  Color get _hairBase => const {
    HairColor.black:   Color(0xFF242436),
    HairColor.brown:   Color(0xFF6B3A14),
    HairColor.blonde:  Color(0xFFEAC844),
    HairColor.red:     Color(0xFFB02020),
    HairColor.gray:    Color(0xFF989898),
    HairColor.fantasy: Color(0xFF7C3AED),
  }[appearance.hairColor]!;

  Color get _outline => const Color(0xFF1A1A2E);

  ({Color top, Color topShad, Color bot, Color botShad,
    Color shoe, Color trim, Color accent}) get _outfit {
    switch (appearance.outfitId) {
      case 'outfit_formal_suit': case 'suit':
        return (top: const Color(0xFF253048), topShad: const Color(0xFF14202E),
                bot: const Color(0xFF364560), botShad: const Color(0xFF1E2D40),
                shoe: const Color(0xFF0E1620), trim: const Color(0xFFCDD5E0),
                accent: const Color(0xFFE8EEF8));
      case 'outfit_sundress': case 'dress':
        return (top: const Color(0xFFEF5BA1), topShad: const Color(0xFFCA3880),
                bot: const Color(0xFFFBCFE8), botShad: const Color(0xFFF4A6CC),
                shoe: const Color(0xFFD0226A), trim: const Color(0xFFFFF0F7),
                accent: const Color(0xFFFFD4EB));
      case 'outfit_sport_set': case 'sporty':
        return (top: const Color(0xFF2257CE), topShad: const Color(0xFF163A95),
                bot: const Color(0xFF1E40AF), botShad: const Color(0xFF0E2870),
                shoe: const Color(0xFFE83030), trim: const Color(0xFFBFDBFE),
                accent: const Color(0xFFDEEEFF));
      case 'outfit_kimono':
        return (top: const Color(0xFFD940EF), topShad: const Color(0xFF9E1FAE),
                bot: const Color(0xFFF0ABFC), botShad: const Color(0xFFD078E8),
                shoe: const Color(0xFF6B1878), trim: const Color(0xFFFDF4FF),
                accent: const Color(0xFFF5D0FE));
      case 'outfit_hanfu':
        return (top: const Color(0xFF05946A), topShad: const Color(0xFF024F38),
                bot: const Color(0xFF6EE7B7), botShad: const Color(0xFF3DC49A),
                shoe: const Color(0xFF033B28), trim: const Color(0xFFECFDF5),
                accent: const Color(0xFFA7F3D0));
      case 'outfit_school_uniform': case 'school_uniform':
        return (top: const Color(0xFFF6F8FC), topShad: const Color(0xFFCDD5E2),
                bot: const Color(0xFF1E3A60), botShad: const Color(0xFF0E2040),
                shoe: const Color(0xFF0E1620), trim: const Color(0xFF0EA5E9),
                accent: const Color(0xFFBAE6FD));
      case 'outfit_casual_hoodie': case 'hoodie':
        return (top: const Color(0xFF60A5FA), topShad: const Color(0xFF3B80D4),
                bot: const Color(0xFF4B5A70), botShad: const Color(0xFF303C4E),
                shoe: const Color(0xFF1C2535), trim: const Color(0xFFDBEAFE),
                accent: const Color(0xFF93C5FD));
      case 'outfit_mage_robe':
        return (top: const Color(0xFF4E1E96), topShad: const Color(0xFF2E0F60),
                bot: const Color(0xFF6D28D9), botShad: const Color(0xFF4A1898),
                shoe: const Color(0xFF2A0E60), trim: const Color(0xFFC4B5FD),
                accent: const Color(0xFFEDE9FE));
      case 'outfit_cyberpunk':
        return (top: const Color(0xFF0F172A), topShad: const Color(0xFF060C18),
                bot: const Color(0xFF1E293B), botShad: const Color(0xFF0A1220),
                shoe: const Color(0xFF000000), trim: const Color(0xFF06B6D4),
                accent: const Color(0xFF22D3EE));
      case 'outfit_knight_armor':
        return (top: const Color(0xFFCBD5E1), topShad: const Color(0xFF94A3B8),
                bot: const Color(0xFF94A3B8), botShad: const Color(0xFF64748B),
                shoe: const Color(0xFF334155), trim: const Color(0xFFF59E0B),
                accent: const Color(0xFFFEF3C7));
      case 'outfit_shrine_maiden':
        return (top: const Color(0xFFDC2626), topShad: const Color(0xFF9C1010),
                bot: const Color(0xFFFEF2F2), botShad: const Color(0xFFFFCCCC),
                shoe: const Color(0xFF1C2535), trim: const Color(0xFF7F1D1D),
                accent: const Color(0xFFFEE2E2));
      case 'outfit_ninja':
        return (top: const Color(0xFF111827), topShad: const Color(0xFF060C14),
                bot: const Color(0xFF111827), botShad: const Color(0xFF060C14),
                shoe: const Color(0xFF0A0F18), trim: const Color(0xFF6B7A8E),
                accent: const Color(0xFF4B5A70));
      case 'outfit_pirate':
        return (top: const Color(0xFF7E3AED), topShad: const Color(0xFF5020B0),
                bot: const Color(0xFF202840), botShad: const Color(0xFF101420),
                shoe: const Color(0xFF2A2018), trim: const Color(0xFFEFB839),
                accent: const Color(0xFFFDE68A));
      case 'outfit_detective':
        return (top: const Color(0xFF7A360E), topShad: const Color(0xFF4E2208),
                bot: const Color(0xFF461C02), botShad: const Color(0xFF280E00),
                shoe: const Color(0xFF1A0A00), trim: const Color(0xFFFCD34D),
                accent: const Color(0xFFFDE68A));
      case 'outfit_egyptian':
        return (top: const Color(0xFFFBBF24), topShad: const Color(0xFFD48F10),
                bot: const Color(0xFFF59E0B), botShad: const Color(0xFFD07808),
                shoe: const Color(0xFF8E3E0A), trim: const Color(0xFFFEF9C3),
                accent: const Color(0xFFFFF3A0));
      case 'outfit_tshirt_white': case 'tshirt':
        return (top: const Color(0xFFF7F9FC), topShad: const Color(0xFFD3DAE6),
                bot: const Color(0xFF3B6BB0), botShad: const Color(0xFF244C86),
                shoe: const Color(0xFF2A3648), trim: const Color(0xFF60A5FA),
                accent: const Color(0xFFFFFFFF));
      case 'outfit_denim_jacket':
        return (top: const Color(0xFF3E72B8), topShad: const Color(0xFF264E88),
                bot: const Color(0xFF20304E), botShad: const Color(0xFF121C30),
                shoe: const Color(0xFF141A28), trim: const Color(0xFFE8B84B),
                accent: const Color(0xFF9EC1EA));
      case 'outfit_tracksuit':
        return (top: const Color(0xFF16A38A), topShad: const Color(0xFF0C6E5C),
                bot: const Color(0xFF14181F), botShad: const Color(0xFF080A0E),
                shoe: const Color(0xFFF4F6FA), trim: const Color(0xFFFACC15),
                accent: const Color(0xFF5EEAD4));
      case 'outfit_trench':
        return (top: const Color(0xFFC9A876), topShad: const Color(0xFF9A7C4E),
                bot: const Color(0xFF4A3A28), botShad: const Color(0xFF2C2016),
                shoe: const Color(0xFF261B10), trim: const Color(0xFF8A6A40),
                accent: const Color(0xFFEAD8B4));
      case 'outfit_chef':
        return (top: const Color(0xFFF8FAFD), topShad: const Color(0xFFD6DCE6),
                bot: const Color(0xFF2E3440), botShad: const Color(0xFF181C24),
                shoe: const Color(0xFF14181F), trim: const Color(0xFFDC2626),
                accent: const Color(0xFFFFFFFF));
      case 'outfit_lab_coat':
        return (top: const Color(0xFFF4F7FB), topShad: const Color(0xFFCED6E2),
                bot: const Color(0xFF44506A), botShad: const Color(0xFF283044),
                shoe: const Color(0xFF1A2130), trim: const Color(0xFF2563EB),
                accent: const Color(0xFFDBE7FA));
      case 'outfit_space_suit':
        return (top: const Color(0xFFEDF0F5), topShad: const Color(0xFFBFC7D4),
                bot: const Color(0xFFE0E5EC), botShad: const Color(0xFFB0B8C6),
                shoe: const Color(0xFF3A4252), trim: const Color(0xFFF97316),
                accent: const Color(0xFF38BDF8));
      default:
        return isMirror
            ? (top: const Color(0xFFDB2777), topShad: const Color(0xFF9D1757),
               bot: const Color(0xFFA01860), botShad: const Color(0xFF700F42),
               shoe: const Color(0xFF7C1040), trim: const Color(0xFFFCE7F3),
               accent: const Color(0xFFFDA4D4))
            : (top: const Color(0xFF5048E5), topShad: const Color(0xFF3428B0),
               bot: const Color(0xFF3B34A8), botShad: const Color(0xFF201C70),
               shoe: const Color(0xFF1A186A), trim: const Color(0xFFE0E7FF),
               accent: const Color(0xFFC7D2FE));
    }
  }

  bool get _isDress => const {
    'outfit_sundress', 'dress', 'outfit_kimono', 'outfit_hanfu',
    'outfit_mage_robe', 'outfit_shrine_maiden', 'outfit_egyptian',
  }.contains(appearance.outfitId);

  // ── helpers ───────────────────────────────────────────────────────────────

  // Fill shape, paint shadow clipped inside, then stroke outline
  void _celFill(Canvas canvas, Path path, Color base,
      {Color? shad, Path? shadPath, Color? hi, Path? hiPath,
       double lw = 2.0}) {
    canvas.drawPath(path, Paint()..color = base);
    if (shad != null && shadPath != null) {
      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(shadPath, Paint()..color = shad);
      canvas.restore();
    }
    if (hi != null && hiPath != null) {
      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(hiPath, Paint()..color = hi);
      canvas.restore();
    }
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..color = _outline
      ..strokeWidth = lw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  Color _lighten(Color c, double a) => HSLColor.fromColor(c)
      .withLightness((HSLColor.fromColor(c).lightness + a).clamp(0.0, 1.0))
      .toColor();
  Color _darken(Color c, double a) => HSLColor.fromColor(c)
      .withLightness((HSLColor.fromColor(c).lightness - a).clamp(0.0, 1.0))
      .toColor();

  // ── main paint ────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final fat = 0.88 + appearance.fatLevel * 0.28;
    final cx  = size.width  / 2;
    final sw  = size.width;
    final sh  = size.height;
    final lw  = sw * 0.014; // lineart stroke width, scales with canvas

    // ── landmarks ──────────────────────────────────────────────────────────
    final headCy    = sh * 0.088;
    final headRx    = sw * 0.170;
    final headRy    = sh * 0.086;

    final neckTopY  = sh * 0.160;
    final neckBotY  = sh * 0.200;
    final neckHW    = sw * 0.050;

    final shoulderY = neckBotY;
    final waistY    = sh * 0.436;
    final hipY      = sh * 0.502;
    final crotchY   = sh * 0.540;
    final kneeY     = sh * 0.714;
    final ankleY    = sh * 0.882;
    final footBotY  = sh * 0.948;

    final sholHW = (isFemale ? 0.194 : 0.244) * sw * fat;
    final waistHW= (isFemale ? 0.122 : 0.166) * sw * fat;
    final hipHW  = (isFemale ? 0.214 : 0.185) * sw * fat;
    final armHW  = (isFemale ? 0.039 : 0.049) * sw * fat;
    final legHW  = (isFemale ? 0.083 : 0.091) * sw * fat;

    final leftLegCx  = cx - hipHW * 0.52;
    final rightLegCx = cx + hipHW * 0.52;

    final skin  = _skin;
    final skS1  = _skinShad1(skin);
    final skS2  = _skinShad2(skin);
    final skHi  = _skinHi(skin);

    // Paint order: back hair → body skin → outfit → head → front hair → face → accessories
    _paintHairBack(canvas, cx, headCy, headRx, headRy, sh, lw);
    _paintBody(canvas, cx, sh, sw, skin, skS1, skS2, skHi, lw,
        neckTopY: neckTopY, neckBotY: neckBotY, neckHW: neckHW,
        shoulderY: shoulderY, waistY: waistY,
        hipY: hipY, crotchY: crotchY,
        kneeY: kneeY, ankleY: ankleY,
        sholHW: sholHW, waistHW: waistHW, hipHW: hipHW,
        armHW: armHW, legHW: legHW,
        leftLegCx: leftLegCx, rightLegCx: rightLegCx);
    _paintOutfit(canvas, cx, sh, sw, lw,
        shoulderY: shoulderY, waistY: waistY,
        hipY: hipY, crotchY: crotchY,
        kneeY: kneeY, ankleY: ankleY, footBotY: footBotY,
        sholHW: sholHW, waistHW: waistHW, hipHW: hipHW,
        armHW: armHW, legHW: legHW,
        leftLegCx: leftLegCx, rightLegCx: rightLegCx);
    _paintHead(canvas, cx, headCy, headRx, headRy, skin, skS1, skHi, lw);
    _paintHairFront(canvas, cx, headCy, headRx, headRy, lw);
    _paintFace(canvas, cx, headCy, headRy, sw, lw);
    _paintAccessories(canvas, cx, headCy, headRx, headRy, sh, sw, lw,
        shoulderY: shoulderY, sholHW: sholHW);
  }

  // ── head ─────────────────────────────────────────────────────────────────

  void _paintHead(Canvas canvas, double cx, double headCy,
      double headRx, double headRy,
      Color skin, Color skS1, Color skHi, double lw) {
    // Jaw slightly pointed at bottom
    final headPath = Path()
      ..moveTo(cx - headRx, headCy - headRy * 0.10)
      ..quadraticBezierTo(cx - headRx * 1.02, headCy + headRy * 0.30,
                          cx - headRx * 0.55, headCy + headRy * 0.95)
      ..quadraticBezierTo(cx - headRx * 0.20, headCy + headRy * 1.06,
                          cx, headCy + headRy * 1.08)
      ..quadraticBezierTo(cx + headRx * 0.20, headCy + headRy * 1.06,
                          cx + headRx * 0.55, headCy + headRy * 0.95)
      ..quadraticBezierTo(cx + headRx * 1.02, headCy + headRy * 0.30,
                          cx + headRx, headCy - headRy * 0.10)
      ..quadraticBezierTo(cx + headRx * 0.95, headCy - headRy * 1.08,
                          cx, headCy - headRy * 1.10)
      ..quadraticBezierTo(cx - headRx * 0.95, headCy - headRy * 1.08,
                          cx - headRx, headCy - headRy * 0.10)
      ..close();

    // Right-side shadow (cel shade)
    final headShadPath = Path()
      ..moveTo(cx + headRx * 0.22, headCy - headRy * 1.10)
      ..quadraticBezierTo(cx + headRx * 0.95, headCy - headRy * 1.08,
                          cx + headRx, headCy - headRy * 0.10)
      ..quadraticBezierTo(cx + headRx * 1.02, headCy + headRy * 0.30,
                          cx + headRx * 0.55, headCy + headRy * 0.95)
      ..quadraticBezierTo(cx + headRx * 0.20, headCy + headRy * 1.06,
                          cx + headRx * 0.14, headCy + headRy * 1.04)
      ..quadraticBezierTo(cx + headRx * 0.38, headCy + headRy * 0.40,
                          cx + headRx * 0.22, headCy - headRy * 1.10)
      ..close();

    // Chin AO shadow
    final chinShad = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(cx, headCy + headRy * 0.85),
          width: headRx * 0.70, height: headRy * 0.28));

    _celFill(canvas, headPath, skin,
        shad: skS1, shadPath: headShadPath, lw: lw);

    // Chin soft shadow
    canvas.save();
    canvas.clipPath(headPath);
    canvas.drawPath(chinShad,
        Paint()..color = skS1.withOpacity(0.45)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.restore();

    // Temple highlight
    canvas.save();
    canvas.clipPath(headPath);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - headRx * 0.32, headCy - headRy * 0.42),
                      width: headRx * 0.44, height: headRy * 0.36),
      Paint()..color = skHi.withOpacity(0.55));
    canvas.restore();
  }

  // ── hair back ─────────────────────────────────────────────────────────────

  void _paintHairBack(Canvas canvas, double cx, double headCy,
      double headRx, double headRy, double sh, double lw) {
    if (appearance.hairStyle == HairStyle.short ||
        appearance.hairStyle == HairStyle.bun) return;

    final hair = _hairBase;
    final hairSh = _darken(hair, 0.14);
    final tailLen = {
      HairStyle.medium: sh * 0.22,
      HairStyle.long:   sh * 0.46,
      HairStyle.curly:  sh * 0.15,
    }[appearance.hairStyle];

    if (tailLen != null) {
      for (final side in [-1.0, 1.0]) {
        final bx = cx + side * headRx * 0.68;
        final path = Path()
          ..moveTo(bx - 11, headCy + headRy * 0.25)
          ..cubicTo(bx - 13, headCy + tailLen * 0.30,
                    bx - 8,  headCy + tailLen * 0.68,
                    bx - 4,  headCy + tailLen)
          ..lineTo(bx + 10,  headCy + tailLen)
          ..cubicTo(bx + 8,  headCy + tailLen * 0.68,
                    bx + 13, headCy + tailLen * 0.30,
                    bx + 11, headCy + headRy * 0.25)
          ..close();
        final shadPath = Path()
          ..moveTo(bx + 2, headCy + headRy * 0.25)
          ..lineTo(bx + 11, headCy + headRy * 0.25)
          ..cubicTo(bx + 13, headCy + tailLen * 0.30,
                    bx + 8,  headCy + tailLen * 0.68,
                    bx + 10, headCy + tailLen)
          ..lineTo(bx + 2,   headCy + tailLen)
          ..close();
        _celFill(canvas, path, hair, shad: hairSh, shadPath: shadPath, lw: lw * 0.85);
      }
    }

    if (appearance.hairStyle == HairStyle.ponytail) {
      final sx = cx + headRx * 0.66;
      final len = sh * 0.30;
      final path = Path()
        ..moveTo(sx - 11, headCy - headRy * 0.10)
        ..cubicTo(sx + sh * 0.07, headCy + sh * 0.045,
                  sx + sh * 0.10, headCy + sh * 0.11,
                  sx + sh * 0.025, headCy + len)
        ..lineTo(sx + sh * 0.025 - 12, headCy + len)
        ..cubicTo(sx - sh * 0.02, headCy + sh * 0.11,
                  sx - sh * 0.02, headCy + sh * 0.045,
                  sx - 11, headCy - headRy * 0.10)
        ..close();
      final shadP = Path()
        ..moveTo(sx + 2, headCy - headRy * 0.10)
        ..cubicTo(sx + sh * 0.07, headCy + sh * 0.045,
                  sx + sh * 0.10, headCy + sh * 0.11,
                  sx + sh * 0.025, headCy + len)
        ..lineTo(sx + sh * 0.025 - 4, headCy + len)
        ..cubicTo(sx + sh * 0.06, headCy + sh * 0.11,
                  sx + sh * 0.03, headCy + sh * 0.045,
                  sx + 2, headCy - headRy * 0.10)
        ..close();
      _celFill(canvas, path, hair, shad: hairSh, shadPath: shadP, lw: lw * 0.85);
    }
  }

  // ── body skin ─────────────────────────────────────────────────────────────

  void _paintBody(Canvas canvas, double cx, double sh, double sw,
      Color skin, Color skS1, Color skS2, Color skHi, double lw, {
    required double neckTopY, required double neckBotY, required double neckHW,
    required double shoulderY, required double waistY,
    required double hipY, required double crotchY,
    required double kneeY, required double ankleY,
    required double sholHW, required double waistHW, required double hipHW,
    required double armHW, required double legHW,
    required double leftLegCx, required double rightLegCx,
  }) {
    // Neck
    final neckPath = Path()
      ..moveTo(cx - neckHW, neckTopY)
      ..lineTo(cx + neckHW * 1.08, neckTopY)
      ..lineTo(cx + neckHW * 1.20, neckBotY)
      ..lineTo(cx - neckHW, neckBotY)
      ..close();
    final neckShad = Path()
      ..moveTo(cx + neckHW * 0.20, neckTopY)
      ..lineTo(cx + neckHW * 1.08, neckTopY)
      ..lineTo(cx + neckHW * 1.20, neckBotY)
      ..lineTo(cx + neckHW * 0.20, neckBotY)
      ..close();
    _celFill(canvas, neckPath, skin, shad: skS1, shadPath: neckShad, lw: lw * 0.85);

    // Torso
    final tl = cx - sholHW; final tr = cx + sholHW;
    final wl = cx - waistHW; final wr = cx + waistHW;
    final hl = cx - hipHW;   final hr = cx + hipHW;
    final tp1 = shoulderY + (waistY - shoulderY) * 0.36;
    final tp2 = shoulderY + (waistY - shoulderY) * 0.72;
    final tp3 = waistY + (hipY - waistY) * 0.34;
    final tp4 = waistY + (hipY - waistY) * 0.78;

    final torsoPath = Path()
      ..moveTo(tl, shoulderY)
      ..cubicTo(wl - sw * 0.020, tp1, wl - sw * 0.009, tp2, wl, waistY)
      ..cubicTo(hl + sw * 0.009, tp3, hl + sw * 0.004, tp4, hl, hipY)
      ..lineTo(hl, crotchY)
      ..lineTo(hr, crotchY)
      ..lineTo(hr, hipY)
      ..cubicTo(hr - sw * 0.004, tp4, hr - sw * 0.009, tp3, wr, waistY)
      ..cubicTo(wr + sw * 0.009, tp2, wr + sw * 0.020, tp1, tr, shoulderY)
      ..close();

    // Right-side torso shadow
    final torsoShad = Path()
      ..moveTo(cx + sholHW * 0.32, shoulderY)
      ..cubicTo(wr + sw * 0.009, tp2, wr + sw * 0.020, tp1, tr, shoulderY)
      ..lineTo(hr, hipY)
      ..lineTo(hr, crotchY)
      ..lineTo(cx + waistHW * 0.55, crotchY)
      ..lineTo(cx + waistHW * 0.55, waistY)
      ..quadraticBezierTo(cx + sholHW * 0.42, tp2, cx + sholHW * 0.32, shoulderY)
      ..close();

    _celFill(canvas, torsoPath, skin, shad: skS1, shadPath: torsoShad, lw: lw);

    // Collar-bone highlight line
    canvas.save();
    canvas.clipPath(torsoPath);
    canvas.drawLine(
      Offset(cx - sholHW * 0.55, shoulderY + sh * 0.022),
      Offset(cx + sholHW * 0.10, shoulderY + sh * 0.022),
      Paint()
        ..color = skHi.withOpacity(0.70)
        ..strokeWidth = lw * 0.70
        ..strokeCap = StrokeCap.round);
    canvas.restore();

    // Female bust area (cel shadow arcs)
    if (isFemale) {
      final bustY = shoulderY + (waistY - shoulderY) * 0.44;
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.clipPath(torsoPath);
        canvas.drawArc(
          Rect.fromCenter(
              center: Offset(cx + side * sholHW * 0.30, bustY - sh * 0.012),
              width: sholHW * 0.60, height: sh * 0.055),
          math.pi * 0.30, math.pi * 0.75, false,
          Paint()
            ..color = skS1.withOpacity(0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = lw * 0.65
            ..strokeCap = StrokeCap.round);
        canvas.restore();
      }
    }

    // Arms
    _paintArm(canvas, true,  cx - sholHW, shoulderY,
              waistY + sh * 0.040, armHW, skin, skS1, lw);
    _paintArm(canvas, false, cx + sholHW, shoulderY,
              waistY + sh * 0.040, armHW, skin, skS1, lw);

    // Calves
    _paintCalf(canvas, leftLegCx,  kneeY, ankleY, legHW, skin, skS1, lw);
    _paintCalf(canvas, rightLegCx, kneeY, ankleY, legHW, skin, skS1, lw);
  }

  void _paintArm(Canvas canvas, bool isLeft, double shoulderX,
      double topY, double botY, double armHW,
      Color skin, Color skS1, double lw) {
    final sign = isLeft ? -1.0 : 1.0;
    final mid  = topY + (botY - topY) * 0.50;
    final elbowX = shoulderX + sign * armHW * 0.58;

    final path = Path()
      ..moveTo(shoulderX - armHW, topY)
      ..lineTo(shoulderX + armHW, topY)
      ..quadraticBezierTo(elbowX + armHW, mid, shoulderX + armHW * 0.48, botY)
      ..lineTo(shoulderX - armHW * 0.48, botY)
      ..quadraticBezierTo(elbowX - armHW, mid, shoulderX - armHW, topY)
      ..close();

    // Shadow: inner (body-facing) half of the arm
    final shadPath = Path()
      ..moveTo(shoulderX + armHW * (isLeft ? -0.08 : 0.08), topY)
      ..lineTo(shoulderX + armHW, topY)
      ..quadraticBezierTo(elbowX + armHW, mid, shoulderX + armHW * 0.48, botY)
      ..lineTo(shoulderX + armHW * (isLeft ? -0.08 : 0.08), botY)
      ..close();

    _celFill(canvas, path, skin, shad: skS1, shadPath: shadPath, lw: lw * 0.85);

    // Hand
    final handPath = Path()..addOval(Rect.fromCenter(
        center: Offset(shoulderX, botY + (botY - topY) * 0.042),
        width: armHW * 1.78, height: (botY - topY) * 0.066));
    _celFill(canvas, handPath, skin, lw: lw * 0.70);
  }

  void _paintCalf(Canvas canvas, double legCx, double topY, double botY,
      double legHW, Color skin, Color skS1, double lw) {
    final path = Path()
      ..moveTo(legCx - legHW, topY)
      ..lineTo(legCx + legHW, topY)
      ..quadraticBezierTo(legCx + legHW * 0.90, topY + (botY - topY) * 0.56,
                          legCx + legHW * 0.62, botY)
      ..lineTo(legCx - legHW * 0.62, botY)
      ..quadraticBezierTo(legCx - legHW * 0.90, topY + (botY - topY) * 0.56,
                          legCx - legHW, topY)
      ..close();
    final shadPath = Path()
      ..moveTo(legCx + legHW * 0.22, topY)
      ..lineTo(legCx + legHW, topY)
      ..quadraticBezierTo(legCx + legHW * 0.90, topY + (botY - topY) * 0.56,
                          legCx + legHW * 0.62, botY)
      ..lineTo(legCx + legHW * 0.22, botY)
      ..close();
    _celFill(canvas, path, skin, shad: skS1, shadPath: shadPath, lw: lw * 0.85);
  }

  // ── outfit ────────────────────────────────────────────────────────────────

  void _paintOutfit(Canvas canvas, double cx, double sh, double sw, double lw, {
    required double shoulderY, required double waistY,
    required double hipY, required double crotchY,
    required double kneeY, required double ankleY, required double footBotY,
    required double sholHW, required double waistHW, required double hipHW,
    required double armHW, required double legHW,
    required double leftLegCx, required double rightLegCx,
  }) {
    final c = _outfit;

    _paintTop(canvas, cx, sh, sw, c.top, c.topShad, c.trim, c.accent, lw,
        shoulderY: shoulderY, waistY: waistY,
        sholHW: sholHW, waistHW: waistHW, armHW: armHW);

    if (_isDress) {
      _paintSkirt(canvas, cx, hipY, ankleY, hipHW * 1.02,
                  c.top, c.topShad, c.bot, c.botShad, c.trim, lw);
    } else {
      _paintPants(canvas, cx, crotchY, ankleY, legHW,
                  c.bot, c.botShad, c.trim, lw,
                  leftLegCx: leftLegCx, rightLegCx: rightLegCx, hipHW: hipHW);
    }

    _paintShoes(canvas, ankleY, footBotY, legHW, c.shoe, c.trim, lw,
        leftLegCx: leftLegCx, rightLegCx: rightLegCx);
  }

  void _paintTop(Canvas canvas, double cx, double sh, double sw,
      Color top, Color topShad, Color trim, Color accent, double lw, {
    required double shoulderY, required double waistY,
    required double sholHW, required double waistHW, required double armHW,
  }) {
    final tl = cx - sholHW - armHW * 0.52;
    final tr = cx + sholHW + armHW * 0.52;
    final wl = cx - waistHW;
    final wr = cx + waistHW;
    final mid = shoulderY + (waistY - shoulderY) * 0.50;

    final topPath = Path()
      ..moveTo(tl, shoulderY)
      ..cubicTo(wl - sw * 0.014, mid - (mid - shoulderY) * 0.22,
                wl - sw * 0.005, mid + (waistY - mid) * 0.28, wl, waistY)
      ..lineTo(wr, waistY)
      ..cubicTo(wr + sw * 0.005, mid + (waistY - mid) * 0.28,
                wr + sw * 0.014, mid - (mid - shoulderY) * 0.22, tr, shoulderY)
      ..close();

    // Right-side shadow
    final topShadPath = Path()
      ..moveTo(cx + sholHW * 0.28, shoulderY)
      ..cubicTo(wr + sw * 0.005, mid + (waistY - mid) * 0.28,
                wr + sw * 0.014, mid - (mid - shoulderY) * 0.22, tr, shoulderY)
      ..lineTo(wr, waistY)
      ..lineTo(cx + waistHW * 0.48, waistY)
      ..quadraticBezierTo(cx + sholHW * 0.38, mid, cx + sholHW * 0.28, shoulderY)
      ..close();

    // Cloth fold highlight down center-left
    final foldHi = Path()
      ..moveTo(cx - sholHW * 0.15, shoulderY + (waistY - shoulderY) * 0.10)
      ..quadraticBezierTo(cx - waistHW * 0.18, mid,
                          cx - waistHW * 0.06, waistY - sh * 0.010)
      ..lineTo(cx - waistHW * 0.20, waistY - sh * 0.010)
      ..quadraticBezierTo(cx - sholHW * 0.30, mid,
                          cx - sholHW * 0.28, shoulderY + (waistY - shoulderY) * 0.10)
      ..close();

    _celFill(canvas, topPath, top, shad: topShad, shadPath: topShadPath,
             hi: accent, hiPath: foldHi, lw: lw);

    // Collar
    if (_isDress) {
      canvas.drawPath(
        Path()
          ..moveTo(cx - sw * 0.056, shoulderY + 4)
          ..lineTo(cx, shoulderY + sh * 0.042)
          ..lineTo(cx + sw * 0.056, shoulderY + 4),
        Paint()
          ..color = trim
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw * 0.80
          ..strokeCap = StrokeCap.round);
    } else {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, shoulderY + 5),
                        width: sw * 0.13, height: sh * 0.033),
        0, math.pi, false,
        Paint()
          ..color = trim
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw * 0.80);
    }

    // Waist seam line
    canvas.drawLine(Offset(wl, waistY), Offset(wr, waistY),
        Paint()..color = topShad..strokeWidth = lw * 0.60);

    // Sleeves
    _paintSleeve(canvas, cx - sholHW, shoulderY, waistY, armHW,
                 top, topShad, trim, lw, isLeft: true);
    _paintSleeve(canvas, cx + sholHW, shoulderY, waistY, armHW,
                 top, topShad, trim, lw, isLeft: false);
  }

  void _paintSleeve(Canvas canvas, double shoulderX, double shoulderY,
      double waistY, double armHW, Color top, Color topShad,
      Color trim, double lw, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    final h = armHW * 1.40;
    final path = Path()
      ..moveTo(shoulderX - armHW * 0.16 * sign, shoulderY)
      ..quadraticBezierTo(
          shoulderX + sign * armHW * 1.10, shoulderY + h * 0.28,
          shoulderX + sign * armHW * 0.90, shoulderY + h)
      ..lineTo(shoulderX - sign * armHW * 0.14, shoulderY + h)
      ..quadraticBezierTo(
          shoulderX - sign * armHW * 0.36, shoulderY + h * 0.36,
          shoulderX - armHW * 0.16 * sign, shoulderY)
      ..close();
    final shadPath = Path()
      ..moveTo(shoulderX + sign * armHW * 0.28, shoulderY)
      ..quadraticBezierTo(
          shoulderX + sign * armHW * 1.10, shoulderY + h * 0.28,
          shoulderX + sign * armHW * 0.90, shoulderY + h)
      ..lineTo(shoulderX + sign * armHW * 0.28, shoulderY + h)
      ..close();
    _celFill(canvas, path, top, shad: topShad, shadPath: shadPath, lw: lw * 0.80);
    // Cuff trim
    canvas.drawLine(
      Offset(shoulderX - sign * armHW * 0.14, shoulderY + h),
      Offset(shoulderX + sign * armHW * 0.90, shoulderY + h),
      Paint()..color = trim..strokeWidth = lw * 0.65);
  }

  void _paintSkirt(Canvas canvas, double cx, double topY, double botY,
      double topHW, Color top, Color topShad, Color bot, Color botShad,
      Color trim, double lw) {
    final botHW = topHW * 1.58;
    final midY  = topY + (botY - topY) * 0.50;
    final midHW = topHW * 1.27;

    final path = Path()
      ..moveTo(cx - topHW, topY)
      ..cubicTo(cx - midHW * 0.78, topY + (midY - topY) * 0.54,
                cx - midHW, midY - 4, cx - midHW, midY)
      ..quadraticBezierTo(cx - botHW * 0.54, midY + (botY - midY) * 0.68,
                          cx - botHW, botY)
      ..lineTo(cx + botHW, botY)
      ..quadraticBezierTo(cx + botHW * 0.54, midY + (botY - midY) * 0.68,
                          cx + midHW, midY)
      ..cubicTo(cx + midHW, midY - 4,
                cx + midHW * 0.78, topY + (midY - topY) * 0.54, cx + topHW, topY)
      ..close();

    // Right-side shadow
    final shadPath = Path()
      ..moveTo(cx + topHW * 0.25, topY)
      ..cubicTo(cx + midHW * 0.78, topY + (midY - topY) * 0.54,
                cx + midHW, midY - 4, cx + midHW, midY)
      ..quadraticBezierTo(cx + botHW * 0.54, midY + (botY - midY) * 0.68,
                          cx + botHW, botY)
      ..lineTo(cx + botHW * 0.30, botY)
      ..quadraticBezierTo(cx + botHW * 0.10, midY + (botY - midY) * 0.68,
                          cx + midHW * 0.10, midY)
      ..cubicTo(cx + midHW * 0.10, midY - 4,
                cx + midHW * 0.22, topY + (midY - topY) * 0.54,
                cx + topHW * 0.25, topY)
      ..close();

    // Fold highlight (center-left strip)
    final hiPath = Path()
      ..moveTo(cx - topHW * 0.22, topY)
      ..cubicTo(cx - midHW * 0.04, topY + (midY - topY) * 0.54,
                cx - midHW * 0.12, midY - 4, cx - midHW * 0.12, midY)
      ..quadraticBezierTo(cx - botHW * 0.02, midY + (botY - midY) * 0.68,
                          cx - botHW * 0.06, botY)
      ..lineTo(cx - botHW * 0.18, botY)
      ..quadraticBezierTo(cx - botHW * 0.14, midY + (botY - midY) * 0.68,
                          cx - midHW * 0.26, midY)
      ..cubicTo(cx - midHW * 0.26, midY - 4,
                cx - midHW * 0.18, topY + (midY - topY) * 0.54,
                cx - topHW * 0.34, topY)
      ..close();

    _celFill(canvas, path, bot, shad: botShad, shadPath: shadPath,
             hi: _lighten(bot, 0.12), hiPath: hiPath, lw: lw);

    // Hem
    canvas.drawPath(
      Path()
        ..moveTo(cx - botHW + 5, botY - 4)
        ..quadraticBezierTo(cx, botY - 8, cx + botHW - 5, botY - 4),
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 0.65
        ..strokeCap = StrokeCap.round);
  }

  void _paintPants(Canvas canvas, double cx, double topY, double ankleY,
      double legHW, Color bot, Color botShad, Color trim, double lw, {
    required double leftLegCx, required double rightLegCx,
    required double hipHW,
  }) {
    // Waistband
    final wbPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - hipHW, topY - 9, cx + hipHW, topY + 11),
        const Radius.circular(4)));
    final wbShad = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + hipHW * 0.20, topY - 9, cx + hipHW, topY + 11),
        const Radius.circular(4)));
    _celFill(canvas, wbPath, _lighten(bot, 0.10), shad: bot,
             shadPath: wbShad, lw: lw * 0.70);

    // Crotch fold
    canvas.drawLine(
      Offset(cx, topY + 2), Offset(cx, topY + (ankleY - topY) * 0.18),
      Paint()..color = botShad..strokeWidth = lw * 0.60);

    _paintTrouserLeg(canvas, leftLegCx,  topY, ankleY, legHW, bot, botShad, trim, lw, true);
    _paintTrouserLeg(canvas, rightLegCx, topY, ankleY, legHW,
                     _darken(bot, 0.06), _darken(botShad, 0.06), trim, lw, false);
  }

  void _paintTrouserLeg(Canvas canvas, double legCx, double topY, double botY,
      double legHW, Color color, Color shad, Color trim, double lw, bool isLeft) {
    final path = Path()
      ..moveTo(legCx - legHW, topY)
      ..lineTo(legCx + legHW, topY)
      ..quadraticBezierTo(legCx + legHW * 0.93, topY + (botY - topY) * 0.57,
                          legCx + legHW * 0.80, botY)
      ..lineTo(legCx - legHW * 0.80, botY)
      ..quadraticBezierTo(legCx - legHW * 0.93, topY + (botY - topY) * 0.57,
                          legCx - legHW, topY)
      ..close();
    // Shadow on inner/right side
    final shadPath = Path()
      ..moveTo(legCx + legHW * (isLeft ? 0.18 : -0.18), topY)
      ..lineTo(legCx + legHW, topY)
      ..quadraticBezierTo(legCx + legHW * 0.93, topY + (botY - topY) * 0.57,
                          legCx + legHW * 0.80, botY)
      ..lineTo(legCx + legHW * (isLeft ? 0.18 : -0.18), botY)
      ..close();
    // Center fold highlight
    final hiPath = Path()
      ..moveTo(legCx - legHW * 0.12, topY)
      ..lineTo(legCx + legHW * 0.12, topY)
      ..lineTo(legCx + legHW * 0.08, botY)
      ..lineTo(legCx - legHW * 0.08, botY)
      ..close();
    _celFill(canvas, path, color, shad: shad, shadPath: shadPath,
             hi: _lighten(color, 0.10), hiPath: hiPath, lw: lw * 0.85);
    // Knee crease
    final kneeY = topY + (botY - topY) * 0.50;
    canvas.drawLine(
      Offset(legCx - legHW * 0.50, kneeY), Offset(legCx + legHW * 0.50, kneeY),
      Paint()..color = shad..strokeWidth = lw * 0.55..strokeCap = StrokeCap.round);
  }

  void _paintShoes(Canvas canvas, double topY, double botY, double legHW,
      Color shoe, Color trim, double lw, {
    required double leftLegCx, required double rightLegCx,
  }) {
    _paintShoe(canvas, leftLegCx,  topY, botY, legHW, shoe, trim, lw, true);
    _paintShoe(canvas, rightLegCx, topY, botY, legHW, shoe, trim, lw, false);
  }

  void _paintShoe(Canvas canvas, double legCx, double topY, double botY,
      double legHW, Color shoe, Color trim, double lw, bool isLeft) {
    final h    = botY - topY;
    final toeX = legCx + (isLeft ? -legHW * 0.20 : legHW * 0.20);
    final path = Path()
      ..moveTo(legCx - legHW * 0.86, topY)
      ..lineTo(legCx + legHW * 0.86, topY)
      ..lineTo(legCx + legHW * 0.86, topY + h * 0.58)
      ..quadraticBezierTo(toeX + legHW * 0.80, botY, toeX + legHW * 1.10, botY)
      ..lineTo(legCx - legHW * 1.08, botY)
      ..quadraticBezierTo(legCx - legHW * 1.08, topY + h * 0.60,
                          legCx - legHW * 0.86, topY)
      ..close();
    // Toe highlight
    final hiPath = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(toeX, botY - h * 0.22),
          width: legHW * 0.90, height: h * 0.22));
    _celFill(canvas, path, shoe,
             hi: _lighten(shoe, 0.18), hiPath: hiPath, lw: lw * 0.85);
    // Sole line
    canvas.drawLine(
      Offset(legCx - legHW * 1.02, botY - h * 0.18),
      Offset(toeX + legHW * 1.02, botY - h * 0.18),
      Paint()..color = trim..strokeWidth = lw * 0.55);
  }

  // ── hair front ────────────────────────────────────────────────────────────

  void _paintHairFront(Canvas canvas, double cx, double headCy,
      double headRx, double headRy, double lw) {
    final hair   = _hairBase;
    final hairSh = _darken(hair, 0.14);
    final hairHi = _lighten(hair, 0.24);

    switch (appearance.hairStyle) {
      case HairStyle.short:
        _paintHairGroup(canvas, cx, headCy, headRx, headRy,
                        hair, hairSh, hairHi, lw, 0.65, false);
        // Side tufts
        for (final side in [-1.0, 1.0]) {
          final path = Path()..addOval(Rect.fromCenter(
              center: Offset(cx + side * headRx * 0.88, headCy - headRy * 0.04),
              width: 16, height: 30));
          _celFill(canvas, path, hair, lw: lw * 0.70);
        }

      case HairStyle.medium:
        _paintHairGroup(canvas, cx, headCy, headRx, headRy,
                        hair, hairSh, hairHi, lw, 0.70, false);
        for (final side in [-1.0, 1.0]) {
          final path = Path()..addOval(Rect.fromCenter(
              center: Offset(cx + side * headRx * 0.90, headCy + headRy * 0.14),
              width: 18, height: headRy * 0.94));
          _celFill(canvas, path, hair, lw: lw * 0.70);
        }

      case HairStyle.long:
        _paintHairGroup(canvas, cx, headCy, headRx, headRy,
                        hair, hairSh, hairHi, lw, 0.74, false);
        for (final side in [-1.0, 1.0]) {
          final path = Path()..addOval(Rect.fromCenter(
              center: Offset(cx + side * headRx * 0.90, headCy + headRy * 0.34),
              width: 18, height: headRy * 1.44));
          _celFill(canvas, path, hair, lw: lw * 0.70);
        }

      case HairStyle.bun:
        _paintHairGroup(canvas, cx, headCy, headRx, headRy,
                        hair, hairSh, hairHi, lw, 0.65, false);
        final bunPath = Path()
          ..addOval(Rect.fromCenter(
              center: Offset(cx, headCy - headRy * 0.62),
              width: headRy * 0.68, height: headRy * 0.66));
        _celFill(canvas, bunPath, hair,
                 hi: hairHi, hiPath: Path()..addOval(Rect.fromCenter(
                     center: Offset(cx - headRy * 0.08, headCy - headRy * 0.72),
                     width: headRy * 0.22, height: headRy * 0.18)),
                 lw: lw);

      case HairStyle.ponytail:
        _paintHairGroup(canvas, cx, headCy, headRx, headRy,
                        hair, hairSh, hairHi, lw, 0.65, false);
        // Hair tie
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + headRx * 0.72, headCy - headRy * 0.10),
                          width: 11, height: 9),
          Paint()..color = _darken(hair, 0.22));
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + headRx * 0.72, headCy - headRy * 0.10),
                          width: 11, height: 9),
          Paint()..color = _outline..style = PaintingStyle.stroke..strokeWidth = lw * 0.65);

      case HairStyle.curly:
        _paintHairGroup(canvas, cx, headCy, headRx, headRy,
                        hair, hairSh, hairHi, lw, 0.72, true);
    }

    // Bangs — drawn as distinct path on top of everything
    final bangPath = Path()
      ..moveTo(cx - headRx * 0.86, headCy - headRy * 0.06)
      ..cubicTo(cx - headRx * 0.55, headCy - headRy * 0.30,
                cx - headRx * 0.10, headCy - headRy * 0.22,
                cx + headRx * 0.14, headCy + headRy * 0.02)
      ..lineTo(cx + headRx * 0.05, headCy + headRy * 0.16)
      ..cubicTo(cx - headRx * 0.08, headCy - headRy * 0.06,
                cx - headRx * 0.46, headCy - headRy * 0.12,
                cx - headRx * 0.72, headCy + headRy * 0.14)
      ..close();

    // Side bang
    final sideBang = Path()
      ..moveTo(cx + headRx * 0.14, headCy + headRy * 0.02)
      ..cubicTo(cx + headRx * 0.50, headCy - headRy * 0.22,
                cx + headRx * 0.82, headCy - headRy * 0.14,
                cx + headRx * 0.86, headCy - headRy * 0.04)
      ..lineTo(cx + headRx * 0.72, headCy + headRy * 0.14)
      ..cubicTo(cx + headRx * 0.65, headCy - headRy * 0.06,
                cx + headRx * 0.42, headCy - headRy * 0.10,
                cx + headRx * 0.05, headCy + headRy * 0.16)
      ..close();

    // Bang shadow
    final bangShad = Path()
      ..moveTo(cx - headRx * 0.02, headCy - headRy * 0.10)
      ..cubicTo(cx + headRx * 0.08, headCy - headRy * 0.20,
                cx + headRx * 0.14, headCy - headRy * 0.08,
                cx + headRx * 0.14, headCy + headRy * 0.02)
      ..lineTo(cx + headRx * 0.05, headCy + headRy * 0.16)
      ..lineTo(cx - headRx * 0.08, headCy + headRy * 0.06)
      ..close();

    _celFill(canvas, bangPath, hair, shad: hairSh, shadPath: bangShad, lw: lw * 0.80);
    _celFill(canvas, sideBang, hair, lw: lw * 0.75);

    // Hair shine highlight stroke
    canvas.drawPath(
      Path()
        ..moveTo(cx - headRx * 0.22, headCy - headRy * 0.50)
        ..quadraticBezierTo(cx + headRx * 0.12, headCy - headRy * 0.24,
                            cx + headRx * 0.08, headCy - headRy * 0.04),
      Paint()
        ..color = hairHi.withOpacity(0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 0.60
        ..strokeCap = StrokeCap.round);
  }

  void _paintHairGroup(Canvas canvas, double cx, double headCy,
      double headRx, double headRy, Color hair, Color hairSh,
      Color hairHi, double lw, double topFrac, bool curly) {
    // Cap shape
    final capPath = Path()
      ..moveTo(cx - headRx * 1.10, headCy - headRy * (topFrac - 0.70))
      ..quadraticBezierTo(cx - headRx * 1.08, headCy - headRy * (topFrac + 0.18),
                          cx - headRx * 0.45, headCy - headRy * (topFrac + 0.30))
      ..quadraticBezierTo(cx, headCy - headRy * (topFrac + 0.36),
                          cx + headRx * 0.45, headCy - headRy * (topFrac + 0.30))
      ..quadraticBezierTo(cx + headRx * 1.08, headCy - headRy * (topFrac + 0.18),
                          cx + headRx * 1.10, headCy - headRy * (topFrac - 0.70))
      ..quadraticBezierTo(cx + headRx * 1.05, headCy + headRy * 0.28,
                          cx + headRx * 0.90, headCy + headRy * (1.0 - topFrac))
      ..lineTo(cx - headRx * 0.90, headCy + headRy * (1.0 - topFrac))
      ..quadraticBezierTo(cx - headRx * 1.05, headCy + headRy * 0.28,
                          cx - headRx * 1.10, headCy - headRy * (topFrac - 0.70))
      ..close();

    // Shadow right half
    final capShad = Path()
      ..moveTo(cx + headRx * 0.25, headCy - headRy * (topFrac + 0.30))
      ..quadraticBezierTo(cx + headRx * 1.08, headCy - headRy * (topFrac + 0.18),
                          cx + headRx * 1.10, headCy - headRy * (topFrac - 0.70))
      ..quadraticBezierTo(cx + headRx * 1.05, headCy + headRy * 0.28,
                          cx + headRx * 0.90, headCy + headRy * (1.0 - topFrac))
      ..lineTo(cx + headRx * 0.25, headCy + headRy * (1.0 - topFrac))
      ..close();

    // Highlight oval top-left
    final capHi = Path()..addOval(Rect.fromCenter(
        center: Offset(cx - headRx * 0.28, headCy - headRy * (topFrac + 0.04)),
        width: headRx * 0.56, height: headRy * 0.30));

    _celFill(canvas, capPath, hair, shad: hairSh, shadPath: capShad,
             hi: hairHi, hiPath: capHi, lw: lw);

    if (curly) {
      // Extra curl bumps along hairline
      for (var i = 0; i < 6; i++) {
        canvas.drawCircle(
          Offset(cx - headRx * 0.90 + i * headRx * 0.36,
                 headCy - headRy * (topFrac + 0.08)),
          headRy * 0.18,
          Paint()..color = hair);
        canvas.drawCircle(
          Offset(cx - headRx * 0.90 + i * headRx * 0.36,
                 headCy - headRy * (topFrac + 0.08)),
          headRy * 0.18,
          Paint()..color = _outline..style = PaintingStyle.stroke..strokeWidth = lw * 0.60);
      }
    }
  }

  // ── face ─────────────────────────────────────────────────────────────────

  void _paintFace(Canvas canvas, double cx, double headCy,
      double headRy, double sw, double lw) {
    final eyeY   = headCy + headRy * 0.12;
    final noseY  = headCy + headRy * 0.50;
    final mouthY = headCy + headRy * 0.74;
    final eyeGap = sw * 0.135;

    // Eyebrows — arched, thick
    for (final side in [-1.0, 1.0]) {
      final bx = cx + side * eyeGap;
      canvas.drawPath(
        Path()
          ..moveTo(bx - 9.5, eyeY - 13)
          ..quadraticBezierTo(bx + side * 2.5, eyeY - 16.5, bx + 9.5, eyeY - 13),
        Paint()
          ..color = _darken(_hairBase, 0.05).withOpacity(0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw * 0.80
          ..strokeCap = StrokeCap.round);
    }

    _paintEye(canvas, Offset(cx - eyeGap, eyeY), sw, lw, false);
    _paintEye(canvas, Offset(cx + eyeGap, eyeY), sw, lw, true);

    // Nose — two subtle shadow dots
    final noseP = Paint()..color = _skinShad1(_skin).withOpacity(0.45);
    canvas.drawCircle(Offset(cx - 3.5, noseY), 1.8, noseP);
    canvas.drawCircle(Offset(cx + 3.5, noseY), 1.8, noseP);

    // Mouth — defined upper + lower lip
    final lipTop = Paint()
      ..color = _darken(_skin, 0.32).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lw * 0.55
      ..strokeCap = StrokeCap.round;
    // Upper lip curve (M shape)
    canvas.drawPath(
      Path()
        ..moveTo(cx - sw * 0.058, mouthY)
        ..quadraticBezierTo(cx - sw * 0.024, mouthY - sw * 0.012,
                            cx, mouthY)
        ..quadraticBezierTo(cx + sw * 0.024, mouthY - sw * 0.012,
                            cx + sw * 0.058, mouthY),
      lipTop);
    // Lower lip arc
    canvas.drawPath(
      Path()
        ..moveTo(cx - sw * 0.046, mouthY)
        ..quadraticBezierTo(cx, mouthY + sw * 0.030, cx + sw * 0.046, mouthY),
      Paint()
        ..color = _darken(_skin, 0.22).withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 0.65
        ..strokeCap = StrokeCap.round);

    // Blush — cel-style, slightly transparent
    final blushP = Paint()..color = const Color(0xFFF78C8C).withOpacity(0.36);
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + side * eyeGap * 1.44, eyeY + headRy * 0.24),
            width: eyeGap * 0.95, height: headRy * 0.24),
        blushP);
    }
  }

  void _paintEye(Canvas canvas, Offset center, double sw, double lw, bool isRight) {
    final accent = isMirror ? const Color(0xFFDB2777) : const Color(0xFF4F46E5);
    final ew = sw * 0.100;
    final eh = sw * 0.088;

    // Upper eyelid shadow area
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + eh * 0.04),
                      width: ew * 1.08, height: eh * 1.08),
      Paint()..color = _darken(_skin, 0.14).withOpacity(0.28));

    // White sclera
    canvas.drawOval(
      Rect.fromCenter(center: center, width: ew, height: eh),
      Paint()..color = const Color(0xFFF6F6FA));

    // Lower sclera shadow
    canvas.save();
    canvas.clipPath(Path()..addOval(
        Rect.fromCenter(center: center, width: ew, height: eh)));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + eh * 0.28),
                      width: ew * 0.90, height: eh * 0.45),
      Paint()..color = const Color(0xFFD0D4EE).withOpacity(0.50));
    canvas.restore();

    // Iris gradient (3 layers for depth)
    canvas.drawOval(
      Rect.fromCenter(center: center, width: ew * 0.70, height: eh * 0.90),
      Paint()..color = _lighten(accent, 0.18));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + eh * 0.06),
                      width: ew * 0.56, height: eh * 0.72),
      Paint()..color = accent);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + eh * 0.12),
                      width: ew * 0.34, height: eh * 0.50),
      Paint()..color = _darken(accent, 0.18));

    // Pupil
    canvas.drawCircle(center, ew * 0.155, Paint()..color = const Color(0xFF060610));

    // Main catch light
    canvas.drawCircle(
      Offset(center.dx - (isRight ? ew * 0.18 : -ew * 0.18), center.dy - eh * 0.28),
      ew * 0.135, Paint()..color = Colors.white);

    // Secondary catch light
    canvas.drawCircle(
      Offset(center.dx + (isRight ? -ew * 0.26 : ew * 0.26), center.dy + eh * 0.16),
      ew * 0.060, Paint()..color = Colors.white.withOpacity(0.70));

    // Iris rim line (gives glass-like depth)
    canvas.drawOval(
      Rect.fromCenter(center: center, width: ew * 0.70, height: eh * 0.90),
      Paint()
        ..color = _darken(accent, 0.10).withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 0.40);

    // Upper lash — thick, flared at outer corner
    final lashPath = Path();
    if (isRight) {
      lashPath
        ..moveTo(center.dx - ew * 0.50, center.dy - eh * 0.40)
        ..quadraticBezierTo(center.dx, center.dy - eh * 0.58,
                            center.dx + ew * 0.52, center.dy - eh * 0.28)
        ..lineTo(center.dx + ew * 0.56, center.dy - eh * 0.12)
        ..quadraticBezierTo(center.dx, center.dy - eh * 0.38,
                            center.dx - ew * 0.50, center.dy - eh * 0.22)
        ..close();
    } else {
      lashPath
        ..moveTo(center.dx + ew * 0.50, center.dy - eh * 0.40)
        ..quadraticBezierTo(center.dx, center.dy - eh * 0.58,
                            center.dx - ew * 0.52, center.dy - eh * 0.28)
        ..lineTo(center.dx - ew * 0.56, center.dy - eh * 0.12)
        ..quadraticBezierTo(center.dx, center.dy - eh * 0.38,
                            center.dx + ew * 0.50, center.dy - eh * 0.22)
        ..close();
    }
    canvas.drawPath(lashPath, Paint()..color = const Color(0xFF0C0C1E));

    // Lower lash hint (thin line)
    canvas.drawArc(
      Rect.fromCenter(center: center, width: ew * 0.88, height: eh * 0.88),
      math.pi * 0.10, math.pi * 0.80, false,
      Paint()
        ..color = const Color(0xFF1A1A30).withOpacity(0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 0.38
        ..strokeCap = StrokeCap.round);

    // Sclera outline
    canvas.drawOval(
      Rect.fromCenter(center: center, width: ew, height: eh),
      Paint()
        ..color = _outline.withOpacity(0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 0.55);
  }

  // ── accessories ───────────────────────────────────────────────────────────

  void _paintAccessories(Canvas canvas, double cx, double headCy,
      double headRx, double headRy, double sh, double sw, double lw, {
    required double shoulderY, required double sholHW,
  }) {
    final eyeY  = headCy + headRy * 0.12;
    final eyeGap = sw * 0.135;

    for (final acc in appearance.accessories) {
      switch (acc) {
        case 'round_glasses':
        case 'sunglasses':
          final isDark = acc == 'sunglasses';
          final lensC  = isDark ? const Color(0xFF1E293B).withOpacity(0.52) : Colors.transparent;
          final frameC = isDark ? const Color(0xFF1C2434) : const Color(0xFF5A6E88);
          final ew = sw * 0.100;
          final eh = sw * 0.085;
          for (final side in [-1.0, 1.0]) {
            final oc = Offset(cx + side * eyeGap, eyeY);
            canvas.drawOval(Rect.fromCenter(center: oc, width: ew, height: eh),
                Paint()..color = lensC);
            canvas.drawOval(Rect.fromCenter(center: oc, width: ew, height: eh),
                Paint()..color = frameC..style = PaintingStyle.stroke..strokeWidth = lw * 0.90);
          }
          canvas.drawLine(
            Offset(cx - eyeGap + ew * 0.46, eyeY),
            Offset(cx + eyeGap - ew * 0.46, eyeY),
            Paint()..color = frameC..strokeWidth = lw * 0.75);

        case 'headband':
          final path = Path()
            ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, headCy - headRy * 0.20),
                              width: headRx * 2.24, height: 9),
              const Radius.circular(5)));
          _celFill(canvas, path, const Color(0xFFEC4899), lw: lw * 0.65);

        case 'cap':
          final brim = Path()..addOval(Rect.fromCenter(
              center: Offset(cx, headCy - headRy * 0.22),
              width: headRx * 2.66, height: 14));
          final crown = Path()..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, headCy - headRy * 0.56),
                              width: headRx * 2.04, height: headRy * 0.80),
              const Radius.circular(10)));
          _celFill(canvas, crown, const Color(0xFF475569),
                   shad: const Color(0xFF2D3C50),
                   shadPath: Path()..addRect(Rect.fromLTRB(
                       cx + headRx * 0.10, headCy - headRy * 0.96,
                       cx + headRx * 1.02, headCy - headRy * 0.16)),
                   lw: lw * 0.80);
          _celFill(canvas, brim, const Color(0xFF334155), lw: lw * 0.70);

        case 'beanie':
          final path = Path()..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, headCy - headRy * 0.30),
                              width: headRx * 2.18, height: headRy * 0.82),
              const Radius.circular(14)));
          _celFill(canvas, path, const Color(0xFFDC2626),
                   shad: const Color(0xFF9C1010),
                   shadPath: Path()..addRect(Rect.fromLTRB(
                       cx + headRx * 0.20, headCy - headRy * 1.12,
                       cx + headRx * 1.09, headCy - headRy * 0.12)),
                   lw: lw * 0.80);
          canvas.drawCircle(Offset(cx, headCy - headRy * 0.74), 10,
              Paint()..color = const Color(0xFFFEE2E2));
          canvas.drawCircle(Offset(cx, headCy - headRy * 0.74), 10,
              Paint()..color = _outline..style = PaintingStyle.stroke..strokeWidth = lw * 0.60);

        case 'scarf':
          final path = Path()..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, shoulderY + 10),
                              width: sholHW * 2 + 16, height: 18),
              const Radius.circular(9)));
          _celFill(canvas, path, const Color(0xFFDC2626),
                   shad: const Color(0xFF9C1010),
                   shadPath: Path()..addRect(Rect.fromLTRB(
                       cx + sholHW * 0.20, shoulderY + 2,
                       cx + sholHW + 8, shoulderY + 19)),
                   lw: lw * 0.70);

        case 'necklace':
          canvas.drawArc(
            Rect.fromCenter(center: Offset(cx, shoulderY + 16), width: 34, height: 22),
            0, math.pi, false,
            Paint()
              ..color = const Color(0xFFD4AF37)
              ..style = PaintingStyle.stroke
              ..strokeWidth = lw * 0.70);

        case 'earrings':
          for (final side in [-1.0, 1.0]) {
            canvas.drawCircle(
              Offset(cx + side * headRx * 0.96, headCy + headRy * 0.24),
              5.0, Paint()..color = const Color(0xFFD4AF37));
            canvas.drawCircle(
              Offset(cx + side * headRx * 0.96, headCy + headRy * 0.24),
              5.0, Paint()..color = _outline..style = PaintingStyle.stroke..strokeWidth = lw * 0.55);
          }

        case 'watch':
          final wpath = Path()..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx - sholHW - sw * 0.066, shoulderY + sh * 0.19),
                  width: 14, height: 10),
              const Radius.circular(3)));
          _celFill(canvas, wpath, const Color(0xFF94A3B8), lw: lw * 0.55);

        default:
          break;
      }
    }
  }

  // ── utility ───────────────────────────────────────────────────────────────

  Color _lighten(Color c, double a) => HSLColor.fromColor(c)
      .withLightness((HSLColor.fromColor(c).lightness + a).clamp(0.0, 1.0))
      .toColor();
  Color _darken(Color c, double a) => HSLColor.fromColor(c)
      .withLightness((HSLColor.fromColor(c).lightness - a).clamp(0.0, 1.0))
      .toColor();

  @override
  bool shouldRepaint(_DollPainter old) =>
      old.appearance != appearance ||
      old.isFemale != isFemale ||
      old.isMirror != isMirror;
}
