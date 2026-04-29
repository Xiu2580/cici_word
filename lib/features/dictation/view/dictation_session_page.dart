import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:cici_word/core/theme/app_colors.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:cici_word/features/dictation/viewmodel/dictation_session_viewmodel.dart';
import 'package:cici_word/features/review/viewmodel/review_mistake_store.dart';
import 'package:cici_word/shared/pages/session_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DictationSessionPage extends StatelessWidget {
  const DictationSessionPage({
    super.key,
    required this.bookId,
    required this.mode,
    this.maskBuilder,
  });

  final String bookId;
  final String mode;
  final DictationMaskBuilder? maskBuilder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DictationSessionViewModel(
        context.read<IWordRepository>(),
        bookId: bookId,
        mode: mode,
        maskBuilder: maskBuilder,
        mistakeStore: Provider.of<ReviewMistakeStore?>(context, listen: false),
      )..ensureLoaded(),
      child: _DictationSessionBody(
        bookId: bookId,
        mode: mode,
      ),
    );
  }
}

class _DictationSessionBody extends StatefulWidget {
  const _DictationSessionBody({
    required this.bookId,
    required this.mode,
  });

  final String bookId;
  final String mode;

  @override
  State<_DictationSessionBody> createState() => _DictationSessionBodyState();
}

class _DictationSessionBodyState extends State<_DictationSessionBody> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DictationSessionViewModel>();

    if (_controller.text != vm.input) {
      _controller.value = _controller.value.copyWith(
        text: vm.input,
        selection: TextSelection.collapsed(offset: vm.input.length),
      );
    }

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => popOrGo(context, '/wordbook/${widget.bookId}'),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('默写练习'),
        ),
        body: Center(child: Text(vm.error!)),
      );
    }

    if (vm.isCompleted) {
      return SessionSummaryPage(
        knownCount: vm.correctCount,
        unknownCount: vm.wrongCount,
        onRestart: vm.restart,
        onBackToWordbook: () => popOrGo(context, '/wordbook/${widget.bookId}'),
      );
    }

    final word = vm.currentWord;
    if (word == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => popOrGo(context, '/wordbook/${widget.bookId}'),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('默写练习'),
        ),
        body: const Center(
          child: Text('当前词书暂无可默写内容'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => popOrGo(context, '/wordbook/${widget.bookId}'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('单词默写'),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _focusNode.requestFocus(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '第 ${vm.currentIndex + 1} / ${vm.totalCount} 题',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        Text(
                          '✓ ${vm.correctCount}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.known,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '✗ ${vm.wrongCount}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.unknown,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: vm.progress,
                    minHeight: 4,
                    backgroundColor: AppColors.dividerLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.known),
                  ),
                ),
                const SizedBox(height: 20),
                Offstage(
                  offstage: false,
                  child: SizedBox(
                    width: 1,
                    height: 1,
                    child: Opacity(
                      opacity: 0,
                      child: TextField(
                        focusNode: _focusNode,
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        onChanged: vm.updateInput,
                        onSubmitted: (_) => vm.submit(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              word.chinese,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              word.partOfSpeech,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '请根据提示写出单词',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: vm.letterCells
                                    .map((cell) => DictationLetterBox(cell: cell))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton(
                              onPressed: vm.showResult ? null : vm.skipCurrent,
                              child: const Text('跳过'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (vm.showResult)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            vm.feedback!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (vm.correctAnswer != null) ...[
                            const SizedBox(height: 8),
                            Text('正确答案：${vm.correctAnswer!}'),
                          ],
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: vm.next,
                            child: const Text('下一题'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DictationLetterBox extends StatelessWidget {
  const DictationLetterBox({super.key, required this.cell});

  final DictationLetterCell cell;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.dividerLight;
    Color backgroundColor = Colors.transparent;
    Color textColor = AppColors.textPrimaryLight;

    switch (cell.state) {
      case DictationLetterState.empty:
        break;
      case DictationLetterState.filled:
        borderColor = AppColors.primary;
        backgroundColor = AppColors.surfaceSoftLight;
        break;
      case DictationLetterState.revealed:
        borderColor = AppColors.primary;
        backgroundColor = AppColors.surfaceSoftLight;
        textColor = AppColors.primary;
        break;
      case DictationLetterState.correct:
        borderColor = AppColors.known;
        backgroundColor = const Color(0xFFE8F5EC);
        textColor = AppColors.known;
        break;
      case DictationLetterState.wrong:
        borderColor = AppColors.unknown;
        backgroundColor = const Color(0xFFF8E7E4);
        textColor = AppColors.unknown;
        break;
    }

    return Container(
      width: 34,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.6),
        color: backgroundColor,
      ),
      alignment: Alignment.center,
      child: Text(
        cell.value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
