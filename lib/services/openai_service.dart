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
    required String bodyGoal,
    required bool isMirror,
    required String style,
    CharacterAppearance? appearance,
    double muscleLevel = 0.5,
    double fatLevel = 0.5,
  }) async {
    final genderDesc = gender == '她' || gender == '女' ? 'female' : 'male';
    final modeDesc = isMirror ? 'ideal romantic partner' : 'personal avatar';

    // Body type from health metrics
    String bodyDesc;
    if (muscleLevel > 0.7 && fatLevel < 0.3) {
      bodyDesc = 'athletic muscular toned body';
    } else if (muscleLevel > 0.5 && fatLevel < 0.4) {
      bodyDesc = 'fit and healthy body';
    } else if (fatLevel > 0.6) {
      bodyDesc = 'slightly chubby soft body, natural and cute';
    } else {
      bodyDesc = 'slender healthy body';
    }

    // Goal override
    if (bodyGoal == 'loseFat') bodyDesc = 'slender and lean body';
    if (bodyGoal == 'gainMuscle') bodyDesc = 'muscular athletic body';

    // Skin tone
    final skinDesc = switch (appearance?.skinTone) {
      SkinTone.light => 'fair pale skin',
      SkinTone.medium => 'medium skin tone',
      SkinTone.tan => 'warm tan skin',
      SkinTone.dark => 'dark skin tone',
      null => 'medium skin tone',
    };

    // Hair style
    final hairStyleDesc = switch (appearance?.hairStyle) {
      HairStyle.short => 'short hair',
      HairStyle.medium => 'medium-length hair',
      HairStyle.long => 'long flowing hair',
      HairStyle.bun => 'hair tied in a bun',
      HairStyle.ponytail => 'ponytail hair',
      HairStyle.curly => 'curly wavy hair',
      null => 'medium-length hair',
    };

    // Hair color
    final hairColorDesc = switch (appearance?.hairColor) {
      HairColor.black => 'black hair',
      HairColor.brown => 'dark brown hair',
      HairColor.blonde => 'golden blonde hair',
      HairColor.red => 'auburn red hair',
      HairColor.gray => 'silver gray hair',
      HairColor.fantasy => 'vibrant purple and blue gradient fantasy hair',
      null => 'black hair',
    };

    // Outfit description
    String outfitDesc = 'modern casual outfit';
    if (appearance?.outfitId != null) {
      outfitDesc = _outfitDescription(appearance!.outfitId!);
    }

    // Accessories
    String accessoriesDesc = '';
    if (appearance?.accessories.isNotEmpty == true) {
      accessoriesDesc =
          'wearing accessories: ${appearance!.accessories.join(', ')}, ';
    }

    // Tattoos / face decals
    String tattoosDesc = '';
    if (appearance?.tattoos.isNotEmpty == true) {
      tattoosDesc = 'with decorative tattoo: ${appearance!.tattoos.first}, ';
    }

    final prompt = 'High quality anime style full-body character illustration, '
        '$genderDesc, age 25, $bodyDesc, $skinDesc, $hairStyleDesc in $hairColorDesc, '
        '$outfitDesc, $accessoriesDesc$tattoosDesc'
        '$modeDesc character, clean white or soft gradient background, '
        'front-facing full body visible, detailed anime art style, soft lighting, '
        'professional character design, no text, no watermark';

    return await _generateImage(prompt);
  }

  String _outfitDescription(String outfitId) {
    // Map outfit IDs to descriptions
    const outfitMap = {
      'school_uniform': 'Japanese school uniform',
      'casual_tshirt': 'casual t-shirt and jeans',
      'sporty': 'athletic sportswear',
      'formal': 'elegant formal dress/suit',
      'traditional': 'traditional Asian hanfu outfit',
      'hoodie': 'cozy hoodie and sweatpants',
      'dress': 'cute summer dress',
      'suit': 'sharp business suit',
      'gym': 'gym workout outfit',
      'pajama': 'comfortable pajamas',
    };
    return outfitMap[outfitId] ?? 'stylish casual outfit';
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

  Future<Uint8List?> _generateImage(String prompt) async {
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
          'size': '1024x1024',
          'quality': 'standard',
          'response_format': 'b64_json',
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final b64 = data['data'][0]['b64_json'] as String;
        return base64Decode(b64);
      }
    } catch (_) {}
    return null;
  }
}
