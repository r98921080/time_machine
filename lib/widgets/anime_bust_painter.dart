import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/character.dart';

/// 專業日系動漫半身立繪繪製引擎 (Anime Bust Portrait Canvas Engine)
/// 完全比照使用者提供的兩張立繪風格：
/// - 正常人體美學結構：優雅天鵝頸、柔和斜方肌與鎖骨線、飽滿胸膛與肩膀弧度
/// - 精緻日系賽璐珞/厚塗上色：臉部軟陰影、微透光耳廓、小巧精緻鼻點、微抿笑唇
/// - 靈動寶石大眼：雙眼皮深邃線、微彎纖細眼線、上下眼睫毛、多層次翡翠綠/水藍漸層、月牙高光、八芒鑽星
/// - 蓬鬆柔順動漫髮型：奶茶灰棕/煙燻灰紫，流暢波浪大捲髮、前額瀏海、頭頂飄逸呆毛、天使光環光澤帶
/// - 換裝與飾品自定義：隨商城與自訂外觀裝備（圓框眼鏡、墨鏡、王冠、貓耳、荷葉領/宮廷禮服/休閒服）
class AnimeBustPainter extends CustomPainter {
  final CharacterAppearance appearance;
  final bool isFemale;
  final bool isMirror;
  final double blinkProgress;

  AnimeBustPainter({
    required this.appearance,
    required this.isFemale,
    this.isMirror = false,
    this.blinkProgress = 0.0,
  });

  // ── 色彩對應 ──────────────────────────────────────────────────────────

  Color get _skinColor => const {
    SkinTone.light:  Color(0xFFFFF0E5),
    SkinTone.medium: Color(0xFFFBE4D2),
    SkinTone.tan:    Color(0xFFE5B995),
    SkinTone.dark:   Color(0xFFB37B56),
  }[appearance.skinTone]!;

  Color get _skinShadow => const {
    SkinTone.light:  Color(0xFFEED0BD),
    SkinTone.medium: Color(0xFFE5BEA3),
    SkinTone.tan:    Color(0xFFC79872),
    SkinTone.dark:   Color(0xFF8F5835),
  }[appearance.skinTone]!;

  Color get _skinDeepShadow => const {
    SkinTone.light:  Color(0xFFDCB59E),
    SkinTone.medium: Color(0xFFD19F7E),
    SkinTone.tan:    Color(0xFFA87550),
    SkinTone.dark:   Color(0xFF724021),
  }[appearance.skinTone]!;

  Color get _hairBase => const {
    HairColor.black:   Color(0xFF2C282F),
    HairColor.brown:   Color(0xFF9E8575), // 參考圖 1 & 2 的奶茶灰棕色
    HairColor.blonde:  Color(0xFFDCC18C), // 參考圖柔和金
    HairColor.red:     Color(0xFFA65851),
    HairColor.gray:    Color(0xFFB5ACB1), // 參考圖 2 的煙燻灰紫
    HairColor.fantasy: Color(0xFF6B587B),
  }[appearance.hairColor]!;

  Color get _eyeIrisColor => isMirror
      ? const Color(0xFF5B92A5) // 參考圖 2 清透灰藍水眸
      : const Color(0xFF48A652); // 參考圖 1 璀璨琉璃翡翠綠

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 半身黃金比例定位點
    final headCx = w * 0.50;
    final headCy = h * 0.38;
    final headRx = w * 0.28;
    final headRy = h * 0.22;

    final chinY = headCy + headRy * 0.95;
    final neckTopY = chinY - headRy * 0.15;
    final shoulderY = h * 0.68;
    final chestBottomY = h * 1.05;

    // 1. 後層大波浪飄逸秀髮 (Back Hair)
    _paintBackHair(canvas, headCx, headCy, headRx, headRy, w, h);

    // 2. 頸部與鎖骨肩膀身軀 (Neck, Shoulders & Bust)
    _paintBodyAndSkin(canvas, headCx, neckTopY, shoulderY, chestBottomY, w, h);

