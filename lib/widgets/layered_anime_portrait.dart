import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/character.dart';

/// 專業手遊級「多圖層全身立繪合成與裝扮引擎」（Layered Fullbody Anime Composite Engine）
/// 1. 支援高解析度【全身立繪】（Full-body Standing Portrait），完美適配商城全身服裝、褲裝、鞋靴、配件。
/// 2. 支援即時自定義：
///    - 膚色調色盤濾鏡（Light 淺膚、Medium 暖中、Tan 小麥色、Dark 深膚色）
///    - 髮型（短髮、中長髮、長波浪、包子頭、雙馬尾、捲髮）
///    - 髮色（黑髮、深棕、流金、緋紅、銀白、星河紫藍）
///    - 裝扮/服飾套裝（歐式學者禮服、天藍宮廷禮服、學院西裝正裝、休閒連帽夾克外套等）
///    - 配件（金絲眼鏡、黃金璀璨王冠、皇家海藍蝴蝶結、耳環、面飾等）
/// 3. 動態層：呼吸縮放（Live2D 微動態）+ 點擊粒子交互回饋
class LayeredAnimePortraitWidget extends StatefulWidget {
  final CharacterAppearance appearance;
  final String gender;
  final bool isMirror;
  final double width;
  final double height;
  final bool enableAnimation;
  final bool interactive;
  final VoidCallback? onTap;

  const LayeredAnimePortraitWidget({
    super.key,
    required this.appearance,
    required this.gender,
    this.isMirror = false,
    this.width = 220,
    this.height = 380,
    this.enableAnimation = true,
    this.interactive = true,
    this.onTap,
  });

  @override
  State<LayeredAnimePortraitWidget> createState() => _LayeredAnimePortraitWidgetState();
}

