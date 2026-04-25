import 'package:cici_word/data/models/wordbook.dart';
import 'package:cici_word/data/repositories/i_settings_repository.dart';
import 'package:cici_word/data/repositories/i_wordbook_repository.dart';
import 'package:flutter/foundation.dart';

class CurrentWordbookViewModel extends ChangeNotifier {
  CurrentWordbookViewModel([
    this._settingsRepository,
    this._wordbookRepository,
  ]) {
    _load();
  }

  final ISettingsRepository? _settingsRepository;
  final IWordbookRepository? _wordbookRepository;
  Wordbook? _current;

  Wordbook? get current => _current;
  String? get currentId => _current?.id;
  bool get hasSelection => _current != null;

  Future<void> _load() async {
    if (_settingsRepository == null || _wordbookRepository == null) {
      return;
    }

    final settings = await _settingsRepository.getSettings();
    final currentId = settings['current_wordbook_id'] as String?;
    if (currentId == null || currentId.isEmpty) {
      return;
    }

    _current = await _wordbookRepository.getWordbookById(currentId);
    notifyListeners();
  }

  void setCurrent(Wordbook? wordbook) {
    if (_current == wordbook) {
      return;
    }
    _current = wordbook;
    _settingsRepository?.saveSettings({
      'current_wordbook_id': wordbook?.id,
    });
    notifyListeners();
  }

  void clear() {
    if (_current == null) {
      return;
    }
    _current = null;
    _settingsRepository?.saveSettings({
      'current_wordbook_id': null,
    });
    notifyListeners();
  }
}
