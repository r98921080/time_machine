import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _revealed = false;
  int _score = 0;
  bool _generatingFallback = false;

  List<Map<String, dynamic>> _questions = [];
  List<String> _options = [];

  static const _categories = [
    '自然科學', '歷史冷知識', '人體秘密', '食物真相', '動物奇聞',
    '太空宇宙', '心理學', '數學趣味', '古文明', '科技發明',
    '藝術音樂', '地理文化', '語言文字', '運動趣聞', '台灣文化',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initQuestions());
  }

  void _initQuestions() {
    final provider = context.read<AppProvider>();
    final cached = provider.cachedKnowledge;
    if (cached.isNotEmpty) {
      setState(() {
        _questions = List<Map<String, dynamic>>.from(cached);
        _currentIndex = 0;
        _setupCurrentQuestion();
      });
    } else {
      _generateFallback();
    }
  }

  void _setupCurrentQuestion() {
    if (_questions.isEmpty) return;
    final q = _questions[_currentIndex];
    final correct = q['correct'] as String? ?? '';
    final wrong1 = q['wrong1'] as String? ?? '';
    final wrong2 = q['wrong2'] as String? ?? '';
    final wrong3 = q['wrong3'] as String? ?? '';
    final opts = [correct, wrong1, wrong2, if (wrong3.isNotEmpty) wrong3]
      ..shuffle();
    setState(() {
      _options = opts;
      _selectedIndex = null;
      _revealed = false;
    });
  }

  Future<void> _generateFallback() async {
    setState(() => _generatingFallback = true);
    final provider = context.read<AppProvider>();
    final category = _categories[DateTime.now().millisecond % _categories.length];
    try {
      final q = await provider.generateKnowledgeQuestionParsed(category);
      if (q != null && q['question'] != null && mounted) {
        setState(() {
          _questions = [q];
          _currentIndex = 0;
          _generatingFallback = false;
          _setupCurrentQuestion();
        });
        return;
      }
    } catch (_) {}
    // Hard fallback — 10 questions
    setState(() {
      _questions = [
        {
          'question': '章魚有幾顆心臟？',
          'correct': '3顆',
          'wrong1': '1顆',
          'wrong2': '2顆',
          'wrong3': '4顆',
          'explanation': '章魚有3顆心臟：1顆主心臟，另外2顆鰓心臟負責將血液送往鰓部進行氣體交換。',
          'category': '動物奇聞',
        },
        {
          'question': '人類一生中平均走多少步？',
          'correct': '約1億步',
          'wrong1': '約1千萬步',
          'wrong2': '約5億步',
          'wrong3': '約5千萬步',
          'explanation': '一般人每天約走8000步，以80年計算，一生大約走1億步以上。',
          'category': '人體秘密',
        },
        {
          'question': '世界上最重的動物是什麼？',
          'correct': '藍鯨',
          'wrong1': '非洲象',
          'wrong2': '長頸鹿',
          'wrong3': '河馬',
          'explanation': '藍鯨是地球上有史以來最重的動物，體重可達200噸，相當於33頭非洲象。',
          'category': '動物奇聞',
        },
        {
          'question': '人體內大約有多少個細胞？',
          'correct': '37兆個',
          'wrong1': '1兆個',
          'wrong2': '100億個',
          'wrong3': '10兆個',
          'explanation': '科學家估計人體約有37.2兆個細胞，這個數字比地球總人口多幾千倍。',
          'category': '人體秘密',
        },
        {
          'question': '閃電的溫度約是太陽表面的幾倍？',
          'correct': '約5倍',
          'wrong1': '等溫',
          'wrong2': '約0.5倍',
          'wrong3': '約10倍',
          'explanation': '閃電表面溫度約30,000K，是太陽表面（約6,000K）的5倍。',
          'category': '自然科學',
        },
        {
          'question': '蜜蜂一生能採多少蜜？',
          'correct': '不到1茶匙',
          'wrong1': '約1公斤',
          'wrong2': '約1杯',
          'wrong3': '約500毫升',
          'explanation': '一隻工蜂一生（約6週）只能採集約1/12茶匙的蜂蜜，是牠們辛勤工作的見證。',
          'category': '動物奇聞',
        },
        {
          'question': '宇宙中最常見的元素是什麼？',
          'correct': '氫',
          'wrong1': '氦',
          'wrong2': '氧',
          'wrong3': '碳',
          'explanation': '氫是宇宙中含量最豐富的元素，約占宇宙質量的75%，是恆星和太陽的主要成分。',
          'category': '太空宇宙',
        },
        {
          'question': '哪個國家發明了披薩？',
          'correct': '義大利',
          'wrong1': '美國',
          'wrong2': '希臘',
          'wrong3': '法國',
          'explanation': '現代披薩起源於18世紀末的義大利那不勒斯，最初是窮人的食物，後來風靡全球。',
          'category': '食物真相',
        },
        {
          'question': '人類有幾塊骨頭？（成人）',
          'correct': '206塊',
          'wrong1': '300塊',
          'wrong2': '180塊',
          'wrong3': '250塊',
          'explanation': '嬰兒出生時有約300塊骨頭，隨著成長逐漸融合，成人最終有206塊骨頭。',
          'category': '人體秘密',
        },
        {
          'question': '世界上最高的山（從地心算起）是哪座？',
          'correct': '欽博拉索山',
          'wrong1': '聖母峰（珠峰）',
          'wrong2': '乞力馬扎羅山',
          'wrong3': '麥金利山',
          'explanation': '由於地球赤道隆起，位於厄瓜多爾的欽博拉索山頂離地心最遠，比珠峰更「高」。',
          'category': '地理文化',
        },
      ];
      _currentIndex = 0;
      _generatingFallback = false;
      _setupCurrentQuestion();
    });
  }

  void _reveal() {
    if (_selectedIndex == null) return;
    setState(() => _revealed = true);
    final q = _questions[_currentIndex];
    final isCorrect = _options[_selectedIndex!] == q['correct'];
    if (isCorrect) {
      setState(() => _score++);
      final provider = context.read<AppProvider>();
      final profile = provider.profile;
      if (profile != null) {
        provider.updateProfile(profile.copyWith(
            growthPoints: (profile.growthPoints + 20).clamp(0, 999999)));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 答對了！獲得 20 成長點數'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      _setupCurrentQuestion();
    } else {
      // Wrapped around — show completion
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎓 今日題目完成！'),
        content: Text('你答對了 $_score / ${_questions.length} 題\n'
            '共獲得 ${_score * 20} 成長點數！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Restart from first question
              setState(() {
                _currentIndex = 0;
                _score = 0;
              });
              _setupCurrentQuestion();
            },
            child: const Text('再玩一次'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = _generatingFallback || _questions.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日冷知識'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${_questions.isEmpty ? '?' : _questions.length}  ✨$_score',
                style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('準備今日題目中…'),
                ],
              ),
            )
          : _buildQuestion(theme),
    );
  }

  Widget _buildQuestion(ThemeData theme) {
    final q = _questions[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 16),

          // Category chip
          Center(
            child: Chip(
              label: Text(q['category'] ?? '知識'),
              avatar: const Text('🧠'),
            ),
          ),
          const SizedBox(height: 16),

          // Question card
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                q['question'] ?? '',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Options
          ..._options.asMap().entries.map((entry) {
            final i = entry.key;
            final opt = entry.value;
            final isCorrect = opt == q['correct'];
            final isSelected = _selectedIndex == i;

            Color bgColor;
            Color textColor;
            Color? borderColor;
            IconData? trailingIcon;
            Color? iconColor;

            if (_revealed) {
              if (isCorrect) {
                bgColor = Colors.green.shade700;
                textColor = Colors.white;
                trailingIcon = Icons.check_circle;
                iconColor = Colors.white;
              } else if (isSelected) {
                bgColor = Colors.red.shade700;
                textColor = Colors.white;
                trailingIcon = Icons.cancel;
                iconColor = Colors.white;
              } else {
                bgColor = theme.colorScheme.surfaceContainerHighest;
                textColor = theme.colorScheme.onSurfaceVariant;
              }
            } else if (isSelected) {
              bgColor = theme.colorScheme.primary;
              textColor = theme.colorScheme.onPrimary;
              borderColor = theme.colorScheme.primary;
            } else {
              bgColor = theme.colorScheme.surfaceContainerHighest;
              textColor = theme.colorScheme.onSurfaceVariant;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap:
                    _revealed ? null : () => setState(() => _selectedIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(opt,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor,
                                fontWeight: isSelected ||
                                        (_revealed && isCorrect)
                                    ? FontWeight.bold
                                    : null)),
                      ),
                      if (trailingIcon != null)
                        Icon(trailingIcon, color: iconColor, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          if (!_revealed)
            FilledButton(
              onPressed: _selectedIndex == null ? null : _reveal,
              child: const Text('揭曉答案'),
            )
          else ...[
            // Explanation
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text('解釋',
                            style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onTertiaryContainer)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q['explanation'] ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.6,
                          color: theme.colorScheme.onTertiaryContainer),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: Icon(_currentIndex < _questions.length - 1
                  ? Icons.arrow_forward
                  : Icons.check),
              label: Text(_currentIndex < _questions.length - 1
                  ? '下一題'
                  : '完成今日挑戰'),
              onPressed: _nextQuestion,
            ),
          ],
        ],
      ),
    );
  }
}
