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
  int? _selectedAnswerIndex;
  bool _revealed = false;
  final _optionsCache = <int, List<String>>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadDailyKnowledge();
    });
  }

  List<String> _buildOptions(int idx, Map<String, dynamic> q) {
    return _optionsCache.putIfAbsent(idx, () => [
      q['correct'] as String? ?? '',
      q['wrong1'] as String? ?? '',
      q['wrong2'] as String? ?? '',
      q['wrong3'] as String? ?? '',
    ]..shuffle());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final questions = provider.dailyKnowledge;
    final answers = provider.knowledgeAnswers;
    final streak = provider.knowledgeStreak;

    if (provider.loadingKnowledge) {
      return Scaffold(
        appBar: AppBar(title: const Text('每日瞎掰王')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('AI 正在出今天的題目…', style: theme.textTheme.bodyMedium),
          ]),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('每日瞎掰王')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('今天的題目還沒準備好', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => provider.loadDailyKnowledge(),
              icon: const Icon(Icons.refresh),
              label: const Text('重新載入'),
            ),
          ]),
        ),
      );
    }

    final allAnswered = questions.every((q) => answers.containsKey(q['id'] as String));

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日瞎掰王'),
        actions: [
          if (streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                const SizedBox(width: 2),
                Text('$streak 天',
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.orange, fontWeight: FontWeight.bold)),
              ]),
            ),
        ],
      ),
      body: Column(children: [
        // Progress dots
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(questions.length, (i) {
              final qId = questions[i]['id'] as String;
              final answered = answers.containsKey(qId);
              final correct = answers[qId] == true;
              return GestureDetector(
                onTap: () => setState(() {
                  _currentIndex = i;
                  _selectedAnswerIndex = null;
                  _revealed = answered;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: _currentIndex == i ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: answered
                        ? (correct ? Colors.green : Colors.red)
                        : (_currentIndex == i
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest),
                  ),
                ),
              );
            }),
          ),
        ),
        // All done banner
        if (allAnswered)
          _DoneCard(questions: questions, answers: answers, streak: streak, theme: theme),
        // Question card
        if (!allAnswered || _currentIndex < questions.length)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _QuestionCard(
                question: questions[_currentIndex],
                questionNumber: _currentIndex + 1,
                total: questions.length,
                options: _buildOptions(_currentIndex, questions[_currentIndex]),
                selectedAnswerIndex: _selectedAnswerIndex,
                revealed: _revealed || answers.containsKey(questions[_currentIndex]['id'] as String),
                existingAnswer: answers[questions[_currentIndex]['id'] as String],
                theme: theme,
                onSelect: (optIdx, opts) async {
                  if (_revealed || answers.containsKey(questions[_currentIndex]['id'] as String)) return;
                  final q = questions[_currentIndex];
                  final correct = opts[optIdx] == (q['correct'] as String? ?? '');
                  setState(() {
                    _selectedAnswerIndex = optIdx;
                    _revealed = true;
                  });
                  await provider.answerKnowledge(q['id'] as String, correct);
                },
                onNext: _currentIndex < questions.length - 1
                    ? () => setState(() {
                          _currentIndex++;
                          _selectedAnswerIndex = null;
                          _revealed = answers.containsKey(questions[_currentIndex]['id'] as String);
                        })
                    : null,
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Question Card ─────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final int questionNumber;
  final int total;
  final List<String> options;
  final int? selectedAnswerIndex;
  final bool revealed;
  final bool? existingAnswer;
  final ThemeData theme;
  final void Function(int, List<String>) onSelect;
  final VoidCallback? onNext;

  const _QuestionCard({
    required this.question,
    required this.questionNumber,
    required this.total,
    required this.options,
    required this.selectedAnswerIndex,
    required this.revealed,
    required this.existingAnswer,
    required this.theme,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final correct = question['correct'] as String? ?? '';
    final category = question['category'] as String? ?? '';
    final questionText = question['question'] as String? ?? '';
    final explanation = question['explanation'] as String? ?? '';

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Category + number
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(category,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Text('$questionNumber / $total',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ]),
        const SizedBox(height: 16),
        // Question
        Text(questionText,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, height: 1.5)),
        const SizedBox(height: 20),
        // Options
        ...List.generate(options.length, (i) {
          final opt = options[i];
          final isCorrect = opt == correct;
          Color? bg;
          Color? fg;
          IconData? icon;
          if (revealed) {
            if (isCorrect) {
              bg = Colors.green.shade100;
              fg = Colors.green.shade800;
              icon = Icons.check_circle;
            } else if (selectedAnswerIndex == i) {
              bg = Colors.red.shade100;
              fg = Colors.red.shade800;
              icon = Icons.cancel;
            } else {
              bg = theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
              fg = theme.colorScheme.onSurfaceVariant.withOpacity(0.6);
            }
          }
          return GestureDetector(
            onTap: revealed ? null : () => onSelect(i, options),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: bg ?? theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: revealed && isCorrect
                      ? Colors.green
                      : theme.colorScheme.outline.withOpacity(0.3),
                  width: revealed && isCorrect ? 2 : 1,
                ),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(opt,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: fg,
                          fontWeight: revealed && isCorrect
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
                if (revealed && icon != null)
                  Icon(icon,
                      color: isCorrect ? Colors.green : Colors.red, size: 20),
              ]),
            ),
          );
        }),
        // Explanation
        if (revealed && explanation.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💡 解析', style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onTertiaryContainer)),
              const SizedBox(height: 6),
              Text(explanation, style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.6, color: theme.colorScheme.onTertiaryContainer)),
            ]),
          ),
        ],
        if (revealed && onNext != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('下一題'),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── All Done Card ─────────────────────────────────────────────────

class _DoneCard extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final Map<String, bool> answers;
  final int streak;
  final ThemeData theme;

  const _DoneCard({
    required this.questions,
    required this.answers,
    required this.streak,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final correctCount = questions.where((q) =>
        answers[q['id'] as String] == true).length;
    final total = questions.length;
    final perfect = correctCount == total;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: perfect
              ? [Colors.amber.shade100, Colors.orange.shade100]
              : [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Text(perfect ? '🏆' : '✅', style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(perfect ? '完美全對！' : '今日挑戰完成',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text('答對 $correctCount / $total 題${streak > 0 ? "  🔥 連續 $streak 天" : ""}',
              style: theme.textTheme.bodySmall),
        ])),
      ]),
    );
  }
}
