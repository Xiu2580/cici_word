import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:cici_word/core/theme/app_colors.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:cici_word/features/dictation/viewmodel/dictation_session_viewmodel.dart';
import 'package:cici_word/features/review/viewmodel/review_mistake_store.dart';
import 'package:cici_word/shared/pages/session_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _prevText = '';
  int _prevWordIndex = 0;
  DictationSessionViewModel? _vm;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _vm = context.read<DictationSessionViewModel>();
        _vm!.addListener(_onWordChanged);
        _focusNode.requestFocus();
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
      }
    });
  }

  void _onWordChanged() {
    if (!mounted || _vm == null) return;
    if (_vm!.currentIndex != _prevWordIndex) {
      _prevWordIndex = _vm!.currentIndex;
      _resetController();
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_onWordChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String newText) {
    final vm = context.read<DictationSessionViewModel>();
    if (newText.length > _prevText.length) {
      final added = newText.substring(_prevText.length);
      for (var i = 0; i < added.length; i++) {
        vm.onKey(added[i]);
      }
    } else if (newText.length < _prevText.length) {
      final removed = _prevText.length - newText.length;
      for (var i = 0; i < removed; i++) {
        vm.deleteAtActive();
      }
    }
    _prevText = newText;
  }

  void _resetController() {
    _prevText = '';
    _controller.clear();
  }

  void _onSubmitted(String _) {
    context.read<DictationSessionViewModel>().submit();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DictationSessionViewModel>();

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
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.known),
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
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z]'),
                          ),
                        ],
                        onChanged: _onChanged,
                        onSubmitted: _onSubmitted,
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
                                    .asMap()
                                    .entries
                                    .map((entry) => DictationLetterBox(
                                          cell: entry.value,
                                          onTap: () =>
                                              vm.selectCell(entry.key),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton(
                              onPressed:
                                  vm.showResult ? null : vm.skipCurrent,
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

class DictationLetterBox extends StatefulWidget {
  const DictationLetterBox({
    super.key,
    required this.cell,
    this.onTap,
  });

  final DictationLetterCell cell;
  final VoidCallback? onTap;

  @override
  State<DictationLetterBox> createState() => _DictationLetterBoxState();
}

class _DictationLetterBoxState extends State<DictationLetterBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.cell.isFocused) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant DictationLetterBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cell.isFocused && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.cell.isFocused && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cell = widget.cell;

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

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
          ),
          if (cell.isFocused)
            AnimatedBuilder(
              animation: _opacity,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacity.value,
                  child: Container(
                    width: 16,
                    height: 2.5,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
