import 'dart:math' as math;

import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:cici_word/core/services/i_tts_service.dart';
import 'package:cici_word/core/theme/app_colors.dart';
import 'package:cici_word/data/models/word.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:cici_word/features/study/viewmodel/study_session_viewmodel.dart';
import 'package:cici_word/shared/pages/session_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class StudyPage extends StatelessWidget {
  const StudyPage({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StudySessionViewModel(
        context.read<IWordRepository>(),
        bookId: bookId,
      )..ensureLoaded(),
      child: _StudyPageBody(bookId: bookId),
    );
  }
}

class _StudyPageBody extends StatelessWidget {
  const _StudyPageBody({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudySessionViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => popOrGo(context, '/wordbook/$bookId'),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('学习'),
        ),
        body: Center(child: Text(vm.error!)),
      );
    }

    if (vm.isCompleted) {
      return SessionSummaryPage(
        knownCount: vm.knownCount,
        fuzzyCount: vm.fuzzyCount,
        unknownCount: vm.unknownCount,
        onRestart: vm.restart,
        onBackToWordbook: () => popOrGo(context, '/wordbook/$bookId'),
      );
    }

    final currentWord = vm.currentWord;
    if (currentWord == null) {
      return const Scaffold(
        body: Center(child: Text('暂无学习内容')),
      );
    }

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): _FlipIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _NavigateIntent(false),
        SingleActivator(LogicalKeyboardKey.arrowRight): _NavigateIntent(true),
        SingleActivator(LogicalKeyboardKey.arrowUp): _GradeIntent(Familiarity.known),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            _GradeIntent(Familiarity.unknown),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _FlipIntent: CallbackAction<_FlipIntent>(
            onInvoke: (_) {
              vm.flipCurrent();
              return null;
            },
          ),
          _NavigateIntent: CallbackAction<_NavigateIntent>(
            onInvoke: (intent) {
              if (intent.forward) {
                vm.goToNext();
              } else {
                vm.goToPrevious();
              }
              return null;
            },
          ),
          _GradeIntent: CallbackAction<_GradeIntent>(
            onInvoke: (intent) async {
              await vm.markCurrent(intent.familiarity);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => popOrGo(context, '/wordbook/$bookId'),
                icon: const Icon(Icons.arrow_back),
              ),
              title: const Text('学习'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: _ProgressRing(
                      progress: vm.progress,
                      displayCount: vm.currentIndex + 1,
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _StudyGestureHint(),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: _StudyDeck(
                        word: currentWord,
                        isFlipped: vm.isCurrentFlipped,
                        onFlip: vm.flipCurrent,
                        onGrade: vm.markCurrent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.displayCount,
  });

  final double progress;
  final int displayCount;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 17,
        );

    return SizedBox(
      width: 38,
      height: 38,
      child: CustomPaint(
        painter: _RingPainter(progress),
        child: Center(
          child: Text(
            '$displayCount',
            style: textStyle,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.6;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = AppColors.dividerLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final foregroundPaint = Paint()
      ..color = AppColors.known
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _StudyGestureHint extends StatelessWidget {
  const _StudyGestureHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoftLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swipe_rounded,
              size: 16,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 6),
            Text(
              '<- 左滑上一词  ·  右滑下一词 ->  ·  ↑ 认识  ·  ↓ 不认识',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyDeck extends StatelessWidget {
  const _StudyDeck({
    required this.word,
    required this.isFlipped,
    required this.onFlip,
    required this.onGrade,
  });

  final Word word;
  final bool isFlipped;
  final VoidCallback onFlip;
  final Future<void> Function(Familiarity familiarity) onGrade;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          top: 28,
          left: 10,
          right: 10,
          child: _DeckShadow(opacity: 0.22),
        ),
        Positioned.fill(
          top: 14,
          left: 5,
          right: 5,
          child: _DeckShadow(opacity: 0.4),
        ),
        Positioned.fill(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 600),
              child: _StudyFlashcard(
                word: word,
                isFlipped: isFlipped,
                onFlip: onFlip,
                onGrade: onGrade,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeckShadow extends StatelessWidget {
  const _DeckShadow({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardLight.withOpacity(opacity),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.dividerLight),
      ),
    );
  }
}

class _StudyFlashcard extends StatefulWidget {
  const _StudyFlashcard({
    required this.word,
    required this.isFlipped,
    required this.onFlip,
    required this.onGrade,
  });

  final Word word;
  final bool isFlipped;
  final VoidCallback onFlip;
  final Future<void> Function(Familiarity familiarity) onGrade;

  @override
  State<_StudyFlashcard> createState() => _StudyFlashcardState();
}

class _StudyFlashcardState extends State<_StudyFlashcard> {
  double _dragOffsetX = 0;
  double _dragOffsetY = 0;

  @override
  void didUpdateWidget(covariant _StudyFlashcard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word.id != widget.word.id ||
        oldWidget.isFlipped != widget.isFlipped) {
      _dragOffsetX = 0;
      _dragOffsetY = 0;
    }
  }

  _GestureAction get _gestureAction {
    if (_dragOffsetX >= 120) {
      return _GestureAction.next;
    }
    if (_dragOffsetX <= -120) {
      return _GestureAction.previous;
    }
    if (_dragOffsetY <= -120) {
      return _GestureAction.known;
    }
    if (_dragOffsetY >= 120) {
      return _GestureAction.unknown;
    }
    return _GestureAction.none;
  }

  Color get _overlayColor {
    if (_dragOffsetY < -24) {
      return AppColors.known.withOpacity(0.14);
    }
    if (_dragOffsetY > 24) {
      return AppColors.unknown.withOpacity(0.14);
    }
    if (_dragOffsetX > 24) {
      return AppColors.primary.withOpacity(0.12);
    }
    if (_dragOffsetX < -24) {
      return AppColors.fuzzy.withOpacity(0.12);
    }
    return Colors.transparent;
  }

  Future<void> _handlePanEnd() async {
    final action = _gestureAction;
    setState(() {
      _dragOffsetX = 0;
      _dragOffsetY = 0;
    });

    switch (action) {
      case _GestureAction.previous:
        context.read<StudySessionViewModel>().goToPrevious();
        return;
      case _GestureAction.next:
        context.read<StudySessionViewModel>().goToNext();
        return;
      case _GestureAction.known:
        await widget.onGrade(Familiarity.known);
        return;
      case _GestureAction.unknown:
        await widget.onGrade(Familiarity.unknown);
        return;
      case _GestureAction.none:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotationDegrees = (_dragOffsetX / 240 * 15).clamp(-15.0, 15.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onFlip,
      onPanUpdate: (details) {
        setState(() {
          _dragOffsetX += details.delta.dx;
          _dragOffsetY += details.delta.dy;
          _dragOffsetX = _dragOffsetX.clamp(-220.0, 220.0).toDouble();
          _dragOffsetY = _dragOffsetY.clamp(-220.0, 220.0).toDouble();
        });
      },
      onPanEnd: (_) => _handlePanEnd(),
      child: Transform.rotate(
        angle: rotationDegrees * math.pi / 180,
        child: Transform.translate(
          offset: Offset(_dragOffsetX, _dragOffsetY * 0.35),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: const BorderSide(color: AppColors.dividerLight),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _overlayColor,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                  child: widget.isFlipped
                      ? _StudyBackFace(word: widget.word)
                      : _StudyFrontFace(word: widget.word),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyFrontFace extends StatelessWidget {
  const _StudyFrontFace({required this.word});

  final Word word;

  Future<void> _speak(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await context.read<ITtsService>().speakEnglish(word.english);
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('朗读暂时不可用，请稍后再试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: FilledButton.tonalIcon(
            onPressed: () => _speak(context),
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('朗读'),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  word.english,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  word.usPhonetic,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StudyBackFace extends StatelessWidget {
  const _StudyBackFace({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final hasPartOfSpeech = word.partOfSpeech.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            children: [
              if (hasPartOfSpeech)
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
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
                      word.partOfSpeech,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Text(
                    word.chinese,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoftLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividerLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '例句',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                word.exampleSentenceEn,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                word.exampleSentenceCn,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlipIntent extends Intent {
  const _FlipIntent();
}

class _NavigateIntent extends Intent {
  const _NavigateIntent(this.forward);

  final bool forward;
}

class _GradeIntent extends Intent {
  const _GradeIntent(this.familiarity);

  final Familiarity familiarity;
}

enum _GestureAction {
  none,
  previous,
  next,
  known,
  unknown,
}
