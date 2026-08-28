import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey;
  OpenAIService(this.apiKey);

  static const _base = 'https://api.openai.com/v1';

  Future<Uint8List?> generateCharacterImage({
    required String gender,
    required String bodyGoal,
    required bool isMirror,
    required String style,
  }) async {
    final modeDesc = isMirror ? '你理想中的另一半' : '代表自己的';
    final goalDesc = bodyGoal == 'loseFat'
        ? '纖細勻稱'
        : bodyGoal == 'gainMuscle'
            ? '肌肉發達'
            : '健康自然';
    final genderDesc = gender == '她' || gender == '女' ? '女性' : '男性';

    final prompt =
        'Anime style full-body character illustration, $genderDesc, $goalDesc physique, '
        '$modeDesc character, modern casual outfit, clean white background, '
        'high quality, cute anime art style, front facing, full body visible, '
        'detailed character design, soft lighting';

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

  Future<Uint8List?> generateShopItemImage(String itemName, String category) async {
    final promptMap = {
      'outfit': 'Anime style clothing item, $itemName, clean white background, product shot, cute illustration',
      'hairstyle': 'Anime character hair style, $itemName, clean white background, illustration',
      'accessory': 'Cute anime accessory item, $itemName, clean white background, product illustration',
      'background': 'Cute anime scene background, $itemName, illustration, vibrant colors',
      'tattoo': 'Cute anime temporary tattoo design, $itemName, clean white background',
      'faceDecal': 'Cute anime face decoration, $itemName, clean white background',
    };
    final prompt = promptMap[category] ??
        'Cute anime illustration of $itemName, clean white background';
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
