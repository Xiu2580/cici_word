import 'package:cici_word/core/theme/app_colors.dart';
import 'package:cici_word/data/models/wordbook.dart';
import 'package:cici_word/data/repositories/i_settings_repository.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:cici_word/data/repositories/i_wordbook_repository.dart';
import 'package:cici_word/features/dictation/dictation_route_helper.dart';
import 'package:cici_word/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:cici_word/features/wordbook/viewmodel/current_wordbook_viewmodel.dart';
import 'package:cici_word/features/wordbook/viewmodel/wordbook_v2_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WordbookV2Page extends StatelessWidget {
  const WordbookV2Page({
    super.key,
    this.viewModel,
    this.onStartStudy,
    this.onStartDictation,
    this.onViewWordList,
  });

  final WordbookV2ViewModel? viewModel;
  final VoidCallback? onStartStudy;
  final VoidCallback? onStartDictation;
  final ValueChanged<Wordbook>? onViewWordList;

  @override
  Widget build(BuildContext context) {
    if (viewModel != null) {
      return ChangeNotifierProvider<WordbookV2ViewModel>.value(
        value: viewModel!,
        child: _WordbookV2Scaffold(
          onStartStudy: onStartStudy,
          onStartDictation: onStartDictation,
          onViewWordList: onViewWordList,
        ),
      );
    }

    return ChangeNotifierProvider<WordbookV2ViewModel>(
      create: (context) => WordbookV2ViewModel(
        context.read<IWordbookRepository>(),
        context.read<IWordRepository>(),
        settingsRepository: context.read<ISettingsRepository>(),
      ),
      child: _WordbookV2Scaffold(
        onStartStudy: onStartStudy,
        onStartDictation: onStartDictation,
        onViewWordList: onViewWordList,
      ),
    );
  }
}

class _WordbookV2Scaffold extends StatefulWidget {
  const _WordbookV2Scaffold({
    this.onStartStudy,
    this.onStartDictation,
    this.onViewWordList,
  });

  final VoidCallback? onStartStudy;
  final VoidCallback? onStartDictation;
  final ValueChanged<Wordbook>? onViewWordList;

  @override
  State<_WordbookV2Scaffold> createState() => _WordbookV2ScaffoldState();
}

class _WordbookV2ScaffoldState extends State<_WordbookV2Scaffold> {
  bool _isGridLayout = false;
  WordbookV2ViewModel? _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<WordbookV2ViewModel>();
    _vm!.addListener(_syncSelectedBook);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vm!.ensureLoaded();
      _syncSelectedBook();
    });
  }

  @override
  void dispose() {
    _vm?.removeListener(_syncSelectedBook);
    super.dispose();
  }

  void _syncSelectedBook() {
    if (!mounted) {
      return;
    }
    final currentWordbookVm = context.read<CurrentWordbookViewModel>();
    final selectedBook = _vm!.selectedBook;
    if (currentWordbookVm.currentId != selectedBook?.id) {
      currentWordbookVm.setCurrent(selectedBook);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WordbookV2ViewModel>();
    final settingsVm = Provider.of<SettingsViewModel?>(context, listen: false);
    final selectedBook = vm.selectedBook;

    return Scaffold(
      appBar: AppBar(
        title: const Text('词库'),
        actions: [
          IconButton(
            onPressed: () => context.go('/import'),
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: '导入词书',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isGridLayout = !_isGridLayout;
              });
            },
            icon: Icon(
              _isGridLayout ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            tooltip: _isGridLayout ? '切换列表布局' : '切换网格布局',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                children: [
                  if (vm.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (vm.error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(vm.error!),
                      ),
                    )
                  else
                    for (final section in vm.sections) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 8),
                        child: Text(
                          section.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          section.subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (_isGridLayout)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GridView.builder(
                            key: ValueKey('wordbook-grid-${section.title}'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.95,
                            ),
                            itemCount: section.items.length,
                            itemBuilder: (context, index) {
                              final book = section.items[index];
                              return _WordbookCard(
                                book: book,
                                isSelected: vm.selectedBookId == book.id,
                                progressLabel: vm.progressLabel(book),
                                statsLabel: vm.statsLabel(book),
                                isCompact: true,
                                onSelect: () => vm.selectBook(book.id),
                                onViewWordList: widget.onViewWordList == null
                                    ? () => context.go('/wordbook/${book.id}')
                                    : () => widget.onViewWordList!(book),
                              );
                            },
                          ),
                        )
                      else
                        for (final book in section.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WordbookCard(
                              book: book,
                              isSelected: vm.selectedBookId == book.id,
                              progressLabel: vm.progressLabel(book),
                              statsLabel: vm.statsLabel(book),
                              isCompact: false,
                              onSelect: () => vm.selectBook(book.id),
                              onViewWordList: widget.onViewWordList == null
                                  ? () => context.go('/wordbook/${book.id}')
                                  : () => widget.onViewWordList!(book),
                            ),
                          ),
                    ],
                ],
              ),
            ),
            _WordbookActions(
              hasSelection: selectedBook != null,
              onStartStudy: widget.onStartStudy ??
                  (selectedBook == null
                      ? null
                      : () => context.go('/study/${selectedBook.id}')),
              onStartDictation: widget.onStartDictation ??
                  (selectedBook == null
                      ? null
                      : () => context.go(
                            buildDefaultDictationRoute(
                              bookId: selectedBook.id,
                              settings: settingsVm,
                            ),
                          )),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordbookCard extends StatelessWidget {
  const _WordbookCard({
    required this.book,
    required this.isSelected,
    required this.progressLabel,
    required this.statsLabel,
    required this.isCompact,
    required this.onSelect,
    required this.onViewWordList,
  });

  final Wordbook book;
  final bool isSelected;
  final String progressLabel;
  final String statsLabel;
  final bool isCompact;
  final VoidCallback onSelect;
  final VoidCallback onViewWordList;

  String get _displayName {
    switch (book.category) {
      case WordbookCategory.elementary:
        return book.name.replaceFirst('小学', '');
      case WordbookCategory.juniorHigh:
        return book.name.replaceFirst('初中', '');
      case WordbookCategory.seniorHigh:
        return book.name
            .replaceFirst('高中', '')
            .replaceFirst('一年级', '高一')
            .replaceFirst('二年级', '高二')
            .replaceFirst('三年级', '高三');
      case WordbookCategory.custom:
        return book.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primaryDark,
                    ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(statsLabel, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: onViewWordList,
                      child: const Text('查看词表'),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoftLight,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.dividerLight),
                        ),
                        child: Text(
                          '当前使用',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: onSelect,
                        child: const Text('设为当前'),
                      ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: onViewWordList,
                      child: const Text('查看词表'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordbookActions extends StatelessWidget {
  const _WordbookActions({
    required this.hasSelection,
    required this.onStartStudy,
    required this.onStartDictation,
  });

  final bool hasSelection;
  final VoidCallback? onStartStudy;
  final VoidCallback? onStartDictation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        border: Border(top: BorderSide(color: AppColors.dividerLight)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: hasSelection ? onStartDictation : null,
                child: const Text('开始默写'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: hasSelection ? onStartStudy : null,
                child: const Text('开始学习'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
