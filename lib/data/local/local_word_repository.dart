import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/word.dart';
import '../repositories/i_settings_repository.dart';
import '../repositories/i_word_repository.dart';

class LocalWordRepository implements IWordRepository {
  LocalWordRepository([ISettingsRepository? settingsRepository])
      : _settingsRepository = settingsRepository;

  final Map<String, List<Word>> _cache = {};
  final Map<String, Word> _wordMap = {};
  final ISettingsRepository? _settingsRepository;

  Set<String>? _favoriteIds;
  Map<String, Familiarity>? _familiarityMap;

  @override
  Future<List<Word>> getWords(String bookId, {StudyFilter filter = StudyFilter.all}) async {
    await _ensureStateLoaded();
    if (!_cache.containsKey(bookId)) {
      await _loadBook(bookId);
    }
    final words = _cache[bookId] ?? const <Word>[];

    return switch (filter) {
      StudyFilter.all => words,
      StudyFilter.unknown =>
        words.where((word) => word.familiarity == Familiarity.unknown).toList(),
      StudyFilter.fuzzy =>
        words.where((word) => word.familiarity == Familiarity.fuzzy).toList(),
      StudyFilter.known =>
        words.where((word) => word.familiarity == Familiarity.known).toList(),
      StudyFilter.favorite => words.where((word) => word.isFavorite).toList(),
    };
  }

  @override
  Future<Word?> getWordById(String id) async {
    await _ensureStateLoaded();
    return _wordMap[id];
  }

  @override
  Future<void> markWord(String id, Familiarity familiarity) async {
    await _ensureStateLoaded();
    _familiarityMap![id] = familiarity;
    _updateCachedWord(
      id,
      (word) => word.copyWith(familiarity: familiarity),
    );
    await _persistFamiliarity();
  }

  @override
  Future<void> toggleFavorite(String id) async {
    await _ensureStateLoaded();
    final current = _wordMap[id];
    if (current == null) {
      return;
    }
    final nextFavorite = !current.isFavorite;
    if (nextFavorite) {
      _favoriteIds!.add(id);
    } else {
      _favoriteIds!.remove(id);
    }
    _updateCachedWord(
      id,
      (word) => word.copyWith(isFavorite: nextFavorite),
    );
    await _settingsRepository?.saveSettings({
      'favorite_word_ids': _favoriteIds!.toList(),
    });
  }

  @override
  Future<List<Word>> getFavorites() async {
    await _ensureStateLoaded();
    return _wordMap.values.where((word) => word.isFavorite).toList();
  }

  @override
  Future<List<Word>> getMistakes() async {
    await _ensureStateLoaded();
    return _wordMap.values
        .where((word) => word.familiarity == Familiarity.unknown)
        .toList();
  }

  @override
  Future<void> clearLearningRecords() async {
    await _ensureStateLoaded();
    _familiarityMap!
      ..clear();

    for (final entry in _cache.entries) {
      entry.value.replaceRange(
        0,
        entry.value.length,
        entry.value
            .map((word) => word.copyWith(familiarity: Familiarity.unknown))
            .toList(),
      );
    }

    for (final entry in _wordMap.entries.toList()) {
      _wordMap[entry.key] = entry.value.copyWith(familiarity: Familiarity.unknown);
    }

    await _persistFamiliarity();
  }

  Future<void> _ensureStateLoaded() async {
    if (_favoriteIds != null && _familiarityMap != null) {
      return;
    }

    final settings = await _settingsRepository?.getSettings() ?? const <String, dynamic>{};
    final storedFavorites = settings['favorite_word_ids'] as List<dynamic>?;
    final storedFamiliarity = settings['word_familiarity_map'] as Map<dynamic, dynamic>?;

    _favoriteIds = storedFavorites == null
        ? <String>{}
        : storedFavorites.map((item) => item.toString()).toSet();
    _familiarityMap = storedFamiliarity == null
        ? <String, Familiarity>{}
        : storedFamiliarity.map(
            (key, value) => MapEntry(
              key.toString(),
              _parseFamiliarity(value?.toString()),
            ),
          );
  }

