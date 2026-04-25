import 'package:flutter/foundation.dart';

/// 词库分类枚举
///
/// 用于区分不同学段的词库:
/// - elementary: 小学
/// - juniorHigh: 初中
/// - seniorHigh: 高中
/// - custom: 用户自定义词库
enum WordbookCategory { elementary, juniorHigh, seniorHigh, custom }

/// 词库数据模型
///
/// 代表一个单词书/词库，包含基本信息、进度等
@immutable
class Wordbook {
  const Wordbook({
    required this.id,
    required this.name,              // 词库名称（如"小学一年级上册"）
    required this.description,       // 词库描述
    required this.category,          // 分类（小学/初中/高中/自定义）
    required this.wordCount,         // 总单词数
    this.learnedCount = 0,          // 已学单词数，默认为0
    this.coverColor = 0xFF4A90D9,   // 封面颜色，默认为蓝色
    this.lastStudyTime,              // 最后学习时间
    this.grade,                      // 年级（1-12）
    this.semester,                   // 学期（0=全册，1=上册，2=下册）
    this.assetPath,                  // 词库资源路径（JSON文件路径）
  });

  // ============ 基本信息 ============
  final String id;
  final String name;
  final String description;
  final WordbookCategory category;
  final int wordCount;
  final int learnedCount;

  // ============ 外观与状态 ============
  final int coverColor;         // 封面颜色（十六进制颜色值）
  final DateTime? lastStudyTime; // 最后学习时间

  // ============ 学年信息 ============
  final int? grade;      // 年级（小学1-6，初中7-9，高中10-12）
  final int? semester;  // 学期（0=全册，1=上学期，2=下学期）

  // ============ 资源路径 ============
  final String? assetPath; // 对应 assets 中的 JSON 文件路径

  /// 学习进度百分比
  ///
  /// 计算方式: 已学单词数 / 总单词数
  /// 如果总单词数为0，返回0
  double get progress => wordCount == 0 ? 0 : learnedCount / wordCount;

  /// 创建副本，允许部分字段更新
  Wordbook copyWith({
    String? id,
    String? name,
    String? description,
    WordbookCategory? category,
    int? wordCount,
    int? learnedCount,
    int? coverColor,
    DateTime? lastStudyTime,
    int? grade,
    int? semester,
    String? assetPath,
  }) {
    return Wordbook(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      wordCount: wordCount ?? this.wordCount,
      learnedCount: learnedCount ?? this.learnedCount,
      coverColor: coverColor ?? this.coverColor,
      lastStudyTime: lastStudyTime ?? this.lastStudyTime,
      grade: grade ?? this.grade,
      semester: semester ?? this.semester,
      assetPath: assetPath ?? this.assetPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Wordbook && other.id == id;

  @override
  int get hashCode => id.hashCode;
}