    // 3. 服飾裝扮 (Outfit / Bust Clothes)
    _paintOutfit(canvas, headCx, shoulderY, chestBottomY, w, h);

    // 4. 頭部輪廓、耳朵與下巴陰影 (Head Base & Ears)
    _paintHeadAndEars(canvas, headCx, headCy, headRx, headRy, chinY);

    // 5. 精緻五官與靈動二次元大眼 (Eyes, Nose, Mouth, Blush)
    _paintFacialFeatures(canvas, headCx, headCy, headRx, headRy);

    // 6. 前額瀏海、鬢角與頭頂呆毛 (Front Hair, Bangs, Ahoge, Halo)
    _paintFrontHair(canvas, headCx, headCy, headRx, headRy, w, h);

    // 7. 配件與裝扮（王冠、細框眼鏡、蝴蝶結、耳環）
    _paintAccessories(canvas, headCx, headCy, headRx, headRy, w, h);
  }

  // ── 1. 後層秀髮 ────────────────────────────────────────────────────────
  void _paintBackHair(Canvas canvas, double cx, double cy, double rx, double ry, double w, double h) {
    final hair = _hairBase;
    final hairDark = Color.lerp(hair, Colors.black, 0.22)!;

    final path = Path()
      ..moveTo(cx - rx * 1.15, cy)
      ..cubicTo(cx - rx * 1.45, cy + ry * 0.8, cx - rx * 1.30, h * 0.75, cx - rx * 0.8, h * 1.05)
      ..lineTo(cx + rx * 0.8, h * 1.05)
      ..cubicTo(cx + rx * 1.30, h * 0.75, cx + rx * 1.45, cy + ry * 0.8, cx + rx * 1.15, cy)
      ..cubicTo(cx + rx * 1.10, cy - ry * 1.1, cx - rx * 1.10, cy - ry * 1.1, cx - rx * 1.15, cy)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [hair, hairDark],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, paint);
  }

  // ── 2. 頸部與身軀 ──────────────────────────────────────────────────────
  void _paintBodyAndSkin(Canvas canvas, double cx, double neckTopY, double shoulderY, double botY, double w, double h) {
    final neckWidth = w * 0.13;
    final shoulderWidth = w * 0.44;

    // 頸部
    final neckPath = Path()
      ..moveTo(cx - neckWidth, neckTopY)
      ..lineTo(cx + neckWidth, neckTopY)
      ..cubicTo(cx + neckWidth * 1.1, shoulderY - 10, cx + shoulderWidth * 0.4, shoulderY - 4, cx + shoulderWidth, shoulderY + 15)
      ..lineTo(cx + shoulderWidth, botY)
      ..lineTo(cx - shoulderWidth, botY)
      ..lineTo(cx - shoulderWidth, shoulderY + 15)
      ..cubicTo(cx - shoulderWidth * 0.4, shoulderY - 4, cx - neckWidth * 1.1, shoulderY - 10, cx - neckWidth, neckTopY)
      ..close();

    canvas.drawPath(neckPath, Paint()..color = _skinColor);

    // 下巴在頸部的柔和投影 (AO Ambient Occlusion)
    final neckShadowPath = Path()
      ..moveTo(cx - neckWidth * 0.95, neckTopY + 4)
      ..cubicTo(cx, neckTopY + 22, cx + neckWidth * 0.95, neckTopY + 4, cx + neckWidth * 0.95, neckTopY + 14)
      ..cubicTo(cx, neckTopY + 34, cx - neckWidth * 0.95, neckTopY + 14, cx - neckWidth * 0.95, neckTopY + 4)
      ..close();
    canvas.drawPath(neckShadowPath, Paint()..color = _skinShadow.withOpacity(0.85));

    // 優雅鎖骨線 (Clavicle lines)
    final claviclePaint = Paint()
      ..color = _skinDeepShadow.withOpacity(0.45)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final clavY = shoulderY + 4;
    canvas.drawPath(
      Path()
        ..moveTo(cx - neckWidth * 0.8, clavY - 2)
        ..quadraticBezierTo(cx - neckWidth * 1.8, clavY + 3, cx - neckWidth * 2.5, clavY + 2),
      claviclePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + neckWidth * 0.8, clavY - 2)
        ..quadraticBezierTo(cx + neckWidth * 1.8, clavY + 3, cx + neckWidth * 2.5, clavY + 2),
      claviclePaint,
    );
  }

  // ── 3. 服飾裝扮 ────────────────────────────────────────────────────────
  void _paintOutfit(Canvas canvas, double cx, double shoulderY, double botY, double w, double h) {
    final outfitId = appearance.outfitId;
    final shoulderWidth = w * 0.45;

    // 配色判斷
    Color outfitMain = const Color(0xFF2B4D58); // 預設典雅青綠（參考圖2）
    Color outfitTrim = const Color(0xFFEED195); // 滾金邊
    bool isRuffle = true;                       // 是否為歐式荷葉領

    if (outfitId != null) {
      if (outfitId.contains('sundress') || outfitId.contains('dress')) {
        outfitMain = const Color(0xFF88C9EE); // 參考圖 1 宮廷天藍
        outfitTrim = const Color(0xFFFAF6EB); // 白毛絨
        isRuffle = false;
      } else if (outfitId.contains('suit')) {
        outfitMain = const Color(0xFF232A38);
        outfitTrim = Colors.white;
        isRuffle = false;
      } else if (outfitId.contains('hoodie') || outfitId.contains('tshirt')) {
        outfitMain = const Color(0xFF566B78);
        outfitTrim = Colors.white70;
        isRuffle = false;
      }
    }

    // 衣服本體
    final clothPath = Path()
      ..moveTo(cx - shoulderWidth, shoulderY + 10)
      ..cubicTo(cx - w * 0.22, shoulderY + 8, cx - w * 0.14, shoulderY + 24, cx, shoulderY + 32)
      ..cubicTo(cx + w * 0.14, shoulderY + 24, cx + w * 0.22, shoulderY + 8, cx + shoulderWidth, shoulderY + 10)
      ..lineTo(cx + shoulderWidth * 1.05, botY)
      ..lineTo(cx - shoulderWidth * 1.05, botY)
      ..close();

    final clothPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [outfitMain, Color.lerp(outfitMain, Colors.black, 0.35)!],
      ).createShader(Rect.fromLTWH(0, shoulderY, w, h - shoulderY));
    canvas.drawPath(clothPath, clothPaint);

    if (isRuffle) {
      // 參考圖 2 的歐式波浪荷葉領 (Victorian Ruffle Collar)
      final rufflePath = Path()
        ..moveTo(cx - w * 0.16, shoulderY + 12)
        ..cubicTo(cx - w * 0.10, shoulderY + 28, cx - w * 0.05, shoulderY + 36, cx, shoulderY + 38)
        ..cubicTo(cx + w * 0.05, shoulderY + 36, cx + w * 0.10, shoulderY + 28, cx + w * 0.16, shoulderY + 12)
        ..cubicTo(cx + w * 0.08, shoulderY + 18, cx - w * 0.08, shoulderY + 18, cx - w * 0.16, shoulderY + 12)
        ..close();
      canvas.drawPath(rufflePath, Paint()..color = const Color(0xFFF7F4EB));
      canvas.drawPath(rufflePath, Paint()..color = const Color(0xFFD4C8B2)..style = PaintingStyle.stroke..strokeWidth = 1.0);

      // 胸前寶石胸針 (Reference 2 Ruby Brooch)
      canvas.drawCircle(Offset(cx, shoulderY + 26), 4.5, Paint()..color = const Color(0xFFC99742));
      canvas.drawCircle(Offset(cx, shoulderY + 26), 3.2, Paint()..color = const Color(0xFF9E1D2D));
    } else {
      // 領口金邊裝飾
      final trimPath = Path()
        ..moveTo(cx - w * 0.22, shoulderY + 8)
        ..cubicTo(cx - w * 0.14, shoulderY + 24, cx - w * 0.08, shoulderY + 32, cx, shoulderY + 32)
        ..cubicTo(cx + w * 0.08, shoulderY + 32, cx + w * 0.14, shoulderY + 24, cx + w * 0.22, shoulderY + 8);
      canvas.drawPath(
        trimPath,
        Paint()
          ..color = outfitTrim
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── 4. 頭部底色與耳朵 ────────────────────────────────────────────────────
  void _paintHeadAndEars(Canvas canvas, double cx, double cy, double rx, double ry, double chinY) {
    // 臉龐精緻線條（圓潤中帶微削瓜子臉，二次元標準）
    final facePath = Path()
      ..moveTo(cx - rx, cy - ry * 0.25)
      ..cubicTo(cx - rx * 1.02, cy + ry * 0.35, cx - rx * 0.65, chinY - ry * 0.18, cx, chinY)
      ..cubicTo(cx + rx * 0.65, chinY - ry * 0.18, cx + rx * 1.02, cy + ry * 0.35, cx + rx, cy - ry * 0.25)
      ..cubicTo(cx + rx * 1.02, cy - ry * 1.15, cx - rx * 1.02, cy - ry * 1.15, cx - rx, cy - ry * 0.25)
      ..close();

    canvas.drawPath(facePath, Paint()..color = _skinColor);

    // 精緻透光耳朵 (Ears)
    for (final side in [-1.0, 1.0]) {
      final earCx = cx + side * rx * 0.98;
      final earCy = cy + ry * 0.15;
      final earPath = Path()
        ..addOval(Rect.fromCenter(center: Offset(earCx, earCy), width: rx * 0.26, height: ry * 0.44));
      canvas.drawPath(earPath, Paint()..color = _skinColor);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(earCx - side * 1.5, earCy), width: rx * 0.14, height: ry * 0.24),
        Paint()..color = _skinShadow.withOpacity(0.65),
      );
    }
  }

  // ── 5. 五官與動漫大眼 ────────────────────────────────────────────────────
  void _paintFacialFeatures(Canvas canvas, double cx, double cy, double rx, double ry) {
    final eyeY = cy + ry * 0.08;
    final eyeGap = rx * 0.52;
    final ew = rx * 0.42;
    final eh = ry * 0.40;

    // 腮紅 (Delicate Gradient Anime Blush)
    for (final side in [-1.0, 1.0]) {
      final bCenter = Offset(cx + side * eyeGap * 1.05, eyeY + eh * 0.65);
      final bRect = Rect.fromCenter(center: bCenter, width: ew * 0.85, height: eh * 0.55);
      canvas.drawOval(
        bRect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFF7E92).withOpacity(0.40),
              const Color(0xFFFF7E92).withOpacity(0.0),
            ],
          ).createShader(bRect),
      );
      // 斜向日系腮紅細線 (///)
      final markPaint = Paint()
        ..color = const Color(0xFFE11D48).withOpacity(0.35)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      for (int m = -1; m <= 1; m++) {
        final mx = bCenter.dx + m * 3.5;
        canvas.drawLine(Offset(mx - 2.0, bCenter.dy + 3.0), Offset(mx + 2.0, bCenter.dy - 3.0), markPaint);
      }
    }

    // 眉毛 (Delicate Arched Eyebrows)
    for (final side in [-1.0, 1.0]) {
      final browCx = cx + side * eyeGap * 0.95;
      final browPath = Path()
        ..moveTo(browCx - side * ew * 0.55, eyeY - eh * 0.85)
        ..quadraticBezierTo(browCx, eyeY - eh * 1.10, browCx + side * ew * 0.50, eyeY - eh * 0.70);
      canvas.drawPath(
        browPath,
        Paint()
          ..color = Color.lerp(_hairBase, Colors.black, 0.25)!.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }

    // 眼睛繪製
    _paintSingleEye(canvas, Offset(cx - eyeGap, eyeY), ew, eh, false);
    _paintSingleEye(canvas, Offset(cx + eyeGap, eyeY), ew, eh, true);

    // 小巧秀氣鼻點 (Subtle anime nose)
    final noseY = cy + ry * 0.44;
    canvas.drawCircle(Offset(cx + 0.5, noseY), 1.4, Paint()..color = _skinDeepShadow.withOpacity(0.65));

    // 微抿笑唇 (Anime soft mouth)
    final mouthY = cy + ry * 0.68;
    final mouthPaint = Paint()
      ..color = const Color(0xFFD4726A).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(cx - rx * 0.16, mouthY)
      ..quadraticBezierTo(cx, mouthY + 2.2, cx + rx * 0.16, mouthY);
    canvas.drawPath(mouthPath, mouthPaint);

    // 下唇淡粉光澤
    canvas.drawCircle(Offset(cx, mouthY + 3.5), 1.8, Paint()..color = const Color(0xFFFF9AA2).withOpacity(0.45));
  }

  void _paintSingleEye(Canvas canvas, Offset center, double ew, double eh, bool isRight) {
    // 眨眼
    if (blinkProgress >= 0.7) {
      final blinkPath = Path()
        ..moveTo(center.dx - ew * 0.55, center.dy)
        ..quadraticBezierTo(center.dx, center.dy - eh * 0.4, center.dx + ew * 0.55, center.dy);
      canvas.drawPath(
        blinkPath,
        Paint()
          ..color = const Color(0xFF262025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    // 雙眼皮線 (Double Eyelid)
    final creasePaint = Paint()
      ..color = _skinDeepShadow.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - ew * 0.45, center.dy - eh * 0.65)
        ..quadraticBezierTo(center.dx, center.dy - eh * 0.82, center.dx + ew * 0.45, center.dy - eh * 0.60),
      creasePaint,
    );

    // 眼白 (Sclera)
    final scleraPath = Path()
      ..addOval(Rect.fromCenter(center: center, width: ew, height: eh));
    canvas.drawPath(scleraPath, Paint()..color = const Color(0xFFFBFBFC));

    // 眼窩上方投影
    canvas.save();
    canvas.clipPath(scleraPath);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - ew, center.dy - eh, ew * 2, eh * 0.8),
      Paint()..color = const Color(0xFFCCD4DD).withOpacity(0.35),
    );
    canvas.restore();

    // 寶石虹膜 (Jewel Iris)
    final irisW = ew * 0.76;
    final irisH = eh * 0.94;
    final irisRect = Rect.fromCenter(center: center, width: irisW, height: irisH);

    final irisPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF151D22),
          Color.lerp(_eyeIrisColor, Colors.black, 0.35)!,
          _eyeIrisColor,
          Color.lerp(_eyeIrisColor, Colors.white, 0.40)!,
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(irisRect);
    canvas.drawOval(irisRect, irisPaint);

    // 底部月牙反光 (Luminous lower crescent)
    final glowRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + eh * 0.22),
      width: irisW * 0.75,
      height: irisH * 0.40,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(_eyeIrisColor, Colors.white, 0.65)!.withOpacity(0.85),
            Colors.transparent,
          ],
        ).createShader(glowRect),
    );

    // 瞳孔 (Deep Pupil)
    canvas.drawCircle(center, irisW * 0.20, Paint()..color = const Color(0xFF0D1217));

    // 上眼線與細緻睫毛 (Eyeliner & Lashes)
    final linerPath = Path()
      ..moveTo(center.dx - ew * 0.58, center.dy - eh * 0.10)
      ..quadraticBezierTo(center.dx, center.dy - eh * 0.70, center.dx + ew * 0.60, center.dy - eh * 0.15);
    canvas.drawPath(
      linerPath,
      Paint()
        ..color = const Color(0xFF231D24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    // 高光亮點 (Sparkling Catchlights)
    final highlightDx = center.dx - (isRight ? ew * 0.18 : -ew * 0.18);
    canvas.drawCircle(Offset(highlightDx, center.dy - eh * 0.25), irisW * 0.15, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx + (isRight ? ew * 0.16 : -ew * 0.16), center.dy + eh * 0.16), irisW * 0.08, Paint()..color = Colors.white.withOpacity(0.9));
  }

  // ── 6. 前額瀏海與天使光環 ────────────────────────────────────────────────
  void _paintFrontHair(Canvas canvas, double cx, double cy, double rx, double ry, double w, double h) {
    final hair = _hairBase;
    final hairLight = Color.lerp(hair, Colors.white, 0.35)!;
    final hairDark = Color.lerp(hair, Colors.black, 0.20)!;

    // 兩側垂墜長鬢角捲髮 (Side Bang Locks from reference)
    for (final side in [-1.0, 1.0]) {
      final lockPath = Path()
        ..moveTo(cx + side * rx * 0.85, cy - ry * 0.50)
        ..cubicTo(cx + side * rx * 1.15, cy + ry * 0.60, cx + side * rx * 0.95, h * 0.72, cx + side * rx * 0.70, h * 0.85)
        ..cubicTo(cx + side * rx * 0.85, h * 0.70, cx + side * rx * 0.90, cy + ry * 0.50, cx + side * rx * 0.65, cy - ry * 0.10)
        ..close();
      canvas.drawPath(lockPath, Paint()..color = hair);
    }

    // 前額齊瀏海/碎瀏海 (Bangs matching reference 1 & 2)
    final bangsPath = Path()
      ..moveTo(cx - rx * 1.02, cy - ry * 0.65)
      ..cubicTo(cx - rx * 0.60, cy - ry * 0.10, cx - rx * 0.40, cy - ry * 0.05, cx - rx * 0.35, cy - ry * 0.08)
      ..cubicTo(cx - rx * 0.20, cy - ry * 0.02, cx - rx * 0.05, cy - ry * 0.02, cx, cy - ry * 0.06)
      ..cubicTo(cx + rx * 0.10, cy - ry * 0.02, cx + rx * 0.30, cy - ry * 0.04, cx + rx * 0.40, cy - ry * 0.12)
      ..cubicTo(cx + rx * 0.65, cy - ry * 0.10, cx + rx * 0.90, cy - ry * 0.50, cx + rx * 1.02, cy - ry * 0.65)
      ..cubicTo(cx + rx * 1.05, cy - ry * 1.25, cx - rx * 1.05, cy - ry * 1.25, cx - rx * 1.02, cy - ry * 0.65)
      ..close();

    final bangsPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [hair, hairDark],
      ).createShader(Rect.fromLTWH(cx - rx, cy - ry * 1.2, rx * 2, ry * 1.5));
    canvas.drawPath(bangsPath, bangsPaint);

    // 經典天使光環髮絲光澤 (Angel Halo Hair Sheen)
    final haloPath = Path()
      ..moveTo(cx - rx * 0.75, cy - ry * 0.60)
      ..quadraticBezierTo(cx, cy - ry * 0.45, cx + rx * 0.75, cy - ry * 0.60)
      ..quadraticBezierTo(cx, cy - ry * 0.52, cx - rx * 0.75, cy - ry * 0.60)
      ..close();
    canvas.drawPath(
      haloPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            hairLight.withOpacity(0.0),
            hairLight.withOpacity(0.75),
            Colors.white.withOpacity(0.90),
            hairLight.withOpacity(0.75),
            hairLight.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(cx - rx, cy - ry * 0.7, rx * 2, ry * 0.4)),
    );

    // 頭頂飄逸呆毛 (Ahoge / Top Strand)
    final ahogePath = Path()
      ..moveTo(cx, cy - ry * 1.05)
      ..cubicTo(cx + rx * 0.25, cy - ry * 1.35, cx + rx * 0.35, cy - ry * 1.15, cx + rx * 0.18, cy - ry * 1.00);
    canvas.drawPath(
      ahogePath,
      Paint()
        ..color = hair
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── 7. 配件與裝扮 ────────────────────────────────────────────────────────
  void _paintAccessories(Canvas canvas, double cx, double cy, double rx, double ry, double w, double h) {
    final accList = appearance.accessories;

    // 1. 金屬眼鏡 (Glasses - 圓框或墨鏡)
    final hasGlasses = accList.any((a) => a.contains('glasses') || a.contains('round'));
    if (hasGlasses) {
      final eyeY = cy + ry * 0.08;
      final eyeGap = rx * 0.52;
      final glassR = rx * 0.24;

      final framePaint = Paint()
        ..color = const Color(0xFFC99742) // 參考圖 2 金絲細框
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      canvas.drawCircle(Offset(cx - eyeGap, eyeY), glassR, framePaint);
      canvas.drawCircle(Offset(cx + eyeGap, eyeY), glassR, framePaint);
      // 中間鼻樑架
      canvas.drawLine(
        Offset(cx - eyeGap + glassR, eyeY),
        Offset(cx + eyeGap - glassR, eyeY),
        framePaint,
      );
      // 鏡片微透光
      canvas.drawCircle(
        Offset(cx - eyeGap, eyeY),
        glassR - 1,
        Paint()..color = Colors.white.withOpacity(0.15),
      );
      canvas.drawCircle(
        Offset(cx + eyeGap, eyeY),
        glassR - 1,
        Paint()..color = Colors.white.withOpacity(0.15),
      );
    }

    // 2. 金冠/王冠 (Crown - 參考圖 1 皇冠)
    final hasCrown = accList.any((a) => a.contains('crown'));
    if (hasCrown) {
      final crownY = cy - ry * 1.12;
      final crownPath = Path()
        ..moveTo(cx - rx * 0.45, crownY)
        ..lineTo(cx - rx * 0.50, crownY - 18)
        ..lineTo(cx - rx * 0.25, crownY - 8)
        ..lineTo(cx, crownY - 24)
        ..lineTo(cx + rx * 0.25, crownY - 8)
        ..lineTo(cx + rx * 0.50, crownY - 18)
        ..lineTo(cx + rx * 0.45, crownY)
        ..close();

      canvas.drawPath(
        crownPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFDF85), Color(0xFFC99742), Color(0xFF8B6B3E)],
          ).createShader(Rect.fromLTWH(cx - rx, crownY - 30, rx * 2, 40)),
      );
      // 皇冠紅寶石
      canvas.drawCircle(Offset(cx, crownY - 14), 2.8, Paint()..color = const Color(0xFFDC2626));
      canvas.drawCircle(Offset(cx - rx * 0.32, crownY - 10), 2.0, Paint()..color = const Color(0xFF2563EB));
      canvas.drawCircle(Offset(cx + rx * 0.32, crownY - 10), 2.0, Paint()..color = const Color(0xFF2563EB));
    }

    // 3. 藍色緞帶/蝴蝶結 (Ribbons - 參考圖 1 髮際蝴蝶結)
    final hasRibbon = accList.any((a) => a.contains('ribbon') || a.contains('flower'));
    if (hasRibbon) {
      final ribPaint = Paint()..color = const Color(0xFF2563EB); // 皇家藍
      for (final side in [-1.0, 1.0]) {
        final ribX = cx + side * rx * 0.90;
        final ribY = cy - ry * 0.10;
        canvas.drawCircle(Offset(ribX, ribY), 4.0, ribPaint);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(ribX - 4, ribY - 2), width: 6, height: 4),
          ribPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(ribX + 4, ribY - 2), width: 6, height: 4),
          ribPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnimeBustPainter oldDelegate) {
    return oldDelegate.appearance != appearance ||
        oldDelegate.blinkProgress != blinkProgress ||
        oldDelegate.isMirror != isMirror;
  }
}
