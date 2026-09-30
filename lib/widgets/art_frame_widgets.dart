import 'package:flutter/material.dart';

/// 專案視覺風格設計系統 (Design Tokens & Shared Widgets)
/// 比照日系典雅二次元精緻卡面風格（琥珀金、深秋楓黃、深邃青金石墨綠、象牙白、金屬古銅）
class AppThemeStyle {
  // ── 核心色彩 (Color Tokens) ──
  static const Color primaryGold = Color(0xFFC99742);       // 琥珀秋金 / 典雅金
  static const Color primaryGoldDark = Color(0xFF9E7127);   // 復古暗金
  static const Color primaryGoldLight = Color(0xFFEED195);  // 高光淡金
  
  static const Color deepTeal = Color(0xFF1E3A42);          // 深邃青綠 / 頂部名牌底色
  static const Color darkTealBg = Color(0xFF0F1E24);        // 極深青黑背景
  static const Color tealAccent = Color(0xFF388E8E);        // 翡翠青光

  static const Color bronzeBorder = Color(0xFF8B6B3E);      // 古銅金金屬雕花邊框
  static const Color bronzeBorderLight = Color(0xFFD4AF37); // 金屬反光線
  static const Color paperBgLight = Color(0xFFFBF8F2);      // 溫潤象牙米白卡片底
  static const Color paperBgDark = Color(0xFF181C20);       // 沉穩夜空古銅底

  static const Color textMainLight = Color(0xFF2C241E);     // 深咖啡黑文字
  static const Color textSubLight = Color(0xFF7A6855);      // 溫潤暖褐次要字
  static const Color textMainDark = Color(0xFFF3EEE6);      // 米白文字
  static const Color textSubDark = Color(0xFFAFA293);       // 暖灰次要字
}

/// 圖 2 風格：折角金屬古典銘牌標籤 (Hexagonal / Bracketed Plaque Badge)
class OrnatePlaqueBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double fontSize;
  final EdgeInsets padding;

  const OrnatePlaqueBadge({
    super.key,
    required this.label,
    this.icon,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlaquePainter(),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 1, color: const Color(0xFFEED195)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                shadows: const [
                  Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cut = h * 0.32;

    // 八角折角名牌外觀
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(w - cut, 0)
      ..lineTo(w, cut)
      ..lineTo(w, h - cut)
      ..lineTo(w - cut, h)
      ..lineTo(cut, h)
      ..lineTo(0, h - cut)
      ..lineTo(0, cut)
      ..close();

    // 填充深青漸層
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2B4D58), Color(0xFF13272F)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, bgPaint);

    // 金屬高光邊框
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5DEB3), Color(0xFF9E7127), Color(0xFFFFE082), Color(0xFF7A551C)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, borderPaint);

    // 左右兩側的小菱形飾點
    final dotPaint = Paint()..color = const Color(0xFFEED195);
    canvas.drawCircle(Offset(cut * 0.5, h / 2), 1.8, dotPaint);
    canvas.drawCircle(Offset(w - cut * 0.5, h / 2), 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 圖 2 風格：巴洛克精雕金屬畫框容器 (Ornate Gilded Frame Container)
class OrnateFrameBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final bool showBadge;
  final String? badgeText;

  const OrnateFrameBox({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(12),
    this.showBadge = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: _OrnateFramePainter(),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: child,
            ),
          ),
        ),
        if (showBadge && badgeText != null)
          Positioned(
            top: -14,
            child: OrnatePlaqueBadge(label: badgeText!),
          ),
      ],
    );
  }
}

class _OrnateFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    // 輕柔現代微陰影
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
    canvas.drawRRect(rrect, shadowPaint);

    // 高級纖細香檳金邊框 (Clean Luxury Border)
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFDF85),
          Color(0xFFC99742),
          Color(0xFF8B6428),
          Color(0xFFEED195),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, framePaint);

    // 四角極簡精緻小菱形亮點點綴
    final dotPaint = Paint()..color = const Color(0xFFFFE082).withOpacity(0.85);
    canvas.drawCircle(const Offset(7, 7), 1.8, dotPaint);
    canvas.drawCircle(Offset(w - 7, 7), 1.8, dotPaint);
    canvas.drawCircle(Offset(7, h - 7), 1.8, dotPaint);
    canvas.drawCircle(Offset(w - 7, h - 7), 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
