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
  String _input = '';
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
  String get input => _input;
  String? get feedback => _feedback;
  String? get correctAnswer => _correctAnswer;
  int get correctCount => _correctCount;
  int get wrongCount => _wrongCount;
  double get progress => _words.isEmpty ? 0 : (_currentIndex + 1) / _words.length;
  Word? get currentWord =>
      _words.isEmpty || _currentIndex >= _words.length ? null : _words[_currentIndex];

  List<DictationLetterCell> get letterCells {
    final word = currentWord;
    if (word == null) {
      return const [];
    }
    final letters = word.english.split('');
    final inputLetters = _input.split('');
    final hiddenIndexes = _hiddenIndexes(letters.length);
    final typedByIndex = <int, String>{};

    for (var i = 0; i < hiddenIndexes.length && i < inputLetters.length; i++) {
      typedByIndex[hiddenIndexes[i]] = inputLetters[i];
    }

    return List.generate(letters.length, (index) {
      final actual = letters[index];
      final typed = mode == 'hint' ? typedByIndex[index] : (index < inputLetters.length ? inputLetters[index] : null);
      if (typed != null && typed.isNotEmpty) {
        final normalizedTyped = typed.toLowerCase();
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
      return const DictationLetterCell(
        value: '',
        state: DictationLetterState.empty,
      );
    });
  }

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
      }
      _hasLoaded = true;
    } catch (_) {
      _error = '默写内容加载失败，请稍后重试。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateInput(String value) {
    final word = currentWord;
    if (word == null) {
      _input = value;
      notifyListeners();
      return;
    }

    final maxLen = word.english.length;
    _input = value.length <= maxLen ? value : value.substring(0, maxLen);
    if (mode == 'hint') {
      final hiddenCount = _hiddenIndexes(word.english.length).length;
      _input = _input.length <= hiddenCount
          ? _input
          : _input.substring(0, hiddenCount);
    }
    notifyListeners();
  }

  void submit() {
    final word = currentWord;
    if (word == null || _showResult) {
      return;
    }

    // In hint mode, require all hidden positions to be filled
    if (mode == 'hint') {
      final hiddenCount = _hiddenIndexes(word.english.length).length;
      if (_input.length < hiddenCount) {
        _feedback = '请填写完整';
        _correctAnswer = null;
        _showResult = true;
        _wrongCount += 1;
        _mistakeStore?.addWord(word);
        notifyListeners();
        return;
      }
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
    _input = '';
    _feedback = null;
    _correctAnswer = null;
    _showResult = false;
    _seedRevealedIndexes();
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
    _input = '';
    _feedback = null;
    _correctAnswer = null;
    _showResult = false;
    _correctCount = 0;
    _wrongCount = 0;
    _seedRevealedIndexes();
    notifyListeners();
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
    if (mode != 'hint') {
      return _input;
    }

    final letters = word.english.split('');
    final inputLetters = _input.split('');
    final hiddenIndexes = _hiddenIndexes(letters.length);

    for (var i = 0; i < hiddenIndexes.length && i < inputLetters.length; i++) {
      letters[hiddenIndexes[i]] = inputLetters[i];
    }

    return letters.join();
  }

  static String _normalize(String value) => value.trim().toLowerCase();

  static String _defaultMaskBuilder(String word, int index) {
    if (word.length <= 1) {
      return word;
    }

    final chars = word.split('');
    final keep = <int>{0};

    if (word.length >= 3) {
      keep.add(word.length - 1);
    }

    if (word.length >= 6) {
      final extraIndex = word.length ~/ 2;
      keep.add(extraIndex);
    }

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
  });

  final String value;
  final DictationLetterState state;
}
