import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/diary_entry.dart';
import '../../providers/app_provider.dart';

class VlogScreen extends StatefulWidget {
  const VlogScreen({super.key});

  @override
  State<VlogScreen> createState() => _VlogScreenState();
}

class _VlogScreenState extends State<VlogScreen> {
  String _searchQuery = '';
  String? _filterTag;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final vlogs = provider.recentVlogs.where((v) {
      final matchQuery = _searchQuery.isEmpty ||
          v.narrative.contains(_searchQuery) ||
          DateFormat('MM/dd').format(v.date).contains(_searchQuery);
      final matchTag = _filterTag == null || v.performanceTag == _filterTag;
      return matchQuery && matchTag;
    }).toList();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('時光 Vlog'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                SearchBar(
                  hintText: '搜尋日期或內容...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                  leading: const Icon(Icons.search, size: 20),
                  padding: const MaterialStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 12)),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      null, '卓越', '普通', '超標', '低落'
                    ].map((tag) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(tag ?? '全部'),
                        selected: _filterTag == tag,
                        onSelected: (_) =>
                            setState(() => _filterTag = _filterTag == tag ? null : tag),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: vlogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_collection_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('還沒有 Vlog',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('完成今日記錄後，可以生成你的第一個 Vlog',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      await provider.generateTodayVlog();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('今日 Vlog 已生成！')));
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('生成今日 Vlog'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vlogs.length,
              itemBuilder: (_, i) {
                final vlog = vlogs[i];
                return _VlogCard(vlog: vlog, theme: theme);
              },
            ),
    );
  }
}

class _VlogCard extends StatelessWidget {
  final VlogEntry vlog;
  final ThemeData theme;

  const _VlogCard({required this.vlog, required this.theme});

  Color _tagColor(String tag) {
    switch (tag) {
      case '卓越': return Colors.green;
      case '超標': return Colors.orange;
      case '低落': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _tagEmoji(String tag) {
    switch (tag) {
      case '卓越': return '🌟';
      case '超標': return '⚠️';
      case '低落': return '💙';
      default: return '📖';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = vlog.stats;
    final cal = (stats['calories'] as num?)?.round() ?? 0;
    final target = (stats['targetCalories'] as num?)?.round() ?? 0;
    final points = stats['goalPoints'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('MM/dd (E)', 'zh_TW').format(vlog.date),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tagColor(vlog.performanceTag).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_tagEmoji(vlog.performanceTag)} ${vlog.performanceTag}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _tagColor(vlog.performanceTag)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              vlog.narrative,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                  height: 1.6),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip('🔥 $cal/$target kcal', theme),
                const SizedBox(width: 8),
                _StatChip('⭐ $points 點', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _StatChip(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: theme.textTheme.labelSmall),
    );
  }
}
