import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../viewmodel/settings_viewmodel.dart';
import '../viewmodel/theme_viewmodel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static final Uri _projectUri =
      Uri.parse('https://github.com/wfeng7578/cici_word');

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final themeVm = context.watch<ThemeViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: '应用设置',
            children: [
              _DialogSelectTile(
                title: '主题模式',
                subtitle: '跟随系统、浅色或深色',
                valueLabel: _themeModeLabel(themeVm.mode),
                onTap: () async {
                  final value = await _showSelectDialog<ThemeMode>(
                    context: context,
                    title: '主题模式',
                    currentValue: themeVm.mode,
                    options: const [
                      _SelectOption(value: ThemeMode.system, label: '跟随系统'),
                      _SelectOption(value: ThemeMode.light, label: '浅色'),
                      _SelectOption(value: ThemeMode.dark, label: '深色'),
                    ],
                  );
                  if (value != null) {
                    themeVm.setThemeMode(value);
                  }
                },
              ),
              _SliderTile(
                title: '字号大小',
                subtitle: '按中文阅读场景调整文字大小',
                value: themeVm.fontScale,
                min: 0.8,
                max: 1.3,
                divisions: 5,
                label: themeVm.fontScale.toStringAsFixed(1),
                onChanged: themeVm.setFontScale,
              ),
              _SwitchTile(
                title: '动画开关',
                subtitle: '减少切换与翻页时的动态效果',
                value: themeVm.animationsEnabled,
                onChanged: themeVm.setAnimationsEnabled,
              ),
              _DialogSelectTile(
                title: '发音设置',
                subtitle: '选择美式或英式发音偏好',
                valueLabel: settingsVm.pronunciation == 'uk' ? '英式发音' : '美式发音',
                onTap: () async {
                  final value = await _showSelectDialog<String>(
                    context: context,
                    title: '发音设置',
                    currentValue: settingsVm.pronunciation,
                    options: const [
                      _SelectOption(value: 'us', label: '美式发音'),
                      _SelectOption(value: 'uk', label: '英式发音'),
                    ],
                  );
                  if (value != null) {
                    settingsVm.setPronunciation(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            title: '学习设置',
            children: [
              const _StaticTile(
                title: '学习顺序',
                subtitle: '按教材章节推进，后续可继续扩展随机模式',
              ),
              _SliderTile(
                title: '每次学习数量',
                subtitle: '控制单次学习的目标词数',
                value: settingsVm.dailyGoal.toDouble(),
                min: 5,
                max: 50,
                divisions: 9,
                label: '${settingsVm.dailyGoal}',
                onChanged: (value) => settingsVm.setDailyGoal(value.round()),
              ),
              _DialogSelectTile(
                title: '默写提示方式',
                subtitle: '设置开始默写时默认进入的模式',
                valueLabel: settingsVm.dictationMode == 'full' ? '完整默写' : '提示默写',
                onTap: () async {
                  final value = await _showSelectDialog<String>(
                    context: context,
                    title: '默写提示方式',
                    currentValue: settingsVm.dictationMode,
                    options: const [
                      _SelectOption(value: 'hint', label: '提示默写'),
                      _SelectOption(value: 'full', label: '完整默写'),
                    ],
                  );
                  if (value != null) {
                    settingsVm.setDictationMode(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            title: '数据管理',
            children: [
              _ActionTile(
                title: '清空学习记录',
                subtitle: '清空单词熟悉度与错词强化记录',
                actionLabel: '清空',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('清空学习记录'),
                        content: const Text('确定要清空当前的学习进度和错词记录吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            child: const Text('确定'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed != true) {
                    return;
                  }

                  await settingsVm.clearLearningRecords();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已清空学习记录')),
                  );
                },
              ),
              _ActionTile(
                title: '恢复默认设置',
                subtitle: '将应用设置恢复到初始状态',
                actionLabel: '恢复',
                onPressed: () async {
                  await settingsVm.resetDefaults();
                  themeVm.setThemeMode(ThemeMode.system);
                  themeVm.setFontScale(1.0);
                  themeVm.setAnimationsEnabled(true);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            title: '关于项目',
            children: [
              _LinkTile(
                title: '项目地址',
                subtitle: '点击跳转到 GitHub 仓库',
                actionLabel: '打开',
                onTap: () async {
                  final launched = await launchUrl(
                    _projectUri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!context.mounted || launched) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('暂时无法打开项目地址')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1) const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

String _themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return '跟随系统';
    case ThemeMode.light:
      return '浅色';
    case ThemeMode.dark:
      return '深色';
  }
}

Future<T?> _showSelectDialog<T>({
  required BuildContext context,
  required String title,
  required T currentValue,
  required List<_SelectOption<T>> options,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (option) => RadioListTile<T>(
                  value: option.value,
                  groupValue: currentValue,
                  title: Text(option.label),
                  onChanged: (value) {
                    Navigator.of(context).pop(value);
                  },
                ),
              )
              .toList(),
        ),
      );
    },
  );
}

class _SelectOption<T> {
  const _SelectOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class _DialogSelectTile extends StatelessWidget {
  const _DialogSelectTile({
    required this.title,
    required this.subtitle,
    required this.valueLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String valueLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(valueLabel, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: onChanged,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StaticTile extends StatelessWidget {
  const _StaticTile({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: onPressed,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}
