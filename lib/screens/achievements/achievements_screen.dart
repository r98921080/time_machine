import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/achievement.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final unlocked = provider.achievements.map((a) => a.key).toSet();
    final theme = Theme.of(context);

    final grouped = <String, List<AchievementDef>>{};
    for (final def in Achievements.all) {
      grouped.putIfAbsent(def.category, () => []).add(def);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('成就系統 (${unlocked.length}/${Achievements.all.length})'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.emoji_events, size: 14),
              label: Text('${unlocked.length}/${Achievements.all.length}',
                  style: const TextStyle(fontSize: 11)),
              backgroundColor: theme.colorScheme.tertiaryContainer,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProgressSummary(unlocked: unlocked.length, total: Achievements.all.length, theme: theme),
          const SizedBox(height: 16),
          ...grouped.entries.map((e) => _CategorySection(
            category: e.key,
            defs: e.value,
            unlocked: unlocked,
            provider: provider,
            theme: theme,
          )),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final int unlocked, total;
  final ThemeData theme;
  const _ProgressSummary({required this.unlocked, required this.total, required this.theme});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? unlocked / total : 0.0;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('你的成就進度', style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer)),
              Text('$unlocked 個已解鎖 · $total 個總計',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7))),
            ])),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: theme.colorScheme.onPrimaryContainer.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<AchievementDef> defs;
  final Set<String> unlocked;
  final AppProvider provider;
  final ThemeData theme;
  const _CategorySection({required this.category, required this.defs,
      required this.unlocked, required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    final unlockedDefs = defs.where((d) => unlocked.contains(d.key)).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(children: [
          Text(category, style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Text('$unlockedDefs/${defs.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6))),
        ]),
      ),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: defs.length,
        itemBuilder: (_, i) {
          final def = defs[i];
          final isUnlocked = unlocked.contains(def.key);
          final unlockedAt = isUnlocked
              ? provider.achievements
                  .firstWhere((a) => a.key == def.key)
                  .unlockedAt
              : null;
          return _AchievementTile(
              def: def, isUnlocked: isUnlocked, unlockedAt: unlockedAt, theme: theme);
        },
      ),
      const SizedBox(height: 16),
    ]);
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementDef def;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final ThemeData theme;
  const _AchievementTile({required this.def, required this.isUnlocked,
      required this.unlockedAt, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('${def.emoji} ${def.title}'),
          content: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(def.description),
            if (unlockedAt != null) ...[
              const SizedBox(height: 8),
              Text('解鎖時間：${_formatDate(unlockedAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
            if (!isUnlocked) ...[
              const SizedBox(height: 8),
              Text('尚未解鎖', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉'))],
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isUnlocked
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: isUnlocked
              ? Border.all(color: theme.colorScheme.primary.withOpacity(0.4))
              : Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(children: [
          Text(isUnlocked ? def.emoji : '🔒',
              style: TextStyle(fontSize: 20, color: isUnlocked ? null : Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(def.title, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.5))),
              Text(def.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10,
                      color: isUnlocked
                          ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.4))),
            ],
          )),
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}/${dt.month.toString().padLeft(2,'0')}/${dt.day.toString().padLeft(2,'0')}';
}
