import 'package:flutter/foundation.dart';

import '../../../data/repositories/i_settings_repository.dart';
import '../../../data/repositories/i_word_repository.dart';
import '../../review/viewmodel/review_mistake_store.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(
    this._repo, [
    this._wordRepository,
    this._mistakeStore,
  ]) {
    _load();
  }

  final ISettingsRepository _repo;
  final IWordRepository? _wordRepository;
  final ReviewMistakeStore? _mistakeStore;

  int _dailyGoal = 20;
  String _pronunciation = 'us';
  String _dictationMode = 'hint';
  bool isLoading = false;

  int get dailyGoal => _dailyGoal;
  String get pronunciation => _pronunciation;
  String get dictationMode => _dictationMode;

  Future<void> _load() async {
    isLoading = true;
    notifyListeners();

    final settings = await _repo.getSettings();
    _dailyGoal = settings['daily_goal'] as int? ?? 20;
    _pronunciation = settings['pronunciation'] as String? ?? 'us';
    _dictationMode = settings['dictation_mode'] as String? ?? 'hint';

    isLoading = false;
    notifyListeners();
  }

  Future<void> setDailyGoal(int goal) async {
    if (_dailyGoal == goal) {
      return;
    }
    _dailyGoal = goal;
    notifyListeners();
    await _repo.saveSettings({'daily_goal': goal});
  }

  Future<void> setPronunciation(String type) async {
    if (_pronunciation == type) {
      return;
    }
    _pronunciation = type;
    notifyListeners();
    await _repo.saveSettings({'pronunciation': type});
  }

  Future<void> setDictationMode(String mode) async {
    if (_dictationMode == mode) {
      return;
    }
    _dictationMode = mode;
    notifyListeners();
    await _repo.saveSettings({'dictation_mode': mode});
  }

  Future<void> clearLearningRecords() async {
    await _wordRepository?.clearLearningRecords();
    _mistakeStore?.clear();
  }

  Future<void> resetDefaults() async {
    _dailyGoal = 20;
    _pronunciation = 'us';
    _dictationMode = 'hint';
    notifyListeners();
    await _repo.saveSettings({
      'daily_goal': _dailyGoal,
      'pronunciation': _pronunciation,
      'dictation_mode': _dictationMode,
    });
  }
}
