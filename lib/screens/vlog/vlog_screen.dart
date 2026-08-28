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
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            title: const Text('時光 Vlog'),
            floating: true,
            snap: true,
            bottom: TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: '今日'),
                Tab(text: '回憶'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: const [
            _TodayVlogTab(),
            _HistoryVlogTab(),
          ],
        ),
      ),
    );
  }
}

// ── Colors by performance ────────────────────────────────────────

Map<String, List<Color>> _perfGradient(String tag) {
  switch (tag) {
    case '卓越':
      return {'gradient': [const Color(0xFF1DB954), const Color(0xFF0A7A3A)]};
    case '超標':
      return {'gradient': [const Color(0xFFFF9500), const Color(0xFFCC5200)]};
    default:
      return {'gradient': [const Color(0xFF636EB0), const Color(0xFF3A4080)]};
  }
}

Color _perfAccent(String tag) {
  switch (tag) {
    case '卓越':  return const Color(0xFF1DB954);
    case '超標':  return const Color(0xFFFF9500);
    default:      return const Color(0xFF636EB0);
  }
}

String _perfEmoji(String tag) {
  switch (tag) {
    case '卓越':  return '🌟';
    case '超標':  return '🔥';
    default:      return '💙';
  }
}

// ── Today Tab ─────────────────────────────────────────────────────

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
      await provider.generateTodayVlog();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今日 Vlog 已生成 ✨'),
            backgroundColor: Color(0xFF1DB954)));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _addPhoto(AppProvider provider, VlogEntry vlog) async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    await provider.updateVlogEdit(
        vlog.copyWith(photoPaths: [...vlog.photoPaths, picked.path]));
  }

  Future<void> _removePhoto(AppProvider provider, VlogEntry vlog, int idx) async {
    final paths = List<String>.from(vlog.photoPaths)..removeAt(idx);
    await provider.updateVlogEdit(vlog.copyWith(photoPaths: paths));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final vlog = provider.todayVlog;

    if (vlog == null) {
      return _EmptyState(generating: _generating, onGenerate: () => _generate(provider));
    }

    return _VlogArticle(
      vlog: vlog,
      isToday: true,
      generating: _generating,
      onRegenerate: () => _generate(provider),
      onAddPhoto: vlog.photoPaths.length < 5 ? () => _addPhoto(provider, vlog) : null,
      onRemovePhoto: (i) => _removePhoto(provider, vlog, i),
      provider: provider,
    );
  }
}

// ── Vlog Article View (shared by today + detail) ──────────────────

class _VlogArticle extends StatefulWidget {
  final VlogEntry vlog;
  final bool isToday;
  final bool generating;
  final VoidCallback? onRegenerate;
  final VoidCallback? onAddPhoto;
  final void Function(int)? onRemovePhoto;
  final AppProvider provider;
  const _VlogArticle({required this.vlog, required this.isToday,
    required this.generating, this.onRegenerate, this.onAddPhoto, this.onRemovePhoto,
    required this.provider});

  @override
  State<_VlogArticle> createState() => _VlogArticleState();
}

class _VlogArticleState extends State<_VlogArticle> {
  bool _editing = false;
  late TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.vlog.displayNarrative);
  }

  @override
  void didUpdateWidget(_VlogArticle old) {
    super.didUpdateWidget(old);
    if (!_editing) _editCtrl.text = widget.vlog.displayNarrative;
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    await widget.provider.updateVlogEdit(
        widget.vlog.copyWith(editedNarrative: _editCtrl.text.trim()));
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vlog = widget.vlog;
    final colors = _perfGradient(vlog.performanceTag)['gradient']!;
    final accent = _perfAccent(vlog.performanceTag);
    final emoji = _perfEmoji(vlog.performanceTag);
    final d = vlog.date;
    final dateLabel =
        '${d.year}年${d.month}月${d.day}日 ${['一','二','三','四','五','六','日'][d.weekday - 1]}';
    final cal = (vlog.stats['calories'] as num?)?.round() ?? 0;
    final target = (vlog.stats['targetCalories'] as num?)?.round() ?? 0;
    final pts = (vlog.stats['goalPoints'] as num?)?.round() ?? 0;

    return CustomScrollView(
      slivers: [
        // ── Hero Banner ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: Stack(children: [
              // Background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.07,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8, childAspectRatio: 1),
                    itemCount: 64,
                    itemBuilder: (_, i) => Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 0.3)),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(emoji, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(vlog.performanceTag,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                      const Spacer(),
                      if (widget.isToday && widget.onRegenerate != null)
                        GestureDetector(
                          onTap: widget.generating ? null : widget.onRegenerate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              widget.generating
                                  ? const SizedBox(width: 12, height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.refresh, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(widget.generating ? '生成中' : '重新生成',
                                  style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ]),
                          ),
                        ),
                    ]),
                    const Spacer(),
                    // AI Title
                    if (vlog.aiTitle?.isNotEmpty == true) ...[
                      Text('「${vlog.aiTitle}」',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black26)])),
                      const SizedBox(height: 4),
                    ],
                    Text(dateLabel,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    // Stats pills
                    Row(children: [
                      _StatsPill(icon: '🔥', label: '$cal kcal'),
                      const SizedBox(width: 8),
                      _StatsPill(icon: '🎯', label: '$pts pts'),
                      const SizedBox(width: 8),
                      if (target > 0)
                        _StatsPill(
                          icon: cal <= target ? '✅' : '⚠️',
                          label: cal <= target
                              ? '達標 ${(cal * 100 / target).round()}%'
                              : '超標 ${((cal - target) / target * 100).round()}%',
                        ),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        ),

        // ── Photos ──────────────────────────────────────────
        if (vlog.photoPaths.isNotEmpty || widget.onAddPhoto != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _PhotoStrip(
                vlog: vlog,
                accent: accent,
                onAdd: widget.onAddPhoto,
                onRemove: widget.onRemovePhoto,
              ),
            ),
          ),

        // ── Narrative ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 3, height: 18,
                    decoration: BoxDecoration(
                        color: accent, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('今日故事', style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
                const Spacer(),
                if (!_editing)
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 18, color: accent),
                    onPressed: () => setState(() => _editing = true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ]),
              const SizedBox(height: 12),
              if (_editing) ...[
                TextField(
                  controller: _editCtrl,
                  maxLines: null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accent, width: 2)),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: () => setState(() => _editing = false),
                      child: const Text('取消')),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _saveEdit, child: const Text('儲存')),
                ]),
              ] else
                Text(
                  vlog.displayNarrative,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.85,
                      letterSpacing: 0.3,
                      color: theme.colorScheme.onSurface),
                ),
            ]),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _StatsPill extends StatelessWidget {
  final String icon, label;
  const _StatsPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text('$icon $label',
        style: const TextStyle(color: Colors.white, fontSize: 11,
            fontWeight: FontWeight.w500)),
  );
}

