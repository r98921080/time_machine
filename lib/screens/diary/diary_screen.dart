import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/diary_entry.dart';
import '../../models/todo_item.dart';
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
  bool _saved = false;
  bool _generatingTitle = false;
  String? _aiTitle;
  String? _completeError;
  String? _lastDiaryForCompletion;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _ctrl = TextEditingController(text: provider.todayDiary?.content ?? '');
    _aiTitle = provider.todayDiary?.aiTitle;
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
    final todos = provider.todos;

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
            // AI Title display
            if (_aiTitle != null && _aiTitle!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 400),
                  builder: (_, v, child) => Opacity(opacity: v, child: child),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Text('✨', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('「$_aiTitle」',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontStyle: FontStyle.italic)),
                      const Spacer(),
                      if (_generatingTitle)
                        SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                color: theme.colorScheme.primary)),
                    ]),
                  ),
                ),
              )
            else if (_generatingTitle)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text('AI 生成標題中…',
                      style: TextStyle(fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                ]),
              ),
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
                            width: 14, height: 14,
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
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.checklist, size: 16),
                    label: const Text('提取待辦'),
                  ),
                ),
              ],
            ),
            // Error + retry
            if (_completeError != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(_completeError!,
                        style: TextStyle(
                            fontSize: 12, color: theme.colorScheme.error)),
                  ),
                  if (_lastDiaryForCompletion != null)
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('重試'),
                      style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          padding: const EdgeInsets.symmetric(horizontal: 8)),
                      onPressed: () => _aiComplete(provider),
                    ),
                ],
              ),
            ],
            // Persistent Todos list
            if (todos.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PersistentTodosBlock(
                todos: todos,
                theme: theme,
                onToggle: (id) => provider.toggleTodo(id),
                onRemove: (id) => provider.removeTodo(id),
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
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _lastDiaryForCompletion = text;
    setState(() { _completing = true; _completeError = null; });
    try {
      final completion = await provider.completeDiary(text);
      if (completion.isNotEmpty) {
        _ctrl.text = _ctrl.text + completion;
        _ctrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _ctrl.text.length));
        setState(() => _completeError = null);
      } else {
        setState(() => _completeError = 'AI 補完暫時無法使用，請點重試');
      }
    } catch (e) {
      setState(() => _completeError = 'AI 補完失敗，請確認網路後點重試');
    } finally {
      setState(() => _completing = false);
    }
  }

  Future<void> _extractTodos(AppProvider provider) async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _extracting = true);
    try {
      final todos = await provider.extractTodos(_ctrl.text);
      if (todos.isNotEmpty) {
        await provider.addTodos(todos);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已新增 ${todos.length} 個待辦事項')));
        }
      }
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
          const SnackBar(content: Text('日記已儲存 ✍️')));
    }

    // Generate AI title in background if content is substantial
    if (content.length >= 30 && (existing?.aiTitle == null || existing!.aiTitle!.isEmpty)) {
      setState(() => _generatingTitle = true);
      try {
        final title = await provider.generateDiaryTitle(content);
        if (mounted && title.isNotEmpty) {
          setState(() => _aiTitle = title);
          // Save title back to diary
          await provider.saveDiary(entry.copyWith(aiTitle: title));
        }
      } catch (_) {
        // Silent failure for title generation
      } finally {
        if (mounted) setState(() => _generatingTitle = false);
      }
    }
  }
}

class _PersistentTodosBlock extends StatelessWidget {
  final List<TodoItem> todos;
  final ThemeData theme;
  final void Function(String) onToggle;
  final void Function(String) onRemove;

  const _PersistentTodosBlock({
    required this.todos,
    required this.theme,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Show undone first, then done (greyed out)
    final undone = todos.where((t) => !t.done).toList();
    final done = todos.where((t) => t.done).toList();
    final ordered = [...undone, ...done];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            '✅ 待辦事項',
            style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary),
          ),
        ),
        ...ordered.map((todo) => _TodoRow(
              todo: todo,
              theme: theme,
              onToggle: () => onToggle(todo.id),
              onRemove: () => onRemove(todo.id),
            )),
      ],
    );
  }
}

class _TodoRow extends StatelessWidget {
  final TodoItem todo;
  final ThemeData theme;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _TodoRow({
    required this.todo,
    required this.theme,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: todo.done
              ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: todo.done
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.secondary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Icon(
                todo.done ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
                color: todo.done
                    ? theme.colorScheme.outline
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                todo.content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: todo.done
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSecondaryContainer,
                  decoration: todo.done ? TextDecoration.lineThrough : null,
                  decorationColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
