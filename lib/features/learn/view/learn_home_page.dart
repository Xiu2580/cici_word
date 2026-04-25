import 'package:cici_word/features/learn/viewmodel/learn_home_viewmodel.dart';
import 'package:cici_word/features/wordbook/viewmodel/current_wordbook_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LearnHomePage extends StatelessWidget {
  const LearnHomePage({
    super.key,
    this.viewModel,
    this.onBrowseWordbook,
    this.onStartStudy,
  });

  final LearnHomeViewModel? viewModel;
  final VoidCallback? onBrowseWordbook;
  final VoidCallback? onStartStudy;

  @override
  Widget build(BuildContext context) {
    if (viewModel != null) {
      return ChangeNotifierProvider<LearnHomeViewModel>.value(
        value: viewModel!,
        child: _LearnHomeScaffold(
          onBrowseWordbook: onBrowseWordbook,
          onStartStudy: onStartStudy,
        ),
      );
    }

    return ChangeNotifierProvider<LearnHomeViewModel>(
      create: (context) =>
          LearnHomeViewModel(context.read<CurrentWordbookViewModel>()),
      child: _LearnHomeScaffold(
        onBrowseWordbook: onBrowseWordbook,
        onStartStudy: onStartStudy,
      ),
    );
  }
}

class _LearnHomeScaffold extends StatelessWidget {
  const _LearnHomeScaffold({
    this.onBrowseWordbook,
    this.onStartStudy,
  });

  final VoidCallback? onBrowseWordbook;
  final VoidCallback? onStartStudy;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LearnHomeViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('学习')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EntryCard(
            title: vm.headline,
            subtitle: vm.subtitle,
          ),
          const SizedBox(height: 12),
          if (!vm.hasWordbook)
            FilledButton(
              onPressed: onBrowseWordbook ?? () => context.go('/wordbook'),
              child: Text(vm.primaryActionLabel),
            )
          else ...[
            FilledButton(
              onPressed: onStartStudy ?? () => context.go('/study/${vm.bookId}'),
              child: Text(vm.primaryActionLabel),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onBrowseWordbook ?? () => context.go('/wordbook'),
              child: Text(vm.secondaryActionLabel),
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
