import 'package:cici_word/data/models/word.dart';
import 'package:cici_word/data/models/wordbook.dart';
import 'package:cici_word/data/repositories/i_settings_repository.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:cici_word/data/repositories/i_wordbook_repository.dart';
import 'package:flutter/foundation.dart';

class WordbookDetailViewModel extends ChangeNotifier {
  WordbookDetailViewModel(
    this._wordbookRepository,
    this._wordRepository, {
    required this.bookId,
    ISettingsRepository? settingsRepository,
  }) : _settingsRepository = settingsRepository;

  final IWordbookRepository _wordbookRepository;
  final IWordRepository _wordRepository;
  final ISettingsRepository? _settingsRepository;
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
      if (_isCustom(bookId)) {
        await _loadCustom();
      } else {
        await _loadBuiltIn();
      }
    } catch (_) {
      _error = '词表加载失败，请稍后重试。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isCustom(String id) => id.startsWith('custom_');

  Future<void> _loadBuiltIn() async {
    _wordbook = await _wordbookRepository.getWordbookById(bookId);
    if (_wordbook == null) {
      _error = '未找到对应词书';
    } else {
      _words = await _wordRepository.getWords(bookId);
      _hasLoaded = true;
    }
  }

  Future<void> _loadCustom() async {
    final index = int.tryParse(bookId.replaceFirst('custom_', ''));
    if (index == null) {
      _error = '词书信息无效';
      return;
    }

    final books = await _settingsRepository?.getCustomWordbooks() ?? [];
    if (index >= books.length) {
      _error = '未找到对应词书';
      return;
    }

    final bookData = books[index];
    final wordsRaw = bookData['words'] as List<dynamic>? ?? [];

    _words = wordsRaw
        .asMap()
        .entries
        .map((entry) {
          final item = entry.value;
          if (item is! Map) return null;
          return Word(
            id: 'custom_${index}_${entry.key}',
            english: (item['english'] ?? '') as String,
            chinese: (item['chinese'] ?? '') as String,
            partOfSpeech: (item['part_of_speech'] ?? '') as String,
            usPhonetic: (item['us_phonetic'] ?? '') as String,
            ukPhonetic: (item['uk_phonetic'] ?? '') as String,
            exampleSentenceEn: (item['example_sentence_en'] ?? '') as String,
            exampleSentenceCn: (item['example_sentence_cn'] ?? '') as String,
            inflection: (item['inflection'] ?? '') as String,
          );
        })
        .whereType<Word>()
        .toList();

    _wordbook = Wordbook(
      id: bookId,
      name: (bookData['name'] as String?) ?? '导入词书',
      description: '导入词书 · ${_words.length} 词',
      category: WordbookCategory.custom,
      wordCount: _words.length,
    );
    _hasLoaded = true;
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
