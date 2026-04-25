import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/i_word_repository.dart';
import '../viewmodel/review_mistake_store.dart';
import '../viewmodel/review_page_viewmodel.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReviewPageViewModel(
        context.read<IWordRepository>(),
        mistakeStore: Provider.of<ReviewMistakeStore?>(context, listen: false),
      )..ensureLoaded(),
      child: const _ReviewPageBody(),
    );
  }
}

class _ReviewPageBody extends StatelessWidget {
  const _ReviewPageBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewPageViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('复习')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReviewStatCard(label: '今日待复习', value: '${vm.todayCount}'),
          const SizedBox(height: 8),
          _ReviewStatCard(label: '错词强化', value: '${vm.mistakeCount}'),
          const SizedBox(height: 8),
          _ReviewStatCard(label: '复习队列', value: '${vm.queueCount} 组'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: vm.isLoading || !vm.hasMistakes
                ? null
                : () => context.go('/review/mistakes'),
            child: const Text('开始复习'),
          ),
        ],
      ),
    );
  }
}

class _ReviewStatCard extends StatelessWidget {
  const _ReviewStatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
