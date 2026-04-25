import 'package:flutter/foundation.dart';
import 'word.dart';

/// 复习项数据模型
///
/// 记录需要复习的单词及其复习计划
@immutable
class ReviewItem {
  const ReviewItem({
    required this.id,              // 复习项唯一ID
    required this.wordId,          // 单词ID
    required this.word,            // 单词详情（Word对象）
    required this.nextReviewTime,  // 下次复习时间
    this.reviewCount = 0,         // 已复习次数，默认为0
  });

  final String id;
  final String wordId;
  final Word word;
  final DateTime nextReviewTime;
  final int reviewCount;

  /// 是否已过期（需要现在复习）
  bool get isOverdue => nextReviewTime.isBefore(DateTime.now());

  /// 从 JSON 创建 ReviewItem
  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'] as String,
      wordId: json['word_id'] as String,
      word: Word(
        id: json['word_id'] as String,
        english: json['english'] as String,
        chinese: json['chinese'] as String,
        partOfSpeech: '',
        usPhonetic: '',
        ukPhonetic: '',
        exampleSentenceEn: '',
        exampleSentenceCn: '',
        inflection: '',
      ),
      nextReviewTime: DateTime.parse(json['next_review_time'] as String),
      reviewCount: json['review_count'] as int,
    );
  }
}