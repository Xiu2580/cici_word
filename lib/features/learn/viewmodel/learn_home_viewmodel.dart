import 'package:cici_word/data/models/wordbook.dart';
import 'package:cici_word/features/wordbook/viewmodel/current_wordbook_viewmodel.dart';
import 'package:flutter/foundation.dart';

class LearnHomeViewModel extends ChangeNotifier {
  LearnHomeViewModel(this._currentWordbookVm) {
    _currentWordbookVm.addListener(notifyListeners);
  }

  final CurrentWordbookViewModel _currentWordbookVm;

  Wordbook? get currentWordbook => _currentWordbookVm.current;
  bool get hasWordbook => currentWordbook != null;
  String? get bookId => currentWordbook?.id;

  String get title => '学习';
  String get headline => currentWordbook?.name ?? '还没有选择词书';
  String get subtitle => currentWordbook == null
      ? '请先去词库里选择一本今天要学习的词书。'
      : '继续当前词书的学习进度，或者重新开始今天的学习。';
  String get primaryActionLabel => currentWordbook == null ? '去词库看看' : '开始学习';
  String get secondaryActionLabel => '更换词书';

  @override
  void dispose() {
    _currentWordbookVm.removeListener(notifyListeners);
    super.dispose();
  }
}
