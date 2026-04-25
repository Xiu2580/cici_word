import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:cici_word/core/theme/app_colors.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:cici_word/data/repositories/i_wordbook_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/search_viewmodel.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.viewModel});

  final SearchViewModel? viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel != null) {
      return ChangeNotifierProvider<SearchViewModel>.value(
        value: viewModel!,
        child: const _SearchPageScaffold(),
      );
    }

    return ChangeNotifierProvider<SearchViewModel>(
      create: (context) => SearchViewModel(
        context.read<IWordRepository>(),
        context.read<IWordbookRepository>(),
      ),
      child: const _SearchPageScaffold(),
    );
  }
}

class _SearchPageScaffold extends StatefulWidget {
  const _SearchPageScaffold();

  @override
  State<_SearchPageScaffold> createState() => _SearchPageScaffoldState();
}

class _SearchPageScaffoldState extends State<_SearchPageScaffold> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<SearchViewModel>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => popOrGo(context, '/wordbook'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('搜索'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _controller,
                    onChanged: vm.updateQuery,
                    decoration: InputDecoration(
                      hintText: '输入英文或中文开始搜索',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: vm.query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _controller.clear();
                                vm.updateQuery('');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                  ),
                  if (vm.query.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '共找到 ${vm.results.length} 个结果',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (vm.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (vm.error != null) {
                    return Center(child: Text(vm.error!));
                  }

                  if (vm.query.trim().isEmpty) {
                    return const _SearchEmptyState(
                      icon: Icons.manage_search_rounded,
                      title: '输入英文或中文开始搜索',
                      subtitle: '例如 apple、苹果、n.',
                    );
                  }

                  if (vm.results.isEmpty) {
                    return const _SearchEmptyState(
                      icon: Icons.search_off_rounded,
                      title: '没有找到匹配结果',
                      subtitle: '试试更短的关键词，或换成中文/英文搜索',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: vm.results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final word = vm.results[index];
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
                                    onPressed: () => vm.toggleFavorite(word.id),
                                    icon: Icon(
                                      word.isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: word.isFavorite
                                          ? AppColors.unknown
                                          : null,
                                    ),
                                    tooltip:
                                        word.isFavorite ? '取消收藏' : '加入收藏',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                word.chinese,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (word.partOfSpeech.trim().isNotEmpty)
                                    _WordTag(label: word.partOfSpeech),
                                  if (word.usPhonetic.trim().isNotEmpty)
                                    _WordTag(label: '美 ${word.usPhonetic}'),
                                  if (word.ukPhonetic.trim().isNotEmpty)
                                    _WordTag(label: '英 ${word.ukPhonetic}'),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WordTag extends StatelessWidget {
  const _WordTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
