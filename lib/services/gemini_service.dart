import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const _model = 'gemini-3.6-flash';

  final GenerativeModel _textModel;
  final GenerativeModel _visionModel;

  GeminiService(String apiKey)
      : _textModel = GenerativeModel(model: _model, apiKey: apiKey),
        _visionModel = GenerativeModel(model: _model, apiKey: apiKey);

  // ── Food Analysis ────────────────────────────────────────────

  static const _foodSystemPrompt = '''你是時光機APP的專業AI飲食分析師，同時擅長中醫食療。
分析食物時必須用以下格式回覆：

【摘要】
一句話說明這餐的整體評價。

【熱量估算】
總熱量：XXX-YYY kcal（最可能：ZZZ kcal）

【三大營養素】
- 蛋白質：XX g
- 碳水化合物：XX g
- 脂肪：XX g

【隱藏熱量提醒】
（如有醬料、油脂、飲料等隱藏熱量，在此說明）

【中醫食補觀點】
（簡短說明食材的食療特性）

【智能建議】
（根據使用者目標給出一條具體建議）
''';

  Future<String> analyzeFood(String description) async {
    final response = await _textModel.generateContent([
      Content.text('$_foodSystemPrompt\n\n使用者說：$description'),
    ]);
    return response.text ?? '無法分析，請稍後再試。';
  }

  Future<String> analyzeFoodImage(Uint8List imageBytes, String? note) async {
    final prompt = note?.isNotEmpty == true
        ? '$_foodSystemPrompt\n\n這是使用者拍的食物照片，補充說明：$note'
        : '$_foodSystemPrompt\n\n請分析照片中的食物。';
    final response = await _visionModel.generateContent([
      Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(prompt),
      ]),
    ]);
    return response.text ?? '無法分析，請稍後再試。';
  }

  // ── Vlog Generation ──────────────────────────────────────────

  Future<String> generateVlog({
    required String nickname,
    required double calories,
    required double targetCalories,
    required int goalPoints,
    required String? diaryContent,
    required String characterMode,
    required String performanceLevel,
  }) async {
    final prompt = '''你是一個生活記錄AI，幫使用者生成今日的生活Vlog文字。
風格要根據「表現等級」調整：
- 卓越：充滿活力、讚美、正向
- 普通：輕鬆平和、中性
- 低落：溫柔鼓勵、不批評

使用者資料：
- 暱稱：$nickname
- 今日熱量：${calories.round()} / ${targetCalories.round()} kcal
- 目標點數：$goalPoints 點
- 日記內容：${diaryContent ?? '（今天沒有寫日記）'}
- 角色模式：$characterMode
- 表現等級：$performanceLevel

請生成約100-150字的今日Vlog，要有溫度、像真人在說話。
如果角色模式是「映照」，可以加入對象的視角或回應。
''';
    final response = await _textModel.generateContent([Content.text(prompt)]);
    return response.text ?? '今天也是美好的一天。';
  }

  // ── Diary Auto-completion ────────────────────────────────────

  Future<String> completeDiary(String partialContent, String nickname) async {
    final prompt = '''你是一個溫柔的日記AI助手。
使用者「$nickname」寫了以下日記草稿，請幫忙優雅地補全，保留原有語氣和事實，約50-100字：

草稿：$partialContent

補全內容（直接續寫，不要重複草稿）：''';
    final response = await _textModel.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }

  // ── Todo Extraction ──────────────────────────────────────────

  Future<List<String>> extractTodos(String diaryContent) async {
    final prompt = '''從以下日記中提取可能的待辦事項（用繁體中文列出，每行一個，最多5個）：

$diaryContent

待辦事項（僅列出清單，不要其他文字）：''';
    final response = await _textModel.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';
    return text.split('\n').where((l) => l.trim().isNotEmpty).take(5).toList();
  }

  // ── Goal Review ──────────────────────────────────────────────

  Future<String> reviewGoals({
    required String nickname,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> recentLogs,
  }) async {
    final catSummary = categories.map((c) => c['title']).join('、');
    final prompt = '''你是生活教練AI，請根據以下資料給「$nickname」提出目標調整建議。

目標類別：$catSummary
最近7天表現：${recentLogs.length}筆記錄

請給出：
1. 做得好的地方（1-2點）
2. 需要改善的地方（1-2點）
3. 具體行動建議（1-2點）

語氣要像朋友，不要太說教。約150字。''';
    final response = await _textModel.generateContent([Content.text(prompt)]);
    return response.text ?? '繼續加油！';
  }

  // ── Character Mirror Response ─────────────────────────────────

  Future<String> getMirrorResponse({
    required String gender,
    required double performanceRatio,
    required String diaryContent,
  }) async {
    final level = performanceRatio >= 0.9
        ? '非常棒'
        : performanceRatio >= 0.7
            ? '不錯'
            : '需要加油';
    final perspective = gender == '女' ? '她' : '他';
    final prompt = '''你是一個溫柔的角色，站在使用者想像中的$perspective的角度，
對使用者今天的表現（$level）說一句話。
語氣要自然、有情感，像是真實的人在說話。20-40字即可。
今天的日記：${diaryContent.isEmpty ? '（沒有寫日記）' : diaryContent}''';
    final response = await _textModel.generateContent([Content.text(prompt)]);
    return response.text ?? '你今天很棒，繼續保持！';
  }

  // ── Knowledge Question ────────────────────────────────────────

  Future<Map<String, String>> generateKnowledgeQuestion(String category) async {
    final prompt = '''請生成一道仿「瞎掰王」風格的趣味知識題，類別：$category

格式（嚴格照以下JSON格式輸出）：
{
  "question": "題目（有趣、讓人想猜）",
  "correct": "正確答案（真實有趣的事實）",
  "wrong1": "假答案1（聽起來合理但是假的）",
  "wrong2": "假答案2（聽起來合理但是假的）",
  "explanation": "解釋為什麼正確答案是對的（50字以內）",
  "category": "$category"
}

只輸出JSON，不要其他文字。''';
    try {
      final response = await _textModel.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      // Return as-is for caller to parse
      return {'raw': clean};
    } catch (_) {
      return {'raw': '{}'};
    }
  }
}
