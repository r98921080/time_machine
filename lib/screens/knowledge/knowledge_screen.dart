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
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    final rng = Random();
    final category = _categories[rng.nextInt(_categories.length)];
    try {
      final raw = await provider.generateKnowledgeQuestion(category)
          ?? {'raw': '{}'};
      final parsed = jsonDecode(raw['raw'] ?? '{}') as Map<String, dynamic>;
      if (parsed.isNotEmpty) {
        final correct = parsed['correct'] as String? ?? '';
        final wrong1 = parsed['wrong1'] as String? ?? '';
        final wrong2 = parsed['wrong2'] as String? ?? '';
        final opts = [correct, wrong1, wrong2]..shuffle();
        setState(() {
          _question = parsed;
          _options = opts;
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    // Fallback sample question
    setState(() {
      _question = {
        'question': '章魚有幾顆心臟？',
        'correct': '3顆',
        'wrong1': '1顆',
        'wrong2': '2顆',
        'explanation': '章魚有3顆心臟：1顆主心臟負責全身循環，另外2顆負責將血液送往鰓部進行氧氣交換。',
        'category': '動物奇聞',
      };
      _options = ['3顆', '1顆', '2顆'];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日冷知識'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _selectedIndex = null;
                _revealed = false;
              });
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _question == null
              ? const Center(child: Text('無法載入，請重試'))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Category chip
                      Center(
                        child: Chip(
                          label: Text(_question!['category'] ?? '知識'),
                          avatar: const Text('🧠'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Question
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
                      const SizedBox(height: 24),
                      // Options
                      ..._options.asMap().entries.map((entry) {
                        final i = entry.key;
                        final opt = entry.value;
                        final isCorrect = opt == _question!['correct'];
                        final isSelected = _selectedIndex == i;

                        Color? cardColor;
                        if (_revealed) {
                          if (isCorrect) cardColor = Colors.green.shade100;
                          else if (isSelected) cardColor = Colors.red.shade100;
                        } else if (isSelected) {
                          cardColor = theme.colorScheme.secondaryContainer;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: _revealed
                                ? null
                                : () => setState(() => _selectedIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor ??
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected && !_revealed
                                    ? Border.all(
                                        color: theme.colorScheme.primary,
                                        width: 2)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(opt,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : null)),
                                  ),
                                  if (_revealed)
                                    Icon(
                                      isCorrect
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color:
                                          isCorrect ? Colors.green : Colors.red,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      if (!_revealed)
                        FilledButton(
                          onPressed: _selectedIndex == null
                              ? null
                              : () {
                                  setState(() => _revealed = true);
                                  final correct =
                                      _options[_selectedIndex!] ==
                                          _question!['correct'];
                                  if (correct) {
                                    context.read<AppProvider>()
                                      .._addGrowthPoints(20);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('🎉 答對了！獲得 20 成長點數'),
                                          backgroundColor: Colors.green),
                                    );
                                  }
                                },
                          child: const Text('揭曉答案'),
                        )
                      else ...[
                        Card(
                          color: Colors.amber.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('💡 解釋',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(_question!['explanation'] ?? '',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(height: 1.5)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

// Allow calling _addGrowthPoints via extension for convenience
extension _ProviderExt on AppProvider {
  void _addGrowthPoints(int delta) {
    // Calls the private method via the public interface
    updateProfile(profile!.copyWith(
        growthPoints: profile!.growthPoints + delta));
  }
}
