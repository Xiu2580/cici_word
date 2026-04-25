import 'package:cici_word/data/models/word.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:flutter/foundation.dart';

class StudySessionViewModel extends ChangeNotifier {
  StudySessionViewModel(
    this._wordRepository, {
    required this.bookId,
  });

  final IWordRepository _wordRepository;
  final String bookId;

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  List<Word> _words = const [];
  int _currentIndex = 0;
  bool _isCurrentFlipped = false;
  bool _isCompleted = false;

  int _knownCount = 0;
  int _fuzzyCount = 0;
  int _unknownCount = 0;
  Familiarity? _lastAction;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Word> get words => List.unmodifiable(_words);
  int get currentIndex => _currentIndex;
  bool get isCompleted => _isCompleted;
  int get totalCount => _words.length;
  bool get isCurrentFlipped => _isCurrentFlipped;
  bool get canGrade => _isCurrentFlipped && !_isCompleted;
  int get remainingCount => (_words.length - _currentIndex).clamp(0, _words.length);
  int get knownCount => _knownCount;
  int get fuzzyCount => _fuzzyCount;
  int get unknownCount => _unknownCount;
  Familiarity? get lastAction => _lastAction;
  double get progress =>
      _words.isEmpty ? 0 : (_currentIndex.clamp(0, _words.length)) / _words.length;

  Word? get currentWord =>
      _words.isEmpty || _currentIndex >= _words.length ? null : _words[_currentIndex];

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
      _hasLoaded = true;
    } catch (_) {
      _error = '学习内容加载失败，请稍后重试。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void flipCurrent() {
    if (_isCompleted || currentWord == null) {
      return;
    }
    _isCurrentFlipped = !_isCurrentFlipped;
    notifyListeners();
  }

  void revealCurrent() {
    if (_isCompleted || currentWord == null || _isCurrentFlipped) {
      return;
    }
    _isCurrentFlipped = true;
    notifyListeners();
  }

  void goToNext() {
    if (_isCompleted || _words.isEmpty) {
      return;
    }
    _currentIndex = (_currentIndex + 1) % _words.length;
    _isCurrentFlipped = false;
    notifyListeners();
  }

  void goToPrevious() {
    if (_isCompleted || _words.isEmpty) {
      return;
    }
    _currentIndex = (_currentIndex - 1 + _words.length) % _words.length;
    _isCurrentFlipped = false;
    notifyListeners();
  }

  Future<void> markCurrent(Familiarity familiarity) async {
    final word = currentWord;
    if (word == null) {
      return;
    }

    _lastAction = familiarity;
    switch (familiarity) {
      case Familiarity.known:
        _knownCount += 1;
        break;
      case Familiarity.fuzzy:
        _fuzzyCount += 1;
        break;
      case Familiarity.unknown:
        _unknownCount += 1;
        break;
    }

    await _wordRepository.markWord(word.id, familiarity);

    if (_currentIndex >= _words.length - 1) {
      _isCompleted = true;
      notifyListeners();
      return;
    }

    _currentIndex += 1;
    _isCurrentFlipped = false;
    notifyListeners();
  }

  void restart() {
    _currentIndex = 0;
    _isCurrentFlipped = false;
    _isCompleted = false;
    _knownCount = 0;
    _fuzzyCount = 0;
    _unknownCount = 0;
    _lastAction = null;
    notifyListeners();
  }
}
