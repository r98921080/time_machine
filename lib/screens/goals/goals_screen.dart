import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/goal.dart';
import 'heatmap_widget.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final categories = provider.categories;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('生活目標'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategorySheet(context, provider),
          ),
        ],
      ),
      body: categories.isEmpty
          ? _EmptyState(onAdd: () => _showAddCategorySheet(context, provider))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeatmapCard(profileId: provider.profile?.id ?? '', theme: theme),
                const SizedBox(height: 16),
                ...categories.map((cat) => _CategoryCard(
                      category: cat,
                      provider: provider,
                      theme: theme,
                    )),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  void _showAddCategorySheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddCategorySheet(provider: provider),
    );
  }
}

// ── Add Category Sheet with AI suggestions ───────────────────────
class _AddCategorySheet extends StatefulWidget {
  final AppProvider provider;
  const _AddCategorySheet({required this.provider});

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _ctrl = TextEditingController();
  static const _presetCategories = [
    '🏃 運動', '🥗 飲食', '😴 睡眠', '📚 學習',
    '🧘 心理', '💼 工作', '🎨 創作', '🏠 生活',
  ];
  List<String> _subCategories = [];
  bool _loadingSubCats = false;
  String? _selectedSubCat;
  Map<String, List<String>>? _aiTargets;
  bool _loadingTargets = false;
  int _step = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubCategories(String cat) async {
    setState(() { _loadingSubCats = true; _step = 1; });
    final subs = await widget.provider.suggestGoalSubCategories(cat);
    setState(() { _subCategories = subs; _loadingSubCats = false; });
  }

  Future<void> _loadTargets(String cat, String sub) async {
    setState(() { _loadingTargets = true; _step = 2; _selectedSubCat = sub; });
    final targets = await widget.provider.generateGoalTargets(cat, sub);
    setState(() { _aiTargets = targets; _loadingTargets = false; });
  }

  Future<void> _createGoal() async {
    final catName = _ctrl.text.trim();
    if (catName.isEmpty && _selectedSubCat == null) return;
    final title = _selectedSubCat != null
        ? '${_cleanLabel(catName)} · $_selectedSubCat'
        : catName;

    final mini = _aiTargets?['mini']?.first ?? '';
    final advanced = _aiTargets?['advanced']?.first ?? '';
    final elite = _aiTargets?['elite']?.first ?? '';

    final cat = GoalCategory(
      title: title,
      subItems: mini.isNotEmpty
          ? [
              GoalSubItem(
                name: _selectedSubCat ?? title,
                miniTarget: mini,
                advancedTarget: advanced,
                eliteTarget: elite,
              ),
            ]
          : [],
    );
    await widget.provider.addCategory(cat);
    if (mounted) Navigator.pop(context);
  }

