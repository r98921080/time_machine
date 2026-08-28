import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Column(
      children: [
        TabBar(
          controller: _periodTab,
          tabs: const [Tab(text: '本週'), Tab(text: '本月')],
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
                        const SizedBox(height: 16),
                        ReportCard(
                          title: '✨ AI 週報',
                          report: _weeklyReport,
                          loading: _loadingWeekly,
                          onGenerate: () => _generateWeeklyReport(provider),
                          theme: theme,
                        ),
                        const SizedBox(height: 80),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  MonthlyHeatmap(provider: provider, theme: theme),
                  const SizedBox(height: 16),
                  ReportCard(
                    title: '📊 AI 月報',
                    report: _monthlyReport,
                    loading: _loadingMonthly,
                    onGenerate: () => _generateMonthlyReport(provider),
                    theme: theme,
                  ),
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

class MonthlyHeatmap extends StatefulWidget {
  final AppProvider provider;
  final ThemeData theme;
  const MonthlyHeatmap({super.key, required this.provider, required this.theme});

  @override
  State<MonthlyHeatmap> createState() => _MonthlyHeatmapState();
}

class _MonthlyHeatmapState extends State<MonthlyHeatmap> {
  Map<String, int> _heatmap = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseService.getGoalHeatmapData(
        widget.provider.profile!.id, 30);
    if (mounted) setState(() { _heatmap = data; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${now.month}月 目標打卡',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (!_loaded)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(daysInMonth, (i) {
                  final day = i + 1;
                  final key = '${now.year}-${now.month}-$day';
                  final count = _heatmap[key] ?? 0;
                  final color = count == 0
                      ? theme.colorScheme.surfaceContainerHighest
                      : count < 3
                          ? theme.colorScheme.primary.withOpacity(0.4)
                          : theme.colorScheme.primary;
                  return Tooltip(
                    message: '$day日：$count 次達成',
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6)),
                      child: Center(
                        child: Text('$day',
                            style: TextStyle(
                                fontSize: 10,
                                color: count > 0
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant)),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
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
