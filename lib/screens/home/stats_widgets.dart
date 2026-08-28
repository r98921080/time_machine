import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../explore/explore_screen.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab>
    with SingleTickerProviderStateMixin {
  late TabController _periodTab;
  String? _weeklyReport;
  String? _monthlyReport;
  bool _loadingWeekly = false;
  bool _loadingMonthly = false;
  List<Map<String, dynamic>> _weeklyData = [];
  bool _dataLoaded = false;
  String? _moodCorrelation;
  bool _loadingCorrelation = false;

  @override
  void initState() {
    super.initState();
    _periodTab = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _periodTab.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<AppProvider>();
    final stats = await provider.getWeeklyStats();
    if (mounted) {
      setState(() {
        _weeklyData = List<Map<String, dynamic>>.from(
            stats['weeklyData'] as List? ?? []);
        _dataLoaded = true;
      });
    }
  }

  Future<void> _generateWeeklyReport(AppProvider provider) async {
    setState(() => _loadingWeekly = true);
    try {
      final report = await provider.generateWeeklyReport();
      if (mounted) setState(() => _weeklyReport = report);
    } finally {
      if (mounted) setState(() => _loadingWeekly = false);
    }
  }

  Future<void> _generateMonthlyReport(AppProvider provider) async {
    setState(() => _loadingMonthly = true);
    try {
      final report = await provider.generateMonthlyReport();
      if (mounted) setState(() => _monthlyReport = report);
    } finally {
      if (mounted) setState(() => _loadingMonthly = false);
    }
  }

  Future<void> _generateCorrelation(AppProvider provider) async {
    setState(() { _loadingCorrelation = true; _moodCorrelation = null; });
    try {
      final result = await provider.generateMoodCorrelation();
      if (mounted) setState(() => _moodCorrelation = result);
    } finally {
      if (mounted) setState(() => _loadingCorrelation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Column(
      children: [
        TabBar(
          controller: _periodTab,
          tabs: const [Tab(text: '本週'), Tab(text: '近3個月')],
          tabAlignment: TabAlignment.start,
          isScrollable: true,
        ),
        Expanded(
          child: TabBarView(
            controller: _periodTab,
            children: [
              _dataLoaded
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        WeeklyCalorieChart(
                            data: _weeklyData,
                            target: provider.profile?.calculatedCalorieTarget ?? 2000,
                            theme: theme),
                        const SizedBox(height: 12),
                        WeeklyNutritionBar(data: _weeklyData, theme: theme),
                        const SizedBox(height: 12),
                        _MoodCorrelationCard(
                          correlation: _moodCorrelation,
                          loading: _loadingCorrelation,
                          onGenerate: () => _generateCorrelation(provider),
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        ReportCard(
                          title: '✨ AI 週報',
                          report: _weeklyReport,
                          loading: _loadingWeekly,
                          onGenerate: () => _generateWeeklyReport(provider),
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _ExploreCard(theme: theme),
                        const SizedBox(height: 80),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  QuarterHeatmap(provider: provider, theme: theme),
                  const SizedBox(height: 16),
                  ReportCard(
                    title: '📊 AI 月報',
                    report: _monthlyReport,
                    loading: _loadingMonthly,
                    onGenerate: () => _generateMonthlyReport(provider),
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _ExploreCard(theme: theme),
                  const SizedBox(height: 80),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Explore CTA ───────────────────────────────────────────────────

class _ExploreCard extends StatelessWidget {
  final ThemeData theme;
  const _ExploreCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ExploreScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B67CA), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Text('🔭', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('深度探索',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('AI 從五個維度深入分析你的生活狀態',
                  style: TextStyle(color: Colors.white.withOpacity(0.85),
                      fontSize: 12)),
            ],
          )),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ]),
      ),
    );
  }
}

// ── Mood-Goal Correlation ─────────────────────────────────────────

class _MoodCorrelationCard extends StatelessWidget {
  final String? correlation;
  final bool loading;
  final VoidCallback onGenerate;
  final ThemeData theme;
  const _MoodCorrelationCard({required this.correlation,
      required this.loading, required this.onGenerate, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🔗', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('情緒 × 目標關聯洞見',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          if (loading)
            const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator()))
          else if (correlation != null && correlation!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(correlation!,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.65)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('重新分析'),
                onPressed: onGenerate,
              ),
            ),
          ] else
            Center(
              child: OutlinedButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('分析情緒與目標關聯'),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Weekly Chart ──────────────────────────────────────────────────

class WeeklyCalorieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final double target;
  final ThemeData theme;
  const WeeklyCalorieChart(
      {super.key, required this.data, required this.target, required this.theme});

  @override
  Widget build(BuildContext context) {
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本週熱量',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.asMap().entries.map((e) {
                  final idx = e.key;
                  final d = e.value;
                  final cal = (d['calories'] as double?) ?? 0;
                  final ratio = target > 0
                      ? (cal / target).clamp(0.0, 1.3)
                      : 0.0;
                  final isOver = cal > target * 1.05;
                  final color = cal == 0
                      ? theme.colorScheme.surfaceContainerHighest
                      : isOver
                          ? Colors.orange
                          : theme.colorScheme.primary;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (cal > 0)
                            Text('${cal.round()}',
                                style: const TextStyle(fontSize: 8),
                                textAlign: TextAlign.center),
                          const SizedBox(height: 2),
                          Container(
                            height: (ratio * 90).clamp(4.0, 100.0),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(days[idx % 7],
                              style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('達標', style: theme.textTheme.labelSmall),
              const SizedBox(width: 12),
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('超標', style: theme.textTheme.labelSmall),
            ]),
          ],
        ),
      ),
    );
  }
}

