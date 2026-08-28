import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/character.dart';
import '../../models/user_profile.dart';
import 'character_painter.dart';
import '../shop/shop_screen.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleCtrl;
  late Animation<double> _idleAnim;
  String? _mirrorMessage;
  bool _loadingMirror = false;

  @override
  void initState() {
    super.initState();
    _idleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _idleAnim = Tween(begin: -4.0, end: 4.0).animate(
        CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;
    final character = provider.character;
    if (profile == null || character == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isMirror = profile.characterMode == CharacterMode.mirror;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMirror ? '映照' : '我的角色'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ShopScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showCustomizeSheet(context, provider, character),
          ),
        ],
      ),
      body: Column(
        children: [
          // Character Display
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isMirror
                      ? [const Color(0xFFFFE0F0), const Color(0xFFFFF0F8)]
                      : [const Color(0xFFE8E8FF), const Color(0xFFF0F0FF)],
                ),
              ),
              child: Center(
                child: AnimatedBuilder(
                  animation: _idleAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _idleAnim.value),
                    child: child,
                  ),
                  child: SizedBox(
                    width: 200,
                    height: 280,
                    child: CustomPaint(
                      painter: CharacterPainter(
                        appearance: character,
                        isMirror: isMirror,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Stats & Mirror Message
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (isMirror) ...[
                    _MirrorPanel(
                      mirrorMessage: _mirrorMessage,
                      loading: _loadingMirror,
                      gender: profile.mirrorGender ?? '她',
                      onRefresh: () => _loadMirrorMessage(provider),
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _CharacterStats(
                    profile: profile,
                    character: character,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMirrorMessage(AppProvider provider) async {
    setState(() => _loadingMirror = true);
    try {
      final msg = await provider.getMirrorResponse();
      setState(() => _mirrorMessage = msg);
    } finally {
      setState(() => _loadingMirror = false);
    }
  }

  void _showCustomizeSheet(BuildContext context, AppProvider provider,
      CharacterAppearance current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CustomizeSheet(current: current, provider: provider),
    );
  }
}

class _MirrorPanel extends StatelessWidget {
  final String? mirrorMessage;
  final bool loading;
  final String gender;
  final VoidCallback onRefresh;
  final ThemeData theme;

  const _MirrorPanel({
    required this.mirrorMessage,
    required this.loading,
    required this.gender,
    required this.onRefresh,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(gender == '她' ? '💕' : '💙',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text('$gender 說…',
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: loading ? null : onRefresh,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ],
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else
              Text(
                mirrorMessage ?? '點擊右上角重新整理，聽聽${gender}說什麼...',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontStyle: mirrorMessage == null
                        ? FontStyle.italic
                        : FontStyle.normal),
              ),
          ],
        ),
      ),
    );
  }
}

class _CharacterStats extends StatelessWidget {
  final dynamic profile;
  final CharacterAppearance character;
  final ThemeData theme;

  const _CharacterStats({
    required this.profile,
    required this.character,
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
            Text('體態進度', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            _ProgressRow('肌肉線條', character.muscleLevel,
                const Color(0xFF3B82F6), theme),
            const SizedBox(height: 8),
            _ProgressRow('體脂控制', 1 - character.fatLevel,
                const Color(0xFF10B981), theme),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ThemeData theme;

  const _ProgressRow(this.label, this.value, this.color, this.theme);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 60,
            child: Text(label, style: theme.textTheme.labelSmall)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(value * 100).round()}%',
            style: theme.textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}

class _CustomizeSheet extends StatefulWidget {
  final CharacterAppearance current;
  final AppProvider provider;

  const _CustomizeSheet({required this.current, required this.provider});

  @override
  State<_CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends State<_CustomizeSheet> {
  late CharacterAppearance _appearance;

  @override
  void initState() {
    super.initState();
    _appearance = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      expand: false,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('自訂外觀', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          _SectionLabel('膚色', theme),
          _EnumRow<SkinTone>(
            values: SkinTone.values,
            selected: _appearance.skinTone,
            labels: ['淺', '中', '小麥', '深'],
            onTap: (v) => setState(
                () => _appearance = _appearance.copyWith(skinTone: v)),
          ),
          const SizedBox(height: 12),
          _SectionLabel('髮型', theme),
          _EnumRow<HairStyle>(
            values: HairStyle.values,
            selected: _appearance.hairStyle,
            labels: ['短', '中', '長', '包子頭', '馬尾', '捲髮'],
            onTap: (v) => setState(
                () => _appearance = _appearance.copyWith(hairStyle: v)),
          ),
          const SizedBox(height: 12),
          _SectionLabel('髮色', theme),
          _EnumRow<HairColor>(
            values: HairColor.values,
            selected: _appearance.hairColor,
            labels: ['黑', '棕', '金', '紅', '灰', '幻想色'],
            onTap: (v) => setState(
                () => _appearance = _appearance.copyWith(hairColor: v)),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await widget.provider.updateCharacterAppearance(_appearance);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _SectionLabel(this.text, this.theme);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant)),
  );
}

class _EnumRow<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final List<String> labels;
  final ValueChanged<T> onTap;

  const _EnumRow({
    required this.values,
    required this.selected,
    required this.labels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(values.length, (i) {
        final isSelected = values[i] == selected;
        return GestureDetector(
          onTap: () => onTap(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: Text(
              i < labels.length ? labels[i] : values[i].toString(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
