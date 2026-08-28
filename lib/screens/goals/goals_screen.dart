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
  int _step = 0; // 0=選類別, 1=選子類, 2=確認目標

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
    final catName = _ctrl.text.trim().isEmpty
        ? (_step > 0 ? _ctrl.text : '')
        : _ctrl.text.trim();
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

                // Preset category chips
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

                // Custom input
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
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 16),
                      const SizedBox(width: 6),
                      Text('AI 建議子類別',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
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
                          avatar: active
                              ? const Icon(Icons.check, size: 16)
                              : null,
                          label: Text(sub),
                          backgroundColor: active
                              ? theme.colorScheme.primaryContainer
                              : null,
                          onPressed: () => _loadTargets(
                              _cleanLabel(_ctrl.text), sub),
                        );
                      }).toList(),
                    ),
                ],

                if (_step >= 2) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('AI 生成目標（可編輯）',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_loadingTargets)
                    const Center(child: CircularProgressIndicator())
                  else if (_aiTargets != null)
                    _TargetPreviewCard(
                      targets: _aiTargets!,
                      theme: theme,
                    )
                  else
                    const Text('無法生成，將建立空白目標'),
                ],

                const SizedBox(height: 24),
                Row(
                  children: [
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
                  ],
                ),
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
                Expanded(
                  child: Text(r.$2, style: theme.textTheme.bodySmall),
                ),
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
    final loggedIds = todayLogs.map((l) => l.subItemId).toSet();
    final completedCount = category.subItems
        .where((s) => loggedIds.contains(s.id))
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
              onPressed: () => provider.deleteCategory(category.id),
            ),
          ],
        ),
        children: category.subItems.map((item) {
          final logged = todayLogs.firstWhere(
            (l) => l.subItemId == item.id,
            orElse: () => DailyGoalLog(
              profileId: provider.profile!.id,
              subItemId: item.id,
              achieved: GoalLevel.mini,
              score: 0,
              date: DateTime.now(),
            ),
          );
          final isLogged = loggedIds.contains(item.id);

          return ListTile(
            title: Text(item.name, style: theme.textTheme.bodyMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LevelBadge('🌱 入門', item.miniTarget, Colors.blue),
                _LevelBadge('⚡ 進階', item.advancedTarget, Colors.orange),
                _LevelBadge('🏆 精英', item.eliteTarget, Colors.green),
              ],
            ),
            trailing: isLogged
                ? Chip(
                    label: Text(logged.achieved.label,
                        style: const TextStyle(fontSize: 11)),
                    backgroundColor: _levelColor(logged.achieved),
                  )
                : TextButton(
                    onPressed: () => _showLogDialog(context, provider, item),
                    child: const Text('打卡'),
                  ),
          );
        }).toList(),
      ),
    );
  }

  Color _levelColor(GoalLevel level) {
    switch (level) {
      case GoalLevel.mini: return Colors.blue.shade100;
      case GoalLevel.advanced: return Colors.orange.shade100;
      case GoalLevel.elite: return Colors.green.shade100;
    }
  }

  void _showLogDialog(
      BuildContext context, AppProvider provider, GoalSubItem item) {
    GoalLevel selected = GoalLevel.mini;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(item.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: GoalLevel.values.map((level) {
              final target = level == GoalLevel.mini
                  ? item.miniTarget
                  : level == GoalLevel.advanced
                      ? item.advancedTarget
                      : item.eliteTarget;
              final emoji = level == GoalLevel.mini
                  ? '🌱'
                  : level == GoalLevel.advanced
                      ? '⚡'
                      : '🏆';
              return RadioListTile<GoalLevel>(
                value: level,
                groupValue: selected,
                onChanged: (v) => setS(() => selected = v!),
                title: Text('$emoji ${level.label}'),
                subtitle: Text(target, style: const TextStyle(fontSize: 11)),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
            FilledButton(
              onPressed: () {
                provider.logGoal(DailyGoalLog(
                  profileId: provider.profile!.id,
                  subItemId: item.id,
                  achieved: selected,
                  score: selected.points,
                  date: DateTime.now(),
                ));
                provider.checkAndUpdateStreak();
                Navigator.pop(ctx);
              },
              child: const Text('確認'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final miniCtrl = TextEditingController();
    final advCtrl = TextEditingController();
    final eliteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final prov = context.findAncestorStateOfType<State<GoalsScreen>>()?.context
            .read<AppProvider>() ??
        provider;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('新增「${category.title}」子項目'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: '項目名稱'),
                    validator: (v) => v?.isEmpty == true ? '請輸入名稱' : null),
                const SizedBox(height: 8),
                TextFormField(
                    controller: miniCtrl,
                    decoration: const InputDecoration(
                        labelText: '🌱 入門標準', hintText: '最低要求')),
                TextFormField(
                    controller: advCtrl,
                    decoration: const InputDecoration(
                        labelText: '⚡ 進階標準', hintText: '有挑戰性')),
                TextFormField(
                    controller: eliteCtrl,
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
              if (formKey.currentState!.validate()) {
                final updated = GoalCategory(
                  id: category.id,
                  title: category.title,
                  subItems: [
                    ...category.subItems,
                    GoalSubItem(
                      name: nameCtrl.text.trim(),
                      miniTarget: miniCtrl.text.trim(),
                      advancedTarget: advCtrl.text.trim(),
                      eliteTarget: eliteCtrl.text.trim(),
                    ),
                  ],
                );
                prov.updateCategory(updated);
                Navigator.pop(context);
              }
            },
            child: const Text('新增'),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String prefix;
  final String target;
  final Color color;
  const _LevelBadge(this.prefix, this.target, this.color);

  @override
  Widget build(BuildContext context) {
    if (target.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11),
          children: [
            TextSpan(
                text: '$prefix ',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            TextSpan(
                text: target,
                style: TextStyle(color: Colors.grey.shade700)),
          ],
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
          const Icon(Icons.track_changes_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('還沒有目標',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('建立你的第一個生活目標類別',
              style: TextStyle(color: Colors.grey)),
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
