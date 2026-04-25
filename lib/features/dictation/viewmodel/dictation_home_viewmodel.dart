import 'package:cici_word/data/models/wordbook.dart';
import 'package:cici_word/features/wordbook/viewmodel/current_wordbook_viewmodel.dart';
import 'package:flutter/foundation.dart';

class DictationHomeViewModel extends ChangeNotifier {
  DictationHomeViewModel(this._currentWordbookVm) {
    _currentWordbookVm.addListener(notifyListeners);
  }

  final CurrentWordbookViewModel _currentWordbookVm;

  String _dictationMode = 'full';

  Wordbook? get currentWordbook => _currentWordbookVm.current;
  bool get hasWordbook => currentWordbook != null;
  String? get bookId => currentWordbook?.id;

  String get title => '默写';
  String get headline => currentWordbook?.name ?? '还没有选择词书';
  String get subtitle => currentWordbook == null
      ? '请先去词库里选择一本词书，再开始今天的默写练习。'
      : '使用当前词书开始一轮默写练习，巩固今天的新词和错词。';
  String get modeLabel => _dictationMode == 'full' ? '完整默写' : '提示默写';

  @visibleForTesting
  void setMode(String value) {
    _dictationMode = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _currentWordbookVm.removeListener(notifyListeners);
    super.dispose();
  }
}
