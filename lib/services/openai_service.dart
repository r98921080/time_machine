import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/character.dart';

class OpenAIService {
  final String apiKey;
  OpenAIService(this.apiKey);

  static const _base = 'https://api.openai.com/v1';

  Future<Uint8List?> generateCharacterImage({
    required String gender,
    required String relationship,
    required bool isMirror,
    CharacterAppearance? appearance,
  }) async {
    final genderDesc = gender == '她' || gender == '女' ? 'female' : 'male';
    final modeDesc = isMirror ? 'romantic partner character' : 'personal companion character';

    final skinDesc = switch (appearance?.skinTone) {
      SkinTone.light => 'fair pale skin',
      SkinTone.medium => 'medium skin tone',
      SkinTone.tan => 'warm tan skin',
      SkinTone.dark => 'dark brown skin tone',
      null => 'medium skin tone',
    };

    final hairStyleDesc = switch (appearance?.hairStyle) {
      HairStyle.short => 'short neat hair',
      HairStyle.medium => 'medium-length hair',
      HairStyle.long => 'long flowing hair',
      HairStyle.bun => 'elegant hair bun',
      HairStyle.ponytail => 'ponytail hairstyle',
      HairStyle.curly => 'curly wavy hair',
      null => 'medium-length hair',
    };

    final hairColorDesc = switch (appearance?.hairColor) {
      HairColor.black => 'black hair',
      HairColor.brown => 'dark brown hair',
      HairColor.blonde => 'golden blonde hair',
      HairColor.red => 'auburn red hair',
      HairColor.gray => 'silver gray hair',
      HairColor.fantasy => 'vibrant purple-blue gradient fantasy hair',
      null => 'black hair',
    };

    final bodyDesc = _bodyDesc(
      appearance?.muscleLevel ?? 0.0,
      appearance?.fatLevel ?? 0.3,
    );

    final outfitDesc = _outfitDescription(appearance?.outfitId);
    final accessoriesDesc = _accessoriesDescription(appearance?.accessories ?? []);
    final tattoosDesc = _tattoosDescription(appearance?.tattoos ?? []);

    final expressionDesc = switch (relationship) {
      '陌生人' => 'calm neutral expression',
      '普通朋友' => 'friendly warm smile',
      '熟悉' => 'easy confident smile',
      '好友' => 'bright cheerful smile',
      '曖昧' => 'soft shy smile with gentle blush',
      '親密' => 'radiant warm smile, affectionate gaze',
      _ => 'gentle expression',
    };

    final backgroundDesc = _backgroundDescription(appearance?.outfitId, relationship);

    final extraParts = [
      if (accessoriesDesc.isNotEmpty) accessoriesDesc,
      if (tattoosDesc.isNotEmpty) tattoosDesc,
    ].join(', ');

    final prompt =
        'masterpiece, best quality, high quality anime illustration, '
        '$genderDesc character, age 22, $bodyDesc, $skinDesc, '
        '$hairStyleDesc, $hairColorDesc, '
        'wearing $outfitDesc, '
        '${extraParts.isNotEmpty ? "$extraParts, " : ""}'
        '$expressionDesc, $modeDesc, '
        'full body shot standing head to toe clearly visible, facing viewer, '
        '$backgroundDesc, '
        'detailed anime art style, soft cinematic lighting, sharp details, '
        'professional character design sheet, no text, no watermark, no cropping';

    return await _generateImage(prompt, size: '1024x1792');
  }

  static String _bodyDesc(double muscle, double fat) {
    if (muscle > 0.65 && fat < 0.3) return 'athletic toned muscular body';
    if (muscle > 0.45 && fat < 0.4) return 'fit healthy body';
    if (fat > 0.65) return 'soft chubby cute body, naturally plump';
    return 'slender healthy body';
  }

  static String _outfitDescription(String? outfitId) {
    const map = {
      'outfit_tshirt_white': 'clean white t-shirt with casual pants',
      'outfit_casual_hoodie': 'oversized hoodie with comfortable pants',
      'outfit_sport_set': 'athletic sportswear set with sneakers',
      'outfit_denim_jacket': 'stylish denim jacket with jeans',
      'outfit_formal_suit': 'sharp formal business suit',
      'outfit_sundress': 'floral summer sundress with sandals',
      'outfit_trench': 'elegant trench coat',
      'outfit_tracksuit': 'plaid double-breasted suit',
      'outfit_kimono': 'traditional Japanese kimono with obi',
      'outfit_hanfu': 'elegant traditional Chinese hanfu with flowing sleeves',
      'outfit_mage_robe': 'mysterious medieval mage robe with arcane details',
      'outfit_knight_armor': 'shining medieval silver full plate armor',
      'outfit_cyberpunk': 'futuristic cyberpunk neon outfit with tech accessories',
      'outfit_ninja': 'sleek black ninja outfit',
      'outfit_lab_coat': 'clean white lab coat over shirt',
      'outfit_chef': 'professional chef whites with apron',
      'outfit_space_suit': 'NASA-style space exploration suit',
      'outfit_detective': 'Sherlock-style long detective overcoat',
      'outfit_shrine_maiden': 'red and white shrine maiden miko outfit',
      'outfit_pirate': 'classic pirate captain coat and hat',
      'outfit_school_uniform': 'neat school uniform',
      'outfit_egyptian': 'ancient Egyptian pharaoh golden ceremonial outfit',
      'school_uniform': 'Japanese high school uniform',
      'casual_tshirt': 'casual t-shirt and jeans',
      'sporty': 'athletic sportswear',
      'formal': 'elegant formal dress',
      'traditional': 'traditional hanfu with flowing sleeves',
      'hoodie': 'oversized cozy hoodie',
      'dress': 'cute floral summer dress',
      'suit': 'sharp business suit',
    };
    return map[outfitId] ?? 'stylish modern casual outfit';
  }

