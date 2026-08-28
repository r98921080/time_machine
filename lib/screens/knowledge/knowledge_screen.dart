import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  bool _loading = true;
  Map<String, dynamic>? _question;
  List<String> _options = [];
  int? _selectedIndex;
  bool _revealed = false;
  int _score = 0;

  static const _categories = [
    '自然科學', '歷史冷知識', '人體秘密', '食物真相', '動物奇聞',
    '太空宇宙', '心理學', '數學趣味', '古文明', '科技發明',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _selectedIndex = null;
      _revealed = false;
    });
    final provider = context.read<AppProvider>();
    final rng = Random();
    final category = _categories[rng.nextInt(_categories.length)];
    try {
      final raw = await provider.generateKnowledgeQuestion(category)
          ?? {'raw': '{}'};
      final parsed = jsonDecode(raw['raw'] ?? '{}') as Map<String, dynamic>;
      if (parsed.isNotEmpty && parsed['question'] != null) {
        final correct = parsed['correct'] as String? ?? '';
        final wrong1 = parsed['wrong1'] as String? ?? '';
        final wrong2 = parsed['wrong2'] as String? ?? '';
        final wrong3 = parsed['wrong3'] as String? ?? '';
        final opts = [correct, wrong1, wrong2, if (wrong3.isNotEmpty) wrong3]..shuffle();
        setState(() {
          _question = parsed;
          _options = opts;
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() {
      _question = {
        'question': '章魚有幾顆心臟？',
        'correct': '3顆',
        'wrong1': '1顆',
        'wrong2': '2顆',
        'explanation': '章魚有3顆心臟：1顆主心臟負責全身循環，另外2顆鰓心臟負責將血液送往鰓部進行氧氣交換。',
        'category': '動物奇聞',
      };
      _options = ['1顆', '3顆', '2顆'];
      _loading = false;
    });
  }

  void _reveal() {
    if (_selectedIndex == null) return;
    setState(() => _revealed = true);
    final isCorrect = _options[_selectedIndex!] == _question!['correct'];
    if (isCorrect) {
      setState(() => _score++);
      context.read<AppProvider>().updateProfile(
          context.read<AppProvider>().profile!.copyWith(
              growthPoints:
                  (context.read<AppProvider>().profile!.growthPoints + 20)
                      .clamp(0, 999999)));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 答對了！獲得 20 成長點數'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日冷知識'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('本次得分: $_score',
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _question == null
              ? const Center(child: Text('無法載入，請重試'))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Chip(
                          label: Text(_question!['category'] ?? '知識'),
                          avatar: const Text('🧠'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _question!['question'] ?? '',
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                                height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._options.asMap().entries.map((entry) {
                        final i = entry.key;
                        final opt = entry.value;
                        final isCorrect = opt == _question!['correct'];
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
                            onTap: _revealed
                                ? null
                                : () => setState(() => _selectedIndex = i),
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
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                color: textColor,
                                                fontWeight: isSelected ||
                                                        (_revealed && isCorrect)
                                                    ? FontWeight.bold
                                                    : null)),
                                  ),
                                  if (trailingIcon != null)
                                    Icon(trailingIcon,
                                        color: iconColor, size: 22),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      if (!_revealed) ...[
                        FilledButton(
                          onPressed: _selectedIndex == null ? null : _reveal,
                          child: const Text('揭曉答案'),
                        ),
                      ] else ...[
                        Card(
                          color: theme.colorScheme.tertiaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('💡',
                                        style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text('解釋',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onTertiaryContainer)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _question!['explanation'] ?? '',
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
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('下一題'),
                          onPressed: _load,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
