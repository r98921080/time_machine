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

  /// 根據性別、服裝、髮型決定主全身立繪基底
  String _resolveFullbodyAsset() {
    final outfitId = widget.appearance.outfitId;
    final isFemale = widget.gender == '她' || widget.gender == '女';

    // 依據玩家選取的服裝指定全身立繪
    if (outfitId == 'outfit_sundress' || outfitId == 'outfit_princess' || outfitId == 'special_newyear_outfit') {
      return 'assets/characters/fullbody_princess.jpg';
    }
    if (outfitId == 'outfit_formal_suit' || outfitId == 'outfit_tracksuit' || outfitId == 'outfit_detective') {
      return isFemale
          ? 'assets/characters/fullbody_female_suit.jpg'
          : 'assets/characters/fullbody_scholar.jpg';
    }
    if (outfitId == 'outfit_casual_hoodie' || outfitId == 'outfit_tshirt_white' || outfitId == 'outfit_sport_set' || outfitId == 'outfit_denim_jacket') {
      return 'assets/characters/fullbody_male_casual.jpg';
    }
    if (outfitId == 'outfit_school_uniform') {
      return 'assets/characters/fullbody_female_suit.jpg';
    }

    // 預設依性別/映照角色提供全身立繪
    if (isFemale) {
      return 'assets/characters/fullbody_princess.jpg';
    } else {
      return 'assets/characters/fullbody_scholar.jpg';
    }
  }

  /// 膚色濾鏡顏色與透明度
  Color _resolveSkinTint(SkinTone tone) {
    switch (tone) {
      case SkinTone.light:
        return const Color(0xFFFFF7F0); // 透白柔光
      case SkinTone.medium:
        return Colors.transparent; // 原生中等膚色
      case SkinTone.tan:
        return const Color(0xFFC68A55).withOpacity(0.24); // 健康小麥色微光
      case SkinTone.dark:
        return const Color(0xFF7A4A28).withOpacity(0.38); // 深沉古銅膚色
    }
  }

  /// 髮色疊色濾鏡
  Color? _resolveHairColorOverlay(HairColor color) {
    switch (color) {
      case HairColor.black:
        return const Color(0xFF1A1A1A).withOpacity(0.18);
      case HairColor.brown:
        return const Color(0xFF5D3A1A).withOpacity(0.20);
      case HairColor.blonde:
        return const Color(0xFFFFD700).withOpacity(0.25);
      case HairColor.red:
        return const Color(0xFFDC2626).withOpacity(0.22);
      case HairColor.gray:
        return const Color(0xFFE2E8F0).withOpacity(0.32);
      case HairColor.fantasy:
        return const Color(0xFF8B5CF6).withOpacity(0.28);
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

                    // 4. 髮色漸層光感層 (若自訂特殊髮色)
                    if (hairOverlay != null)
                      Positioned(
                        top: widget.height * 0.03,
                        left: widget.width * 0.25,
                        width: widget.width * 0.50,
                        height: widget.height * 0.25,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  hairOverlay,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 5. 髮型輪廓特徵動態渲染 (配合玩家髮型切換：馬尾/包子頭/波浪)
                    if (widget.appearance.hairStyle == HairStyle.ponytail ||
                        widget.appearance.hairStyle == HairStyle.bun ||
                        widget.appearance.hairStyle == HairStyle.curly)
                      Positioned(
                        top: widget.height * 0.05,
                        child: CustomPaint(
                          size: Size(widget.width * 0.70, widget.height * 0.18),
                          painter: _HairStyleAccentPainter(style: widget.appearance.hairStyle),
                        ),
                      ),

                    // 6. 實體飾品動態配件圖層 (Accessories Layer - 全身比例座標精準校對)
                    // (A) 黃金璀璨王冠
                    if (hasCrown)
                      Positioned(
                        top: widget.height * 0.025,
                        child: CustomPaint(
                          size: Size(widget.width * 0.32, widget.height * 0.09),
                          painter: _CrownAccessoryPainter(),
                        ),
                      ),

                    // (B) 金絲細框眼鏡
                    if (hasGlasses)
                      Positioned(
                        top: widget.height * 0.115,
                        child: CustomPaint(
                          size: Size(widget.width * 0.28, widget.height * 0.06),
                          painter: _GlassesAccessoryPainter(),
                        ),
                      ),

                    // (C) 皇家藍蝴蝶結 / 領結
                    if (hasRibbon)
                      Positioned(
                        top: widget.height * 0.19,
                        child: CustomPaint(
                          size: Size(widget.width * 0.18, widget.height * 0.06),
                          painter: _RibbonAccessoryPainter(),
                        ),
                      ),

                    // (D) 星星垂墜耳環
                    if (hasStarEarring)
                      Positioned(
                        top: widget.height * 0.13,
                        left: widget.width * 0.32,
                        child: CustomPaint(
                          size: Size(widget.width * 0.06, widget.height * 0.06),
                          painter: _StarEarringPainter(),
                        ),
                      ),

                    // (E) 貓咪腮紅鬍鬚面飾
                    if (hasCatWhiskers)
                      Positioned(
                        top: widget.height * 0.125,
                        child: CustomPaint(
                          size: Size(widget.width * 0.35, widget.height * 0.05),
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

// ── 髮型特徵動態渲染器 ──────────────────────────────────────────

class _HairStyleAccentPainter extends CustomPainter {
  final HairStyle style;
  const _HairStyleAccentPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..color = const Color(0xFF3B271A).withOpacity(0.65)
      ..style = PaintingStyle.fill;

    if (style == HairStyle.ponytail) {
      // 馬尾蓬鬆輪廓
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.12, h * 0.35), width: w * 0.16, height: h * 0.65), p);
    } else if (style == HairStyle.bun) {
      // 俏皮包子頭丸子
      canvas.drawCircle(Offset(w * 0.15, h * 0.2), w * 0.12, p);
      canvas.drawCircle(Offset(w * 0.85, h * 0.2), w * 0.12, p);
    }
  }

  @override
  bool shouldRepaint(covariant _HairStyleAccentPainter old) => old.style != style;
}

// ── 配件繪製器 (全身立繪比例金屬飾品) ──────────────────────────

class _GlassesAccessoryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = h * 0.40;

    final paint = Paint()
      ..color = const Color(0xFFC99742) // 古典金絲
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 左眼鏡框
    final leftCenter = Offset(w * 0.32, h * 0.50);
    canvas.drawCircle(leftCenter, r, paint);
    canvas.drawCircle(leftCenter, r - 0.8, Paint()..color = Colors.white.withOpacity(0.18));

    // 右眼鏡框
    final rightCenter = Offset(w * 0.68, h * 0.50);
    canvas.drawCircle(rightCenter, r, paint);
    canvas.drawCircle(rightCenter, r - 0.8, Paint()..color = Colors.white.withOpacity(0.18));

    // 鼻樑金屬橫槓
    canvas.drawLine(
      Offset(leftCenter.dx + r, h * 0.48),
      Offset(rightCenter.dx - r, h * 0.48),
      paint,
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
