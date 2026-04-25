import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:cici_word/core/theme/app_colors.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/favorites_viewmodel.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, this.viewModel});

  final FavoritesViewModel? viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel != null) {
      return ChangeNotifierProvider<FavoritesViewModel>.value(
        value: viewModel!,
        child: const _FavoritesPageScaffold(),
      );
    }

    return ChangeNotifierProvider<FavoritesViewModel>(
      create: (context) => FavoritesViewModel(
        context.read<IWordRepository>(),
      ),
      child: const _FavoritesPageScaffold(),
    );
  }
}

class _FavoritesPageScaffold extends StatefulWidget {
  const _FavoritesPageScaffold();

  @override
  State<_FavoritesPageScaffold> createState() => _FavoritesPageScaffoldState();
}

class _FavoritesPageScaffoldState extends State<_FavoritesPageScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<FavoritesViewModel>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => popOrGo(context, '/wordbook'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('收藏'),
      ),
      body: Builder(
        builder: (context) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.error != null) {
            return Center(child: Text(vm.error!));
          }

          if (vm.isEmpty) {
            return const _FavoritesEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vm.words.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final word = vm.words[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              word.english,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: () => vm.removeFavorite(word.id),
                            icon: Icon(
                              word.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: word.isFavorite ? AppColors.unknown : null,
                            ),
                            tooltip: word.isFavorite ? '取消收藏' : '加入收藏',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word.chinese,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (word.partOfSpeech.trim().isNotEmpty)
                            _WordChip(label: word.partOfSpeech),
                          if (word.usPhonetic.trim().isNotEmpty)
                            _WordChip(label: '美 ${word.usPhonetic}'),
                        ],
                      ),
                      if (word.exampleSentenceEn.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          word.exampleSentenceEn,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (word.exampleSentenceCn.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          word.exampleSentenceCn,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 48,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 12),
            Text(
              '还没有收藏的单词',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '在搜索、学习或词表中把重要单词加入收藏',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
