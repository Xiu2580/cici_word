import 'package:cici_word/features/dictation/dictation_route_helper.dart';
import 'package:cici_word/features/dictation/viewmodel/dictation_home_viewmodel.dart';
import 'package:cici_word/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:cici_word/features/wordbook/viewmodel/current_wordbook_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DictationHomePage extends StatelessWidget {
  const DictationHomePage({
    super.key,
    this.viewModel,
    this.onBrowseWordbook,
    this.onStartDictation,
  });

  final DictationHomeViewModel? viewModel;
  final VoidCallback? onBrowseWordbook;
  final VoidCallback? onStartDictation;

  @override
  Widget build(BuildContext context) {
    if (viewModel != null) {
      return ChangeNotifierProvider<DictationHomeViewModel>.value(
        value: viewModel!,
        child: _DictationHomeScaffold(
          onBrowseWordbook: onBrowseWordbook,
          onStartDictation: onStartDictation,
        ),
      );
    }

    return ChangeNotifierProvider<DictationHomeViewModel>(
      create: (context) =>
          DictationHomeViewModel(context.read<CurrentWordbookViewModel>(),
              defaultMode:
                  Provider.of<SettingsViewModel?>(context, listen: false)
                      ?.dictationMode),
      child: _DictationHomeScaffold(
        onBrowseWordbook: onBrowseWordbook,
        onStartDictation: onStartDictation,
      ),
    );
  }
}

class _DictationHomeScaffold extends StatelessWidget {
  const _DictationHomeScaffold({
    this.onBrowseWordbook,
    this.onStartDictation,
  });

  final VoidCallback? onBrowseWordbook;
  final VoidCallback? onStartDictation;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DictationHomeViewModel>();
    final settingsVm = Provider.of<SettingsViewModel?>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('默写')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EntryCard(
            title: vm.headline,
            subtitle: vm.subtitle,
          ),
          const SizedBox(height: 12),
          _InfoChip(label: '当前模式', value: vm.modeLabel),
          const SizedBox(height: 20),
          if (!vm.hasWordbook)
            FilledButton(
              onPressed: onBrowseWordbook ?? () => context.go('/wordbook'),
              child: const Text('去词库看看'),
            )
          else ...[
            FilledButton(
              onPressed: onStartDictation ??
                  () => context.go(
                        buildDefaultDictationRoute(
                          bookId: vm.bookId!,
                          settings: settingsVm,
                        ),
                      ),
              child: const Text('开始默写'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onBrowseWordbook ?? () => context.go('/wordbook'),
              child: const Text('更换词书'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
