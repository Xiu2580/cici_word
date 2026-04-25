import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:flutter/foundation.dart';

import 'review_mistake_store.dart';

class ReviewPageViewModel extends ChangeNotifier {
  ReviewPageViewModel(
    this._wordRepository, {
    ReviewMistakeStore? mistakeStore,
  }) : _mistakeStore = mistakeStore {
    _mistakeStore?.addListener(_handleMistakesChanged);
  }

  final IWordRepository _wordRepository;
  final ReviewMistakeStore? _mistakeStore;

  bool _isLoading = false;
  bool _hasLoaded = false;
  int _todayCount = 0;
  int _queueCount = 0;

  bool get isLoading => _isLoading;
  int get todayCount => _todayCount;
  int get mistakeCount => _mistakeStore?.count ?? _todayCount;
  int get queueCount => _queueCount;
  bool get hasMistakes => mistakeCount > 0;

  Future<void> ensureLoaded() async {
    if (_isLoading || _hasLoaded) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final items = await _wordRepository.getMistakes();
      _todayCount = items.length;
      _queueCount = items.isEmpty ? 0 : ((items.length - 1) ~/ 5) + 1;
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  void _handleMistakesChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _mistakeStore?.removeListener(_handleMistakesChanged);
    super.dispose();
  }
}
