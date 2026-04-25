import 'package:cici_word/data/models/word.dart';
import 'package:cici_word/data/models/wordbook.dart';
import 'package:cici_word/data/repositories/i_settings_repository.dart';
import 'package:cici_word/data/repositories/i_word_repository.dart';
import 'package:cici_word/data/repositories/i_wordbook_repository.dart';
import 'package:flutter/foundation.dart';

class WordbookV2ViewModel extends ChangeNotifier {
  WordbookV2ViewModel(
    IWordbookRepository repository,
    IWordRepository wordRepository, {
    ISettingsRepository? settingsRepository,
    String? selectedBookId,
  })  : _loadWordbooks = repository.getBuiltInWordbooks,
        _loadLearnedCount = ((bookId) async {
          final words = await wordRepository.getWords(bookId);
          return words.where((word) => word.familiarity != Familiarity.unknown).length;
        }),
        _loadPersistedSelectedBookId = (() async {
          final settings = await settingsRepository?.getSettings() ?? const <String, dynamic>{};
          return settings['current_wordbook_id'] as String?;
        }),
        _persistSelectedBookId = ((bookId) async {
          await settingsRepository?.saveSettings({'current_wordbook_id': bookId});
        }),
        _initialSelectedBookId = selectedBookId;

  WordbookV2ViewModel.testOnly({
    required List<Wordbook> wordbooks,
    Future<int> Function(String bookId)? loadLearnedCount,
    String? selectedBookId,
  })  : _loadWordbooks = (() async => wordbooks),
        _loadLearnedCount = loadLearnedCount ?? ((_) async => 0),
        _loadPersistedSelectedBookId = (() async => selectedBookId),
        _persistSelectedBookId = ((_) async {}),
        _initialSelectedBookId = selectedBookId;

  final Future<List<Wordbook>> Function() _loadWordbooks;
  final Future<int> Function(String bookId) _loadLearnedCount;
  final Future<String?> Function() _loadPersistedSelectedBookId;
  final Future<void> Function(String?) _persistSelectedBookId;
  final String? _initialSelectedBookId;

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  List<WordbookSection> _sections = const [];
  String? _selectedBookId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<WordbookSection> get sections => List.unmodifiable(_sections);
  String? get selectedBookId => _selectedBookId;

  Wordbook? get selectedBook {
    for (final section in _sections) {
      for (final book in section.items) {
        if (book.id == _selectedBookId) {
          return book;
        }
      }
    }
    return null;
  }

  Future<void> ensureLoaded() async {
    if (_hasLoaded || _isLoading) {
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
      final wordbooks = await _loadWordbooks();
      final hydratedWordbooks = await Future.wait(
        wordbooks.map((book) async {
          final learnedCount = await _loadLearnedCount(book.id);
          return book.copyWith(
            learnedCount: learnedCount.clamp(0, book.wordCount),
          );
        }),
      );
      _sections = _groupWordbooks(hydratedWordbooks);
      final persistedSelectedBookId = await _loadPersistedSelectedBookId();
      _selectedBookId = _resolveSelectedBookId(
        _initialSelectedBookId ?? persistedSelectedBookId,
      );
      _hasLoaded = true;
    } catch (_) {
      _error = '词书加载失败，请稍后重试。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectBook(String bookId) {
    if (_selectedBookId == bookId) {
      return;
    }
    _selectedBookId = bookId;
    _persistSelectedBookId(bookId);
    notifyListeners();
  }

  String progressLabel(Wordbook book) {
    if (book.learnedCount <= 0) {
      return '未开始';
    }
    if (book.learnedCount >= book.wordCount) {
      return '已完成';
    }
    return '进行中';
  }

  String statsLabel(Wordbook book) {
    final remain = (book.wordCount - book.learnedCount).clamp(0, book.wordCount);
    return '总词数 ${book.wordCount} · 已学 ${book.learnedCount} · 剩余 $remain';
  }

  String? _resolveSelectedBookId(String? preferredId) {
    final books = _sections.expand((section) => section.items);
    if (preferredId != null && books.any((book) => book.id == preferredId)) {
      return preferredId;
    }
    return books.isEmpty ? null : books.first.id;
  }

  List<WordbookSection> _groupWordbooks(List<Wordbook> wordbooks) {
    final grouped = <WordbookCategory, List<Wordbook>>{};
    for (final book in wordbooks) {
      grouped.putIfAbsent(book.category, () => <Wordbook>[]).add(book);
    }

    const ordered = [
      WordbookCategory.elementary,
      WordbookCategory.juniorHigh,
      WordbookCategory.seniorHigh,
      WordbookCategory.custom,
    ];

    return ordered
        .where(grouped.containsKey)
        .map((category) {
          final items = grouped[category]!.toList()
            ..sort((a, b) {
              final gradeCompare = (a.grade ?? 0).compareTo(b.grade ?? 0);
              if (gradeCompare != 0) {
                return gradeCompare;
              }
              return (a.semester ?? 0).compareTo(b.semester ?? 0);
            });

          return WordbookSection(
            title: _titleFor(category),
            subtitle: _subtitleFor(category),
            items: items,
          );
        })
        .toList(growable: false);
  }

  String _titleFor(WordbookCategory category) {
    switch (category) {
      case WordbookCategory.elementary:
        return '小学词汇';
      case WordbookCategory.juniorHigh:
        return '初中词汇';
      case WordbookCategory.seniorHigh:
        return '高中词汇';
      case WordbookCategory.custom:
        return '自定义词书';
    }
  }

  String _subtitleFor(WordbookCategory category) {
    switch (category) {
      case WordbookCategory.elementary:
        return '从启蒙词汇开始，适合建立长期记忆节奏。';
      case WordbookCategory.juniorHigh:
        return '围绕课本词汇展开，兼顾同步学习与复习。';
      case WordbookCategory.seniorHigh:
        return '覆盖高频考纲词汇，适合集中冲刺。';
      case WordbookCategory.custom:
        return '收纳你自己的词表，按自己的节奏推进。';
    }
  }
}

@immutable
class WordbookSection {
  const WordbookSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<Wordbook> items;
}
