import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../providers/app_provider.dart';
import '../../models/character.dart';
import '../../models/user_profile.dart';
import '../../models/chat_message.dart';
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
  Uint8List? _characterImage;
  bool _generatingImage = false;
  static const _imageCacheKey = 'character_ai_image';

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _chatExpanded = false;

  @override
  void initState() {
    super.initState();
    _idleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _idleAnim = Tween(begin: -4.0, end: 4.0).animate(
        CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut));
    _loadCachedImage();
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final b64 = prefs.getString(_imageCacheKey);
    if (b64 != null && b64.isNotEmpty && mounted) {
      setState(() => _characterImage = base64Decode(b64));
    }
  }

  Future<void> _generateImage(AppProvider provider) async {
    setState(() => _generatingImage = true);
    try {
      Uint8List? bytes;

      // Try Gemini image generation first (uses existing Gemini key)
      bytes = await provider.generateCharacterImageWithGemini();

      // Fall back to OpenAI DALL-E if Gemini failed and user has key
      if (bytes == null) {
        final openAI = provider.openAI;
        if (openAI != null) {
          final profile = provider.profile!;
          final character = provider.character!;
          final isMirror = profile.characterMode == CharacterMode.mirror;
          bytes = await openAI.generateCharacterImage(
            gender: isMirror ? (profile.mirrorGender ?? '她') : profile.sex,
            bodyGoal: profile.goal.name,
            isMirror: isMirror,
            style: 'anime',
            appearance: character,
            muscleLevel: character.muscleLevel,
            fatLevel: character.fatLevel,
          );
        }
      }

      if (bytes != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_imageCacheKey, base64Encode(bytes));
        if (mounted) setState(() => _characterImage = bytes);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ 圖片生成失敗，請稍後再試（Gemini 圖片功能需要支援的 API 配額）'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingImage = false);
    }
  }

  void _showKeyDialog(AppProvider provider) {
    final ctrl = TextEditingController(text: provider.openAIKey ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('設定 OpenAI API Key'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: 'sk-proj-...',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await provider.saveOpenAIKey(ctrl.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                _generateImage(provider);
              }
            },
            child: const Text('儲存並生成'),
          ),
        ],
      ),
    );
  }

  void _showAmnesiaDialog(AppProvider provider) {
    final isMirror =
        provider.profile?.characterMode == CharacterMode.mirror;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('讓角色失憶？'),
        content: Text(isMirror
            ? '${provider.profile?.mirrorGender ?? '她'}會忘記你們之間的所有對話，關係重置為陌生人。確定嗎？'
            : '角色會忘記所有聊天記錄，關係重置為陌生人。確定嗎？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.orange),
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

  Future<void> _sendMessage(AppProvider provider) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await provider.sendCharacterMessage(text);
    if (_scrollCtrl.hasClients) {
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
    final characterName = isMirror
        ? (profile.mirrorGender == '她' ? '小琪' : '小凱')
        : '時光';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(isMirror ? '映照' : '我的角色'),
            const SizedBox(width: 8),
            _RelationshipBadge(relationship: provider.relationship),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ShopScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () =>
                _showCustomizeSheet(context, provider, character),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'amnesia') _showAmnesiaDialog(provider);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'amnesia',
                child: Row(
                  children: [
                    Icon(Icons.psychology_alt, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('讓角色失憶'),
                  ],
                ),
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
            height: _chatExpanded ? 160 : 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isMirror
                    ? [
                        theme.colorScheme.secondaryContainer,
                        theme.colorScheme.surface,
                      ]
                    : [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.surface,
                      ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _idleAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _idleAnim.value),
                    child: child,
                  ),
                  child: _characterImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _characterImage!,
                            width: _chatExpanded ? 100 : 180,
                            height: _chatExpanded ? 140 : 260,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _PlaceholderCharacter(
                          isMirror: isMirror,
                          gender: isMirror
                              ? (profile.mirrorGender ?? '她')
                              : profile.sex,
                          compact: _chatExpanded,
                          theme: theme,
                        ),
                ),
                Positioned(
                  bottom: 8,
                  right: 16,
                  child: _generatingImage
                      ? const CircularProgressIndicator()
                      : FloatingActionButton.small(
                          heroTag: 'gen_char',
                          onPressed: () => _generateImage(provider),
                          tooltip: 'AI 生成角色圖片',
                          child: const Icon(Icons.auto_awesome),
                        ),
                ),
                // Expand/collapse chat toggle
                Positioned(
                  bottom: 8,
                  left: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'toggle_chat',
                    backgroundColor:
                        theme.colorScheme.secondaryContainer,
                    foregroundColor:
                        theme.colorScheme.onSecondaryContainer,
                    onPressed: () =>
                        setState(() => _chatExpanded = !_chatExpanded),
                    tooltip: _chatExpanded ? '顯示角色' : '展開聊天',
                    child: Icon(_chatExpanded
                        ? Icons.person
                        : Icons.chat_bubble_outline),
                  ),
                ),
              ],
            ),
          ),

          // ── Chat area ─────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Character name + relationship
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Text(characterName,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold)),
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

                // Message list
                Expanded(
                  child: provider.chatHistory.isEmpty
                      ? _EmptyChatPlaceholder(
                          characterName: characterName,
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
                            final isUser = msg.role == 'user';
                            return _ChatBubble(
                              message: msg,
                              isUser: isUser,
                              characterName: characterName,
                              theme: theme,
                            );
                          },
                        ),
                ),

                // Input area
                _ChatInput(
                  controller: _msgCtrl,
                  sending: provider.chatting,
                  onSend: () => _sendMessage(provider),
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
          '朋友': '熟悉的朋友',
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
      builder: (_) =>
          _CustomizeSheet(current: current, provider: provider),
    );
  }
}

