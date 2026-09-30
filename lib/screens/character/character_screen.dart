import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/character.dart';
import '../../models/user_profile.dart';
import '../../models/chat_message.dart';
import '../../widgets/doll_character.dart';
import '../shop/shop_screen.dart';
import '../achievements/achievements_screen.dart';
import '../../widgets/art_frame_widgets.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleCtrl;
  late Animation<double> _idleAnim;

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _chatExpanded = false;

  // Track the last message that errored so user can retry
  String? _lastFailedMessage;
  String? _chatError;

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
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _showMirrorResponse(AppProvider provider) async {
    final isMirror = provider.profile?.characterMode == CharacterMode.mirror;
    if (!isMirror) return;
    final msg = await provider.getMirrorResponse();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${provider.characterName} 說…'),
        content: Text(msg, style: const TextStyle(fontSize: 16, height: 1.6)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('謝謝你 ♡'),
          ),
        ],
      ),
    );
  }

  void _showNameEditDialog(AppProvider provider) {
    final ctrl = TextEditingController(text: provider.characterName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('幫角色取名字'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 10,
          decoration: const InputDecoration(
            labelText: '角色名稱',
            hintText: '例如：小晴、Kai…',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await provider.saveCharacterName(ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _showAmnesiaDialog(AppProvider provider) {
    final isMirror = provider.profile?.characterMode == CharacterMode.mirror;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('讓角色失憶？'),
        content: Text(isMirror
            ? '${provider.characterName}會忘記你們之間的所有對話，關係重置為陌生人。確定嗎？'
            : '角色會忘記所有聊天記錄，關係重置為陌生人。確定嗎？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await provider.resetCharacterRelationship();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('讓他失憶'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(AppProvider provider, String text) async {
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() { _chatError = null; _lastFailedMessage = null; });
    try {
      await provider.sendCharacterMessage(text);
      if (_scrollCtrl.hasClients) {
        await Future.delayed(const Duration(milliseconds: 100));
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      setState(() {
        _chatError = '⚠️ 回應失敗，請點重試';
        _lastFailedMessage = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;
    final character = provider.character;
    if (profile == null || character == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isMirror = profile.characterMode == CharacterMode.mirror;
    final charName = provider.characterName;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => _showNameEditDialog(provider),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isMirror ? '映照' : '我的角色'),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 14),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RelationshipBadge(relationship: provider.relationship),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AchievementsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ShopScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showCustomizeSheet(context, provider, character),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'amnesia') _showAmnesiaDialog(provider);
              if (val == 'rename') _showNameEditDialog(provider);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('修改角色名'),
                ]),
              ),
              const PopupMenuItem(
                value: 'amnesia',
                child: Row(children: [
                  Icon(Icons.psychology_alt, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('讓角色失憶'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Character image area ──────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _chatExpanded ? 190 : 360,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.1,
                colors: isMirror
                    ? [
                        const Color(0xFF5A3E28).withOpacity(0.55),
                        theme.colorScheme.surface,
                      ]
                    : [
                        const Color(0xFF3A2D1D).withOpacity(0.65),
                        theme.colorScheme.surface,
                      ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ornate Frame Border Presentation around companion
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: OrnateFrameBox(
                    width: _chatExpanded ? 140 : 235,
                    height: _chatExpanded ? 180 : 340,
                    padding: const EdgeInsets.all(6),
                    showBadge: !_chatExpanded,
                    badgeText: isMirror ? (profile.mirrorGender ?? '映照伴侶') : charName,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Warm autumn amber glow backdrop
                        Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(0, -0.15),
                              radius: 0.95,
                              colors: [
                                Color(0xFFF3E2B8),
                                Color(0xFFD4A864),
                                Color(0xFF8B6432),
                              ],
                            ),
                          ),
                        ),
                        // Character with subtle breathing animation
                        AnimatedBuilder(
                          animation: _idleAnim,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _idleAnim.value),
                            child: child,
                          ),
                          child: DollCharacterWidget(
                            appearance: character,
                            gender: isMirror ? (profile.mirrorGender ?? '她') : profile.sex,
                            isMirror: isMirror,
                            width: _chatExpanded ? 120 : 210,
                            height: _chatExpanded ? 170 : 325,
                            enableAnimation: true,
                            interactive: true,
                            onTap: () async {
                              final quote = await provider.interactWithCharacter();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$charName：$quote'),
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 14,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFFC99742).withOpacity(0.18),
                      foregroundColor: const Color(0xFFC99742),
                    ),
                    onPressed: () => _showCustomizeSheet(context, provider, character),
                    icon: const Icon(Icons.checkroom, size: 15),
                    label: const Text('自訂外觀', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'toggle_chat',
                        backgroundColor: const Color(0xFF2B4D58),
                        foregroundColor: Colors.white,
                        onPressed: () => setState(() => _chatExpanded = !_chatExpanded),
                        tooltip: _chatExpanded ? '顯示角色' : '展開聊天',
                        child: Icon(_chatExpanded ? Icons.person : Icons.chat_bubble_outline),
                      ),
                      if (provider.profile?.characterMode == CharacterMode.mirror) ...[
                        const SizedBox(width: 8),
                        FloatingActionButton.small(
                          heroTag: 'mirror_resp',
                          backgroundColor: const Color(0xFFC99742),
                          foregroundColor: Colors.white,
                          onPressed: () => _showMirrorResponse(provider),
                          tooltip: '映照視角',
                          child: const Icon(Icons.favorite_border),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Chat area ─────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // EXP progress bar
                _ExpProgressBar(provider: provider, theme: theme),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showNameEditDialog(provider),
                        child: Row(
                          children: [
                            Text(charName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 12,
                                color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relationshipDesc(provider.relationship),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: provider.chatHistory.isEmpty
                      ? _EmptyChatPlaceholder(
                          characterName: charName,
                          relationship: provider.relationship,
                          theme: theme,
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: provider.chatHistory.length,
                          itemBuilder: (ctx, i) {
                            final msg = provider.chatHistory[i];
                            return _ChatBubble(
                              message: msg,
                              isUser: msg.role == 'user',
                              characterName: charName,
                              theme: theme,
                            );
                          },
                        ),
                ),

                // Error + retry row
                if (_chatError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_chatError!,
                              style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 13)),
                        ),
                        if (_lastFailedMessage != null)
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('重試'),
                            onPressed: () {
                              final msg = _lastFailedMessage!;
                              _sendMessage(provider, msg);
                            },
                          ),
                      ],
                    ),
                  ),

                _ChatInput(
                  controller: _msgCtrl,
                  sending: provider.chatting,
                  onSend: () => _sendMessage(provider, _msgCtrl.text.trim()),
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relationshipDesc(String rel) {
    return {
          '陌生人': '剛認識，有些陌生',
          '普通朋友': '認識了，開始熟悉',
          '熟悉': '彼此漸漸了解',
          '好友': '很好的朋友了',
          '曖昧': '彼此有好感',
          '親密': '非常親近的關係',
        }[rel] ??
        rel;
  }

  Future<void> _showCustomizeSheet(BuildContext context, AppProvider provider,
      CharacterAppearance current) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CustomizeSheet(current: current, provider: provider),
    );
  }
}

// ── Relationship badge ────────────────────────────────────────────────
class _RelationshipBadge extends StatelessWidget {
  final String relationship;
  const _RelationshipBadge({required this.relationship});

  @override
  Widget build(BuildContext context) {
    const icons = {
      '陌生人': '👤', '普通朋友': '😊', '熟悉': '🙂',
      '好友': '😄', '曖昧': '💗', '親密': '❤️'
    };
    final ico = icons[relationship] ?? '✨';
    return OrnatePlaqueBadge(
      label: '$ico $relationship',
      fontSize: 10.5,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
    );
  }
}

// ── EXP Progress Bar ──────────────────────────────────────────────────
class _ExpProgressBar extends StatelessWidget {
  final AppProvider provider;
  final ThemeData theme;
  const _ExpProgressBar({required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    final profile = provider.profile;
    if (profile == null) return const SizedBox.shrink();
    final exp = profile.characterExp;
    final current = profile.currentLevelExp;
    final next = profile.nextRelationshipExpTarget;
    final ratio = next < 0
        ? 1.0
        : current == next
            ? 1.0
            : (exp - current) / (next - current);
    final rel = profile.relationshipLevel;
    final barColor = const Color(0xFFC99742);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(rel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
              color: Color(0xFFC99742))),
          Text(next < 0 ? '已達最高' : '$exp / $next EXP',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFC99742).withOpacity(0.18),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFC99742)),
          ),
        ),
      ]),
    );
  }
}