class WeeklyNutritionBar extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final ThemeData theme;
  const WeeklyNutritionBar({super.key, required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final avgP = data.isEmpty ? 0.0 :
        data.fold<double>(0, (s, d) => s + (d['protein'] as double? ?? 0)) / data.length;
    final avgC = data.isEmpty ? 0.0 :
        data.fold<double>(0, (s, d) => s + (d['carbs'] as double? ?? 0)) / data.length;
    final avgF = data.isEmpty ? 0.0 :
        data.fold<double>(0, (s, d) => s + (d['fat'] as double? ?? 0)) / data.length;
    final total = avgP + avgC + avgF;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('平均營養素',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _NutritionRow('蛋白質', avgP, total, Colors.blue, theme),
            const SizedBox(height: 6),
            _NutritionRow('碳水', avgC, total, Colors.amber, theme),
            const SizedBox(height: 6),
            _NutritionRow('脂肪', avgF, total, Colors.red, theme),
          ],
        ),
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final double value, total;
  final Color color;
  final ThemeData theme;
  const _NutritionRow(this.label, this.value, this.total, this.color, this.theme);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(width: 44, child: Text(label, style: theme.textTheme.labelSmall)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${value.round()}g', style: theme.textTheme.labelSmall),
      ],
    );
  }
}

// ── 3-Month Heatmap ────────────────────────────────────────────────

class QuarterHeatmap extends StatefulWidget {
  final AppProvider provider;
  final ThemeData theme;
  const QuarterHeatmap({super.key, required this.provider, required this.theme});

  @override
  State<QuarterHeatmap> createState() => _QuarterHeatmapState();
}