class _PhotoStrip extends StatelessWidget {
  final VlogEntry vlog;
  final Color accent;
  final VoidCallback? onAdd;
  final void Function(int)? onRemove;
  const _PhotoStrip({required this.vlog, required this.accent, this.onAdd, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...vlog.photoPaths.asMap().entries.map((e) {
            final idx = e.key;
            final path = e.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: File(path).existsSync()
                      ? Image.file(File(path), width: 90, height: 100, fit: BoxFit.cover)
                      : Container(
                          width: 90, height: 100,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image)),
                ),
                if (onRemove != null)
                  Positioned(top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove!(idx),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ]),
            );
          }),
          if (onAdd != null)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 90, height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withOpacity(0.5), width: 1.5,
                      style: BorderStyle.solid),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_photo_alternate_outlined, color: accent, size: 26),
                  const SizedBox(height: 4),
                  Text('加照片', style: TextStyle(fontSize: 10, color: accent)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool generating;
  final VoidCallback onGenerate;
  const _EmptyState({required this.generating, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.video_collection_outlined,
                  size: 44, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('今天的故事還沒寫', style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('AI 會根據你今天的飲食、目標和日記\n自動撰寫今日故事',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, height: 1.6)),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: generating ? null : onGenerate,
              icon: generating
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(generating ? 'AI 正在撰寫中…' : '生成今日 Vlog'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────

class _HistoryVlogTab extends StatelessWidget {
  const _HistoryVlogTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final vlogs = provider.recentVlogs;

    if (vlogs.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.auto_stories_outlined, size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text('還沒有 Vlog 記錄', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('到「今日」分頁生成第一篇',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ]));
    }

    // Group by month
    final Map<String, List<VlogEntry>> grouped = {};
    for (final v in vlogs) {
      final key = '${v.date.year}年${v.date.month}月';
      grouped.putIfAbsent(key, () => []).add(v);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text('共 ${vlogs.length} 篇時光記錄',
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
        ...grouped.entries.expand((entry) => [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(children: [
              Container(width: 3, height: 14,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(entry.key, style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              const SizedBox(width: 8),
              Text('${entry.value.length} 篇',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ),
          ...entry.value.map((vlog) => _HistoryCard(
            vlog: vlog, theme: theme,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => _VlogDetailPage(vlog: vlog))),
          )),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final VlogEntry vlog;
  final ThemeData theme;
  final VoidCallback onTap;
  const _HistoryCard({required this.vlog, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = vlog.date;
    final accent = _perfAccent(vlog.performanceTag);
    final emoji = _perfEmoji(vlog.performanceTag);
    final hasPhoto = vlog.photoPaths.isNotEmpty && File(vlog.photoPaths.first).existsSync();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Date column
          SizedBox(
            width: 44,
            child: Column(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${d.day}', style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold, color: accent)),
                  Text(['一','二','三','四','五','六','日'][d.weekday - 1],
                      style: TextStyle(fontSize: 9, color: accent.withOpacity(0.7))),
                ]),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          // Card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: accent, width: 3)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(emoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(vlog.performanceTag,
                            style: TextStyle(fontSize: 11, color: accent,
                                fontWeight: FontWeight.bold)),
                        if (vlog.aiTitle?.isNotEmpty == true) ...[
                          const SizedBox(width: 8),
                          Expanded(child: Text('「${vlog.aiTitle}」',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic))),
                        ],
                      ]),
                      const SizedBox(height: 4),
                      Text(vlog.displayNarrative,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.5,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                ),
                if (hasPhoto)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12)),
                    child: Image.file(File(vlog.photoPaths.first),
                        width: 72, height: 80, fit: BoxFit.cover),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Vlog Detail Page ─────────────────────────────────────────────

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
    final updated = _vlog.copyWith(photoPaths: [..._vlog.photoPaths, picked.path]);
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
    final d = _vlog.date;
    return Scaffold(
      appBar: AppBar(
        title: Text('${d.year}/${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}'),
      ),
      body: _VlogArticle(
        vlog: _vlog,
        isToday: false,
        generating: false,
        onAddPhoto: _vlog.photoPaths.length < 5 ? () => _addPhoto(provider) : null,
        onRemovePhoto: (i) => _removePhoto(provider, i),
        provider: provider,
      ),
    );
  }
}