// ── Empty chat placeholder ────────────────────────────────────────────
class _EmptyChatPlaceholder extends StatelessWidget {
  final String characterName;
  final String relationship;
  final ThemeData theme;
  const _EmptyChatPlaceholder(
      {required this.characterName, required this.relationship, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hints = {
      '陌生人': '說聲「你好」，開始認識$characterName吧！',
      '朋友': '和$characterName聊聊今天過得怎麼樣',
      '曖昧': '傳個訊息給$characterName，看$characterName怎麼說',
      '親密': '$characterName在等你說話呢',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💬', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            hints[relationship] ?? '開始對話吧',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final CharacterChatMessage message;
  final bool isUser;
  final String characterName;
  final ThemeData theme;

  const _ChatBubble({
    required this.message,
    required this.isUser,
    required this.characterName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(characterName,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFC99742)
                    : const Color(0xFF2B4D58).withOpacity(0.12),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFF9E7127)
                      : const Color(0xFF2B4D58).withOpacity(0.35),
                  width: 1,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat input ────────────────────────────────────────────────────────
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final ThemeData theme;

  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border:
            Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '傳訊息給角色…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          sending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: onSend,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Customize Sheet ───────────────────────────────────────────────────
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
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('自訂外觀與配件', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _SectionLabel('自訂全身服飾', theme),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSimpleOption(
                label: '歐式宮廷禮服',
                selected: _appearance.outfitId == null || _appearance.outfitId == 'outfit_victorian' || _appearance.outfitId == 'outfit_scholar',
                onTap: () => setState(() => _appearance = _appearance.copyWith(outfitId: 'outfit_victorian')),
              ),
              _buildSimpleOption(
                label: '天藍宮廷裙裝',
                selected: _appearance.outfitId == 'outfit_sundress' || _appearance.outfitId == 'outfit_princess',
                onTap: () => setState(() => _appearance = _appearance.copyWith(outfitId: 'outfit_sundress')),
              ),
              _buildSimpleOption(
                label: '俐落學院正裝',
                selected: _appearance.outfitId == 'outfit_formal_suit',
                onTap: () => setState(() => _appearance = _appearance.copyWith(outfitId: 'outfit_formal_suit')),
              ),
              _buildSimpleOption(
                label: '街頭連帽夾克',
                selected: _appearance.outfitId == 'outfit_casual_hoodie',
                onTap: () => setState(() => _appearance = _appearance.copyWith(outfitId: 'outfit_casual_hoodie')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionLabel('特色飾品與配件', theme),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSimpleOption(
                label: '金絲細框眼鏡',
                selected: _appearance.accessories.contains('acc_glasses_round'),
                onTap: () {
                  final list = List<String>.from(_appearance.accessories);
                  if (list.contains('acc_glasses_round')) {
                    list.remove('acc_glasses_round');
                  } else {
                    list.add('acc_glasses_round');
                  }
                  setState(() => _appearance = _appearance.copyWith(accessories: list));
                },
              ),
              _buildSimpleOption(
                label: '璀璨黃金王冠',
                selected: _appearance.accessories.contains('acc_crown_gold'),
                onTap: () {
                  final list = List<String>.from(_appearance.accessories);
                  if (list.contains('acc_crown_gold')) {
                    list.remove('acc_crown_gold');
                  } else {
                    list.add('acc_crown_gold');
                  }
                  setState(() => _appearance = _appearance.copyWith(accessories: list));
                },
              ),
              _buildSimpleOption(
                label: '皇家藍蝴蝶結',
                selected: _appearance.accessories.contains('acc_ribbon_blue'),
                onTap: () {
                  final list = List<String>.from(_appearance.accessories);
                  if (list.contains('acc_ribbon_blue')) {
                    list.remove('acc_ribbon_blue');
                  } else {
                    list.add('acc_ribbon_blue');
                  }
                  setState(() => _appearance = _appearance.copyWith(accessories: list));
                },
              ),
              _buildSimpleOption(
                label: '閃亮星芒耳環',
                selected: _appearance.accessories.contains('acc_earring_star'),
                onTap: () {
                  final list = List<String>.from(_appearance.accessories);
                  if (list.contains('acc_earring_star')) {
                    list.remove('acc_earring_star');
                  } else {
                    list.add('acc_earring_star');
                  }
                  setState(() => _appearance = _appearance.copyWith(accessories: list));
                },
              ),
              _buildSimpleOption(
                label: '純白天使羽翼',
                selected: _appearance.accessories.contains('acc_wings_angel'),
                onTap: () {
                  final list = List<String>.from(_appearance.accessories);
                  if (list.contains('acc_wings_angel')) {
                    list.remove('acc_wings_angel');
                  } else {
                    list.add('acc_wings_angel');
                  }
                  setState(() => _appearance = _appearance.copyWith(accessories: list));
                },
              ),
              _buildSimpleOption(
                label: '可愛貓咪鬍鬚',
                selected: _appearance.accessories.contains('face_cat_whiskers'),
                onTap: () {
                  final list = List<String>.from(_appearance.accessories);
                  if (list.contains('face_cat_whiskers')) {
                    list.remove('face_cat_whiskers');
                  } else {
                    list.add('face_cat_whiskers');
                  }
                  setState(() => _appearance = _appearance.copyWith(accessories: list));
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionLabel('膚色', theme),
          _EnumRow<SkinTone>(
            values: SkinTone.values,
            selected: _appearance.skinTone,
            labels: ['淺膚色', '中等', '小麥色', '深膚色'],
            onTap: (v) =>
                setState(() => _appearance = _appearance.copyWith(skinTone: v)),
          ),
          const SizedBox(height: 12),
          _SectionLabel('髮型', theme),
          _EnumRow<HairStyle>(
            values: HairStyle.values,
            selected: _appearance.hairStyle,
            labels: ['短髮', '中長髮', '長髮', '包子頭', '馬尾', '捲髮'],
            onTap: (v) => setState(
                () => _appearance = _appearance.copyWith(hairStyle: v)),
          ),
          const SizedBox(height: 12),
          _SectionLabel('髮色', theme),
          _EnumRow<HairColor>(
            values: HairColor.values,
            selected: _appearance.hairColor,
            labels: ['黑髮', '棕髮', '金髮', '紅髮', '銀髮', '幻想色'],
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

  Widget _buildSimpleOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFC99742).withOpacity(0.18)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: const Color(0xFFC99742), width: 2)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? const Color(0xFFC99742) : null,
          ),
        ),
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