// ── Relationship badge ────────────────────────────────────────────────
class _RelationshipBadge extends StatelessWidget {
  final String relationship;
  const _RelationshipBadge({required this.relationship});

  @override
  Widget build(BuildContext context) {
    final colors = {
      '陌生人': (Colors.grey.shade600, Colors.grey.shade100),
      '朋友': (Colors.blue.shade700, Colors.blue.shade50),
      '曖昧': (Colors.pink.shade600, Colors.pink.shade50),
      '親密': (Colors.red.shade600, Colors.red.shade50),
    };
    final (fg, bg) = colors[relationship] ??
        (Colors.grey.shade600, Colors.grey.shade100);
    final icons = {
      '陌生人': '👤',
      '朋友': '😊',
      '曖昧': '💗',
      '親密': '❤️',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${icons[relationship] ?? ''} $relationship',
        style: TextStyle(
            fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Empty chat placeholder ────────────────────────────────────────────
class _EmptyChatPlaceholder extends StatelessWidget {
  final String characterName;
  final String relationship;
  final ThemeData theme;
  const _EmptyChatPlaceholder(
      {required this.characterName,
      required this.relationship,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    final hints = {
      '陌生人': '說聲「你好」，開始認識$characterName吧！',
      '朋友': '和$characterName聊聊今天過得怎麼樣',
      '曖昧': '傳個訊息給$characterName，看${characterName}怎麼說',
      '親密': '$characterName在等你說話呢',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💬', style: const TextStyle(fontSize: 40)),
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
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
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
        border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant)),
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
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
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

// ── Placeholder when no AI image yet ─────────────────────────────────
class _PlaceholderCharacter extends StatelessWidget {
  final bool isMirror;
  final String gender;
  final bool compact;
  final ThemeData theme;
  const _PlaceholderCharacter(
      {required this.isMirror,
      required this.gender,
      required this.compact,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 90 : 180,
      height: compact ? 130 : 250,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isMirror ? (gender == '她' ? '👩' : '👨') : '🙂',
            style: TextStyle(fontSize: compact ? 32 : 52),
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Text(
              '點擊 ✨\nAI 生成圖片',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
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
          Text('自訂外觀', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
