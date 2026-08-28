import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/diary_entry.dart';
import '../../providers/app_provider.dart';

class VlogScreen extends StatefulWidget {
  const VlogScreen({super.key});

  @override
  State<VlogScreen> createState() => _VlogScreenState();
}

class _VlogScreenState extends State<VlogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('時光 Vlog'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: '今日'),
            Tab(icon: Icon(Icons.history), text: '歷史'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _TodayVlogTab(),
          _HistoryVlogTab(),
        ],
      ),
    );
  }
}

// ── Today Tab ───────────────────────────────────────────────────

class _TodayVlogTab extends StatefulWidget {
  const _TodayVlogTab();

  @override
  State<_TodayVlogTab> createState() => _TodayVlogTabState();
}

class _TodayVlogTabState extends State<_TodayVlogTab> {
  bool _generating = false;
  final _picker = ImagePicker();

  Future<void> _generate(AppProvider provider) async {
    setState(() => _generating = true);
    try {
      final ok = await provider.generateTodayVlog();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ 今日 Vlog 已生成！' : '⚠️ 生成失敗，請稍後再試'),
        backgroundColor: ok ? Colors.green.shade700 : Colors.orange.shade700,
      ));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _addPhoto(AppProvider provider, VlogEntry vlog) async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    final updated = vlog.copyWith(
        photoPaths: [...vlog.photoPaths, picked.path]);
    await provider.updateVlogEdit(updated);
  }

  Future<void> _removePhoto(AppProvider provider, VlogEntry vlog, int idx) async {
    final paths = List<String>.from(vlog.photoPaths)..removeAt(idx);
    await provider.updateVlogEdit(vlog.copyWith(photoPaths: paths));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final vlog = provider.todayVlog;
    final now = DateTime.now();

    if (vlog == null) {
      return _EmptyTodayVlog(
          generating: _generating, onGenerate: () => _generate(provider));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header ───────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${now.year}年${now.month}月${now.day}日',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  _PerformanceChip(tag: vlog.performanceTag, theme: theme),
                ],
              ),
            ),
            TextButton.icon(
              icon: _generating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 16),
              label: Text(_generating ? '生成中…' : '重新生成'),
              onPressed: _generating ? null : () => _generate(provider),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Photo Strip ──────────────────────────────────────
        _PhotoStrip(
          vlog: vlog,
          onAdd: vlog.photoPaths.length < 5
              ? () => _addPhoto(provider, vlog)
              : null,
          onRemove: (i) => _removePhoto(provider, vlog, i),
        ),
        const SizedBox(height: 16),

        // ── Narrative ────────────────────────────────────────
        _NarrativeCard(vlog: vlog, provider: provider, theme: theme),
        const SizedBox(height: 16),

        // ── Stats ────────────────────────────────────────────
        _StatsRow(vlog: vlog, theme: theme),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _EmptyTodayVlog extends StatelessWidget {
  final bool generating;
  final VoidCallback onGenerate;
  const _EmptyTodayVlog({required this.generating, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_collection_outlined,
                size: 72,
                color: theme.colorScheme.primary.withOpacity(0.4)),
            const SizedBox(height: 24),
            Text('今天的 Vlog 還沒生成',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('AI 會根據你今天的記錄、日記和飲食\n幫你寫下今天的故事',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: generating ? null : onGenerate,
              icon: generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(generating ? '生成中…' : '生成今日 Vlog'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  final VlogEntry vlog;
  final VoidCallback? onAdd;
  final void Function(int) onRemove;
  const _PhotoStrip(
      {required this.vlog, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...vlog.photoPaths.asMap().entries.map((e) {
            final idx = e.key;
            final path = e.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: File(path).existsSync()
                        ? Image.file(File(path),
                            width: 90, height: 110, fit: BoxFit.cover)
                        : Container(
                            width: 90,
                            height: 110,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image)),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(idx),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (onAdd != null)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 90,
                height: 110,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: theme.colorScheme.primary, size: 28),
                    const SizedBox(height: 4),
                    Text('加照片',
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NarrativeCard extends StatefulWidget {
  final VlogEntry vlog;
  final AppProvider provider;
  final ThemeData theme;
  const _NarrativeCard(
      {required this.vlog, required this.provider, required this.theme});

  @override
  State<_NarrativeCard> createState() => _NarrativeCardState();
}

class _NarrativeCardState extends State<_NarrativeCard> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.vlog.displayNarrative);
  }

  @override
  void didUpdateWidget(_NarrativeCard old) {
    super.didUpdateWidget(old);
    if (!_editing) {
      _ctrl.text = widget.vlog.displayNarrative;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated =
        widget.vlog.copyWith(editedNarrative: _ctrl.text.trim());
    await widget.provider.updateVlogEdit(updated);
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('今日故事',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (!_editing)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: '編輯',
                    onPressed: () => setState(() => _editing = true),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_editing) ...[
              TextField(
                controller: _ctrl,
                maxLines: null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _editing = false),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('儲存'),
                  ),
                ],
              ),
            ] else
              Text(
                widget.vlog.displayNarrative,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final VlogEntry vlog;
  final ThemeData theme;
  const _StatsRow({required this.vlog, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cal = (vlog.stats['calories'] as num?)?.round() ?? 0;
    final target = (vlog.stats['targetCalories'] as num?)?.round() ?? 0;
    final pts = (vlog.stats['goalPoints'] as num?)?.round() ?? 0;
    return Row(
      children: [
        Expanded(
            child: _MiniStat(
                icon: '🔥', label: '熱量', value: '$cal / $target kcal',
                theme: theme)),
        const SizedBox(width: 8),
        Expanded(
            child: _MiniStat(
                icon: '🎯', label: '目標點', value: '$pts 點', theme: theme)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String icon, label, value;
  final ThemeData theme;
  const _MiniStat(
      {required this.icon, required this.label, required this.value,
       required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  Text(value,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceChip extends StatelessWidget {
  final String tag;
  final ThemeData theme;
  const _PerformanceChip({required this.tag, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = tag == '卓越'
        ? Colors.green
        : tag == '超標'
            ? Colors.orange
            : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Text(tag,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

// ── History Tab ──────────────────────────────────────────────────

class _HistoryVlogTab extends StatelessWidget {
  const _HistoryVlogTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final vlogs = provider.recentVlogs;

    if (vlogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('還沒有 Vlog 記錄',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('到「今日」分頁生成第一篇',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    // Group by month
    final Map<String, List<VlogEntry>> grouped = {};
    for (final v in vlogs) {
      final key = '${v.date.year}年${v.date.month}月';
      grouped.putIfAbsent(key, () => []).add(v);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(entry.key,
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)),
            ),
            ...entry.value.map((vlog) => _HistoryCard(
                vlog: vlog, theme: theme,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => _VlogDetailPage(vlog: vlog))))),
          ],
        );
      }).toList(),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final VlogEntry vlog;
  final ThemeData theme;
  final VoidCallback onTap;
  const _HistoryCard(
      {required this.vlog, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = vlog.date;
    final dateStr =
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    final summary = vlog.displayNarrative.length > 60
        ? '${vlog.displayNarrative.substring(0, 60)}…'
        : vlog.displayNarrative;
    final hasPhoto = vlog.photoPaths.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            if (hasPhoto && File(vlog.photoPaths.first).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(vlog.photoPaths.first),
                    width: 56, height: 56, fit: BoxFit.cover),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text('📅',
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(dateStr,
                          style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _PerformanceChip(
                          tag: vlog.performanceTag, theme: theme),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(summary,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Vlog Detail Page (history entry full view) ──────────────────

class _VlogDetailPage extends StatefulWidget {
  final VlogEntry vlog;
  const _VlogDetailPage({required this.vlog});

  @override
  State<_VlogDetailPage> createState() => _VlogDetailPageState();
}

class _VlogDetailPageState extends State<_VlogDetailPage> {
  late VlogEntry _vlog;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _vlog = widget.vlog;
  }

  Future<void> _addPhoto(AppProvider provider) async {
    if (_vlog.photoPaths.length >= 5) return;
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    final updated = _vlog.copyWith(
        photoPaths: [..._vlog.photoPaths, picked.path]);
    await provider.updateVlogEdit(updated);
    setState(() => _vlog = updated);
  }

  Future<void> _removePhoto(AppProvider provider, int idx) async {
    final paths = List<String>.from(_vlog.photoPaths)..removeAt(idx);
    final updated = _vlog.copyWith(photoPaths: paths);
    await provider.updateVlogEdit(updated);
    setState(() => _vlog = updated);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final theme = Theme.of(context);
    final d = _vlog.date;
    return Scaffold(
      appBar: AppBar(
        title: Text('${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _PerformanceChip(tag: _vlog.performanceTag, theme: theme),
          ]),
          const SizedBox(height: 12),
          _PhotoStrip(
            vlog: _vlog,
            onAdd: _vlog.photoPaths.length < 5
                ? () => _addPhoto(provider)
                : null,
            onRemove: (i) => _removePhoto(provider, i),
          ),
          const SizedBox(height: 16),
          _NarrativeCard(vlog: _vlog, provider: provider, theme: theme),
          const SizedBox(height: 16),
          _StatsRow(vlog: _vlog, theme: theme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
