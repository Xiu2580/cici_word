import 'dart:math';

import 'package:cici_word/data/models/word.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:cici_word/features/review/viewmodel/review_mistake_store.dart';
import 'package:flutter/foundation.dart';

typedef DictationMaskBuilder = String Function(String word, int index);

class DictationSessionViewModel extends ChangeNotifier {
  DictationSessionViewModel(
    this._wordRepository, {
    required this.bookId,
    required this.mode,
    DictationMaskBuilder? maskBuilder,
    ReviewMistakeStore? mistakeStore,
  })  : _maskBuilder = maskBuilder ?? _defaultMaskBuilder,
        _mistakeStore = mistakeStore;

  final IWordRepository _wordRepository;
  final String bookId;
  final String mode;
  final DictationMaskBuilder _maskBuilder;
  final ReviewMistakeStore? _mistakeStore;

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  List<Word> _words = const [];
  int _currentIndex = 0;
  bool _isCompleted = false;
  Map<int, String> _cellInputs = {};
  int _activeIndex = -1;
  String? _feedback;
  String? _correctAnswer;
  bool _showResult = false;
  Set<int> _revealedIndexes = <int>{};
  int _correctCount = 0;
  int _wrongCount = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentIndex => _currentIndex;
  int get totalCount => _words.length;
  bool get isCompleted => _isCompleted;
  bool get showResult => _showResult;
  String get input => _cellInputs.entries
      .toList()
      .map((e) => e.value)
      .join();
  String? get feedback => _feedback;
  String? get correctAnswer => _correctAnswer;
  int get correctCount => _correctCount;
  int get wrongCount => _wrongCount;
  int get activeIndex => _activeIndex;
  double get progress =>
      _words.isEmpty ? 0 : (_currentIndex + 1) / _words.length;
  Word? get currentWord =>
      _words.isEmpty || _currentIndex >= _words.length
          ? null
          : _words[_currentIndex];

  List<DictationLetterCell> get letterCells {
    final word = currentWord;
    if (word == null) {
      return const [];
    }
    final letters = word.english.split('');

    return List.generate(letters.length, (index) {
      final actual = letters[index];
      final cellInput = _cellInputs[index];

      if (cellInput != null && cellInput.isNotEmpty) {
        final normalizedTyped = cellInput.toLowerCase();
        if (_showResult) {
          return DictationLetterCell(
            value: normalizedTyped,
            state: normalizedTyped == actual.toLowerCase()
                ? DictationLetterState.correct
                : DictationLetterState.wrong,
          );
        }
        return DictationLetterCell(
          value: normalizedTyped,
          state: DictationLetterState.filled,
        );
      }
      if (_revealedIndexes.contains(index)) {
        return DictationLetterCell(
          value: actual,
          state: DictationLetterState.revealed,
        );
      }
      return DictationLetterCell(
        value: '',
        state: DictationLetterState.empty,
        isFocused: !_showResult && index == _activeIndex,
      );
    });
  }

  int get focusedIndex => _showResult ? -1 : _activeIndex;

  Future<void> ensureLoaded() async {
    if (_isLoading || _hasLoaded) {
      return;
    }
    await load();
  }

