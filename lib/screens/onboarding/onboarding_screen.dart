import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../providers/app_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  int _step = 0;
  BodyGoal _goal = BodyGoal.loseFat;
  String _sex = '男';
  CharacterMode _charMode = CharacterMode.self;
  String _mirrorGender = '她';
  bool _loading = false;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(step: _step, theme: theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: [
                      _buildStep0(theme),
                      _buildStep1(theme),
                      _buildStep2(theme),
                      _buildStep3(theme),
                    ][_step],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0(ThemeData theme) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WelcomeText(),
        const SizedBox(height: 32),
        Text('你叫什麼名字？', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nicknameCtrl,
          decoration: const InputDecoration(
            labelText: '暱稱',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) => v?.trim().isEmpty == true ? '請輸入暱稱' : null,
          autofocus: true,
        ),
        const SizedBox(height: 32),
        _NextButton(onTap: () {
          if (_formKey.currentState!.validate()) {
            setState(() => _step = 1);
          }
        }),
      ],
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('你的目標是什麼？', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('這會幫助計算你的每日熱量需求',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        _GoalCards(value: _goal, onChanged: (g) => setState(() => _goal = g), theme: theme),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                  controller: _heightCtrl,
                  decoration:
                      const InputDecoration(labelText: '身高 cm', prefixIcon: Icon(Icons.height)),
                  keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                  controller: _weightCtrl,
                  decoration: const InputDecoration(
                      labelText: '體重 kg', prefixIcon: Icon(Icons.monitor_weight_outlined)),
                  keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                  controller: _ageCtrl,
                  decoration: const InputDecoration(
                      labelText: '年齡', prefixIcon: Icon(Icons.cake_outlined)),
                  keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sex,
                decoration: const InputDecoration(labelText: '性別'),
                items: const [
                  DropdownMenuItem(value: '男', child: Text('男')),
                  DropdownMenuItem(value: '女', child: Text('女')),
                ],
                onChanged: (v) => setState(() => _sex = v ?? '男'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(
              child: OutlinedButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('上一步'))),
          const SizedBox(width: 12),
          Expanded(child: _NextButton(onTap: () => setState(() => _step = 2))),
        ]),
      ],
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('角色設定', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('選擇你的角色模式',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        _ModeCard(
          title: '自我成長',
          subtitle: '角色反映你自己的身體變化和進步',
          emoji: '💪',
          selected: _charMode == CharacterMode.self,
          onTap: () => setState(() => _charMode = CharacterMode.self),
          theme: theme,
        ),
        const SizedBox(height: 12),
        _ModeCard(
          title: '映照',
          subtitle: '角色是你理想中的對象，你的進步讓TA變得更完美',
          emoji: '💕',
          selected: _charMode == CharacterMode.mirror,
          onTap: () => setState(() => _charMode = CharacterMode.mirror),
          theme: theme,
        ),
        if (_charMode == CharacterMode.mirror) ...[
          const SizedBox(height: 16),
          Text('映照對象的性別', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _mirrorGender = '她'),
                  child: _GenderCard(
                      label: '她', selected: _mirrorGender == '她', theme: theme),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _mirrorGender = '他'),
                  child: _GenderCard(
                      label: '他', selected: _mirrorGender == '他', theme: theme),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 32),
        Row(children: [
          Expanded(
              child: OutlinedButton(
                  onPressed: () => setState(() => _step = 1),
                  child: const Text('上一步'))),
          const SizedBox(width: 12),
          Expanded(child: _NextButton(onTap: () => setState(() => _step = 3))),
        ]),
      ],
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('一切就緒！', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('${_nicknameCtrl.text.trim()}，歡迎來到時光機',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 32),
        _SummaryRow('目標', _goal.label, theme),
        _SummaryRow('性別', _sex, theme),
        _SummaryRow('角色模式',
            _charMode == CharacterMode.self ? '自我成長' : '映照（$_mirrorGender）',
            theme),
        const SizedBox(height: 40),
        _loading
            ? const Center(child: CircularProgressIndicator())
            : FilledButton(
                onPressed: _finish,
                child: const Text('開始 時光機 ！'),
              ),
        const SizedBox(height: 12),
        OutlinedButton(
            onPressed: () => setState(() => _step = 2),
            child: const Text('上一步')),
      ],
    );
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    await provider.createProfile(
      nickname: _nicknameCtrl.text.trim(),
      goal: _goal,
      height: double.tryParse(_heightCtrl.text),
      weight: double.tryParse(_weightCtrl.text),
      age: int.tryParse(_ageCtrl.text),
      sex: _sex,
      characterMode: _charMode,
      mirrorGender: _charMode == CharacterMode.mirror ? _mirrorGender : null,
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('⏰', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text('時光機',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
        Text('生活目標 × 飲食記錄 × 角色養成',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int step;
  final ThemeData theme;
  const _Header({required this.step, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          final active = i == step;
          final done = i < step;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 32 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: done || active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NextButton({required this.onTap});

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    child: const Text('下一步'),
  );
}

class _GoalCards extends StatelessWidget {
  final BodyGoal value;
  final ValueChanged<BodyGoal> onChanged;
  final ThemeData theme;
  const _GoalCards({required this.value, required this.onChanged, required this.theme});

  @override
  Widget build(BuildContext context) {
    const goals = [
      (BodyGoal.loseFat, '減脂', '🔥', '燃燒脂肪，塑造線條'),
      (BodyGoal.gainMuscle, '增肌', '💪', '增加肌肉，提升力量'),
      (BodyGoal.maintain, '維持', '⚖️', '維持現狀，健康生活'),
    ];
    return Column(
      children: goals.map((g) {
        final selected = value == g.$1;
        return GestureDetector(
          onTap: () => onChanged(g.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Text(g.$3, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.$2,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? theme.colorScheme.primary
                                : null)),
                    Text(g.$4,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle,
                      color: theme.colorScheme.primary),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title, subtitle, emoji;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ModeCard({
    required this.title, required this.subtitle, required this.emoji,
    required this.selected, required this.onTap, required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold,
                              color: selected ? theme.colorScheme.primary : null)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeData theme;
  const _GenderCard({required this.label, required this.selected, required this.theme});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      border: selected
          ? Border.all(color: theme.colorScheme.primary, width: 2)
          : null,
    ),
    child: Center(
      child: Text(label,
          style: theme.textTheme.titleLarge
              ?.copyWith(color: selected ? theme.colorScheme.primary : null)),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final ThemeData theme;
  const _SummaryRow(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Text('$label：',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
