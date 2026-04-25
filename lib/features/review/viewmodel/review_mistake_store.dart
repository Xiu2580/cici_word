import 'package:cici_word/data/models/word.dart';
import 'package:cici_word/data/repositories/i_settings_repository.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:flutter/foundation.dart';

class ReviewMistakeStore extends ChangeNotifier {
  ReviewMistakeStore([
    this._settingsRepository,
    this._wordRepository,
  ]);

  final ISettingsRepository? _settingsRepository;
  final IWordRepository? _wordRepository;
  final Map<String, Word> _mistakes = <String, Word>{};

  bool _isLoading = false;
  bool _isLoaded = false;

  List<Word> get words => _mistakes.values.toList(growable: false);
  int get count => _mistakes.length;
  bool get isEmpty => _mistakes.isEmpty;

  Future<void> ensureLoaded() async {
    if (_isLoaded || _isLoading) {
      return;
    }

    if (_settingsRepository == null || _wordRepository == null) {
      _isLoaded = true;
      return;
    }

    _isLoading = true;
    final settings = await _settingsRepository.getSettings();
    final ids = (settings['review_mistake_ids'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();

    _mistakes.clear();
    for (final id in ids) {
      final word = await _wordRepository.getWordById(id);
      if (word != null) {
        _mistakes[id] = word;
      }
    }

    _isLoading = false;
    _isLoaded = true;
    notifyListeners();
  }

  void addWord(Word word) {
    _mistakes[word.id] = word;
    _persist();
    notifyListeners();
  }

  void clear() {
    if (_mistakes.isEmpty) {
      return;
    }
    _mistakes.clear();
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _settingsRepository?.saveSettings({
      'review_mistake_ids': _mistakes.keys.toList(),
    });
  }
}
