import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:cici_word/core/services/i_tts_service.dart';
import 'package:cici_word/core/theme/app_colors.dart';
import 'package:cici_word/data/models/word.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:cici_word/data/repositories/i_wordbook_repository.dart';
import 'package:cici_word/features/dictation/dictation_route_helper.dart';
import 'package:cici_word/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:cici_word/features/wordbook/viewmodel/wordbook_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WordbookDetailPage extends StatelessWidget {
  const WordbookDetailPage({
    super.key,
    required this.bookId,
    this.onStartStudy,
    this.onStartDictation,
  });

  final String bookId;
  final VoidCallback? onStartStudy;
  final VoidCallback? onStartDictation;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WordbookDetailViewModel(
        context.read<IWordbookRepository>(),
        context.read<IWordRepository>(),
        bookId: bookId,
      )..ensureLoaded(),
      child: _WordbookDetailScaffold(
        bookId: bookId,
        onStartStudy: onStartStudy,
        onStartDictation: onStartDictation,
      ),
    );
  }
}

class _WordbookDetailScaffold extends StatelessWidget {
  const _WordbookDetailScaffold({
    required this.bookId,
    this.onStartStudy,
    this.onStartDictation,
  });

  final String bookId;
  final VoidCallback? onStartStudy;
  final VoidCallback? onStartDictation;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WordbookDetailViewModel>();
    final settingsVm = Provider.of<SettingsViewModel?>(context, listen: false);

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.error != null || vm.wordbook == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => popOrGo(context, '/wordbook'),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('词书详情'),
        ),
        body: Center(
          child: Text(vm.error ?? '未找到对应词书'),
        ),
      );
    }

    final wordbook = vm.wordbook!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => popOrGo(context, '/wordbook'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(wordbook.name),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                children: [
                  for (var index = 0; index < vm.words.length; index++)
                    _WordRow(
                      index: index + 1,
                      word: vm.words[index],
                      onToggleFavorite: () =>
                          vm.toggleFavorite(vm.words[index].id),
                    ),
                ],
              ),
            ),
            _WordbookDetailActions(
              onStartStudy: onStartStudy ?? () => context.go('/study/$bookId'),
              onStartDictation: onStartDictation ??
                  () => context.go(
                        buildDefaultDictationRoute(
                          bookId: bookId,
                          settings: settingsVm,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.index,
    required this.word,
    required this.onToggleFavorite,
  });

  final int index;
  final Word word;
  final Future<void> Function() onToggleFavorite;

  Future<void> _speak(BuildContext context) async {
    final tts = Provider.of<ITtsService?>(context, listen: false);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (tts == null) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('朗读暂时不可用，请稍后再试')),
      );
      return;
    }
    try {
      await tts.speakEnglish(word.english);
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('朗读暂时不可用，请稍后再试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$index',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  word.english,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (word.partOfSpeech.trim().isNotEmpty)
                  Text(
                    word.partOfSpeech,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                Text(
                  word.chinese,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _speak(context),
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: '朗读单词',
          ),
          IconButton(
            onPressed: onToggleFavorite,
            icon: Icon(
              word.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: word.isFavorite ? AppColors.secondary : null,
            ),
            tooltip: word.isFavorite ? '取消收藏' : '收藏单词',
          ),
        ],
      ),
    );
  }
}

class _WordbookDetailActions extends StatelessWidget {
  const _WordbookDetailActions({
    required this.onStartStudy,
    required this.onStartDictation,
  });

  final VoidCallback onStartStudy;
  final VoidCallback onStartDictation;

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
                onPressed: onStartDictation,
                child: const Text('开始默写'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onStartStudy,
                child: const Text('开始学习'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
