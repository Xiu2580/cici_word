import 'package:flutter/foundation.dart';

import '../../../../data/models/study_stats.dart';
import '../../../../data/models/word.dart';
import '../../../../data/repositories/i_word_repository.dart';
import '../../../../data/repositories/i_wordbook_repository.dart';

class StatViewModel extends ChangeNotifier {
  StatViewModel(this._wordRepo, [this._wordbookRepository]) {
    load();
  }

  final IWordRepository _wordRepo;
  final IWordbookRepository? _wordbookRepository;

  StudyStats _stats = const StudyStats();
  bool isLoading = false;
  String? error;

  StudyStats get stats => _stats;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final favorites = await _wordRepo.getFavorites();
      final mistakes = await _wordRepo.getMistakes();
      final wordbooks =
          await _wordbookRepository?.getBuiltInWordbooks() ?? const [];

      final loadedWordIds = <String>{};
      var knownCount = 0;
      var studiedCount = 0;

      for (final wordbook in wordbooks) {
        final words = await _wordRepo.getWords(wordbook.id);
        for (final word in words) {
          if (!loadedWordIds.add(word.id)) {
            continue;
          }
          if (word.familiarity == Familiarity.known) {
            knownCount += 1;
          }
          if (word.familiarity != Familiarity.unknown) {
            studiedCount += 1;
          }
        }
      }

      final reviewedCount = studiedCount + mistakes.length;
      final correctRate = reviewedCount == 0 ? 0.0 : knownCount / reviewedCount;

      _stats = StudyStats(
        todayLearned: studiedCount,
        todayReviewed: reviewedCount,
        totalMastered: knownCount,
        streakDays: favorites.isEmpty && studiedCount == 0 ? 0 : 1,
        correctRate: correctRate,
      );
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
