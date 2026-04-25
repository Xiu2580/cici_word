import 'package:flutter/foundation.dart';
import 'word.dart';

/// 学习记录数据模型
///
/// 记录用户每次学习某个单词的结果
@immutable
class StudyRecord {
  const StudyRecord({
    required this.id,           // 记录唯一ID
    required this.wordId,      // 单词ID
    required this.bookId,      // 词库ID
    required this.familiarity,  // 学习后的熟悉度
    required this.studyTime,   // 学习时间
  });

  final String id;
  final String wordId;
  final String bookId;
  final Familiarity familiarity;
  final DateTime studyTime;
}