  String _cleanLabel(String label) =>
      label.replaceAll(RegExp(r'[🏃🥗😴📚🧘💼🎨🏠]\s*'), '').trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text('新增目標類別', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('選擇預設類別，或輸入自訂名稱',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetCategories.map((cat) {
                    final active = _ctrl.text == cat;
                    return FilterChip(
                      label: Text(cat),
                      selected: active,
                      onSelected: (_) {
                        _ctrl.text = cat;
                        _loadSubCategories(_cleanLabel(cat));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    labelText: '或輸入自訂類別',
                    hintText: '例：冥想、閱讀',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.auto_awesome),
                      tooltip: 'AI建議',
                      onPressed: () {
                        if (_ctrl.text.trim().isNotEmpty) {
                          _loadSubCategories(_ctrl.text.trim());
                        }
                      },
                    ),
                  ),
                ),
                if (_step >= 1) ...[
                  const SizedBox(height: 20),
                  Row(children: [
                    const Icon(Icons.auto_awesome, size: 16),
                    const SizedBox(width: 6),
                    Text('AI 建議子類別',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  if (_loadingSubCats)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _subCategories.map((sub) {
                        final active = _selectedSubCat == sub && _step == 2;
                        return ActionChip(
                          avatar: active ? const Icon(Icons.check, size: 16) : null,
                          label: Text(sub),
                          backgroundColor: active ? theme.colorScheme.primaryContainer : null,
                          onPressed: () => _loadTargets(_cleanLabel(_ctrl.text), sub),
                        );
                      }).toList(),
                    ),
                ],
                if (_step >= 2) ...[
                  const SizedBox(height: 20),
                  Row(children: [
                    const Icon(Icons.flag_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text('AI 生成目標（可編輯）',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  if (_loadingTargets)
                    const Center(child: CircularProgressIndicator())
                  else if (_aiTargets != null)
                    _TargetPreviewCard(targets: _aiTargets!, theme: theme)
                  else
                    const Text('無法生成，將建立空白目標'),
                ],
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(_step == 0 ? '直接建立' : '建立目標'),
                      onPressed: _step == 0 && _ctrl.text.trim().isEmpty
                          ? null
                          : _createGoal,
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetPreviewCard extends StatelessWidget {
  final Map<String, List<String>> targets;
  final ThemeData theme;
  const _TargetPreviewCard({required this.targets, required this.theme});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('🌱 入門', targets['mini']?.first ?? '', Colors.blue),
      ('⚡ 進階', targets['advanced']?.first ?? '', Colors.orange),
      ('🏆 精英', targets['elite']?.first ?? '', Colors.green),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 54,
                  child: Text(r.$1,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: r.$3, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Text(r.$2, style: theme.textTheme.bodySmall)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}

// ── Heatmap Card ──────────────────────────────────────────────────
class _HeatmapCard extends StatelessWidget {
  final String profileId;
  final ThemeData theme;
  const _HeatmapCard({required this.profileId, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('90天活躍度', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            GoalHeatmap(profileId: profileId),
          ],
        ),
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final GoalCategory category;
  final AppProvider provider;
  final ThemeData theme;

  const _CategoryCard({
    required this.category,
    required this.provider,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final todayLogs = provider.todayLogs;
    // Count unique subItems that have at least one log
    final loggedSubItems = todayLogs.map((l) => l.subItemId).toSet();
    final completedCount = category.subItems
        .where((s) => loggedSubItems.contains(s.id))
        .length;
    final total = category.subItems.length;
    final progress = total > 0 ? completedCount / total : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              progress >= 1.0 ? Colors.green : theme.colorScheme.primary,
            ),
          ),
        ),
        title: Text(category.title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('$completedCount / $total 項完成',
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _showAddSubItemDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmDelete(context, provider),
            ),
          ],
        ),
        children: [
          ...category.subItems.map((item) => _SubItemTile(
            item: item,
            provider: provider,
            theme: theme,
            category: category,
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('刪除目標'),
        content: Text('確定刪除「${category.title}」嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              provider.deleteCategory(category.id);
              Navigator.pop(context);
            },
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  void _showAddSubItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddSubItemDialog(
        categoryTitle: category.title,
        provider: provider,
        onAdd: (subItem) {
          final updated = GoalCategory(
            id: category.id,
            title: category.title,
            subItems: [...category.subItems, subItem],
          );
          provider.updateCategory(updated);
        },
      ),
    );
  }
}

// ── Add Sub-Item Dialog with AI ────────────────────────────────────
class _AddSubItemDialog extends StatefulWidget {
  final String categoryTitle;
  final AppProvider provider;
  final ValueChanged<GoalSubItem> onAdd;

  const _AddSubItemDialog({
    required this.categoryTitle,
    required this.provider,
    required this.onAdd,
  });

  @override
  State<_AddSubItemDialog> createState() => _AddSubItemDialogState();
}

class _AddSubItemDialogState extends State<_AddSubItemDialog> {
  final _nameCtrl = TextEditingController();
  final _miniCtrl = TextEditingController();
  final _advCtrl = TextEditingController();
  final _eliteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<String> _aiNameSuggestions = [];
  bool _loadingNames = false;
  bool _loadingTargets = false;

  String get _cleanCat => widget.categoryTitle
      .replaceAll(RegExp(r'[^一-鿿㐀-䶿\w\s]'), '')
      .trim();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _miniCtrl.dispose();
    _advCtrl.dispose();
    _eliteCtrl.dispose();
    super.dispose();
  }

  Future<void> _suggestNames() async {
    setState(() => _loadingNames = true);
    final names =
        await widget.provider.suggestGoalSubCategories(_cleanCat);
    setState(() {
      _aiNameSuggestions = names;
      _loadingNames = false;
    });
  }

  Future<void> _fillTargets(String name) async {
    _nameCtrl.text = name;
    setState(() => _loadingTargets = true);
    final targets =
        await widget.provider.generateGoalTargets(_cleanCat, name);
    if (targets != null && mounted) {
      _miniCtrl.text = targets['mini']?.first ?? '';
      _advCtrl.text = targets['advanced']?.first ?? '';
      _eliteCtrl.text = targets['elite']?.first ?? '';
    }
    if (mounted) setState(() => _loadingTargets = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('新增「${widget.categoryTitle}」子項目'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field + AI suggest button
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration:
                          const InputDecoration(labelText: '項目名稱'),
                      validator: (v) =>
                          v?.isEmpty == true ? '請輸入名稱' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _loadingNames
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton.outlined(
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          tooltip: 'AI 建議名稱',
                          onPressed: _suggestNames,
                        ),
                ],
              ),

              // AI name suggestions chips
              if (_aiNameSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _aiNameSuggestions.map((name) {
                    final selected = _nameCtrl.text == name;
                    return ActionChip(
                      label: Text(name,
                          style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : null)),
                      backgroundColor: selected
                          ? theme.colorScheme.primaryContainer
                          : null,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _fillTargets(name),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Target fields
              if (_loadingTargets)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              TextFormField(
                  controller: _miniCtrl,
                  decoration: const InputDecoration(
                      labelText: '🌱 入門標準', hintText: '最低要求')),
              TextFormField(
                  controller: _advCtrl,
                  decoration: const InputDecoration(
                      labelText: '⚡ 進階標準', hintText: '有挑戰性')),
              TextFormField(
                  controller: _eliteCtrl,
                  decoration: const InputDecoration(
                      labelText: '🏆 精英標準', hintText: '高標準')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd(GoalSubItem(
                name: _nameCtrl.text.trim(),
                miniTarget: _miniCtrl.text.trim(),
                advancedTarget: _advCtrl.text.trim(),
                eliteTarget: _eliteCtrl.text.trim(),
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('新增'),
        ),
      ],
    );
  }
}

// ── Sub Item Tile with independent level check-in ─────────────────
class _SubItemTile extends StatefulWidget {
  final GoalSubItem item;
  final AppProvider provider;
  final ThemeData theme;
  final GoalCategory category;

  const _SubItemTile({
    required this.item,
    required this.provider,
    required this.theme,
    required this.category,
  });

  @override
  State<_SubItemTile> createState() => _SubItemTileState();
}

class _SubItemTileState extends State<_SubItemTile> {
  bool _rebuilding = false;

  Set<GoalLevel> _loggedLevels() {
    return widget.provider.todayLogs
        .where((l) => l.subItemId == widget.item.id)
        .map((l) => l.achieved)
        .toSet();
  }

  Future<void> _rebuildTargets() async {
    setState(() => _rebuilding = true);
    List<Map<String, dynamic>> options = [];
    try {
      options = await widget.provider.generateGoalRebuildOptions(
          widget.category, widget.item);
    } finally {
      if (mounted) setState(() => _rebuilding = false);
    }
    if (!mounted || options.isEmpty) return;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RebuildOptionsSheet(options: options, theme: widget.theme),
    );
    if (selected == null || !mounted) return;

    final updated = GoalCategory(
      id: widget.category.id,
      title: widget.category.title,
      subItems: widget.category.subItems.map((s) {
        if (s.id != widget.item.id) return s;
        return GoalSubItem(
          id: s.id,
          name: s.name,
          miniTarget: selected['mini'] as String? ?? s.miniTarget,
          advancedTarget: selected['advanced'] as String? ?? s.advancedTarget,
          eliteTarget: selected['elite'] as String? ?? s.eliteTarget,
        );
      }).toList(),
    );
    await widget.provider.updateCategory(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ 已套用「${selected['name']}」方案')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final logged = _loggedLevels();
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.item.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600)),
              ),
              _rebuilding
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      tooltip: 'AI 重新建構目標',
                      visualDensity: VisualDensity.compact,
                      color: theme.colorScheme.primary,
                      onPressed: _rebuildTargets,
                    ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LevelButton(
                level: GoalLevel.mini,
                target: widget.item.miniTarget,
                checked: logged.contains(GoalLevel.mini),
                onToggle: () => _toggle(context, GoalLevel.mini, logged),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _LevelButton(
                level: GoalLevel.advanced,
                target: widget.item.advancedTarget,
                checked: logged.contains(GoalLevel.advanced),
                onToggle: () => _toggle(context, GoalLevel.advanced, logged),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _LevelButton(
                level: GoalLevel.elite,
                target: widget.item.eliteTarget,
                checked: logged.contains(GoalLevel.elite),
                onToggle: () => _toggle(context, GoalLevel.elite, logged),
                theme: theme,
              ),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Future<void> _toggle(BuildContext context, GoalLevel level,
      Set<GoalLevel> currentLogged) async {
    if (currentLogged.contains(level)) {
      await widget.provider.removeGoalLog(widget.item.id, level);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已取消 ${_levelEmoji(level)} ${level.label}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      await widget.provider.logGoal(DailyGoalLog(
        profileId: widget.provider.profile!.id,
        subItemId: widget.item.id,
        achieved: level,
        score: level.points,
        date: DateTime.now(),
      ));
      widget.provider.checkAndUpdateStreak();
    }
  }

  String _levelEmoji(GoalLevel l) {
    switch (l) {
      case GoalLevel.mini: return '🌱';
      case GoalLevel.advanced: return '⚡';
      case GoalLevel.elite: return '🏆';
    }
  }
}

class _LevelButton extends StatelessWidget {
  final GoalLevel level;
  final String target;
  final bool checked;
  final VoidCallback onToggle;
  final ThemeData theme;

  const _LevelButton({
    required this.level,
    required this.target,
    required this.checked,
    required this.onToggle,
    required this.theme,
  });

  Color get _color {
    switch (level) {
      case GoalLevel.mini: return Colors.blue;
      case GoalLevel.advanced: return Colors.orange;
      case GoalLevel.elite: return Colors.green;
    }
  }

  String get _emoji {
    switch (level) {
      case GoalLevel.mini: return '🌱';
      case GoalLevel.advanced: return '⚡';
      case GoalLevel.elite: return '🏆';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: checked
                ? _color.withOpacity(0.15)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: checked ? _color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 2),
                  if (checked)
                    Icon(Icons.check_circle, size: 14, color: _color)
                  else
                    Icon(Icons.radio_button_unchecked,
                        size: 14, color: theme.colorScheme.outlineVariant),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                level.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: checked ? _color : theme.colorScheme.onSurfaceVariant,
                  fontWeight: checked ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (target.isNotEmpty)
                Text(
                  target,
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.track_changes_outlined,
              size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          const Text('還沒有目標',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('建立你的第一個生活目標類別',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI 智能建立目標'),
          ),
        ],
      ),
    );
  }
}

class _RebuildOptionsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final ThemeData theme;
  const _RebuildOptionsSheet({required this.options, required this.theme});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: ListView(
          controller: ctrl,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('✨ 選擇目標重建方案',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('AI 依據日記及歷史達成率為你量身推薦',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final name = opt['name'] as String? ?? '';
              final desc = opt['description'] as String? ?? '';
              final mini = opt['mini'] as String? ?? '';
              final adv = opt['advanced'] as String? ?? '';
              final elite = opt['elite'] as String? ?? '';
              final color = name.contains('激進')
                  ? Colors.orange
                  : name.contains('輕量')
                      ? Colors.green
                      : theme.colorScheme.primary;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context, opt),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(name,
                                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios, size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                        ]),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(desc, style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                        ],
                        const SizedBox(height: 12),
                        _TargetRow('🌱 入門', mini, theme),
                        const SizedBox(height: 4),
                        _TargetRow('⚡ 進階', adv, theme),
                        const SizedBox(height: 4),
                        _TargetRow('🔥 精英', elite, theme),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  const _TargetRow(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 48,
            child: Text(label, style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary))),
        Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}
