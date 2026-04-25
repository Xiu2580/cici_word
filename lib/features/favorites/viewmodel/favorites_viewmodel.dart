import 'package:flutter/foundation.dart';

import '../../../data/models/word.dart';
import '../../../data/repositories/i_word_repository.dart';

class FavoritesViewModel extends ChangeNotifier {
  FavoritesViewModel(this._repository);

  final IWordRepository _repository;

  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;
  List<Word> _words = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Word> get words => List.unmodifiable(_words);
  bool get isEmpty => _words.isEmpty;

  Future<void> ensureLoaded() async {
    if (_isLoading || _isLoaded) {
      return;
    }
    await reload();
    _isLoaded = true;
  }

  Future<void> reload() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _words = await _repository.getFavorites();
    } catch (_) {
      _error = '收藏内容加载失败，请稍后重试';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String wordId) async {
    await _repository.toggleFavorite(wordId);
    _words = _words.where((word) => word.id != wordId).toList();
    notifyListeners();
  }
}
