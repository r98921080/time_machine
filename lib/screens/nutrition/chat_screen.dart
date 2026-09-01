import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/meal.dart';
import '../../providers/app_provider.dart';

class ChatScreen extends StatefulWidget {
  final bool embedded;
  const ChatScreen({super.key, this.embedded = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();

  final List<_Message> _messages = [];
  XFile? _pendingImage;
  Uint8List? _pendingImageBytes;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('飲食分析'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showManualAddDialog(context, provider),
                  tooltip: '手動新增',
                ),
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _WelcomeState(onTap: () => _focusInput())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _MessageBubble(
                        msg: _messages[i], provider: provider, theme: theme,
                        onSave: (meal) => _saveMeal(provider, meal)),
                  ),
          ),
          if (_pendingImage != null)
            _ImagePreviewBar(
              imageFile: _pendingImage!,
              onRemove: () => setState(() {
                _pendingImage = null;
                _pendingImageBytes = null;
              }),
              theme: theme,
            ),
          _InputBar(
            ctrl: _ctrl,
            sending: provider.sendingMessage,
            onSend: () => _send(provider),
            onCamera: () => _pickImage(ImageSource.camera),
            onGallery: () => _pickImage(ImageSource.gallery),
            theme: theme,
          ),
        ],
      ),
    );
  }

  void _focusInput() {}

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 75);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pendingImage = file;
      _pendingImageBytes = bytes;
    });
  }

  Future<void> _send(AppProvider provider) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    // Capture the image locally, then clear the pending selection IMMEDIATELY
    // so the UI can never get stuck on "selected" if analysis fails.
    final Uint8List? imageBytes = _pendingImageBytes;
    final bool hasImage = imageBytes != null;
    final userMsg = hasImage
        ? '📷 ${text.isEmpty ? '請分析這張照片的食物' : text}'
        : text;

    setState(() {
      _messages.add(_Message(role: 'user', text: userMsg));
      _ctrl.clear();
      _pendingImage = null;
      _pendingImageBytes = null;
    });
    _scrollToBottom();

    String? response;
    try {
      response = hasImage
          ? await provider.analyzeFoodImage(imageBytes!, text.isEmpty ? null : text)
          : await provider.analyzeFood(text);
    } catch (_) {
      response = '分析失敗，請稍後再試一次 🙏';
    }

    if (response != null && mounted) {
      setState(() => _messages.add(_Message(role: 'ai', text: response!)));
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _saveMeal(AppProvider provider, Map<String, dynamic> data) async {
    final meal = Meal.create(
      profileId: provider.profile!.id,
      mealType: data['mealType'] as String? ?? '一般',
      description: data['description'] as String? ?? '',
      totalCalories: (data['totalCalories'] as num?)?.toDouble() ?? 0,
      caloriesMin: (data['caloriesMin'] as num?)?.toDouble() ?? 0,
      caloriesMax: (data['caloriesMax'] as num?)?.toDouble() ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0,
      aiSummary: data['aiSummary'] as String?,
    );
    await provider.saveMeal(meal);
    await provider.checkAndUpdateStreak();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 已記錄')));
    }
  }

  void _showManualAddDialog(BuildContext context, AppProvider provider) {
    final calCtrl = TextEditingController();
    final proCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String mealType = '早餐';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('手動新增餐點',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: mealType,
                items: ['早餐', '午餐', '晚餐', '點心', '宵夜']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setS(() => mealType = v!),
                decoration: const InputDecoration(labelText: '餐次'),
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: '食物描述')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(
                    controller: calCtrl,
                    decoration: const InputDecoration(labelText: '熱量 (kcal)'),
                    keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                    controller: proCtrl,
                    decoration: const InputDecoration(labelText: '蛋白質 (g)'),
                    keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(
                    controller: carbCtrl,
                    decoration: const InputDecoration(labelText: '碳水 (g)'),
                    keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                    controller: fatCtrl,
                    decoration: const InputDecoration(labelText: '脂肪 (g)'),
                    keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final cal = double.tryParse(calCtrl.text) ?? 0;
                  _saveMeal(provider, {
                    'mealType': mealType,
                    'description': descCtrl.text.trim(),
                    'totalCalories': cal,
                    'caloriesMin': cal * 0.9,
                    'caloriesMax': cal * 1.1,
                    'protein': double.tryParse(proCtrl.text) ?? 0,
                    'carbs': double.tryParse(carbCtrl.text) ?? 0,
                    'fat': double.tryParse(fatCtrl.text) ?? 0,
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('新增'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message {
  final String role;
  final String text;
  const _Message({required this.role, required this.text});
}

class _MessageBubble extends StatefulWidget {
  final _Message msg;
  final AppProvider provider;
  final ThemeData theme;
  final ValueChanged<Map<String, dynamic>> onSave;

  const _MessageBubble({
    required this.msg,
    required this.provider,
    required this.theme,
    required this.onSave,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.msg.role == 'user';
    final theme = widget.theme;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(widget.msg.text,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onPrimary)),
        ),
      );
    }

    // AI message — parse sections
    final sections = _parseSections(widget.msg.text);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sections['摘要'] != null)
                      Text(sections['摘要']!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                    if (sections['熱量估算'] != null) ...[
                      const SizedBox(height: 8),
                      _SectionChip('🔥 ${sections['熱量估算']}', theme),
                    ],
                    if (_expanded) ...[
                      if (sections['三大營養素'] != null) ...[
                        const SizedBox(height: 8),
                        _SectionBlock('三大營養素', sections['三大營養素']!, theme),
                      ],
                      if (sections['隱藏熱量提醒'] != null) ...[
                        const SizedBox(height: 8),
                        _SectionBlock('⚠️ 隱藏熱量', sections['隱藏熱量提醒']!, theme),
                      ],
                      if (sections['中醫食補觀點'] != null) ...[
                        const SizedBox(height: 8),
                        _SectionBlock('🌿 中醫觀點', sections['中醫食補觀點']!, theme),
                      ],
                      if (sections['智能建議'] != null) ...[
                        const SizedBox(height: 8),
                        _SectionBlock('💡 建議', sections['智能建議']!, theme),
                      ],
                    ],
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Text(
                        _expanded ? '收起詳情 ▲' : '查看詳情 ▼',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: TextButton.icon(
                onPressed: () => _showSaveDialog(context),
                icon: const Icon(Icons.save_alt, size: 16),
                label: const Text('記錄這餐'),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _parseSections(String text) {
    final result = <String, String>{};
    final sections = [
      '摘要', '熱量估算', '三大營養素', '隱藏熱量提醒', '中醫食補觀點', '智能建議',
    ];
    for (var i = 0; i < sections.length; i++) {
      final key = sections[i];
      final start = text.indexOf('【$key】');
      if (start < 0) continue;
      final contentStart = start + '【$key】'.length;
      int end = text.length;
      for (final next in sections.skip(i + 1)) {
        final idx = text.indexOf('【$next】', contentStart);
        if (idx >= 0 && idx < end) end = idx;
      }
      result[key] = text.substring(contentStart, end).trim();
    }
    return result;
  }

  void _showSaveDialog(BuildContext context) {
    final sections = _parseSections(widget.msg.text);
    final calText = sections['熱量估算'] ?? '';
    double cal = 0, min = 0, max = 0;
    final numMatch = RegExp(r'(\d+)-(\d+)\s*kcal.*最可能.*?(\d+)').firstMatch(calText);
    if (numMatch != null) {
      min = double.parse(numMatch.group(1)!);
      max = double.parse(numMatch.group(2)!);
      cal = double.parse(numMatch.group(3)!);
    }

    String mealType = '一般';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('記錄這餐'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('估計熱量：${cal.round()} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: mealType,
                items: ['早餐', '午餐', '晚餐', '點心', '宵夜']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setS(() => mealType = v!),
                decoration: const InputDecoration(labelText: '餐次'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
            FilledButton(
              onPressed: () {
                widget.onSave({
                  'mealType': mealType,
                  'description': sections['摘要'] ?? widget.msg.text.substring(0, 40),
                  'totalCalories': cal,
                  'caloriesMin': min,
                  'caloriesMax': max,
                  'protein': _parseNutrient(sections['三大營養素'] ?? '', '蛋白質'),
                  'carbs': _parseNutrient(sections['三大營養素'] ?? '', '碳水化合物'),
                  'fat': _parseNutrient(sections['三大營養素'] ?? '', '脂肪'),
                  'aiSummary': widget.msg.text,
                });
                Navigator.pop(ctx);
              },
              child: const Text('記錄'),
            ),
          ],
        ),
      ),
    );
  }

  double _parseNutrient(String text, String key) {
    final match = RegExp('$key：(\\d+(?:\\.\\d+)?)').firstMatch(text);
    return match != null ? double.parse(match.group(1)!) : 0;
  }
}

class _SectionChip extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _SectionChip(this.text, this.theme);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text,
        style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold)),
  );
}

class _SectionBlock extends StatelessWidget {
  final String title, content;
  final ThemeData theme;
  const _SectionBlock(this.title, this.content, this.theme);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: theme.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      Text(content,
          style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
    ],
  );
}

class _WelcomeState extends StatelessWidget {
  final VoidCallback onTap;
  const _WelcomeState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('告訴我你吃了什麼',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('輸入食物名稱或拍照，AI 幫你分析',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ImagePreviewBar extends StatelessWidget {
  final XFile imageFile;
  final VoidCallback onRemove;
  final ThemeData theme;

  const _ImagePreviewBar({
    required this.imageFile,
    required this.onRemove,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(imageFile.path),
                width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('已選擇照片',
                style: theme.textTheme.bodySmall),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ThemeData theme;

  const _InputBar({
    required this.ctrl,
    required this.sending,
    required this.onSend,
    required this.onCamera,
    required this.onGallery,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: theme.colorScheme.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: sending ? null : onCamera,
            ),
            IconButton(
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: sending ? null : onGallery,
            ),
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: '今天吃了什麼？',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  isDense: true,
                ),
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            sending
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                : IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: onSend,
                  ),
          ],
        ),
      ),
    );
  }
}