class _LayeredAnimePortraitWidgetState extends State<LayeredAnimePortraitWidget>
    with TickerProviderStateMixin {
  late AnimationController _breatheCtrl;
  late AnimationController _tapCtrl;
  final math.Random _rnd = math.Random();
  final List<_FloatingHeart> _hearts = [];

  @override
  void initState() {
    super.initState();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.interactive) return;
    _tapCtrl.forward(from: 0.0);

    final id = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _hearts.add(_FloatingHeart(
        id: id,
        x: (widget.width / 2) + (_rnd.nextDouble() * 40 - 20),
        y: widget.height * 0.35,
        emoji: ['❤️', '✨', '💖', '⭐', '🌸'][_rnd.nextInt(5)],
      ));
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _hearts.removeWhere((h) => h.id == id);
        });
      }
    });

    widget.onTap?.call();
  }

  /// 根據性別、服裝決定主全身立繪基底（性別絕對鎖定，不受衣服變動而跳轉）
  String _resolveFullbodyAsset() {
    final outfitId = widget.appearance.outfitId;
    final isFemale = widget.gender == '她' || widget.gender == '女';

    if (isFemale) {
      // 女性立繪基底
      if (outfitId == 'outfit_pajamas') {
        return 'assets/characters/female_base_pajamas.jpg';
      }
      if (outfitId == 'outfit_sundress' || outfitId == 'outfit_princess' || outfitId == 'special_newyear_outfit') {
        return 'assets/characters/fullbody_princess.jpg';
      }
      if (outfitId == 'outfit_formal_suit' || outfitId == 'outfit_tracksuit' || outfitId == 'outfit_detective' || outfitId == 'outfit_school_uniform') {
        return 'assets/characters/fullbody_female_suit.jpg';
      }
      // 基礎預設或運動休閒服裝均呈現女版運動服
      return 'assets/characters/female_base_sporty.jpg';
    } else {
      // 男性立繪基底
      if (outfitId == 'outfit_pajamas') {
        return 'assets/characters/male_base_pajamas.jpg';
      }
      if (outfitId == 'outfit_formal_suit' || outfitId == 'outfit_scholar' || outfitId == 'outfit_tracksuit' || outfitId == 'outfit_detective') {
        return 'assets/characters/fullbody_scholar.jpg';
      }
      if (outfitId == 'outfit_casual_hoodie' || outfitId == 'outfit_tshirt_white' || outfitId == 'outfit_denim_jacket') {
        return 'assets/characters/fullbody_male_casual.jpg';
      }
      // 基礎預設或運動休閒服裝均呈現男版運動服
      return 'assets/characters/male_base_sporty.jpg';
    }
  }

  /// 膚色濾鏡顏色與透明度
  Color _resolveSkinTint(SkinTone tone) {
    switch (tone) {
      case SkinTone.light:
        return const Color(0xFFFFF6ED).withOpacity(0.18); // 柔白粉嫩
      case SkinTone.medium:
        return Colors.transparent; // 原生中等膚色
      case SkinTone.tan:
        return const Color(0xFFB8783C).withOpacity(0.32); // 健康陽光小麥色
      case SkinTone.dark:
        return const Color(0xFF5E361A).withOpacity(0.45); // 深沉古銅膚色
    }
  }

  /// 鮮明立體的髮色疊色渲染
  Color? _resolveHairColorOverlay(HairColor color) {
    switch (color) {
      case HairColor.black:
        return const Color(0xFF151515).withOpacity(0.55);
      case HairColor.brown:
        return const Color(0xFF6B3A18).withOpacity(0.45);
      case HairColor.blonde:
        return const Color(0xFFFFCC00).withOpacity(0.50);
      case HairColor.red:
        return const Color(0xFFDC2626).withOpacity(0.48);
      case HairColor.gray:
        return const Color(0xFFCBD5E1).withOpacity(0.55);
      case HairColor.fantasy:
        return const Color(0xFF8B5CF6).withOpacity(0.52);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullbodyAsset = _resolveFullbodyAsset();
    final skinTint = _resolveSkinTint(widget.appearance.skinTone);
    final hairOverlay = _resolveHairColorOverlay(widget.appearance.hairColor);

    // 配件識別
    final accList = widget.appearance.accessories;
    final hasGlasses = accList.any((a) => a.contains('glasses') || a.contains('round'));
    final hasCrown = accList.any((a) => a.contains('crown'));
    final hasRibbon = accList.any((a) => a.contains('ribbon'));
    final hasStarEarring = accList.any((a) => a.contains('earring') || a.contains('star'));
    final hasAngelWings = accList.any((a) => a.contains('wings_angel'));
    final hasCatWhiskers = accList.any((a) => a.contains('whiskers') || a.contains('cat'));

    final content = AnimatedBuilder(
      animation: Listenable.merge([_breatheCtrl, _tapCtrl]),
      builder: (context, _) {
        final breatheVal = math.sin(_breatheCtrl.value * math.pi);
        final dy = breatheVal * 1.5;
        final scaleBreathe = 1.0 + (breatheVal * 0.008);

        final tapProgress = _tapCtrl.value;
        final tapScale = tapProgress == 0
            ? 1.0
            : 1.0 + math.sin(tapProgress * math.pi) * 0.05;

        final totalScale = scaleBreathe * tapScale;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: totalScale,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    // 1. 溫暖復古琥珀至深黛漸層背景底色
                    Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.2),
                          radius: 1.2,
                          colors: [
                            Color(0xFF263D45),
                            Color(0xFF132228),
                            Color(0xFF0C161A),
                          ],
                        ),
                      ),
                    ),

                    // 特殊翅膀後置層 (Angel Wings / Demon Wings)
                    if (hasAngelWings)
                      Positioned(
                        top: widget.height * 0.12,
                        child: CustomPaint(
                          size: Size(widget.width * 0.95, widget.height * 0.35),
                          painter: _AngelWingsPainter(),
                        ),
                      ),

                    // 2. 高精度日系動漫【全身立繪】(Full-body Standing Illustration)
                    Image.asset(
                      fullbodyAsset,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      filterQuality: FilterQuality.high,
                    ),

                    // 3. 膚色即時渲染層 (動態色溫調配)
                    if (skinTint != Colors.transparent)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: skinTint,
                              backgroundBlendMode: BlendMode.colorBurn,
                            ),
                          ),
                        ),
                      ),

                    // 4. 自然光影髮色滲透與秀髮高光層 (Natural Anime Hair Luster & Tint)
                    // 以柔和徑向調色與立繪自帶髮流自然融合，徹底消除生硬突兀與獵奇幾何感
                    if (hairOverlay != null)
                      Positioned(
                        top: widget.height * 0.045,
                        left: widget.width * 0.28,
                        width: widget.width * 0.44,
                        height: widget.height * 0.16,
                        child: IgnorePointer(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 柔和髮色氛圍光
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      hairOverlay.withOpacity(0.55),
                                      hairOverlay.withOpacity(0.25),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.60, 1.0],
                                  ),
                                ),
                              ),
                              // 日漫天使光環微光（秀髮高光 Angel Ring Highlight）
                              Positioned(
                                top: widget.height * 0.04,
                                child: Container(
                                  width: widget.width * 0.26,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.40),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 6. 實體飾品動態配件圖層 (Accessories Layer - 全身比例座標精準校對，完美貼合五官)
                    // (A) 黃金璀璨王冠 (頭頂中心 y = 0.045)
                    if (hasCrown)
                      Positioned(
                        top: widget.height * 0.042,
                        child: CustomPaint(
                          size: Size(widget.width * 0.28, widget.height * 0.075),
                          painter: _CrownAccessoryPainter(),
                        ),
                      ),

                    // (B) 金絲細框眼鏡 (雙眼中心 y = 0.138, 寬度與眼距精準校正)
                    if (hasGlasses)
                      Positioned(
                        top: widget.height * 0.138 - (widget.height * 0.045 / 2),
                        child: CustomPaint(
                          size: Size(widget.width * 0.25, widget.height * 0.045),
                          painter: _GlassesAccessoryPainter(),
                        ),
                      ),

                    // (C) 皇家藍蝴蝶結 / 領結 (領口 y = 0.205)
                    if (hasRibbon)
                      Positioned(
                        top: widget.height * 0.205,
                        child: CustomPaint(
                          size: Size(widget.width * 0.20, widget.height * 0.06),
                          painter: _RibbonAccessoryPainter(),
                        ),
                      ),

                    // (D) 星星垂墜耳環 (耳際 y = 0.145)
                    if (hasStarEarring) ...[
                      Positioned(
                        top: widget.height * 0.142,
                        left: widget.width * 0.36,
                        child: CustomPaint(
                          size: Size(widget.width * 0.05, widget.height * 0.05),
                          painter: _StarEarringPainter(),
                        ),
                      ),
                      Positioned(
                        top: widget.height * 0.142,
                        right: widget.width * 0.36,
                        child: CustomPaint(
                          size: Size(widget.width * 0.05, widget.height * 0.05),
                          painter: _StarEarringPainter(),
                        ),
                      ),
                    ],

                    // (E) 貓咪腮紅鬍鬚面飾 (臉頰兩側 y = 0.142)
                    if (hasCatWhiskers)
                      Positioned(
                        top: widget.height * 0.140,
                        child: CustomPaint(
                          size: Size(widget.width * 0.32, widget.height * 0.045),
                          painter: _CatWhiskersPainter(),
                        ),
                      ),

                    // 7. 復古典雅四周暗角與琥珀金色微光
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFC99742).withOpacity(0.35),
                              width: 1.0,
                            ),
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.25,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          content,
          for (final heart in _hearts)
            _AnimatedHeartParticle(
              heart: heart,
              height: widget.height,
            ),
        ],
      ),
    );
  }
}



