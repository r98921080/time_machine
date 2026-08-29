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
  bool _analyzingJournal = false;
  bool _generatingMindMap = false;
  bool _saved = false;
  bool _generatingTitle = false;
  String? _aiTitle;
  String? _completeError;
  String? _lastDiaryForCompletion;
  Map<String, dynamic>? _journalAnalysis;

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
            // AI Tools Row 1
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _completing ? null : () => _aiComplete(provider),
                    icon: _completing
                        ? const SizedBox(width: 14, height: 14,
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
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.checklist, size: 16),
                    label: const Text('提取待辦'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // AI Tools Row 2
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _analyzingJournal ? null : () => _analyzeJournal(provider),
                    icon: _analyzingJournal
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.event_note, size: 16),
                    label: const Text('行程提取'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generatingMindMap ? null : () => _showMindMap(provider),
                    icon: _generatingMindMap
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.account_tree_outlined, size: 16),
                    label: const Text('今日心智圖'),
                  ),
                ),
              ],
            ),
            // Journal Analysis Result
            if (_journalAnalysis != null) ...[
              const SizedBox(height: 8),
              _JournalAnalysisCard(analysis: _journalAnalysis!, theme: theme),
            ],
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
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _completeError = msg.length > 80 ? msg.substring(0, 80) : msg);
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

  Future<void> _analyzeJournal(AppProvider provider) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _analyzingJournal = true);
    try {
      final result = await provider.analyzeJournal(text);
      final events = (result['events'] as List?) ?? [];
      final todos = (result['todos'] as List?) ?? [];
      if (events.isEmpty && todos.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日記中未發現明確的行程或待辦')));
        return;
      }
      setState(() => _journalAnalysis = result);
      // Auto-add todos from journal analysis
      if (todos.isNotEmpty) {
        await provider.addTodos(todos.cast<String>());
      }
    } finally {
      if (mounted) setState(() => _analyzingJournal = false);
    }
  }

  Future<void> _showMindMap(AppProvider provider) async {
    setState(() => _generatingMindMap = true);
    try {
      final mindMap = await provider.generateMindMap();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => _MindMapDialog(mindMap: mindMap),
      );
    } finally {
      if (mounted) setState(() => _generatingMindMap = false);
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

// ── Journal Analysis Card ─────────────────────────────────────────

class _JournalAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final ThemeData theme;
  const _JournalAnalysisCard({required this.analysis, required this.theme});

  @override
  Widget build(BuildContext context) {
    final events = (analysis['events'] as List?)?.cast<Map>() ?? [];
    final todos = (analysis['todos'] as List?)?.cast<String>() ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📅 AI 發現的行程與待辦',
            style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onTertiaryContainer)),
        const SizedBox(height: 8),
        if (events.isNotEmpty) ...[
          Text('行程', style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer.withOpacity(0.7))),
          const SizedBox(height: 4),
          ...events.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.event, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(
                '${e['title'] ?? ''}'
                '${(e['date'] as String?)?.isNotEmpty == true ? "  ${e['date']}" : ""}'
                '${(e['time'] as String?)?.isNotEmpty == true ? " ${e['time']}" : ""}',
                style: theme.textTheme.bodySmall,
              )),
            ]),
          )),
        ],
        if (todos.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('待辦（已自動加入）',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer.withOpacity(0.7))),
          const SizedBox(height: 4),
          ...todos.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(children: [
              const Icon(Icons.check_box_outline_blank, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(t, style: theme.textTheme.bodySmall)),
            ]),
          )),
        ],
      ]),
    );
  }
}

// ── Mind Map Dialog ───────────────────────────────────────────────

class _MindMapDialog extends StatelessWidget {
  final Map<String, dynamic> mindMap;
  const _MindMapDialog({required this.mindMap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = mindMap['center'] as String? ?? '今日記錄';
    final branches = (mindMap['branches'] as List?)
        ?.map((b) => Map<String, dynamic>.from(b as Map))
        .toList() ?? [];

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Icon(Icons.account_tree_outlined),
            const SizedBox(width: 8),
            Text('今日心智圖', style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          // Center node
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(center,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer)),
          ),
          const SizedBox(height: 12),
          // Branches
          ...branches.map((b) {
            final label = b['label'] as String? ?? '';
            final nodes = (b['nodes'] as List?)?.cast<String>() ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 20, height: 2,
                      color: theme.colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(label,
                        style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSecondaryContainer)),
                  ),
                ]),
                if (nodes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 30, top: 4),
                    child: Wrap(spacing: 6, runSpacing: 4,
                      children: nodes.map((n) => Chip(
                        label: Text(n, style: theme.textTheme.labelSmall),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ),
              ]),
            );
          }),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ]),
      ),
    );
  }
}
