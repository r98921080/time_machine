import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

/// AI 私人健康顧問聊天畫面。
///
/// 取代原本的「角色（洋娃娃 + 商城）」分頁，聚焦在專業對談：
/// 讀取使用者的日記、熱量、目標達成等資料，給予具體可執行的建議。
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  static const _suggestions = [
    '幫我看看今天的飲食狀況',
    '這週目標達成得如何？給我回饋',
    '我想減脂，根據我的數據給建議',
    '最近有點累，該怎麼調整作息？',
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(AppProvider provider, String text) async {
    final t = text.trim();
    if (t.isEmpty || provider.chatting) return;
    _msgCtrl.clear();
    _scrollToBottom();
    try {
      await provider.sendAdvisorMessage(t);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('顧問暫時沒回應：$e')),
      );
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppProvider>();
    final messages = provider.chatHistory;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.support_agent,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('AI 健康顧問',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text('營養 · 運動 · 習慣 · 心理',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              tooltip: '清除對話',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(provider),
            ),
        ],
      ),
      body: Column(
        children: [
          _ContextBar(provider: provider),
          Expanded(
            child: messages.isEmpty
                ? _EmptyState(
                    onPick: (s) => _send(provider, s),
                    suggestions: _suggestions,
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: messages.length + (provider.chatting ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= messages.length) {
                        return const _TypingBubble();
                      }
                      final m = messages[i];
                      return _Bubble(
                        text: m.content,
                        isUser: m.role == 'user',
                      );
                    },
                  ),
          ),
          _InputBar(
            controller: _msgCtrl,
            sending: provider.chatting,
            onSend: () => _send(provider, _msgCtrl.text),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(AppProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除對話'),
        content: const Text('確定要清除和顧問的所有對話紀錄嗎？此動作無法復原。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.clearChatHistory();
    }
  }
}

/// 頂部今日狀態列：讓使用者一眼看到顧問正在參考的資料。
class _ContextBar extends StatelessWidget {
  final AppProvider provider;
  const _ContextBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = provider.profile?.calculatedCalorieTarget ?? 0;
    final cal = provider.todayCalories.round();
    final pts = provider.todayGoalPoints;
    final hasDiary = (provider.todayDiary?.content ?? '').isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      child: Row(
        children: [
          Icon(Icons.insights, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip(theme, Icons.local_fire_department,
                    '$cal${target > 0 ? ' / ${target.round()}' : ''} kcal'),
                _chip(theme, Icons.track_changes, '目標 $pts 點'),
                _chip(theme, Icons.menu_book,
                    hasDiary ? '今日已寫日記' : '今日未寫日記'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final void Function(String) onPick;
  final List<String> suggestions;
  const _EmptyState({required this.onPick, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        Icon(Icons.support_agent,
            size: 64, color: theme.colorScheme.primary.withOpacity(0.85)),
        const SizedBox(height: 16),
        Text('我是你的專屬健康顧問',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          '我會參考你的飲食熱量、目標達成與日記，給你具體、可執行的建議。\n有什麼想聊的，直接說 👇',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        ...suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => onPick(s),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s)),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _Bubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: SelectableText(
          text,
          style: TextStyle(color: fg, fontSize: 15, height: 1.45),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text('顧問思考中…',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
              top: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: '問問你的顧問…',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: sending ? null : onSend,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
              ),
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