  Future<void> _persistFamiliarity() async {
    await _settingsRepository?.saveSettings({
      'word_familiarity_map': _familiarityMap!.map(
        (key, value) => MapEntry(key, value.name),
      ),
    });
  }

  void _updateCachedWord(String id, Word Function(Word word) update) {
    final current = _wordMap[id];
    if (current == null) {
      return;
    }

    final updated = update(current);
    _wordMap[id] = updated;

    for (final words in _cache.values) {
      final index = words.indexWhere((word) => word.id == id);
      if (index != -1) {
        words[index] = updated;
        break;
      }
    }
  }

  Future<void> _loadBook(String bookId) async {
    final assetPath = _bookIdToAssetPath(bookId);
    if (assetPath == null) {
      _cache[bookId] = <Word>[];
      return;
    }

    try {
      await _ensureStateLoaded();
      final jsonStr = await rootBundle.loadString(assetPath);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      final words = list.asMap().entries.map((entry) {
        final id = '${bookId}_${entry.key}';
        final baseWord = Word.fromJson(
          entry.value as Map<String, dynamic>,
          id: id,
        );
        final hydratedWord = baseWord.copyWith(
          isFavorite: _favoriteIds!.contains(id),
          familiarity: _familiarityMap![id] ?? Familiarity.unknown,
        );
        _wordMap[id] = hydratedWord;
        return hydratedWord;
      }).toList();
      _cache[bookId] = words;
    } catch (_) {
      _cache[bookId] = <Word>[];
    }
  }

  static Familiarity _parseFamiliarity(String? value) {
    return Familiarity.values.firstWhere(
      (item) => item.name == value,
      orElse: () => Familiarity.unknown,
    );
  }

  String? _bookIdToAssetPath(String bookId) {
    const paths = {
      'elementary_g1s1': 'assets/word_lists/elementary_school/grade1_semester1.json',
      'elementary_g1s2': 'assets/word_lists/elementary_school/grade1_semester2.json',
      'elementary_g2s1': 'assets/word_lists/elementary_school/grade2_semester1.json',
      'elementary_g2s2': 'assets/word_lists/elementary_school/grade2_semester2.json',
      'elementary_g3s1': 'assets/word_lists/elementary_school/grade3_semester1.json',
      'elementary_g3s2': 'assets/word_lists/elementary_school/grade3_semester2.json',
      'elementary_g4s1': 'assets/word_lists/elementary_school/grade4_semester1.json',
      'elementary_g4s2': 'assets/word_lists/elementary_school/grade4_semester2.json',
      'elementary_g5s1': 'assets/word_lists/elementary_school/grade5_semester1.json',
      'elementary_g5s2': 'assets/word_lists/elementary_school/grade5_semester2.json',
      'elementary_g6s1': 'assets/word_lists/elementary_school/grade6_semester1.json',
      'elementary_g6s2': 'assets/word_lists/elementary_school/grade6_semester2.json',
      'junior_g7s1': 'assets/word_lists/junior_high/grade7_semester1.json',
      'junior_g7s2': 'assets/word_lists/junior_high/grade7_semester2.json',
      'junior_g8s1': 'assets/word_lists/junior_high/grade8_semester1.json',
      'junior_g8s2': 'assets/word_lists/junior_high/grade8_semester2.json',
      'junior_g9': 'assets/word_lists/junior_high/grade9_full.json',
      'senior_g10s1': 'assets/word_lists/senior_high/grade10_semester1.json',
      'senior_g10s2': 'assets/word_lists/senior_high/grade10_semester2.json',
      'senior_g11s1': 'assets/word_lists/senior_high/grade11_semester1.json',
      'senior_g11s2': 'assets/word_lists/senior_high/grade11_semester2.json',
      'senior_g12s1': 'assets/word_lists/senior_high/grade12_semester1.json',
      'senior_g12s2': 'assets/word_lists/senior_high/grade12_semester2.json',
    };
    return paths[bookId];
  }
}
