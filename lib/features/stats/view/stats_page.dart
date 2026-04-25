import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:cici_word/data/repositories/i_wordbook_repository.dart';
import 'package:cici_word/features/stats/viewmodel/stat_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, this.viewModel});

  final StatViewModel? viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel != null) {
      return ChangeNotifierProvider<StatViewModel>.value(
        value: viewModel!,
        child: const _StatsPageScaffold(),
      );
    }

    return ChangeNotifierProvider<StatViewModel>(
      create: (context) => StatViewModel(
        context.read<IWordRepository>(),
        context.read<IWordbookRepository>(),
      ),
      child: const _StatsPageScaffold(),
    );
  }
}

class _StatsPageScaffold extends StatelessWidget {
  const _StatsPageScaffold();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatViewModel>();
    final stats = vm.stats;
    final correctRate = '${(stats.correctRate * 100).round()}%';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => popOrGo(context, '/wordbook'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('学习统计'),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? Center(child: Text(vm.error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '学习统计',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '用简单指标快速查看当前学习状态',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StatCard(title: '今日学习', value: '${stats.todayLearned}'),
                        _StatCard(title: '今日复习', value: '${stats.todayReviewed}'),
                        _StatCard(title: '累计掌握', value: '${stats.totalMastered}'),
                        _StatCard(title: '连续天数', value: '${stats.streakDays} 天'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '正确率',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              correctRate,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: stats.correctRate.clamp(0.0, 1.0),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: vm.load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('刷新统计'),
                    ),
                  ],
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
