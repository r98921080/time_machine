import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/gemini_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _geminiCtrl = TextEditingController();
  final TextEditingController _openAICtrl = TextEditingController();
  bool _testingGemini = false;
  String? _geminiStatus;
  bool _geminiSuccess = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _geminiCtrl.text = provider.apiKey ?? '';
    _openAICtrl.text = provider.openAIKey ?? '';
  }

  @override
  void dispose() {
    _geminiCtrl.dispose();
    _openAICtrl.dispose();
    super.dispose();
  }

  Future<void> _testGeminiConnection() async {
    final key = _geminiCtrl.text.trim();
    if (key.isEmpty) {
      setState(() {
        _geminiStatus = '請先輸入 Gemini API Key';
        _geminiSuccess = false;
      });
      return;
    }

    setState(() {
      _testingGemini = true;
      _geminiStatus = null;
    });

    final ok = await GeminiService.testApiKey(key);
    if (!mounted) return;

    setState(() {
      _testingGemini = false;
      _geminiSuccess = ok;
      _geminiStatus = ok ? '✓ 連線成功！Gemini 模型運作正常' : '✗ 連線失敗，請檢查 Key 是否正確或具備額度';
    });
  }

  Future<void> _saveKeys(AppProvider provider) async {
    await provider.saveApiKey(_geminiCtrl.text.trim());
    await provider.saveOpenAIKey(_openAICtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已儲存 API Key 設定！')),
      );
    }
  }

  Future<void> _exportBackup(AppProvider provider) async {
    try {
      final jsonStr = await provider.exportBackupJson();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_download_outlined),
              SizedBox(width: 8),
              Text('資料備份 JSON'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('以下是您完整的時光機資料庫（目標、飲食、心情、角色裝扮等）：',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                height: 140,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('關閉'),
            ),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonStr));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已複製備份內容至剪貼簿！')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('複製備份碼'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('匯出失敗：$e')),
        );
      }
    }
  }

  Future<void> _importBackup(AppProvider provider) async {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_upload_outlined),
            SizedBox(width: 8),
            Text('還原資料備份'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('請貼上先前複製的備份 JSON 內容：\n注意：這將會覆蓋當前裝置上的資料！',
                style: TextStyle(fontSize: 13, color: Colors.orange)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '{"version": 5, "tables": {...}}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await provider.importBackupJson(text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? '✓ 資料還原成功！' : '✗ 還原失敗，請檢查備份格式是否正確。'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('確認還原'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定與偏好'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── AI Services Section ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('AI 智慧服務金鑰',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('支援飲食拍照分析、生活顧問對談、每日冷知識與 Vlog 生成。',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _geminiCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Google Gemini API Key',
                      hintText: 'AIzaSy...',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste),
                        tooltip: '貼上剪貼簿',
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            _geminiCtrl.text = data!.text!.trim();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _testingGemini ? null : _testGeminiConnection,
                        icon: _testingGemini
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.network_check, size: 16),
                        label: const Text('測試連線'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => _saveKeys(provider),
                        child: const Text('儲存'),
                      ),
                    ],
                  ),
                  if (_geminiStatus != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _geminiSuccess ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _geminiStatus!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _geminiSuccess ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 24),
                  TextField(
                    controller: _openAICtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'OpenAI API Key（選填，用於高解析繪圖）',
                      hintText: 'sk-...',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Data Backup & Restore ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.backup_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('資料備份與安全',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('您的所有記錄均安全儲存於本機資料庫。定期備份可避免換手機或誤刪時資料遺失。',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportBackup(provider),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('匯出備份'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _importBackup(provider),
                          icon: const Icon(Icons.upload, size: 18),
                          label: const Text('還原備份'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── About App ──
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('時光機 TimeMachine'),
              subtitle: const Text('版本 1.0.0 • 生活目標與健康管理，融合角色養成'),
              trailing: const Chip(
                label: Text('PRO'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