  Future<void> load() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _words = await _wordRepository.getWords(bookId);
      if (_words.isNotEmpty) {
        _seedRevealedIndexes();
        _selectFirstEditable();
      }
      _hasLoaded = true;
    } catch (_) {
      _error = '默写内容加载失败，请稍后重试。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCell(int index) {
    final word = currentWord;
    if (word == null || _showResult) return;

    final hiddenIndexes = _hiddenIndexes(word.english.length);
    if (!hiddenIndexes.contains(index)) return;

    _activeIndex = index;
    notifyListeners();
  }

  void onKey(String character) {
    final word = currentWord;
    if (word == null || _showResult) return;

    if (_activeIndex < 0) {
      _selectFirstEditable();
    }
    if (_activeIndex < 0) return;

    final hiddenIndexes = _hiddenIndexes(word.english.length);
    if (!hiddenIndexes.contains(_activeIndex)) return;

    _cellInputs[_activeIndex] = character;
    _advanceActive(hiddenIndexes);
    notifyListeners();
  }

  void deleteAtActive() {
    if (_showResult || _cellInputs.isEmpty) return;

    final word = currentWord;
    if (word == null) return;

    final hiddenIndexes = _hiddenIndexes(word.english.length);
    if (hiddenIndexes.isEmpty) return;

    final activePos = hiddenIndexes.indexOf(_activeIndex);
    final startIdx =
        activePos >= 0 ? activePos : hiddenIndexes.length - 1;

    for (var i = startIdx; i >= 0; i--) {
      final pos = hiddenIndexes[i];
      if (_cellInputs.containsKey(pos)) {
        _cellInputs.remove(pos);
        _activeIndex = pos;
        notifyListeners();
        return;
      }
    }
  }

  void submit() {
    final word = currentWord;
    if (word == null || _showResult) {
      return;
    }

    final hiddenCount = _hiddenIndexes(word.english.length).length;
    if (_cellInputs.length < hiddenCount) {
      _feedback = '请填写完整';
      _correctAnswer = null;
      _showResult = true;
      _wrongCount += 1;
      _mistakeStore?.addWord(word);
      notifyListeners();
      return;
    }

    final normalizedInput = _normalize(_buildAttemptedWord(word));
    final normalizedAnswer = _normalize(word.english);
    if (normalizedInput == normalizedAnswer) {
      _feedback = '回答正确';
      _correctAnswer = null;
      _correctCount += 1;
    } else {
      _feedback = '回答错误';
      _correctAnswer = word.english;
      _wrongCount += 1;
      _mistakeStore?.addWord(word);
    }
    _showResult = true;
    notifyListeners();
  }

  void next() {
    if (!_showResult) {
      return;
    }

    if (_currentIndex >= _words.length - 1) {
      _isCompleted = true;
      notifyListeners();
      return;
    }

    _currentIndex += 1;
    _cellInputs = {};
    _activeIndex = -1;
    _feedback = null;
    _correctAnswer = null;
    _showResult = false;
    _seedRevealedIndexes();
    _selectFirstEditable();
    notifyListeners();
  }

  void skipCurrent() {
    final word = currentWord;
    if (word == null || _showResult) {
      return;
    }
    _feedback = '已跳过';
    _correctAnswer = word.english;
    _wrongCount += 1;
    _showResult = true;
    _mistakeStore?.addWord(word);
    notifyListeners();
  }

  void restart() {
    _currentIndex = 0;
    _isCompleted = false;
    _cellInputs = {};
    _activeIndex = -1;
    _feedback = null;
    _correctAnswer = null;
    _showResult = false;
    _correctCount = 0;
    _wrongCount = 0;
    _seedRevealedIndexes();
    _selectFirstEditable();
    notifyListeners();
  }

  void _selectFirstEditable() {
    final word = currentWord;
    if (word == null) return;
    final hiddenIndexes = _hiddenIndexes(word.english.length);
    if (hiddenIndexes.isNotEmpty) {
      _activeIndex = hiddenIndexes.first;
    }
  }

  void _advanceActive(List<int> hiddenIndexes) {
    final currentPos = hiddenIndexes.indexOf(_activeIndex);
    if (currentPos >= 0 && currentPos < hiddenIndexes.length - 1) {
      _activeIndex = hiddenIndexes[currentPos + 1];
    } else {
      _activeIndex = -1;
    }
  }

  void _seedRevealedIndexes() {
    final word = currentWord;
    _revealedIndexes = <int>{};
    if (word == null || mode != 'hint' || word.english.isEmpty) {
      return;
    }
    final mask = _maskBuilder(word.english, _currentIndex);
    final letters = word.english.split('');
    final maskLetters = mask.split('');

    for (var index = 0; index < letters.length; index++) {
      if (index >= maskLetters.length) {
        continue;
      }
      final actual = letters[index];
      final masked = maskLetters[index];
      if (masked.toLowerCase() == actual.toLowerCase()) {
        _revealedIndexes.add(index);
      }
    }

    if (_revealedIndexes.isEmpty) {
      _revealedIndexes.add(0);
    }
  }

  List<int> _hiddenIndexes(int length) {
    if (mode != 'hint') {
      return List<int>.generate(length, (index) => index);
    }
    return List<int>.generate(length, (index) => index)
        .where((index) => !_revealedIndexes.contains(index))
        .toList();
  }

  String _buildAttemptedWord(Word word) {
    final letters = word.english.split('');
    for (final entry in _cellInputs.entries) {
      if (entry.key < letters.length) {
        letters[entry.key] = entry.value;
      }
    }
    return letters.join();
  }

  static String _normalize(String value) => value.trim().toLowerCase();

  static String _defaultMaskBuilder(String word, int index) {
    if (word.isEmpty) return '';

    final chars = word.split('');
    final len = chars.length;
    if (len == 1) return word;

    final rng = Random(Object.hash(word, index));

    if (len <= 3) {
      final keep = <int>{rng.nextInt(len)};
      return _buildMask(chars, keep);
    }

    final pct = 0.30 + rng.nextDouble() * 0.20;
    final revealCount = ((len - 1) * pct).round().clamp(1, len - 1);

    final positions = List<int>.generate(len, (i) => i);
    positions.shuffle(rng);

    final keep = positions.take(revealCount).toSet();

    return _buildMask(chars, keep);
  }

  static String _buildMask(List<String> chars, Set<int> keep) {
    final result = <String>[];
    for (var i = 0; i < chars.length; i++) {
      result.add(keep.contains(i) ? chars[i] : '_');
    }
    return result.join();
  }

}

enum DictationLetterState { empty, filled, revealed, correct, wrong }

@immutable
class DictationLetterCell {
  const DictationLetterCell({
    required this.value,
    required this.state,
    this.isFocused = false,
  });

  final String value;
  final DictationLetterState state;
  final bool isFocused;
}
