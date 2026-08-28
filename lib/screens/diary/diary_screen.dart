import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/diary_entry.dart';
import '../../providers/app_provider.dart';

class DiaryScreen extends StatefulWidget {
  final bool embedded;
  const DiaryScreen({super.key, this.embedded = false});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late TextEditingController _ctrl;
  bool _completing = false;
  bool _extracting = false;
  List<String> _todos = [];
  bool _saved = false;
  String? _completeError;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _ctrl = TextEditingController(text: provider.todayDiary?.content ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('今日日記'),
              actions: [
                if (_saved)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.check_circle, color: Colors.green),
                  ),
              ],
            ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: '今天發生了什麼？\n心情如何？有什麼想法？',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                onChanged: (_) => setState(() => _saved = false),
              ),
            ),
            const SizedBox(height: 12),
            // AI Tools Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _completing ? null : () => _aiComplete(provider),
                    icon: _completing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text('AI 補完'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _extracting ? null : () => _extractTodos(provider),
                    icon: _extracting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.checklist, size: 16),
                    label: const Text('提取待辦'),
                  ),
                ),
              ],
            ),
            if (_completeError != null) ...[
              const SizedBox(height: 4),
              Text(_completeError!,
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.error)),
            ],
            if (_todos.isNotEmpty) ...[
              const SizedBox(height: 8),
              _TodosBlock(
                todos: _todos,
                theme: theme,
                onRemove: (i) => setState(() => _todos.removeAt(i)),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _save(provider),
              child: const Text('儲存日記'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _aiComplete(AppProvider provider) async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _completing = true; _completeError = null; });
    try {
      final completion = await provider.completeDiary(_ctrl.text);
      if (completion.isNotEmpty) {
        _ctrl.text = _ctrl.text + completion;
        _ctrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _ctrl.text.length));
      } else {
        setState(() => _completeError = 'AI 補完暫時無法使用，請稍後再試');
      }
    } catch (_) {
      setState(() => _completeError = 'AI 補完失敗，請檢查網路後再試');
    } finally {
      setState(() => _completing = false);
    }
  }

  Future<void> _extractTodos(AppProvider provider) async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _extracting = true);
    try {
      final todos = await provider.extractTodos(_ctrl.text);
      setState(() => _todos = todos);
    } finally {
      setState(() => _extracting = false);
    }
  }

  Future<void> _save(AppProvider provider) async {
    final content = _ctrl.text.trim();
    if (content.isEmpty) return;

    final existing = provider.todayDiary;
    final entry = DiaryEntry(
      id: existing?.id,
      profileId: provider.profile!.id,
      content: content,
      date: existing?.date ?? DateTime.now(),
    );
    await provider.saveDiary(entry);
    setState(() => _saved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日記已儲存')));
    }
  }
}

class _TodosBlock extends StatelessWidget {
  final List<String> todos;
  final ThemeData theme;
  final void Function(int) onRemove;

  const _TodosBlock({
    required this.todos,
    required this.theme,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            '✅ AI 提取的待辦事項',
            style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(todos.length, (i) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_box_outline_blank,
                      size: 14,
                      color: theme.colorScheme.onSecondaryContainer),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.55),
                    child: Text(
                      todos[i],
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => onRemove(i),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.close,
                          size: 14,
                          color: theme.colorScheme.onSecondaryContainer
                              .withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