  static String _accessoriesDescription(List<String> accessories) {
    const map = {
      'round_glasses': 'round wire-frame glasses',
      'sunglasses': 'cool sunglasses',
      'cap': 'baseball cap',
      'beanie': 'cozy knit beanie',
      'earrings': 'elegant earrings',
      'necklace': 'delicate necklace',
      'scarf': 'soft scarf',
      'headband': 'cute headband',
      'watch': 'wristwatch',
      'bracelet': 'bracelet',
    };
    final descs = accessories.where(map.containsKey).map((a) => 'wearing ${map[a]}').toList();
    return descs.join(', ');
  }

  static String _tattoosDescription(List<String> tattoos) {
    const map = {
      'arm_tattoo': 'small tasteful arm tattoo',
      'neck_tattoo': 'small neck tattoo',
      'wrist_tattoo': 'wrist tattoo',
      'back_tattoo': 'visible upper back tattoo',
    };
    final descs = tattoos.where(map.containsKey).map((t) => map[t]!).toList();
    return descs.join(', ');
  }

  static String _backgroundDescription(String? outfitId, String relationship) {
    final base = {
      'outfit_kimono': 'cherry blossom Japanese garden',
      'outfit_hanfu': 'classical Chinese garden with pavilion',
      'outfit_knight_armor': 'medieval castle courtyard',
      'outfit_cyberpunk': 'futuristic neon city night',
      'outfit_mage_robe': 'magical library with floating books',
      'outfit_space_suit': 'outer space station interior',
      'outfit_shrine_maiden': 'serene Shinto shrine with torii gate',
      'outfit_sport_set': 'modern gym or outdoor track',
      'outfit_chef': 'bright professional kitchen',
      'outfit_detective': 'rainy foggy London street',
      'school_uniform': 'sakura blossom school courtyard',
      'sporty': 'sunny outdoor park',
      'formal': 'elegant ballroom with chandeliers',
    }[outfitId] ?? 'soft pastel gradient studio';

    if (relationship == '親密') return '$base, warm bokeh depth of field, cozy intimate atmosphere';
    if (relationship == '曖昧') return '$base, soft romantic lighting with subtle pink tones';
    return '$base, clean bright even lighting';
  }

  Future<Uint8List?> generateShopItemImage(
      String itemName, String category) async {
    final promptMap = {
      'outfit': 'Anime style clothing item display, $itemName, clean white background, '
          'product illustration, cute and detailed, vibrant colors',
      'hairstyle': 'Anime character hairstyle reference sheet, $itemName, '
          'clean white background, illustration, multiple angles',
      'accessory': 'Cute anime accessory item, $itemName, clean white background, '
          'product illustration, sparkly and detailed',
      'background': 'Anime scene background illustration, $itemName, '
          'vibrant colors, detailed environment art',
      'tattoo': 'Cute anime temporary tattoo design, $itemName, '
          'clean white background, ornate and detailed',
      'faceDecal': 'Cute anime face decoration sticker, $itemName, '
          'clean white background, kawaii style',
      'title': 'Decorative badge or title card design, "$itemName", '
          'anime style, golden or colorful, clean background',
      'effect': 'Magical particle effect illustration, $itemName, '
          'anime style, glowing, clean dark background',
    };
    final prompt = promptMap[category] ??
        'Cute anime illustration of $itemName, clean white background, '
            'high quality product shot';
    return await _generateImage(prompt);
  }

  Future<Uint8List?> _generateImage(String prompt, {String size = '1024x1024'}) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/images/generations'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': 1,
          'size': size,
          'quality': 'hd',
          'style': 'vivid',
          'response_format': 'b64_json',
        }),
      ).timeout(const Duration(seconds: 120));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final b64 = data['data'][0]['b64_json'] as String;
        return base64Decode(b64);
      }
    } catch (_) {}
    return null;
  }
}
