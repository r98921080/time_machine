import 'dart:typed_data';
import 'package:http/http.dart' as http;

class PollinationsService {
  static const _base = 'https://image.pollinations.ai/prompt';

  static String _relationshipExpression(String relationship) {
    switch (relationship) {
      case '陌生人': return 'neutral expression, calm, slight distance';
      case '朋友': return 'friendly smile, relaxed, warm expression';
      case '曖昧': return 'soft blush, gentle shy smile, warm gaze';
      case '親密': return 'radiant warm smile, affectionate gaze, close and comfortable';
      default: return 'gentle expression';
    }
  }

  static String _skinToneDesc(String? skin) {
    switch (skin) {
      case 'light': return 'fair pale skin';
      case 'medium': return 'medium skin tone';
      case 'tan': return 'warm tan skin';
      case 'dark': return 'dark skin tone';
      default: return 'medium skin tone';
    }
  }

  static String _hairStyleDesc(String? style) {
    switch (style) {
      case 'short': return 'short hair';
      case 'medium': return 'medium-length hair';
      case 'long': return 'long flowing hair';
      case 'bun': return 'hair in a bun';
      case 'ponytail': return 'ponytail';
      case 'curly': return 'curly wavy hair';
      default: return 'medium hair';
    }
  }

  static String _hairColorDesc(String? color) {
    switch (color) {
      case 'black': return 'black hair';
      case 'brown': return 'dark brown hair';
      case 'blonde': return 'golden blonde hair';
      case 'red': return 'auburn red hair';
      case 'gray': return 'silver gray hair';
      case 'fantasy': return 'vibrant purple-blue gradient hair';
      default: return 'black hair';
    }
  }

  static String _bodyDesc(double muscle, double fat) {
    if (muscle > 0.6 && fat < 0.35) return 'athletic toned body';
    if (fat > 0.6) return 'soft chubby cute body';
    return 'slender healthy body';
  }

  static String _outfitDesc(String? outfitId) {
    const map = {
      'school_uniform': 'Japanese high school uniform with pleated skirt',
      'casual_tshirt': 'casual white t-shirt and light blue jeans',
      'sporty': 'athletic sportswear, compression leggings, sneakers',
      'formal': 'elegant formal evening dress with heels',
      'traditional': 'traditional Chinese hanfu with flowing sleeves',
      'hoodie': 'oversized cozy hoodie and shorts',
      'dress': 'cute floral summer dress with sandals',
      'suit': 'sharp business suit with tie',
    };
    return map[outfitId] ?? 'stylish casual outfit, jeans and blouse';
  }

  static String _backgroundDesc(String? outfitId, String relationship) {
    final bg = {
      'school_uniform': 'sakura blossom school courtyard',
      'sporty': 'modern gym with equipment',
      'formal': 'elegant ballroom interior',
      'traditional': 'classical Chinese garden',
      'hoodie': 'cozy bedroom with warm lighting',
      'dress': 'sunny outdoor park',
      'suit': 'city office rooftop',
    }[outfitId] ?? 'soft pastel gradient studio background';

    if (relationship == '親密') return '$bg, close warm atmosphere, bokeh depth';
    if (relationship == '曖昧') return '$bg, soft romantic lighting';
    return '$bg, clean bright lighting';
  }

  static int _appearanceSeed({
    required String? skin,
    required String? hairStyle,
    required String? hairColor,
    required String? outfit,
  }) {
    final str = '${skin ?? "medium"}_${hairStyle ?? "medium"}_${hairColor ?? "black"}_${outfit ?? "casual"}';
    var h = 5381;
    for (final c in str.codeUnits) {
      h = ((h << 5) + h + c) & 0x7FFFFFFF;
    }
    return h;
  }

  static Future<Uint8List?> generateCharacterImage({
    required String gender,
    required bool isMirror,
    required String relationship,
    required String? skinTone,
    required String? hairStyle,
    required String? hairColor,
    required double muscleLevel,
    required double fatLevel,
    required String? outfitId,
  }) async {
    final genderWord = (gender == '她' || gender == '女') ? 'female' : 'male';
    final expression = _relationshipExpression(relationship);
    final skin = _skinToneDesc(skinTone);
    final hair = '${_hairStyleDesc(hairStyle)}, ${_hairColorDesc(hairColor)}';
    final body = _bodyDesc(muscleLevel, fatLevel);
    final outfit = _outfitDesc(outfitId);
    final background = _backgroundDesc(outfitId, relationship);
    final modeHint = isMirror ? 'romantic partner character' : 'personal companion character';
    final framingHint = relationship == '親密'
        ? 'medium full body shot, from knees up'
        : 'full body shot, standing, head to toe visible';

    final prompt =
        'high quality anime illustration, $genderWord, age 22, '
        '$body, $skin, $hair, wearing $outfit, $expression, '
        '$modeHint, $framingHint, facing viewer, '
        '$background, detailed anime art style, '
        'soft lighting, sharp details, no text, no watermark, masterpiece quality';

    final seed = _appearanceSeed(
      skin: skinTone, hairStyle: hairStyle, hairColor: hairColor, outfit: outfitId);
    final encoded = Uri.encodeComponent(prompt);
    final url = '$_base/$encoded?width=512&height=896&nologo=true&seed=$seed';

    try {
      final res = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }
}
