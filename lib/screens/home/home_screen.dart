import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/diary_entry.dart';
import '../../models/bonus_challenge.dart';
import '../knowledge/knowledge_screen.dart';
import '../diary/diary_screen.dart';
import '../vlog/vlog_screen.dart';
import 'stats_widgets.dart';
import '../../widgets/activity_ring.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDialogs());
  }

  void _checkDialogs() {
    final provider = context.read<AppProvider>();
    if (provider.loginRewardPending) _showLoginReward(provider);
    if (provider.proactiveMessage != null) _showProactiveMessage(provider);
  }

  void _showLoginReward(AppProvider provider) {
    provider.dismissLoginReward();
    final streak = provider.profile?.loginStreak ?? 1;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(streak % 7 == 0 ? '🎉' : '🔥',
              style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(streak % 7 == 0
              ? '連續登入 $streak 天！週期獎勵 +30 EXP'
              : '第 $streak 天登入！+5 EXP',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ]),
        actions: [FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('繼續'),
        )],
      ),
    );
  }

  void _showProactiveMessage(AppProvider provider) {
    final msg = provider.proactiveMessage;
    final name = provider.characterName;
    provider.clearProactiveMessage();
    if (msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$name：$msg'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(label: '回覆', onPressed: () {}),
    ));
  }

  void _showMorningIntentSheet(AppProvider provider) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(_).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🌅', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text('今天的意圖是什麼？',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('設定一個今天最重要的方向',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(
              hintText: '例如：保持專注，完成最重要的事',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) async {
              if (v.trim().isNotEmpty) {
                await provider.saveMorningIntent(v.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await provider.saveMorningIntent(ctrl.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('設定意圖'),
          ),
        ]),
      ),
    );
  }

  void _showMoodSheet(AppProvider provider) {
    final emojis = ['😞', '😔', '😐', '😊', '😄'];
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('今天的心情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () async {
                await provider.saveMoodEntry(MoodEntry(
                  profileId: provider.profile!.id,
                  date: DateTime.now(),
                  score: i + 1,
                  emoji: emojis[i],
                ));
                if (context.mounted) Navigator.pop(context);
              },
              child: Column(children: [
                Text(emojis[i], style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 4),
                Text('${i + 1}', style: const TextStyle(fontSize: 11)),
              ]),
            )),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showEnergySheet(AppProvider provider) {
    int selected = provider.todayEnergy?.score ?? 5;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('今天的精力', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$selected / 10', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Slider(
            value: selected.toDouble(),
            min: 1, max: 10, divisions: 9,
            onChanged: (v) => setSt(() => selected = v.round()),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('精疲力竭', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              Text('滿載能量', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await provider.saveEnergyEntry(EnergyEntry(
                profileId: provider.profile!.id,
                date: DateTime.now(),
                score: selected,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('記錄精力'),
          ),
        ]),
      )),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;
    if (profile == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? '早安' : hour < 18 ? '午安' : '晚安';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            snap: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('$greeting，${profile.nickname}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 48),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Chip(
                  avatar: const Icon(Icons.local_fire_department, size: 14),
                  label: Text('${profile.loginStreak}天',
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: theme.colorScheme.errorContainer,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              if (provider.achievements.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Chip(
                    avatar: const Icon(Icons.emoji_events, size: 14),
                    label: Text('${provider.achievements.length}',
                        style: const TextStyle(fontSize: 11)),
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
            bottom: TabBar(
              controller: _tab,
              tabs: const [Tab(text: '首頁'), Tab(text: '統計')],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _HomeTab(
              onMorningIntent: () => _showMorningIntentSheet(provider),
              onMood: () => _showMoodSheet(provider),
              onEnergy: () => _showEnergySheet(provider),
            ),
            const StatisticsTab(),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final VoidCallback onMorningIntent;
  final VoidCallback onMood;
  final VoidCallback onEnergy;
  const _HomeTab({required this.onMorningIntent, required this.onMood, required this.onEnergy});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile!;
    final target = profile.calculatedCalorieTarget;
    final current = provider.todayCalories;
    final caloriesRatio = target > 0 ? current / target : 0.0;
    final points = provider.todayGoalPoints;
    final maxPoints = 15.0;
    final goalsRatio = (points / maxPoints).clamp(0.0, 1.0);
    final streakRatio = (profile.loginStreak / 30).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // ── Activity Ring Hero ──────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(alignment: Alignment.center, children: [
                    ActivityRing(
                      caloriesProgress: caloriesRatio,
                      goalsProgress: goalsRatio,
                      streakProgress: streakRatio,
                      size: 140,
                    ),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('${current.round()}',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text('kcal', style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                    ]),
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RingLegend(color: const Color(0xFFFF375F),
                          label: '熱量', value: '${current.round()} / ${target.round()} kcal'),
                      const SizedBox(height: 8),
                      _RingLegend(color: const Color(0xFF30D158),
                          label: '目標', value: '$points pts'),
                      const SizedBox(height: 8),
                      _RingLegend(color: const Color(0xFF0A84FF),
                          label: '連續', value: '${profile.loginStreak} 天'),
                      const SizedBox(height: 12),
                      // Mood & Energy row
                      Row(children: [
                        _QuickPill(
                          icon: provider.todayMood?.emoji ?? '😊',
                          label: provider.todayMood != null
                              ? '${provider.todayMood!.score}/5'
                              : '記情緒',
                          onTap: onMood,
                          recorded: provider.todayMood != null,
                          theme: theme,
                        ),
                        const SizedBox(width: 6),
                        _QuickPill(
                          icon: '⚡',
                          label: provider.todayEnergy != null
                              ? '${provider.todayEnergy!.score}/10'
                              : '記精力',
                          onTap: onEnergy,
                          recorded: provider.todayEnergy != null,
                          theme: theme,
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Morning Intent ──────────────────────────────────────
        _MorningIntentCard(
          intent: profile.morningIntent,
          today: DateTime.now(),
          lastDate: profile.lastMorningIntentDate,
          onTap: onMorningIntent,
          theme: theme,
        ),
        const SizedBox(height: 10),

        // ── Water tracking ──────────────────────────────────────
        _WaterCard(provider: provider, theme: theme),
        const SizedBox(height: 10),

        // ── Bonus challenges ────────────────────────────────────
        if (provider.bonusChallenges.isNotEmpty) ...[
          _BonusChallengesCard(
              challenges: provider.bonusChallenges,
              provider: provider,
              theme: theme),
          const SizedBox(height: 10),
        ],

        // ── Vlog card ───────────────────────────────────────────
        _VlogCard(provider: provider, theme: theme),
        const SizedBox(height: 10),

        // ── One year ago ─────────────────────────────────────────
        _YearAgoCard(provider: provider, theme: theme),
        const SizedBox(height: 10),

        // ── Knowledge ──────────────────────────────────────────
        _KnowledgeTeaser(theme: theme),
        const SizedBox(height: 10),

        // ── Today diary summary ─────────────────────────────────
        _TodaySummaryCard(provider: provider, theme: theme),
      ],
    );
  }
}

class _RingLegend extends StatelessWidget {
  final Color color;
  final String label, value;
  const _RingLegend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      const SizedBox(width: 4),
      Expanded(child: Text(value,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class _QuickPill extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  final bool recorded;
  final ThemeData theme;
  const _QuickPill({required this.icon, required this.label, required this.onTap,
    required this.recorded, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: recorded
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: recorded
              ? Border.all(color: theme.colorScheme.primary.withOpacity(0.5))
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(
              fontSize: 11,
              color: recorded
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _MorningIntentCard extends StatelessWidget {
  final String? intent;
  final DateTime today;
  final String? lastDate;
  final VoidCallback onTap;
  final ThemeData theme;
  const _MorningIntentCard({required this.intent, required this.today,
      required this.lastDate, required this.onTap, required this.theme});

  bool get _isToday {
    if (lastDate == null) return false;
    final d = today;
    final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    return lastDate == key;
  }

  @override
  Widget build(BuildContext context) {
    final hasIntent = _isToday && (intent?.isNotEmpty == true);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: hasIntent
            ? theme.colorScheme.primaryContainer.withOpacity(0.6)
            : theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Text('🌅', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('晨間意圖', style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
                if (hasIntent)
                  Text(intent!, style: theme.textTheme.bodySmall)
                else
                  Text('點擊設定今天的方向', style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              ],
            )),
            if (!hasIntent)
              Icon(Icons.add_circle_outline,
                  color: theme.colorScheme.primary, size: 20),
          ]),
        ),
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final AppProvider provider;
  final ThemeData theme;
  const _WaterCard({required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    final ml = provider.waterMl;
    final target = 2000;
    final ratio = (ml / target).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const Text('💧', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Text('喝水記錄', style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
                Text('$ml / ${target}ml', style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF0A84FF)),
                ),
              ),
            ],
          )),
          const SizedBox(width: 8),
          Row(children: [
            _WaterBtn(ml: 150, provider: provider),
            const SizedBox(width: 4),
            _WaterBtn(ml: 250, provider: provider),
            const SizedBox(width: 4),
            _WaterBtn(ml: 500, provider: provider),
          ]),
        ]),
      ),
    );
  }
}

class _WaterBtn extends StatelessWidget {
  final int ml;
  final AppProvider provider;
  const _WaterBtn({required this.ml, required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => provider.addWaterMl(ml),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0A84FF).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('+${ml}ml',
            style: const TextStyle(fontSize: 10, color: Color(0xFF0A84FF),
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _VlogCard extends StatelessWidget {
  final AppProvider provider;
  final ThemeData theme;
  const _VlogCard({required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    final vlog = provider.todayVlog;
    final recent = provider.recentVlogs;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const VlogScreen())),
      child: Card(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.6),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('🎬', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('時光 Vlog', style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer)),
                const Spacer(),
                Text('${recent.length} 篇', style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer.withOpacity(0.7))),
                const Icon(Icons.chevron_right, size: 16),
              ]),
              if (vlog != null) ...[
                const SizedBox(height: 8),
                Text(vlog.displayTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer)),
                Text(vlog.displayNarrative,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer.withOpacity(0.8))),
              ] else ...[
                const SizedBox(height: 6),
                Text('今日 Vlog 尚未生成，點擊前往',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer.withOpacity(0.7))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _YearAgoCard extends StatefulWidget {
  final AppProvider provider;
  final ThemeData theme;
  const _YearAgoCard({required this.provider, required this.theme});

  @override
  State<_YearAgoCard> createState() => _YearAgoCardState();
}

class _YearAgoCardState extends State<_YearAgoCard> {
  bool _loading = true;
  String? _yearAgoText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vlog = await widget.provider.getVlogOneYearAgo();
    if (mounted) {
      setState(() {
        _yearAgoText = vlog?.displayNarrative;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _yearAgoText == null) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('⏰', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('一年前的今天', style: widget.theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
          ]),
          const SizedBox(height: 6),
          Text(_yearAgoText!, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: widget.theme.textTheme.bodySmall?.copyWith(
                  color: Colors.brown.shade600, fontStyle: FontStyle.italic)),
        ]),
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
          child: Row(children: [
            const Text('🧠', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('今日冷知識', style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer)),
              Text('點擊挑戰今天的知識題', style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer.withOpacity(0.7))),
            ])),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSecondaryContainer),
          ]),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🎯', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('今日 Bonus 挑戰', style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('$doneCount/${challenges.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 10),
          ...challenges.map((c) => GestureDetector(
            onTap: c.done ? null : () => provider.completeBonusChallenge(c.id),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(c.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20, color: c.done ? Colors.green : null),
                const SizedBox(width: 8),
                Text(_typeEmoji(c.type), style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Expanded(child: Text(c.title, style: theme.textTheme.bodySmall?.copyWith(
                    decoration: c.done ? TextDecoration.lineThrough : null,
                    color: c.done ? theme.colorScheme.onSurfaceVariant : null))),
                if (!c.done)
                  Text('+${c.points}', style: TextStyle(
                      fontSize: 11, color: Colors.green.shade700,
                      fontWeight: FontWeight.bold)),
              ]),
            ),
          )),
        ]),
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
    final diary = provider.todayDiary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('今日日記', style: theme.textTheme.titleSmall),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DiaryScreen())),
              child: Text(diary == null ? '+ 寫日記' : '編輯'),
            ),
          ]),
          if (diary != null) ...[
            if (diary.aiTitle?.isNotEmpty == true)
              Text('「${diary.aiTitle}」', style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic)),
            Text(diary.content, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ] else
            Text('今天有什麼想說的嗎？', style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}