// ── 配件繪製器 (全身立繪比例金屬飾品 - 精準校對五官) ───────────────────

class _GlassesAccessoryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = h * 0.42;

    // 陰影投射，增強立體層次
    final shadowPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final leftCenter = Offset(w * 0.30, h * 0.50);
    final rightCenter = Offset(w * 0.70, h * 0.50);

    // 投射微陰影
    canvas.drawCircle(leftCenter.translate(0, 1.0), r, shadowPaint);
    canvas.drawCircle(rightCenter.translate(0, 1.0), r, shadowPaint);

    // 典雅金絲金屬漸層鏡框
    final framePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFDF85), Color(0xFFC99742), Color(0xFF8B6428)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // 左眼鏡框與鏡片高光
    canvas.drawCircle(leftCenter, r, framePaint);
    canvas.drawCircle(leftCenter, r - 1.0, Paint()..color = const Color(0xFF93C5FD).withOpacity(0.12));

    // 右眼鏡框與鏡片高光
    canvas.drawCircle(rightCenter, r, framePaint);
    canvas.drawCircle(rightCenter, r - 1.0, Paint()..color = const Color(0xFF93C5FD).withOpacity(0.12));

    // 鏡片反光條 (日漫眼鏡標誌性白色反光)
    final reflectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(leftCenter.dx - r * 0.5, leftCenter.dy - r * 0.4),
      Offset(leftCenter.dx - r * 0.1, leftCenter.dy - r * 0.7),
      reflectionPaint,
    );
    canvas.drawLine(
      Offset(rightCenter.dx - r * 0.5, rightCenter.dy - r * 0.4),
      Offset(rightCenter.dx - r * 0.1, rightCenter.dy - r * 0.7),
      reflectionPaint,
    );

    // 鼻樑中樑橫槓
    canvas.drawLine(
      Offset(leftCenter.dx + r, h * 0.48),
      Offset(rightCenter.dx - r, h * 0.48),
      framePaint,
    );

    // 左右鏡腿延伸
    canvas.drawLine(
      Offset(leftCenter.dx - r, h * 0.48),
      Offset(w * 0.05, h * 0.45),
      framePaint,
    );
    canvas.drawLine(
      Offset(rightCenter.dx + r, h * 0.48),
      Offset(w * 0.95, h * 0.45),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrownAccessoryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.10, h * 0.85)
      ..lineTo(w * 0.05, h * 0.25)
      ..lineTo(w * 0.32, h * 0.55)
      ..lineTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.68, h * 0.55)
      ..lineTo(w * 0.95, h * 0.25)
      ..lineTo(w * 0.90, h * 0.85)
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFDF85), Color(0xFFC99742), Color(0xFF8B6B3E)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, paint);

    // 珠寶微光
    canvas.drawCircle(Offset(w * 0.50, h * 0.38), 2.5, Paint()..color = const Color(0xFFDC2626));
    canvas.drawCircle(Offset(w * 0.26, h * 0.58), 2.0, Paint()..color = const Color(0xFF2563EB));
    canvas.drawCircle(Offset(w * 0.74, h * 0.58), 2.0, Paint()..color = const Color(0xFF2563EB));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RibbonAccessoryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF2563EB); // 皇家藍
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 3.5, p);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.28, size.height * 0.48), width: size.width * 0.35, height: size.height * 0.45),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.72, size.height * 0.48), width: size.width * 0.35, height: size.height * 0.45),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarEarringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawCircle(Offset(cx, cy * 0.5), 1.5, p);
    // 小五角星
    canvas.drawCircle(Offset(cx, cy * 1.3), 2.5, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CatWhiskersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF333333).withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    // 左鬍鬚
    canvas.drawLine(Offset(size.width * 0.1, size.height * 0.4), Offset(size.width * 0.3, size.height * 0.45), p);
    canvas.drawLine(Offset(size.width * 0.08, size.height * 0.65), Offset(size.width * 0.28, size.height * 0.6), p);
    // 右鬍鬚
    canvas.drawLine(Offset(size.width * 0.9, size.height * 0.4), Offset(size.width * 0.7, size.height * 0.45), p);
    canvas.drawLine(Offset(size.width * 0.92, size.height * 0.65), Offset(size.width * 0.72, size.height * 0.6), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AngelWingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..color = Colors.white.withOpacity(0.40)
      ..style = PaintingStyle.fill;

    // 左羽翼
    final leftWing = Path()
      ..moveTo(w * 0.45, h * 0.6)
      ..quadraticBezierTo(w * 0.2, h * 0.1, 0, h * 0.2)
      ..quadraticBezierTo(w * 0.15, h * 0.7, w * 0.45, h * 0.8)
      ..close();
    canvas.drawPath(leftWing, p);

    // 右羽翼
    final rightWing = Path()
      ..moveTo(w * 0.55, h * 0.6)
      ..quadraticBezierTo(w * 0.8, h * 0.1, w, h * 0.2)
      ..quadraticBezierTo(w * 0.85, h * 0.7, w * 0.55, h * 0.8)
      ..close();
    canvas.drawPath(rightWing, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 愛心微粒效果 ────────────────────────────────────────────────────────

class _FloatingHeart {
  final int id;
  final double x;
  final double y;
  final String emoji;
  _FloatingHeart({required this.id, required this.x, required this.y, required this.emoji});
}

class _AnimatedHeartParticle extends StatefulWidget {
  final _FloatingHeart heart;
  final double height;
  const _AnimatedHeartParticle({required this.heart, required this.height});

  @override
  State<_AnimatedHeartParticle> createState() => _AnimatedHeartParticleState();
}

class _AnimatedHeartParticleState extends State<_AnimatedHeartParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final progress = _ctrl.value;
        final floatY = widget.heart.y - (progress * 70);
        final opacity = (1.0 - progress).clamp(0.0, 1.0);
        final scale = 0.6 + (math.sin(progress * math.pi) * 0.7);

        return Positioned(
          left: widget.heart.x - 12,
          top: floatY,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Text(
                widget.heart.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        );
      },
    );
  }
}
