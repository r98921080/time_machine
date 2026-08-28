import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _model = 'gemini-3.6-flash';

  final String _apiKey;
  final GenerativeModel _textModel;
  final GenerativeModel _visionModel;

  GeminiService(String apiKey)
      : _apiKey = apiKey,
        _textModel = GenerativeModel(model: _model, apiKey: apiKey),
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
    final response = await _gen([
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
    List<String> foodPhotoDescriptions = const [],
  }) async {
    final photoHint = foodPhotoDescriptions.isNotEmpty
        ? '\n- 今日飲食照片描述：${foodPhotoDescriptions.join('；')}'
        : '';
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
- 表現等級：$performanceLevel$photoHint

請生成約100-150字的今日Vlog，第一人稱敘事，有溫度像真人在說話。
如果是映照模式，從使用者想像中的對象視角加入一句話。
如果有飲食照片描述，自然地帶入食物細節。
絕對不要空白回覆，一定要有內容。''';
    try {
      final response = await _gen([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) return text;
    } catch (_) {}
    return '今天是充實的一天。不管結果如何，能記錄下來就是進步的開始。明天的$nickname，會比今天更好。';
  }

  Future<String> describeFoodPhoto(Uint8List imageBytes) async {
    const prompt = '請用一句話（20字以內）描述這張照片中的食物，包含食物名稱和大致份量。';
    try {
      final response = await _visionModel.generateContent([
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(prompt),
        ]),
      ]);
      return response.text?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  // ── Diary Auto-completion ────────────────────────────────────

  Future<String> completeDiary(String partialContent, String nickname) async {
    final prompt = '''你是一個溫柔的日記AI助手。
使用者「$nickname」寫了以下日記草稿，請幫忙優雅地補全，保留原有語氣和事實，約50-100字：

草稿：$partialContent

補全內容（直接續寫，不要重複草稿）：''';
    final response = await _chatGen([Content.text(prompt)]);
    return response.text ?? '';
  }

  // ── Todo Extraction ──────────────────────────────────────────

  Future<List<String>> extractTodos(String diaryContent) async {
    final prompt = '''從以下日記中提取可能的待辦事項（用繁體中文列出，每行一個，最多5個）：

$diaryContent

待辦事項（僅列出清單，不要其他文字）：''';
    final response = await _gen([Content.text(prompt)]);
    final text = response.text ?? '';
    return text.split('\n').where((l) => l.trim().isNotEmpty).take(5).toList();
  }

  // ── Bonus Challenges ─────────────────────────────────────────

  Future<List<Map<String, String>>> generateBonusChallenges({
    required String nickname,
    required String goal,
    required String? diaryContent,
    required List<String> goalCategories,
    required String relationship,
  }) async {
    final goalStr = goalCategories.isNotEmpty ? goalCategories.join('、') : '一般健康目標';
    final prompt = '''你是時光機APP的AI教練，要為使用者「$nickname」生成今天的3個Bonus小挑戰。

使用者目標：$goal
目標類別：$goalStr
與角色關係：$relationship
今日日記：${diaryContent?.isNotEmpty == true ? diaryContent : '（未填寫）'}

請生成3個小挑戰，分別對應3種類型：
1. physical（身體運動類）
2. dietary（飲食健康類）
3. emotional（情緒社交類）

要求：
- 每個挑戰要具體可執行，今天就能完成
- 難度適中，不要太難讓人放棄，也不要太簡單
- 用正向鼓勵的語氣
- 每個挑戰15字以內

輸出JSON格式：
[
  {"type":"physical","title":"挑戰內容"},
  {"type":"dietary","title":"挑戰內容"},
  {"type":"emotional","title":"挑戰內容"}
]

只輸出JSON陣列，不要其他文字。''';
    try {
      final res = await _gen([Content.text(prompt)]);
      final text = (res.text ?? '').replaceAll('```json', '').replaceAll('```', '').trim();
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start < 0 || end < 0) return _fallbackChallenges();
      final list = jsonDecode(text.substring(start, end + 1)) as List;
      return list.map((e) => {
        'type': (e['type'] as String?) ?? 'physical',
        'title': (e['title'] as String?) ?? '完成一個小目標',
      }).toList();
    } catch (_) {
      return _fallbackChallenges();
    }
  }

  List<Map<String, String>> _fallbackChallenges() => [
    {'type': 'physical', 'title': '起身走動10分鐘'},
    {'type': 'dietary', 'title': '今天多喝一杯水'},
    {'type': 'emotional', 'title': '傳一則暖心訊息給朋友'},
  ];

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
    final response = await _gen([Content.text(prompt)]);
    return response.text ?? '繼續加油！';
  }

  static const _timeout = Duration(seconds: 30);
  static const _chatTimeout = Duration(seconds: 120);

  Future<GenerateContentResponse> _gen(List<Content> content) =>
      _textModel.generateContent(content).timeout(_timeout);

  Future<GenerateContentResponse> _chatGen(List<Content> content) =>
      _textModel.generateContent(content).timeout(_chatTimeout);

  // ── Character Chat (no fallback — throws on failure) ─────────

  Future<String> chatWithCharacter({
    required String characterName,
    required String relationship,
    required bool isMirror,
    required String gender,
    required List<Map<String, String>> history,
    required String userMessage,
    required Map<String, dynamic> todayData,
    String? memorySummary,
  }) async {
    final isGirl = gender == '她' || gender == '女';
    final roleHint = isMirror
        ? '你是個${isGirl ? '女生' : '男生'}，正在和對方聊天，對他有好感但不急著表白。'
        : '你是使用者的AI夥伴，像個有趣的朋友一起聊天。';

    final relHint = {
          '陌生人': '剛認識，保持適當距離，偶爾好奇',
          '朋友': '熟悉的朋友，可以開玩笑，輕鬆',
          '曖昧': '互有好感，說話帶點曖昧，偶爾心跳',
          '親密': '非常親近，懂對方的心，很有默契',
        }[relationship] ??
        '正常朋友';

    // History: include all messages; compress old ones if >50
    String histStr = '';
    if (memorySummary != null && memorySummary.isNotEmpty) {
      histStr = '【過去的對話記憶摘要】\n$memorySummary\n\n';
    }
    final recent = history.length > 50 ? history.sublist(history.length - 50) : history;
    if (recent.isNotEmpty) {
      histStr += '【近期對話】\n${recent.map((h) => '${h['role'] == 'user' ? '他' : characterName}：${h['content']}').join('\n')}\n\n';
    }

    final cal = (todayData['calories'] as num?)?.round() ?? 0;
    final pts = todayData['goalPoints'] ?? 0;
    final diary = todayData['diary'] as String? ?? '';
    final contextHint = cal > 0
        ? '（背景：他今天吃了 $cal kcal，積分 $pts 點${diary.isNotEmpty ? '，日記：「${diary.length > 50 ? diary.substring(0, 50) + '…' : diary}」' : ''}。有機會自然帶入，但不要每次都說。）'
        : '';

    final prompt = '''你叫$characterName。$roleHint 關係：$relHint。$contextHint

$histStr他說：「$userMessage」

你（$characterName）的回應——
要求：
- 直接針對「他說」的內容回應，不要忽略他說的話
- 口語化繁體中文，不超過80字
- 禁止用「嗯」「好的」「原來如此」「我在聽」「辛苦了」開頭
- 有自己的個性，像真實的人在聊天
- 如果他問你問題，就認真回答那個問題
- 可以參考過去對話記憶來回應，展示你記得他說過的事
$characterName：''';

    final response = await _chatGen([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) throw Exception('Empty response from Gemini');
    return text;
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
    final response = await _gen([Content.text(prompt)]);
    return response.text ?? '你今天很棒，繼續保持！';
  }

  // ── Goal AI Suggestions ───────────────────────────────────────

  Future<List<String>> suggestGoalSubCategories(String category) async {
    final prompt = '''使用者想設定「$category」類別的目標。
請列出6-8個常見的子類別選項（簡短，2-6字），例如：
- 運動 → 跑步、重訓、游泳、球類、瑜伽、騎腳踏車
只輸出清單，每行一個，不要編號或其他文字。''';
    try {
      final res = await _gen([Content.text(prompt)]);
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
      '運動': ['跑步', '重訓', '游泳', '球類', '瑜伽', '騎腳踏車', '拳擊', '爬山'],
      '飲食': ['蔬果攝取', '蛋白質補充', '減糖', '少油烹調', '多喝水', '吃早餐', '減少外食', '均衡飲食'],
      '睡眠': ['早睡早起', '睡眠品質', '規律作息', '戒睡前手機', '午休'],
      '學習': ['閱讀', '語言學習', '專業課程', '技能練習', '筆記整理', '線上課程'],
      '心理': ['冥想', '感恩練習', '情緒日記', '社交活動', '正念練習', '寫日記'],
      '工作': ['每日任務規劃', '專注時段', '文件整理', '技能升級', '溝通管理', '會議效率'],
      '創作': ['繪畫', '寫作', '音樂練習', '攝影', '手工藝', '設計', '拍影片', '寫歌'],
      '生活': ['整理家務', '理財記帳', '旅行計畫', '學烹飪', '環保習慣', '興趣培養'],
      '烹飪': ['中式料理', '日式料理', '烘焙甜點', '健康輕食', '備餐規劃', '刀工練習'],
      '財務': ['每日記帳', '存款目標', '投資學習', '節省開支', '副業計畫'],
      '社交': ['聯繫舊友', '參加活動', '拓展人脈', '家人互動'],
      '健康': ['定期檢查', '補充維生素', '健走', '戒菸戒酒', '保持水分'],
      '語言': ['英文口說', '日文學習', '詞彙練習', '聽力訓練', '閱讀外文'],
      '閱讀': ['每日讀書', '閱讀筆記', '書評撰寫', '書單規劃'],
    };
    for (final key in defaults.keys) {
      if (category.contains(key)) return defaults[key]!;
    }
    return ['每日練習', '技能提升', '習慣培養', '成效記錄', '目標設定'];
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
      final res = await _gen([Content.text(prompt)]);
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
      final response = await _gen([Content.text(prompt)]);
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

  Future<Map<String, String>?> generateKnowledgeQuestion(String category) async {
    final result = await generateKnowledgeQuestionParsed(category);
    if (result == null) return null;
    return {'raw': result.toString()};
  }
}
