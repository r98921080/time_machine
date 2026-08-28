import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/diary_entry.dart';
import '../../models/bonus_challenge.dart';
import '../knowledge/knowledge_screen.dart';
import '../diary/diary_screen.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;
    if (profile == null) return const SizedBox.shrink();

    final target = profile.calculatedCalorieTarget;
    final current = provider.todayCalories;
    final ratio = target > 0 ? (current / target).clamp(0.0, 1.2) : 0.0;
    final points = provider.todayGoalPoints;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('早安，${profile.nickname}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  avatar: const Icon(Icons.local_fire_department, size: 16),
                  label: Text('${profile.streak} 天',
                      style: const TextStyle(fontSize: 12)),
                  backgroundColor: theme.colorScheme.errorContainer,
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Calorie Progress Card
                _CalorieCard(current: current, target: target, ratio: ratio, theme: theme),
                const SizedBox(height: 12),
                // Growth Points + Goal Points Row
                Row(children: [
                  Expanded(child: _StatMiniCard(
                    icon: Icons.star, color: Colors.amber,
                    label: '成長點數', value: '${profile.growthPoints}', theme: theme)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatMiniCard(
                    icon: Icons.track_changes, color: Colors.green,
                    label: '今日目標點', value: '$points', theme: theme)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatMiniCard(
                    icon: Icons.local_fire_department, color: Colors.orange,
                    label: '蛋白質', value: '${provider.todayProtein.round()}g', theme: theme)),
                ]),
                const SizedBox(height: 16),
                // Bonus Challenges
                if (provider.bonusChallenges.isNotEmpty) ...[
                  _BonusChallengesCard(
                      challenges: provider.bonusChallenges,
                      provider: provider,
                      theme: theme),
                  const SizedBox(height: 12),
                ],
                // Daily Knowledge Card
                _KnowledgeTeaser(theme: theme),
                const SizedBox(height: 12),
                // Shop Teaser
                _ShopTeaser(points: profile.growthPoints, theme: theme),
                const SizedBox(height: 12),
                // Today Vlog / Diary
                _TodaySummaryCard(provider: provider, theme: theme),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieCard extends StatelessWidget {
  final double current, target, ratio;
  final ThemeData theme;
  const _CalorieCard({required this.current, required this.target,
      required this.ratio, required this.theme});

  @override
  Widget build(BuildContext context) {
    final overflow = ratio > 1.0;
    Color barColor = overflow
        ? theme.colorScheme.error
        : ratio > 0.85
            ? const Color(0xFFF59E0B)
            : theme.colorScheme.primary;
    final remaining = target - current;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('今日熱量', style: theme.textTheme.titleSmall),
                Text(
                  overflow
                      ? '超出 ${(-remaining).round()} kcal'
                      : '剩 ${remaining.round()} kcal',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: overflow ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${current.round()}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: barColor),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('/ ${target.round()} kcal',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final ThemeData theme;
  const _StatMiniCard({required this.icon, required this.color,
      required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeTeaser extends StatelessWidget {
  final ThemeData theme;
  const _KnowledgeTeaser({required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const KnowledgeScreen())),
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('今日冷知識',
                        style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer)),
                    Text('點擊挑戰今天的知識題',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer
                                .withOpacity(0.7))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSecondaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopTeaser extends StatelessWidget {
  final int points;
  final ThemeData theme;
  const _ShopTeaser({required this.points, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ShopScreen())),
      child: Card(
        color: theme.colorScheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Text('🛍️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('成長商店',
                        style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onTertiaryContainer)),
                    Text('你有 $points 點可以使用',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer
                                .withOpacity(0.75))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onTertiaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _BonusChallengesCard extends StatelessWidget {
  final List<BonusChallenge> challenges;
  final AppProvider provider;
  final ThemeData theme;
  const _BonusChallengesCard(
      {required this.challenges, required this.provider, required this.theme});

  String _typeEmoji(String type) {
    switch (type) {
      case 'physical': return '🏃';
      case 'dietary': return '🥗';
      case 'emotional': return '💬';
      default: return '⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = challenges.where((c) => c.done).length;
    return Card(
      color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('今日 Bonus 挑戰',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onTertiaryContainer)),
                const Spacer(),
                Text('$doneCount/${challenges.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer
                            .withOpacity(0.7))),
              ],
            ),
            const SizedBox(height: 10),
            ...challenges.map((c) => GestureDetector(
                  onTap: c.done ? null : () => provider.completeBonusChallenge(c.id),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          c.done ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 20,
                          color: c.done
                              ? Colors.green
                              : theme.colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(_typeEmoji(c.type),
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            c.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: c.done
                                  ? theme.colorScheme.onTertiaryContainer
                                      .withOpacity(0.5)
                                  : theme.colorScheme.onTertiaryContainer,
                              decoration: c.done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (!c.done)
                          Text('+${c.points}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  final AppProvider provider;
  final ThemeData theme;
  const _TodaySummaryCard({required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    final vlog = provider.todayVlog;
    final diary = provider.todayDiary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('今日記錄', style: theme.textTheme.titleSmall),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DiaryScreen())),
                  child: Text(diary == null ? '+ 寫日記' : '編輯'),
                ),
              ],
            ),
            if (diary != null) ...[
              Text(diary.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
            ],
            if (vlog != null) ...[
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.play_circle_outline,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('今日 Vlog 已生成',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary)),
              ]),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () async {
                  await provider.generateTodayVlog();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('今日 Vlog 已生成！')));
                  }
                },
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('生成今日 Vlog'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
