import 'package:flutter/material.dart';
import '../models/character.dart';
import 'layered_anime_portrait.dart';

/// 伴侶人像顯示組件（導向手遊級多圖層高清立繪引擎）
class DollCharacterWidget extends StatelessWidget {
  final CharacterAppearance appearance;
  final String gender;
  final bool isMirror;
  final double width;
  final double height;
  final bool enableAnimation;
  final bool interactive;
  final VoidCallback? onTap;

  const DollCharacterWidget({
    super.key,
    required this.appearance,
    required this.gender,
    this.isMirror = false,
    this.width = 180,
    this.height = 320,
    this.enableAnimation = true,
    this.interactive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayeredAnimePortraitWidget(
      appearance: appearance,
      gender: gender,
      isMirror: isMirror,
      width: width,
      height: height,
      enableAnimation: enableAnimation,
      interactive: interactive,
      onTap: onTap,
    );
  }
}
