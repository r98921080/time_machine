import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/goal.dart';
import 'heatmap_widget.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
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
            onPressed: () => _showAddCategoryDialog(context, provider),
          ),
        ],
      ),
      body: categories.isEmpty
          ? _EmptyState(onAdd: () => _showAddCategoryDialog(context, provider))
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

  void _showAddCategoryDialog(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新增目標類別'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: '例：飲食、運動、睡眠',
            labelText: '類別名稱',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                provider.addCategory(GoalCategory(title: ctrl.text.trim()));
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
        leading: CircularProgressIndicator(
          value: progress,
          strokeWidth: 3,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(
            progress >= 1.0 ? Colors.green : theme.colorScheme.primary,
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
                Text('入門: ${item.miniTarget}',
                    style: theme.textTheme.labelSmall),
                Text('進階: ${item.advancedTarget}',
                    style: theme.textTheme.labelSmall),
                Text('精英: ${item.eliteTarget}',
                    style: theme.textTheme.labelSmall),
              ],
            ),
            trailing: isLogged
                ? Chip(
                    label: Text(logged.achieved.label,
                        style: const TextStyle(fontSize: 11)),
                    backgroundColor: _levelColor(logged.achieved),
                  )
                : TextButton(
                    onPressed: () =>
                        _showLogDialog(context, provider, item),
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
              return RadioListTile<GoalLevel>(
                value: level,
                groupValue: selected,
                onChanged: (v) => setS(() => selected = v!),
                title: Text(level.label),
                subtitle: Text(target,
                    style: const TextStyle(fontSize: 11)),
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
                    validator: (v) =>
                        v?.isEmpty == true ? '請輸入名稱' : null),
                const SizedBox(height: 8),
                TextFormField(
                    controller: miniCtrl,
                    decoration: const InputDecoration(labelText: '入門標準'),
                    validator: (v) =>
                        v?.isEmpty == true ? '請輸入標準' : null),
                TextFormField(
                    controller: advCtrl,
                    decoration: const InputDecoration(labelText: '進階標準'),
                    validator: (v) =>
                        v?.isEmpty == true ? '請輸入標準' : null),
                TextFormField(
                    controller: eliteCtrl,
                    decoration: const InputDecoration(labelText: '精英標準'),
                    validator: (v) =>
                        v?.isEmpty == true ? '請輸入標準' : null),
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
                // Access provider from ancestor context
                context.findAncestorStateOfType<_GoalsScreenState>()
                    ?.context
                    .read<AppProvider>()
                    .updateCategory(updated);
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.track_changes_outlined, size: 64,
              color: Colors.grey),
          const SizedBox(height: 16),
          const Text('還沒有目標',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('建立你的第一個生活目標類別',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('新增目標'),
          ),
        ],
      ),
    );
  }
}
