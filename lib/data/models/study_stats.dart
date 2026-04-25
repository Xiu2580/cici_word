import 'package:flutter/foundation.dart';

/// 学习统计数据模型
///
/// 记录用户的学习进度和历史
@immutable
class StudyStats {
  const StudyStats({
    this.todayLearned = 0,    // 今日学习单词数
    this.todayReviewed = 0,   // 今日复习单词数
    this.totalMastered = 0,   // 累计掌握单词数
    this.streakDays = 0,      // 连续学习天数
    this.correctRate = 0.0,  // 正确率（0.0 - 1.0）
  });

  final int todayLearned;
  final int todayReviewed;
  final int totalMastered;
  final int streakDays;
  final double correctRate;

  /// 从 JSON 创建 StudyStats
  factory StudyStats.fromJson(Map<String, dynamic> json) {
    return StudyStats(
      todayLearned: json['today_learned'] as int? ?? 0,
      todayReviewed: json['today_reviewed'] as int? ?? 0,
      totalMastered: json['total_mastered'] as int? ?? 0,
      streakDays: json['streak_days'] as int? ?? 0,
      correctRate: (json['correct_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 创建副本，允许部分字段更新
  StudyStats copyWith({
    int? todayLearned,
    int? todayReviewed,
    int? totalMastered,
    int? streakDays,
    double? correctRate,
  }) {
    return StudyStats(
      todayLearned: todayLearned ?? this.todayLearned,
      todayReviewed: todayReviewed ?? this.todayReviewed,
      totalMastered: totalMastered ?? this.totalMastered,
      streakDays: streakDays ?? this.streakDays,
      correctRate: correctRate ?? this.correctRate,
    );
  }
}