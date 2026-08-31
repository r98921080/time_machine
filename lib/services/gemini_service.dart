import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _model = 'gemini-3.6-flash';

  final List<String> _apiKeys;
  int _keyIndex = 0;
  late GenerativeModel _textModel;
  late GenerativeModel _visionModel;

  GeminiService(String primaryKey, {List<String> fallbackKeys = const []})
      : _apiKeys = [primaryKey, ...fallbackKeys] {
    _initModels();
  }

  void _initModels() {
    _textModel = GenerativeModel(model: _model, apiKey: _apiKeys[_keyIndex]);
    _visionModel = GenerativeModel(model: _model, apiKey: _apiKeys[_keyIndex]);
  }

  bool _rotateKey() {
    if (_apiKeys.length <= 1) return false;
    _keyIndex = (_keyIndex + 1) % _apiKeys.length;
    _initModels();
    return true;
  }

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
    ]).timeout(_timeout);
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
      ]).timeout(_timeout);
      return response.text?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  // ── Diary ────────────────────────────────────────────────────

  Future<String> completeDiary(String partialContent, String nickname) async {
    final prompt = '''你是一個溫柔的日記AI助手。
使用者「$nickname」寫了以下日記草稿，請幫忙優雅地補全，保留原有語氣和事實，約50-100字：

草稿：$partialContent

補全內容（直接續寫，不要重複草稿）：''';
    final response = await _chatGen([Content.text(prompt)]);
    return response.text ?? '';
  }

  Future<String> generateDiaryTitle(String content) async {
    final prompt = '''請根據以下日記內容，生成一個極具創意、幽默或富有詩意的標題（5個字以內）。
標題應該能深刻反映當天的情緒或獨特事件，避免平庸描述。
例如：快樂採菇人、旋轉的陀螺、人生的低谷、突破的前夕

日記內容：
"${content.length > 200 ? content.substring(0, 200) : content}"

請直接回傳標題文字，不要有引號或其他符號。''';
    try {
      final response = await _gen([Content.text(prompt)]);
      return response.text?.trim() ?? '今日記錄';
    } catch (_) {
      return '今日記錄';
    }
  }

  Future<List<String>> extractTodos(String diaryContent) async {
    final prompt = '''從以下日記中提取可能的待辦事項（用繁體中文列出，每行一個，最多5個）：

$diaryContent

待辦事項（僅列出清單，不要其他文字）：''';
    final response = await _gen([Content.text(prompt)]);
    final text = response.text ?? '';
    return text.split('\n').where((l) => l.trim().isNotEmpty).take(5).toList();
  }

  // ── Deep Life Analysis (5 dimensions) ────────────────────────

  Future<Map<String, String>> performDeepLifeAnalysis({
    required List<String> categories,
    required List<Map<String, dynamic>> recentLogs,
    required String? diaryContent,
    required int? moodScore,
    required int? energyScore,
    required String nickname,
  }) async {
    final prompt = '''你是一位全方位的生命教練與心理學家，深刻理解人性。
請根據使用者「$nickname」的所有數據，進行深度的生活狀態分析。

數據：
- 目標類別：${categories.join('、')}
- 最近目標達成紀錄：${recentLogs.length}筆
- 今日日記摘要：${diaryContent?.isNotEmpty == true ? '"${diaryContent!.substring(0, diaryContent.length.clamp(0, 150))}"' : '（未填寫）'}
- 今日情緒評分：${moodScore != null ? '$moodScore/5分' : '（未記錄）'}
- 今日精力評分：${energyScore != null ? '$energyScore/10分' : '（未記錄）'}

請深度分析以下五個維度（每個維度2-4句，直接說重點，避免廢話）：

1. 情緒心理：目前的情緒狀態、潛在壓力或動力來源
2. 生活平衡：工作、休閒、健康的平衡狀況
3. 個人建議：3個具體可執行的行動建議
4. 目標洞見：目前目標是否需要微調？有哪些值得關注的模式？
5. 成長亮點：這個人身上讓你印象深刻的優點或潛力

輸出JSON格式：
{
  "emotions": "情緒心理分析",
  "balance": "生活平衡分析",
  "advice": "個人建議",
  "goalInsight": "目標洞見",
  "growth": "成長亮點"
}

只輸出JSON，語氣像朋友在對話，不要太正式。''';
    try {
      final res = await _chatGen([Content.text(prompt)]);
      final text = (res.text ?? '').replaceAll('```json', '').replaceAll('```', '').trim();
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start < 0 || end < 0) return _fallbackAnalysis();
      final decoded = jsonDecode(text.substring(start, end + 1)) as Map;
      return {
        'emotions': decoded['emotions'] as String? ?? '',
        'balance': decoded['balance'] as String? ?? '',
        'advice': decoded['advice'] as String? ?? '',
        'goalInsight': decoded['goalInsight'] as String? ?? '',
        'growth': decoded['growth'] as String? ?? '',
      };
    } catch (_) {
      return _fallbackAnalysis();
    }
  }

  Map<String, String> _fallbackAnalysis() => {
    'emotions': '你今天似乎有在努力，情緒狀態值得持續觀察。',
    'balance': '記得在高強度的努力之餘，給自己留些空間休息。',
    'advice': '1. 今天完成最重要的一件事 2. 喝足夠的水 3. 睡前花5分鐘回顧今天',
    'goalInsight': '繼續保持記錄的習慣，數據累積後會有更清晰的洞見。',
    'growth': '你願意用APP追蹤自己，這本身就是自我成長意識的展現。',
  };

  // ── Mood Correlation ─────────────────────────────────────────

  Future<String> generateMoodCorrelation({
    required List<Map<String, dynamic>> weekMoods,
    required List<Map<String, dynamic>> weekGoals,
  }) async {
    final prompt = '''根據以下一週的情緒和目標數據，分析兩者之間的相關性，用一段話說明（50字以內）：

情緒數據（日期:評分）：${weekMoods.map((m) => '${m['date']}:${m['score']}').join(', ')}
目標達成數據（日期:點數）：${weekGoals.map((g) => '${g['date']}:${g['points']}').join(', ')}

請輸出一句洞見，例如：「完成目標的那天，你的情緒評分平均高出 X 分」''';
    try {
      final res = await _gen([Content.text(prompt)]);
      return res.text?.trim() ?? '數據積累中，洞見即將浮現。';
    } catch (_) {
      return '持續記錄，讓AI找出你的最佳狀態規律。';
    }
  }

  // ── Proactive Character Message ───────────────────────────────

  Future<String> generateCharacterProactiveMessage({
    required String characterName,
    required String relationship,
    required String nickname,
    required double caloriesRatio,
    required int goalPoints,
    required int loginStreak,
    required String? diaryContent,
    required String gender,
    required String? styleHint,
  }) async {
    String trigger;
    if (loginStreak >= 7) {
      trigger = '連續登入第$loginStreak天，使用者非常有毅力';
    } else if (caloriesRatio < 0.5) {
      trigger = '今天進食量偏少（只達到目標${(caloriesRatio * 100).round()}%），有點擔心';
    } else if (caloriesRatio > 1.2) {
      trigger = '今天吃超過目標${(caloriesRatio * 100).round()}%，想溫柔提醒一下';
    } else if (goalPoints >= 5) {
      trigger = '今天目標達成了$goalPoints點，想給予鼓勵';
    } else {
      trigger = '今天比較平淡，想說點什麼讓使用者感受到關心';
    }

    final prompt = '''你是「$characterName」，與「$nickname」的關係是「$relationship」。
${styleHint?.isNotEmpty == true ? '說話風格：$styleHint' : ''}
觸發原因：$trigger
${diaryContent?.isNotEmpty == true ? '日記摘要：「${diaryContent!.substring(0, diaryContent.length.clamp(0, 80))}」' : ''}

請自然地主動傳一則訊息給使用者（25-50字），不要開頭說「嗯」「好的」「我來」。
要符合關係親密度（$relationship），感覺像真實的人在傳訊息，不是機器人通知。''';
    try {
      final res = await _chatGen([Content.text(prompt)]);
      return res.text?.trim() ?? '嘿，今天過得怎麼樣？';
    } catch (_) {
      return '嘿，記得照顧好自己喔 ✨';
    }
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
    final prompt = '''你是時光機APP的AI教練，為使用者「$nickname」生成今天的3個Bonus小挑戰。

使用者目標：$goal（類別：$goalStr）
今日日記：${diaryContent?.isNotEmpty == true ? diaryContent!.substring(0, diaryContent!.length.clamp(0, 80)) : '未填寫'}

請生成3個小挑戰，分別對應3種類型：
1. physical（身體類）
2. dietary（飲食類）
3. emotional（情緒社交類）

⚠️ 嚴格要求：
- 每個挑戰必須能在「今天內」用「10-30分鐘」完成，不能是長期目標
- 要非常具體，有明確動作和數量（例：喝300ml水、走1000步）
- 不要說「今天開始」「每天」「持續」等暗示多天的詞
- 語氣積極、15字以內

JSON格式輸出：
[
  {"type":"physical","title":"挑戰內容"},
  {"type":"dietary","title":"挑戰內容"},
  {"type":"emotional","title":"挑戰內容"}
]
只輸出JSON陣列。''';
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

  // ── Goal AI ───────────────────────────────────────────────────

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
    };
    for (final key in defaults.keys) {
      if (category.contains(key)) return defaults[key]!;
    }
    return ['每日練習', '技能提升', '習慣培養', '成效記錄', '目標設定'];
  }

  Future<Map<String, List<String>>?> generateGoalTargets(
      String category, String subCategory) async {
    final prompt = '''為「$category - $subCategory」生成三個難度層次的「當日打卡標準」。

這是每天打卡用的：使用者「今天」做到就能打卡，明天重新計算。絕對不是累積型或長期型。
三個難度是「同一件事」的輕量／中等／高強度版本，用最適合這件事的量化單位（時間、次數、頁數、份量、距離…）來分級，**不一定要用時間**。

✅ 正確範例：
- 閱讀 → mini:借一本書 ／ advanced:今天讀10頁 ／ elite:今天讀完一本書
- 肌力訓練 → mini:走1000步 ／ advanced:慢跑30分鐘 ／ elite:波比跳100下
- 跑步 → mini:步行3000步 ／ advanced:跑3公里 ／ elite:跑8公里
- 喝水 → mini:今天喝1000ml ／ advanced:今天喝2000ml ／ elite:今天喝3000ml

❌ 錯誤（絕對不能出現任何一個字）：
- 「連續30天」「本週三次」「每天堅持」「三個月達到」「持續」等任何跨日或累積字眼

規則：
- mini = 今天最低門檻（再忙也做得到）
- advanced = 今天正常目標
- elite = 今天全力以赴
- 每個都要有具體數字、動詞開頭、描述「今天做什麼」
- 用這件事最自然的單位分級，別硬套時間

JSON格式：
{
  "mini": ["今天做X（有數字）"],
  "advanced": ["今天做X（有數字）"],
  "elite": ["今天做X（有數字）"]
}
只輸出JSON。''';
    try {
      final res = await _gen([Content.text(prompt)]);
      final text = (res.text ?? '{}').replaceAll('```json', '').replaceAll('```', '').trim();
      return _parseGoalTargets(text);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> generateGoalRebuildOptions({
    required String category,
    required String subCategory,
    required String subItemName,
    required String subItemMini,
    required String subItemAdvanced,
    required String subItemElite,
    required String? diaryContent,
    required double achievementRate,
  }) async {
    final rateStr = '${(achievementRate * 100).round()}%';
    final diaryHint = diaryContent?.isNotEmpty == true
        ? '最近日記：「${diaryContent!.substring(0, diaryContent.length.clamp(0, 100))}」'
        : '';
    final prompt = '''使用者在「$category」下有一個具體目標「$subItemName」。
現有目標設定：
- 入門：$subItemMini
- 進階：$subItemAdvanced
- 精英：$subItemElite

歷史達成率：$rateStr
$diaryHint

請以這個目標「$subItemName」為基礎，生成 3 個修改方案，每個方案都要給出新的 mini/advanced/elite。

⚠️ 所有 mini/advanced/elite 都是「今天做一次就能打卡」的當日標準，明天重新計算。
❌ 不能寫「連續X天」「本週X次」「每天堅持」「持續X個月」等任何跨日/累積字眼。
✅ 要寫「今天做X分鐘」「今天完成X次」「今天讀X頁」「走X步」等單次可完成的描述。

三個方案固定為（順序不可變）：
1. 降階版：覺得現在太難時用，把三個難度都往下調一階，讓忙碌或低潮時也做得到（仍要有意義、有數字）。
2. 升階版：已經游刃有餘時用，把三個難度都往上調一階，帶來新挑戰。
3. 改變方向版：保留同一個大目標的精神，但換一種「做法或活動」來達成（例：跑步→改游泳或騎車；讀紙本→改聽有聲書；重訓→改徒手核心），給人新鮮感。

JSON格式：
[
  {"name":"降階版","description":"方案核心精神（20字以內）","mini":"今天做X（有數字）","advanced":"今天做X（有數字）","elite":"今天做X（有數字）"},
  {"name":"升階版","description":"方案核心精神（20字以內）","mini":"今天做X（有數字）","advanced":"今天做X（有數字）","elite":"今天做X（有數字）"},
  {"name":"改變方向版","description":"方案核心精神（20字以內）","mini":"今天做X（有數字）","advanced":"今天做X（有數字）","elite":"今天做X（有數字）"}
]
只輸出JSON陣列。''';
    try {
      final res = await _gen([Content.text(prompt)]);
      final text = (res.text ?? '').replaceAll('```json', '').replaceAll('```', '').trim();
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start < 0 || end < 0) return _fallbackRebuildOptions(subItemName);
      final list = jsonDecode(text.substring(start, end + 1)) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return _fallbackRebuildOptions(subItemName);
    }
  }

  List<Map<String, dynamic>> _fallbackRebuildOptions(String sub) => [
    {'name': '降階版', 'description': '門檻放低，忙碌時也打得到卡', 'mini': '今天花5分鐘做$sub', 'advanced': '今天花15分鐘做$sub', 'elite': '今天花30分鐘做$sub'},
    {'name': '升階版', 'description': '加點強度，突破舒適圈', 'mini': '今天花20分鐘做$sub', 'advanced': '今天花40分鐘做$sub', 'elite': '今天全力做$sub 60分鐘'},
    {'name': '改變方向版', 'description': '換個做法保持新鮮感', 'mini': '今天用新方式接觸$sub 10分鐘', 'advanced': '今天試$sub的變化版30分鐘', 'elite': '今天挑戰$sub的高難度版60分鐘'},
  ];

  Future<String> generateWeeklyReport({
    required String nickname,
    required List<Map<String, dynamic>> weeklyData,
    required int goalCompletions,
    required int bonusDone,
    required String? diaryContent,
  }) async {
    final avgCal = weeklyData.isEmpty ? 0 : weeklyData.fold<double>(0, (s, d) => s + (d['calories'] as double? ?? 0)) / weeklyData.length;
    final prompt = '''請為使用者「$nickname」生成本週健康報告（繁體中文）。

本週數據：
- 平均每日熱量：${avgCal.round()} kcal
- 目標達成次數：$goalCompletions 次
- Bonus 挑戰完成：$bonusDone 個
- 日記摘要：${diaryContent?.isNotEmpty == true ? diaryContent!.substring(0, diaryContent!.length.clamp(0, 100)) : '未填寫'}

請以溫柔朋友的語氣，分三段：
1. ✨ 這週做得好的地方（1-2點）
2. 💪 可以加強的地方（1-2點，正向建議語氣）
3. 🎯 下週建議重點（1-2點具體行動）

約200字，真誠有溫度。''';
    try {
      final res = await _gen([Content.text(prompt)]);
      return res.text?.trim() ?? '這週你很努力了！繼續保持。';
    } catch (_) {
      return '這週你很努力了！繼續保持。';
    }
  }

  Future<String> generateMonthlyReport({
    required String nickname,
    required int totalDays,
    required int activeDays,
    required double avgCalories,
    required double targetCalories,
    required int totalGoalPoints,
    required int growthPoints,
  }) async {
    final prompt = '''請為使用者「$nickname」生成本月健康回顧（繁體中文）。

本月數據：
- 記錄天數：$activeDays / $totalDays 天
- 平均每日熱量：${avgCalories.round()} / ${targetCalories.round()} kcal
- 目標總點數：$totalGoalPoints 點
- 成長點數：$growthPoints 點

請生成一份有溫度的月度報告，包含：
1. 🌟 本月最大亮點
2. 📈 進步趨勢分析
3. 🔮 下個月的可能性
約250字，像朋友寫給你的信。''';
    try {
      final res = await _gen([Content.text(prompt)]);
      return res.text?.trim() ?? '本月你很棒！期待下個月的你。';
    } catch (_) {
      return '本月你很棒！期待下個月的你。';
    }
  }

  // ── Character Chat ────────────────────────────────────────────

  Future<String> chatWithCharacter({
    required String characterName,
    required String relationship,
    required bool isMirror,
    required String gender,
    required List<Map<String, String>> history,
    required String userMessage,
    required Map<String, dynamic> todayData,
    String? memorySummary,
    String? styleHint,
  }) async {
    final isGirl = gender == '她' || gender == '女';
    final roleHint = isMirror
        ? '你是個${isGirl ? '女生' : '男生'}，正在和對方聊天，對他有好感但不急著表白。'
        : '你是使用者的AI夥伴，像個有趣的朋友一起聊天。';

    final relHint = {
          '陌生人': '剛認識，保持適當距離，偶爾好奇',
          '普通朋友': '熟悉的朋友，可以開玩笑，輕鬆',
          '熟悉': '相當熟悉了，說話自然流暢',
          '好友': '很好的朋友，說話毫不拘束',
          '曖昧': '互有好感，說話帶點曖昧，偶爾心跳',
          '親密': '非常親近，懂對方的心，很有默契',
        }[relationship] ??
        '普通朋友';

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

    final stylePrefix = styleHint?.isNotEmpty == true ? '說話風格提示：$styleHint\n' : '';

    final prompt = '''你叫$characterName。$roleHint 關係：$relHint。$contextHint
$stylePrefix
$histStr他說：「$userMessage」

你（$characterName）的回應——
要求：
- 直接針對「他說」的內容回應，不要忽略他說的話
- 口語化繁體中文，不超過80字
- 禁止用「嗯」「好的」「原來如此」「我在聽」「辛苦了」開頭
- 有自己的個性，像真實的人在聊天
- 如果他問你問題，就認真回答那個問題
- 可以參考過去對話記憶來回應
$characterName：''';

    final response = await _chatGen([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) throw Exception('Empty response from Gemini');
    return text;
  }

  Future<String> getMirrorResponse({
    required String gender,
    required double performanceRatio,
    required String diaryContent,
  }) async {
    final level = performanceRatio >= 0.9 ? '非常棒' : performanceRatio >= 0.7 ? '不錯' : '需要加油';
    final perspective = gender == '女' || gender == '她' ? '她' : '他';
    final prompt = '''你是一個溫柔的角色，站在使用者想像中的${perspective}的角度，
對使用者今天的表現（$level）說一句話。
語氣要自然、有情感，像是真實的人在說話。20-40字即可。
今天的日記：${diaryContent.isEmpty ? '（沒有寫日記）' : diaryContent}''';
    final response = await _gen([Content.text(prompt)]);
    return response.text ?? '你今天很棒，繼續保持！';
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
      if (parsed != null && parsed['question'] != null && parsed['correct'] != null) {
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

  // ── Journal Analysis ──────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeJournal(String diaryContent) async {
    final prompt = '''你是一位貼心的個人助理。請閱讀以下日記內容，提取出：
1. 可能需要安排的行程或約定（含主題、日期時間推測、地點、備註）
2. 可能需要完成的待辦事項

日記內容：
"$diaryContent"

請以 JSON 格式回傳（今日日期視為記錄當天，時間格式 HH:mm）：
{
  "events": [
    {"title":"行程主題","date":"推測日期如明天/後天等用自然語言","time":"推測時間或空字串","location":"地點或空字串","note":"備註"}
  ],
  "todos": ["待辦1","待辦2"]
}
若無行程或待辦，對應陣列回傳空陣列。只輸出 JSON。''';
    try {
      final res = await _gen([Content.text(prompt)]);
      final text = (res.text ?? '').replaceAll('```json', '').replaceAll('```', '').trim();
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start < 0 || end < 0) return {'events': [], 'todos': []};
      final decoded = jsonDecode(text.substring(start, end + 1)) as Map;
      return {
        'events': (decoded['events'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        'todos': List<String>.from(decoded['todos'] as List? ?? []),
      };
    } catch (_) {
      return {'events': [], 'todos': []};
    }
  }

  // ── Mind Map ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> generateMindMap({
    required String diaryContent,
    required String nickname,
    required List<String> goalCategories,
    required int goalPoints,
  }) async {
    final prompt = '''你是一位心理分析師與成長教練。請根據「$nickname」今日的資料，生成今日心智圖。

資料：
- 目標類別：${goalCategories.join('、')}
- 今日目標積分：$goalPoints 點
- 日記內容：${diaryContent.isNotEmpty ? '"${diaryContent.length > 300 ? diaryContent.substring(0, 300) : diaryContent}"' : '（未填寫）'}

請生成心智圖結構，包含：
- 中心主題（今日的一句話概括，10字以內）
- 3-5 個主要分支（每個分支有 1-3 個子節點）

JSON 格式：
{
  "center": "今日中心主題",
  "branches": [
    {"label": "分支名稱", "nodes": ["子節點1", "子節點2"]},
    {"label": "分支名稱", "nodes": ["子節點1"]}
  ]
}
只輸出 JSON。''';
    try {
      final res = await _gen([Content.text(prompt)]);
      final text = (res.text ?? '').replaceAll('```json', '').replaceAll('```', '').trim();
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start < 0 || end < 0) return _fallbackMindMap(nickname);
      final decoded = jsonDecode(text.substring(start, end + 1)) as Map;
      return {
        'center': decoded['center'] as String? ?? '今日記錄',
        'branches': (decoded['branches'] as List? ?? [])
            .map((b) => {
                  'label': (b as Map)['label'] as String? ?? '',
                  'nodes': List<String>.from(b['nodes'] as List? ?? []),
                })
            .toList(),
      };
    } catch (_) {
      return _fallbackMindMap(nickname);
    }
  }

  Map<String, dynamic> _fallbackMindMap(String nickname) => {
    'center': '今天也努力了',
    'branches': [
      {'label': '健康', 'nodes': ['飲食記錄', '運動習慣']},
      {'label': '目標', 'nodes': ['持續追蹤']},
      {'label': '心情', 'nodes': ['值得被記錄']},
    ],
  };

  // ── Todo Prioritization ───────────────────────────────────────

  Future<List<String>> prioritizeTodos(List<Map<String, dynamic>> todos) async {
    if (todos.isEmpty) return [];
    final list = todos.map((t) => '- [${t['id']}] ${t['content']}').join('\n');
    final prompt = '''你是一位高效能專家。請根據以下待辦事項，從重要性與緊迫性評估，回傳排序後的 ID 清單（最優先的在前）。

待辦事項：
$list

只輸出 JSON 陣列，例如 ["id1","id2","id3"]，不要其他文字。''';
    try {
      final res = await _gen([Content.text(prompt)]);
      final text = (res.text ?? '').replaceAll('```json', '').replaceAll('```', '').trim();
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start < 0 || end < 0) return todos.map((t) => t['id'] as String).toList();
      final list2 = jsonDecode(text.substring(start, end + 1)) as List;
      return list2.map((e) => e as String).toList();
    } catch (_) {
      return todos.map((t) => t['id'] as String).toList();
    }
  }

  // ── Daily Knowledge Challenge ─────────────────────────────────

  static const _knowledgeCategories = [
    '自然科學', '歷史冷知識', '人體秘密', '食物真相', '動物奇聞',
    '太空宇宙', '心理學', '數學趣味', '古文明', '科技發明',
    '藝術音樂', '地理文化', '語言文字', '運動趣聞', '台灣文化',
  ];

  static List<String> getDailyCategories(String dateStr) {
    var hash = 5381;
    for (final c in dateStr.codeUnits) {
      hash = ((hash << 5) + hash + c) & 0x7FFFFFFF;
    }
    final shuffled = List<String>.from(_knowledgeCategories);
    for (var i = shuffled.length - 1; i > 0; i--) {
      hash = ((hash << 5) + hash + i) & 0x7FFFFFFF;
      final j = hash % (i + 1);
      final tmp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = tmp;
    }
    return shuffled.take(5).toList();
  }

  Future<List<Map<String, dynamic>>> generateDailyKnowledge({
    required String dateStr,
    required List<String> categories,
    List<String> avoidTopics = const [],
  }) async {
    final avoidHint = avoidTopics.isNotEmpty
        ? '\n請避開以下近期已出現的主題關鍵字：${avoidTopics.take(30).join('、')}'
        : '';
    final prompt = '''今天是 $dateStr，請生成「每日瞎掰王知識挑戰」共 5 道題目，各題對應以下類別：
${categories.asMap().entries.map((e) => '第${e.key + 1}題：${e.value}').join('\n')}
$avoidHint

每道題格式：
- 題目：有趣、讓人想猜的問句
- 正確答案：真實有趣的事實（10字以內）
- 假答案×3：聽起來合理但錯誤（各10字以內）
- 解析：為什麼正確答案是對的（50字以內）

輸出 JSON 陣列（嚴格照格式）：
[
  {
    "id": "q1",
    "category": "類別",
    "question": "題目",
    "correct": "正確答案",
    "wrong1": "假答案1",
    "wrong2": "假答案2",
    "wrong3": "假答案3",
    "explanation": "解析"
  }
]
只輸出 JSON 陣列，5 個元素，不要其他文字。''';
    try {
      final res = await _gen([Content.text(prompt)]);
      final text = (res.text ?? '').replaceAll('```json', '').replaceAll('```', '').trim();
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start < 0 || end < 0) return [];
      final list = jsonDecode(text.substring(start, end + 1)) as List;
      return list.asMap().entries.map((e) {
        final q = Map<String, dynamic>.from(e.value as Map);
        q['id'] = '${dateStr}_q${e.key + 1}';
        return q;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Personal Advisor Chat ────────────────────────────────────

  Future<String> chatWithAdvisor({
    required String nickname,
    required List<Map<String, String>> history,
    required String userMessage,
    required Map<String, dynamic> context,
    String? memorySummary,
  }) async {
    final buf = StringBuffer();

    final cal = (context['todayCalories'] as num?)?.round() ?? 0;
    final target = (context['targetCalories'] as num?)?.round() ?? 0;
    final pts = context['todayGoalPoints'] ?? 0;
    final diary = (context['todayDiary'] as String?) ?? '';
    buf.writeln('【今日狀態】');
    buf.writeln('- 熱量攝取：$cal / ${target > 0 ? target : '未設定'} kcal');
    buf.writeln('- 今日目標達成點數：$pts');
    if (diary.isNotEmpty) {
      final d = diary.length > 120 ? '${diary.substring(0, 120)}…' : diary;
      buf.writeln('- 今日日記：「$d」');
    }

    final week = (context['weeklyCalories'] as List?) ?? const [];
    if (week.isNotEmpty) {
      final line =
          week.map((d) => ((d['calories'] as num?) ?? 0).round()).join(', ');
      buf.writeln('- 近7日熱量：[$line] kcal');
    }

    final goals = (context['goals'] as List?) ?? const [];
    if (goals.isNotEmpty) {
      buf.writeln('【正在追蹤的目標】${goals.join('、')}');
    }

    final gc = (context['weeklyGoalCompletions'] as List?) ?? const [];
    if (gc.isNotEmpty) {
      final total =
          gc.fold<int>(0, (s, e) => s + ((e['completions'] as int?) ?? 0));
      buf.writeln('- 近7日目標達成共 $total 次（${gc.length} 天有記錄）');
    }

    final diaries = (context['recentDiaries'] as List?) ?? const [];
    if (diaries.isNotEmpty) {
      buf.writeln('【近期日記摘要】');
      for (final d in diaries) {
        final mood = d['mood'] != null ? '（心情:${d['mood']}）' : '';
        buf.writeln('- ${d['date']}$mood：${d['snippet']}');
      }
    }

    final streak = context['loginStreak'];
    if (streak is int && streak > 0) {
      buf.writeln('- 連續使用天數：$streak 天');
    }

    String histStr = '';
    if (memorySummary != null && memorySummary.isNotEmpty) {
      histStr = '【過往對話重點】\n$memorySummary\n\n';
    }
    final recent =
        history.length > 40 ? history.sublist(history.length - 40) : history;
    if (recent.isNotEmpty) {
      histStr +=
          '【近期對話】\n${recent.map((h) => '${h['role'] == 'user' ? '使用者' : '顧問'}：${h['content']}').join('\n')}\n\n';
    }

    final prompt = '''你是「$nickname」的專屬私人健康與生活顧問，一個人整合了「營養師 × 私人教練 × 習慣養成教練 × 心理支持」四種專業。

你的任務是根據使用者的真實數據（飲食熱量、目標達成、日記、作息），提供**專業、具體、可執行**的建議，並像一位值得信任的顧問一樣與他自然對談。

使用者資料：
${buf.toString()}
$histStr使用者現在說：「$userMessage」

回應原則：
- 先直接回應他說的內容或問題，不要打太極、不要複述。
- 建議要具體、可執行、有依據（份量、時間、次數、原理），避免空泛口號。
- 適時引用他的真實數據佐證（如熱量偏高、目標連續達成），但不要每次都硬塞數據。
- 若資訊不足以給到位建議，主動問一個關鍵問題再給建議。
- 專業但溫暖，繁體中文口語，像真人顧問。一般回應 150 字內；使用者要求詳細規劃時可長一些。
- 不要用「嗯」「好的」「我了解了」「辛苦了」這類空洞開頭。
- 誠實：不確定就說不確定，不編造數據；不做醫療診斷，必要時建議尋求專業醫療協助。

你的回應：''';

    final response = await _chatGen([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) throw Exception('Empty response from Gemini');
    return text;
  }

  // ── Internal ──────────────────────────────────────────────────

  static const _timeout = Duration(seconds: 120);
  static const _chatTimeout = Duration(seconds: 240);

  Future<GenerateContentResponse> _gen(List<Content> content) =>
      _genWithRotation(content, _timeout);

  Future<GenerateContentResponse> _chatGen(List<Content> content) =>
      _genWithRotation(content, _chatTimeout);

  Future<GenerateContentResponse> _genWithRotation(
      List<Content> content, Duration timeout) async {
    for (var attempt = 0; attempt < _apiKeys.length; attempt++) {
      try {
        return await _textModel.generateContent(content).timeout(timeout);
      } catch (e) {
        if (isQuotaError(e) && attempt < _apiKeys.length - 1) {
          _rotateKey();
          continue;
        }
        rethrow;
      }
    }
    throw Exception(quotaErrorMessage());
  }

  static bool isQuotaError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('429') ||
        msg.contains('quota') ||
        msg.contains('resource_exhausted') ||
        msg.contains('rate limit');
  }

  static String quotaErrorMessage() =>
      'AI 今日使用次數已達上限。請至設定輸入您自己的 Gemini API Key 以解鎖無限使用。';

  Map<String, List<String>>? _parseGoalTargets(String json) {
    try {
      final mini = RegExp(r'"mini":\s*\["([^"]+)"\]').firstMatch(json)?.group(1);
      final advanced = RegExp(r'"advanced":\s*\["([^"]+)"\]').firstMatch(json)?.group(1);
      final elite = RegExp(r'"elite":\s*\["([^"]+)"\]').firstMatch(json)?.group(1);
      if (mini != null && advanced != null && elite != null) {
        return {'mini': [mini], 'advanced': [advanced], 'elite': [elite]};
      }
    } catch (_) {}
    return null;
  }
}
