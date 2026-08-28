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
    final prompt = '''你是一個溫柔的生活記錄AI，幫使用者生成今日的Vlog文字日誌。
風格根據「表現等級」調整：
- 卓越：充滿活力、讚美、正向鼓勵
- 超標：溫柔提醒、不批評、找亮點
- 低落：溫暖抱抱、說今天努力了、明天繼續

使用者資料：
- 暱稱：$nickname
- 今日熱量：${calories.round()} / ${targetCalories.round()} kcal
- 目標點數：$goalPoints 點
- 日記：${diaryContent?.isNotEmpty == true ? diaryContent : '（今天沒有寫日記）'}
- 角色模式：$characterMode
- 表現等級：$performanceLevel

請生成約100-150字的今日Vlog，第一人稱敘事，有溫度像真人在說話。
如果是映照模式，從使用者想像中的對象視角加入一句話。
絕對不要空白回覆，一定要有內容。''';
    try {
      final response = await _textModel.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) return text;
    } catch (_) {}
    return '今天是充實的一天。不管結果如何，能記錄下來就是進步的開始。明天的$nickname，會比今天更好。';
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

  // ── Character Chat (with memory) ─────────────────────────────

  Future<String> chatWithCharacter({
    required String characterName,
    required String relationship, // 陌生人/朋友/曖昧/親密
    required bool isMirror,
    required String gender, // 她/他
    required List<Map<String, String>> history, // [{role, content}, ...]
    required String userMessage,
    required Map<String, dynamic> todayData, // calories, goalPoints, diary
  }) async {
    final roleDesc = isMirror
        ? '你是使用者理想中的${gender == '她' ? '女朋友' : '男朋友'}候選人，正在和使用者發展關係。'
        : '你是使用者的生活夥伴，一個關心對方健康和成長的朋友。';

    final relDesc = {
      '陌生人': '你們剛認識，互動略為正式、謹慎，但帶點好奇。',
      '朋友': '你們已是朋友，輕鬆自然，偶爾關心對方近況。',
      '曖昧': '你們互有好感，說話有些嬌羞，偶爾有小曖昧。',
      '親密': '你們已非常親近，話語溫柔體貼，像家人一般理解對方。',
    }[relationship] ?? '自然地互動。';

    final todayCalories = todayData['calories'] ?? 0;
    final todayTarget = todayData['targetCalories'] ?? 2000;
    final goalPoints = todayData['goalPoints'] ?? 0;
    final diaryContent = todayData['diary'] ?? '';

    final systemContext = '''$roleDesc
關係階段：$relationship。$relDesc
你的名字是「$characterName」。

今天使用者的狀態：
- 熱量攝取：${todayCalories.round()} / ${todayTarget.round()} kcal
- 目標得分：$goalPoints 點
${diaryContent.isNotEmpty ? '- 今日日記：$diaryContent' : ''}

對話規則：
1. 回應要自然、有個性，不要像機器人
2. 偶爾主動關心使用者（不要每次都這樣）
3. 可以提到你「看到」的今日數據，但要自然地帶入，不要像報告
4. 用繁體中文，不要超過100字
5. 根據關係階段調整親密度
6. 不要用敬語，用「你」稱呼對方''';

    // Build message history for context
    final historyContent = history.takeLast(20).map((h) {
      return h['role'] == 'user'
          ? Content.text('使用者：${h['content']}')
          : Content.text('$characterName：${h['content']}');
    }).toList();

    final fullPrompt = '$systemContext\n\n以下是最近的對話：\n'
        '${history.takeLast(10).map((h) => '${h['role'] == 'user' ? '使用者' : characterName}：${h['content']}').join('\n')}'
        '\n\n使用者現在說：$userMessage\n\n$characterName 回應（不要說自己的名字）：';

    try {
      final response = await _textModel.generateContent([Content.text(fullPrompt)]);
      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) return text;
    } catch (_) {}
    return '嗯，我在聽你說。今天辛苦了，好好休息吧。';
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
    final perspective = gender == '女' || gender == '她' ? '她' : '他';
    final prompt = '''你是一個溫柔的角色，站在使用者想像中的${perspective}的角度，
對使用者今天的表現（$level）說一句話。
語氣要自然、有情感，像是真實的人在說話。20-40字即可。
今天的日記：${diaryContent.isEmpty ? '（沒有寫日記）' : diaryContent}''';
    final response = await _textModel.generateContent([Content.text(prompt)]);
    return response.text ?? '你今天很棒，繼續保持！';
  }

  // ── Goal AI Suggestions ───────────────────────────────────────

  Future<List<String>> suggestGoalSubCategories(String category) async {
    final prompt = '''使用者想設定「$category」類別的目標。
請列出6-8個常見的子類別選項（簡短，2-6字），例如：
- 運動 → 跑步、重訓、游泳、球類、瑜伽、騎腳踏車
只輸出清單，每行一個，不要編號或其他文字。''';
    try {
      final res = await _textModel.generateContent([Content.text(prompt)]);
      final lines = (res.text ?? '').split('\n')
          .map((l) => l.replaceAll(RegExp(r'^[-•\s]+'), '').trim())
          .where((l) => l.isNotEmpty)
          .take(8)
          .toList();
      return lines.isNotEmpty ? lines : _fallbackSubCategories(category);
    } catch (_) {
      return _fallbackSubCategories(category);
    }
  }

  List<String> _fallbackSubCategories(String category) {
    const defaults = {
      '運動': ['跑步', '重訓', '游泳', '球類', '瑜伽', '騎腳踏車'],
      '飲食': ['蔬果攝取', '蛋白質', '減糖', '少油', '補水', '早餐'],
      '睡眠': ['早睡', '睡眠品質', '午休', '規律作息'],
      '學習': ['閱讀', '語言', '專業課程', '技能練習', '筆記整理'],
      '心理': ['冥想', '感恩練習', '日記', '情緒記錄', '社交'],
    };
    for (final key in defaults.keys) {
      if (category.contains(key)) return defaults[key]!;
    }
    return ['項目A', '項目B', '項目C', '項目D'];
  }

  Future<Map<String, List<String>>?> generateGoalTargets(
      String category, String subCategory) async {
    final prompt = '''為「$category - $subCategory」生成三個難度層次的具體目標。
格式（嚴格照以下JSON輸出）：
{
  "mini": ["入門目標（容易達到，適合初學者）"],
  "advanced": ["進階目標（需要努力，有挑戰性）"],
  "elite": ["精英目標（高標準，需要持續努力）"]
}
每個難度只給1個具體目標描述，要有數字或明確標準，例如「每天30分鐘」「每週3次」。
只輸出JSON。''';
    try {
      final res = await _textModel.generateContent([Content.text(prompt)]);
      final text = (res.text ?? '{}').replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = _parseGoalTargets(text);
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Map<String, List<String>>? _parseGoalTargets(String json) {
    try {
      final mini = RegExp(r'"mini":\s*\["([^"]+)"\]').firstMatch(json)?.group(1);
      final advanced = RegExp(r'"advanced":\s*\["([^"]+)"\]').firstMatch(json)?.group(1);
      final elite = RegExp(r'"elite":\s*\["([^"]+)"\]').firstMatch(json)?.group(1);
      if (mini != null && advanced != null && elite != null) {
        return {
          'mini': [mini],
          'advanced': [advanced],
          'elite': [elite],
        };
      }
    } catch (_) {}
    return null;
  }

  // ── Knowledge Question ────────────────────────────────────────

  Future<Map<String, dynamic>?> generateKnowledgeQuestionParsed(String category) async {
    final prompt = '''請生成一道仿「瞎掰王」風格的趣味知識題，類別：$category

格式（嚴格照以下JSON格式輸出）：
{
  "question": "題目（有趣、讓人想猜，用問句）",
  "correct": "正確答案（真實有趣的事實，10字以內）",
  "wrong1": "假答案1（聽起來合理但是假的，10字以內）",
  "wrong2": "假答案2（聽起來合理但是假的，10字以內）",
  "wrong3": "假答案3（聽起來合理但是假的，10字以內）",
  "explanation": "解釋為什麼正確答案是對的（50字以內）",
  "category": "$category"
}

只輸出JSON，不要其他文字。''';
    try {
      final response = await _textModel.generateContent([Content.text(prompt)]);
      final text = (response.text ?? '').replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = _parseKnowledgeJson(text);
      if (parsed != null &&
          parsed['question'] != null &&
          parsed['correct'] != null) {
        return parsed;
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? _parseKnowledgeJson(String text) {
    try {
      // Find the JSON object
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start < 0 || end < 0) return null;
      final jsonStr = text.substring(start, end + 1);
      final result = <String, dynamic>{};
      for (final field in ['question', 'correct', 'wrong1', 'wrong2', 'wrong3', 'explanation', 'category']) {
        final match = RegExp('"$field":\\s*"((?:[^"\\\\]|\\\\.)*)\"').firstMatch(jsonStr);
        if (match != null) {
          result[field] = match.group(1)?.replaceAll('\\"', '"') ?? '';
        }
      }
      return result.isNotEmpty ? result : null;
    } catch (_) {
      return null;
    }
  }

  // Legacy method kept for compatibility
  Future<Map<String, String>?> generateKnowledgeQuestion(String category) async {
    final result = await generateKnowledgeQuestionParsed(category);
    if (result == null) return null;
    return {'raw': result.toString()};
  }
}

extension _ListTakeLast<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}
