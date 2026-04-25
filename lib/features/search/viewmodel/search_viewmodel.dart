import 'package:flutter/foundation.dart';

import '../../../data/models/word.dart';
import '../../../data/repositories/i_word_repository.dart';
import '../../../data/repositories/i_wordbook_repository.dart';

class SearchViewModel extends ChangeNotifier {
  SearchViewModel(this._wordRepository, this._wordbookRepository);

  final IWordRepository _wordRepository;
  final IWordbookRepository _wordbookRepository;

  final List<Word> _allWords = [];
  List<Word> _results = const [];

  bool _isLoading = false;
  bool _isLoaded = false;
  String _query = '';
  String? _error;

  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String get query => _query;
  String? get error => _error;
  List<Word> get results => List.unmodifiable(_results);

  Future<void> ensureLoaded() async {
    if (_isLoading || _isLoaded) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final books = await _wordbookRepository.getBuiltInWordbooks();
      final loadedWords = <Word>[];
      for (final book in books) {
        final words = await _wordRepository.getWords(book.id);
        loadedWords.addAll(words);
      }
      _allWords
        ..clear()
        ..addAll(loadedWords);
      _applyQuery(_query);
      _isLoaded = true;
    } catch (_) {
      _error = '搜索内容加载失败，请稍后重试';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateQuery(String value) {
    _query = value;
    _applyQuery(value);
    notifyListeners();
  }

  Future<void> toggleFavorite(String wordId) async {
    await _wordRepository.toggleFavorite(wordId);
    final updatedWord = await _wordRepository.getWordById(wordId);
    if (updatedWord == null) {
      notifyListeners();
      return;
    }

    final allIndex = _allWords.indexWhere((word) => word.id == wordId);
    if (allIndex != -1) {
      _allWords[allIndex] = updatedWord;
    }

    final resultIndex = _results.indexWhere((word) => word.id == wordId);
    if (resultIndex != -1) {
      _results[resultIndex] = updatedWord;
    }

    notifyListeners();
  }

  void _applyQuery(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      _results = const [];
      return;
    }

    _results = _allWords.where((word) {
      return word.english.toLowerCase().contains(normalized) ||
          word.chinese.contains(value.trim()) ||
          word.partOfSpeech.toLowerCase().contains(normalized);
    }).toList();
  }
}
