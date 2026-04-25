import 'package:flutter/foundation.dart';

/// 单词熟悉度枚举
///
/// 用于记录用户对单词的掌握程度:
/// - unknown: 完全不认识
/// - fuzzy: 模糊，有印象但不确定
/// - known: 认识，掌握良好
enum Familiarity { unknown, fuzzy, known }

/// 单词数据模型
///
/// 不可变对象，使用 @immutable 注解
@immutable
class Word {
  const Word({
    required this.id,
    required this.english,          // 英文单词
    required this.chinese,         // 中文释义
    required this.partOfSpeech,    // 词性（如 n. / v. / adj.）
    required this.usPhonetic,      // 美式音标
    required this.ukPhonetic,      // 英式音标
    required this.exampleSentenceEn, // 英文例句
    required this.exampleSentenceCn, // 例句中文翻译
    required this.inflection,      // 词形变化（复数/时态等）
    this.familiarity = Familiarity.unknown, // 熟悉度，默认为不认识
    this.isFavorite = false,       // 是否收藏，默认为否
  });

  // ============ 基本信息 ============
  final String id;
  final String english;
  final String chinese;
  final String partOfSpeech;
  final String usPhonetic;
  final String ukPhonetic;

  // ============ 例句 ============
  final String exampleSentenceEn;
  final String exampleSentenceCn;

  // ============ 其他属性 ============
  final String inflection;      // 词形变化
  final Familiarity familiarity; // 熟悉度
  final bool isFavorite;        // 是否收藏

  /// 从 JSON 创建 Word 对象
  ///
  /// [id] 可选参数，如果不提供则使用 english 作为 id
  factory Word.fromJson(Map<String, dynamic> json, {String? id}) {
    return Word(
      id: id ?? json['english'] as String,
      english: json['english'] as String,
      chinese: json['chinese'] as String,
      partOfSpeech: json['part_of_speech'] as String,
      usPhonetic: json['us_phonetic'] as String,
      ukPhonetic: json['uk_phonetic'] as String,
      exampleSentenceEn: json['example_sentence_en'] as String,
      exampleSentenceCn: json['example_sentence_cn'] as String,
      inflection: json['inflection'] as String,
    );
  }

  /// 创建副本，允许部分字段更新
  Word copyWith({
    String? id,
    String? english,
    String? chinese,
    String? partOfSpeech,
    String? usPhonetic,
    String? ukPhonetic,
    String? exampleSentenceEn,
    String? exampleSentenceCn,
    String? inflection,
    Familiarity? familiarity,
    bool? isFavorite,
  }) {
    return Word(
      id: id ?? this.id,
      english: english ?? this.english,
      chinese: chinese ?? this.chinese,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      usPhonetic: usPhonetic ?? this.usPhonetic,
      ukPhonetic: ukPhonetic ?? this.ukPhonetic,
      exampleSentenceEn: exampleSentenceEn ?? this.exampleSentenceEn,
      exampleSentenceCn: exampleSentenceCn ?? this.exampleSentenceCn,
      inflection: inflection ?? this.inflection,
      familiarity: familiarity ?? this.familiarity,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Word && other.id == id;

  @override
  int get hashCode => id.hashCode;
}