class _QuarterHeatmapState extends State<QuarterHeatmap> {
  Map<String, int> _heatmap = {};
  bool _loaded = false;
  static const _cellSize = 12.0;
  static const _gap = 3.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.provider.getHeatmap3Months();
    if (mounted) setState(() { _heatmap = data; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final now = DateTime.now();

    // Build 91-day grid aligned to weeks (cols = weeks, rows = days Sun-Sat)
    final startDate = now.subtract(const Duration(days: 90));
    // Align to Sunday
    final gridStart = startDate.subtract(Duration(days: startDate.weekday % 7));
    final totalDays = now.difference(gridStart).inDays + 1;
    final cols = (totalDays / 7).ceil();

    // Month labels: collect which column each month starts at
    final monthLabels = <int, String>{};
    for (int c = 0; c < cols; c++) {
      final d = gridStart.add(Duration(days: c * 7));
      if (d.day <= 7) {
        monthLabels[c] = _monthAbbr(d.month);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('近3個月 目標打卡',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              _Legend(theme: theme),
            ]),
            const SizedBox(height: 10),
            if (!_loaded)
              const Center(child: CircularProgressIndicator())
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month labels row
                    SizedBox(
                      height: 14,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(cols, (c) {
                          return SizedBox(
                            width: _cellSize + _gap,
                            child: monthLabels.containsKey(c)
                                ? Text(monthLabels[c]!,
                                    style: TextStyle(fontSize: 9,
                                        color: theme.colorScheme.onSurfaceVariant))
                                : null,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(cols, (c) {
                        return Column(
                          children: List.generate(7, (r) {
                            final d = gridStart.add(Duration(days: c * 7 + r));
                            if (d.isAfter(now)) {
                              return _cell(0, false, theme);
                            }
                            final isFuture = d.isAfter(now);
                            final key = '${d.year}-${d.month}-${d.day}';
                            final count = _heatmap[key] ?? 0;
                            return Tooltip(
                              message: '${d.month}/${d.day}: $count 次',
                              child: _cell(count, !isFuture, theme),
                            );
                          }),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Summary stats
            if (_loaded) _HeatmapStats(heatmap: _heatmap, theme: theme),
          ],
        ),
      ),
    );
  }

  Widget _cell(int count, bool inRange, ThemeData theme) {
    Color color;
    if (!inRange || count == 0) {
      color = theme.colorScheme.surfaceContainerHighest;
    } else if (count == 1) {
      color = theme.colorScheme.primary.withOpacity(0.25);
    } else if (count <= 3) {
      color = theme.colorScheme.primary.withOpacity(0.55);
    } else {
      color = theme.colorScheme.primary;
    }
    return Container(
      width: _cellSize,
      height: _cellSize,
      margin: const EdgeInsets.all(_gap / 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _monthAbbr(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _Legend extends StatelessWidget {
  final ThemeData theme;
  const _Legend({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('少', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(width: 3),
      ...([0.0, 0.25, 0.55, 1.0].map((o) => Container(
        width: 10, height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: o == 0
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.primary.withOpacity(o),
          borderRadius: BorderRadius.circular(2),
        ),
      ))),
      const SizedBox(width: 3),
      Text('多', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _HeatmapStats extends StatelessWidget {
  final Map<String, int> heatmap;
  final ThemeData theme;
  const _HeatmapStats({required this.heatmap, required this.theme});

  @override
  Widget build(BuildContext context) {
    int activeDays = 0, maxStreak = 0, curStreak = 0;
    final now = DateTime.now();

    for (int i = 90; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.year}-${d.month}-${d.day}';
      final count = heatmap[key] ?? 0;
      if (count > 0) {
        activeDays++;
        curStreak++;
        maxStreak = math.max(maxStreak, curStreak);
      } else {
        curStreak = 0;
      }
    }

    return Row(children: [
      _StatChip('📅 活躍天數', '$activeDays 天', theme),
      const SizedBox(width: 8),
      _StatChip('🔥 最長連續', '$maxStreak 天', theme),
      const SizedBox(width: 8),
      _StatChip('✅ 達成率', '${activeDays > 0 ? (activeDays * 100 ~/ 91) : 0}%', theme),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final ThemeData theme;
  const _StatChip(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary)),
        Text(label, style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class ReportCard extends StatelessWidget {
  final String title;
  final String? report;
  final bool loading;
  final VoidCallback onGenerate;
  final ThemeData theme;
  const ReportCard({
    super.key,
    required this.title,
    required this.report,
    required this.loading,
    required this.onGenerate,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator()))
            else if (report != null)
              Text(report!, style: theme.textTheme.bodySmall?.copyWith(height: 1.7))
            else
              Center(
                child: OutlinedButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('AI 生成報告'),
                ),
              ),
            if (report != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('重新生成'),
                  onPressed: onGenerate,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
