import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool _loading = false;
  bool _mindMapLoading = false;
  Map<String, String>? _result;
  String? _error;
  int _selectedDimension = 0;

  static const _dimensions = [
    ('情緒心理', '😊', 'emotions'),
    ('生活平衡', '⚖️', 'balance'),
    ('個人建議', '💡', 'advice'),
    ('目標洞見', '🎯', 'goalInsight'),
    ('成長亮點', '✨', 'growth'),
  ];

  Future<void> _showMindMap(AppProvider provider) async {
    setState(() => _mindMapLoading = true);
    try {
      final mindMap = await provider.generateMindMap();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => _MindMapDialog(mindMap: mindMap),
      );
    } finally {
      if (mounted) setState(() => _mindMapLoading = false);
    }
  }

  Future<void> _analyze(AppProvider provider) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await provider.performDeepLifeAnalysis();
      if (mounted) setState(() { _result = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '分析失敗：$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('深度探索'),
        actions: [
          _mindMapLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  icon: const Icon(Icons.account_tree_outlined),
                  tooltip: '今日心智圖',
                  onPressed: () => _showMindMap(provider),
                ),
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重新分析',
              onPressed: _loading ? null : () => _analyze(provider),
            ),
        ],
      ),
      body: _result == null
          ? _LandingView(loading: _loading, error: _error, onAnalyze: () => _analyze(provider), theme: theme)
          : _ResultView(
              result: _result!,
              selectedDimension: _selectedDimension,
              dimensions: _dimensions,
              onSelectDimension: (i) => setState(() => _selectedDimension = i),
              theme: theme,
            ),
    );
  }
}

class _LandingView extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onAnalyze;
  final ThemeData theme;
  const _LandingView({required this.loading, required this.error,
      required this.onAnalyze, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔭', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text('深度探索', style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'AI 將從五個維度深入分析你的生活狀態：\n情緒心理、生活平衡、個人建議、目標洞見、成長亮點',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (error != null) ...[
            Text(error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
            const SizedBox(height: 16),
          ],
          if (loading)
            const Column(children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI 正在深度分析中，請稍候…', style: TextStyle(fontSize: 13)),
            ])
          else
            FilledButton.icon(
              onPressed: onAnalyze,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('開始深度探索'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
            ),
          const SizedBox(height: 16),
          Text('分析需要約30-60秒，請耐心等待',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final Map<String, String> result;
  final int selectedDimension;
  final List<(String, String, String)> dimensions;
  final ValueChanged<int> onSelectDimension;
  final ThemeData theme;
  const _ResultView({required this.result, required this.selectedDimension,
      required this.dimensions, required this.onSelectDimension, required this.theme});

  @override
  Widget build(BuildContext context) {
    final dim = dimensions[selectedDimension];
    final content = result[dim.$3] ?? '暫無資料';

    return Column(children: [
      // Dimension selector
      SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: dimensions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final d = dimensions[i];
            final selected = i == selectedDimension;
            return GestureDetector(
              onTap: () => onSelectDimension(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: selected
                      ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                      : null,
                ),
                child: Text('${d.$2} ${d.$1}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant)),
              ),
            );
          },
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${dim.$2} ${dim.$1}',
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(content,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.7)),
            ),
          ]),
        ),
      ),
    ]);
  }
}

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
            Text('今日心智圖',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
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
          ...branches.map((b) {
            final label = b['label'] as String? ?? '';
            final nodes = (b['nodes'] as List?)?.cast<String>() ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 20, height: 2,
                      color: theme.colorScheme.primary.withOpacity(0.4)),
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
