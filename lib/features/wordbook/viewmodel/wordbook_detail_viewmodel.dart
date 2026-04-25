import 'package:cici_word/data/models/word.dart';
import 'package:cici_word/data/models/wordbook.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:cici_word/data/repositories/i_wordbook_repository.dart';
import 'package:flutter/foundation.dart';

class WordbookDetailViewModel extends ChangeNotifier {
  WordbookDetailViewModel(
    this._wordbookRepository,
    this._wordRepository, {
    required this.bookId,
  });

  final IWordbookRepository _wordbookRepository;
  final IWordRepository _wordRepository;
  final String bookId;

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  Wordbook? _wordbook;
  List<Word> _words = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Wordbook? get wordbook => _wordbook;
  List<Word> get words => List.unmodifiable(_words);

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
      _wordbook = await _wordbookRepository.getWordbookById(bookId);
      if (_wordbook == null) {
        _error = '未找到对应词书';
      } else {
        _words = await _wordRepository.getWords(bookId);
        _hasLoaded = true;
      }
    } catch (_) {
      _error = '词表加载失败，请稍后重试。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String wordId) async {
    final index = _words.indexWhere((word) => word.id == wordId);
    if (index == -1) {
      return;
    }

    final current = _words[index];
    _words = List<Word>.from(_words)
      ..[index] = current.copyWith(isFavorite: !current.isFavorite);
    notifyListeners();

    await _wordRepository.toggleFavorite(wordId);
  }
}
