import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/wordbook.dart';
import '../repositories/i_wordbook_repository.dart';

/// 本地词库仓储实现
class LocalWordbookRepository implements IWordbookRepository {
  LocalWordbookRepository({
    Future<int> Function(String assetPath)? loadWordCount,
  }) : _loadWordCount = loadWordCount ?? _defaultLoadWordCount;

  static const List<Wordbook> _builtIn = [
    Wordbook(
      id: 'elementary_g1s1',
      name: '一年级上册',
      description: '人教版小学英语一年级上册',
      category: WordbookCategory.elementary,
      wordCount: 23,
      grade: 1,
      semester: 1,
      assetPath: 'assets/word_lists/elementary_school/grade1_semester1.json',
      coverColor: 0xFFFF6B6B,
    ),
    Wordbook(
      id: 'elementary_g1s2',
      name: '一年级下册',
      description: '人教版小学英语一年级下册',
      category: WordbookCategory.elementary,
      wordCount: 23,
      grade: 1,
      semester: 2,
      assetPath: 'assets/word_lists/elementary_school/grade1_semester2.json',
      coverColor: 0xFFFF8E53,
    ),
    Wordbook(
      id: 'elementary_g2s1',
      name: '二年级上册',
      description: '人教版小学英语二年级上册',
      category: WordbookCategory.elementary,
      wordCount: 30,
      grade: 2,
      semester: 1,
      assetPath: 'assets/word_lists/elementary_school/grade2_semester1.json',
      coverColor: 0xFFFFD93D,
    ),
    Wordbook(
      id: 'elementary_g2s2',
      name: '二年级下册',
      description: '人教版小学英语二年级下册',
      category: WordbookCategory.elementary,
      wordCount: 30,
      grade: 2,
      semester: 2,
      assetPath: 'assets/word_lists/elementary_school/grade2_semester2.json',
      coverColor: 0xFF6BCB77,
    ),
    Wordbook(
      id: 'elementary_g3s1',
      name: '三年级上册',
      description: '人教版小学英语三年级上册',
      category: WordbookCategory.elementary,
      wordCount: 45,
      grade: 3,
      semester: 1,
      assetPath: 'assets/word_lists/elementary_school/grade3_semester1.json',
      coverColor: 0xFF4D96FF,
    ),
    Wordbook(
      id: 'elementary_g3s2',
      name: '三年级下册',
      description: '人教版小学英语三年级下册',
      category: WordbookCategory.elementary,
      wordCount: 45,
      grade: 3,
      semester: 2,
      assetPath: 'assets/word_lists/elementary_school/grade3_semester2.json',
      coverColor: 0xFF845EC2,
    ),
    Wordbook(
      id: 'elementary_g4s1',
      name: '四年级上册',
      description: '人教版小学英语四年级上册',
      category: WordbookCategory.elementary,
      wordCount: 50,
      grade: 4,
      semester: 1,
      assetPath: 'assets/word_lists/elementary_school/grade4_semester1.json',
      coverColor: 0xFFFF6B6B,
    ),
    Wordbook(
      id: 'elementary_g4s2',
      name: '四年级下册',
      description: '人教版小学英语四年级下册',
      category: WordbookCategory.elementary,
      wordCount: 50,
      grade: 4,
      semester: 2,
      assetPath: 'assets/word_lists/elementary_school/grade4_semester2.json',
      coverColor: 0xFFFF8E53,
    ),
    Wordbook(
      id: 'elementary_g5s1',
      name: '五年级上册',
      description: '人教版小学英语五年级上册',
      category: WordbookCategory.elementary,
      wordCount: 55,
      grade: 5,
      semester: 1,
      assetPath: 'assets/word_lists/elementary_school/grade5_semester1.json',
      coverColor: 0xFFFFD93D,
    ),
    Wordbook(
      id: 'elementary_g5s2',
      name: '五年级下册',
      description: '人教版小学英语五年级下册',
      category: WordbookCategory.elementary,
      wordCount: 55,
      grade: 5,
      semester: 2,
      assetPath: 'assets/word_lists/elementary_school/grade5_semester2.json',
      coverColor: 0xFF6BCB77,
    ),
    Wordbook(
      id: 'elementary_g6s1',
      name: '六年级上册',
      description: '人教版小学英语六年级上册',
      category: WordbookCategory.elementary,
      wordCount: 60,
      grade: 6,
      semester: 1,
      assetPath: 'assets/word_lists/elementary_school/grade6_semester1.json',
      coverColor: 0xFF4D96FF,
    ),
    Wordbook(
      id: 'elementary_g6s2',
      name: '六年级下册',
      description: '人教版小学英语六年级下册',
      category: WordbookCategory.elementary,
      wordCount: 60,
      grade: 6,
      semester: 2,
      assetPath: 'assets/word_lists/elementary_school/grade6_semester2.json',
      coverColor: 0xFF845EC2,
    ),
    Wordbook(
      id: 'junior_g7s1',
      name: '七年级上册',
      description: '人教版初中英语七年级上册',
      category: WordbookCategory.juniorHigh,
      wordCount: 134,
      grade: 7,
      semester: 1,
      assetPath: 'assets/word_lists/junior_high/grade7_semester1.json',
      coverColor: 0xFF0081CF,
    ),
    Wordbook(
      id: 'junior_g7s2',
      name: '七年级下册',
      description: '人教版初中英语七年级下册',
      category: WordbookCategory.juniorHigh,
      wordCount: 134,
      grade: 7,
      semester: 2,
      assetPath: 'assets/word_lists/junior_high/grade7_semester2.json',
      coverColor: 0xFF00B4D8,
    ),
    Wordbook(
      id: 'junior_g8s1',
      name: '八年级上册',
      description: '人教版初中英语八年级上册',
      category: WordbookCategory.juniorHigh,
      wordCount: 150,
      grade: 8,
      semester: 1,
      assetPath: 'assets/word_lists/junior_high/grade8_semester1.json',
      coverColor: 0xFF48CAE4,
    ),
    Wordbook(
      id: 'junior_g8s2',
      name: '八年级下册',
      description: '人教版初中英语八年级下册',
      category: WordbookCategory.juniorHigh,
      wordCount: 150,
      grade: 8,
      semester: 2,
      assetPath: 'assets/word_lists/junior_high/grade8_semester2.json',
      coverColor: 0xFF90E0EF,
    ),
    Wordbook(
      id: 'junior_g9',
      name: '九年级全册',
      description: '人教版初中英语九年级全册',
      category: WordbookCategory.juniorHigh,
      wordCount: 200,
      grade: 9,
      semester: 0,
      assetPath: 'assets/word_lists/junior_high/grade9_full.json',
      coverColor: 0xFF0081CF,
    ),
    Wordbook(
      id: 'senior_g10s1',
      name: '高一上册',
      description: '人教版高中英语高一上册',
      category: WordbookCategory.seniorHigh,
      wordCount: 180,
      grade: 10,
      semester: 1,
      assetPath: 'assets/word_lists/senior_high/grade10_semester1.json',
      coverColor: 0xFF7B2D8B,
    ),
    Wordbook(
      id: 'senior_g10s2',
      name: '高一下册',
      description: '人教版高中英语高一下册',
      category: WordbookCategory.seniorHigh,
      wordCount: 180,
      grade: 10,
      semester: 2,
      assetPath: 'assets/word_lists/senior_high/grade10_semester2.json',
      coverColor: 0xFF9B59B6,
    ),
    Wordbook(
      id: 'senior_g11s1',
      name: '高二上册',
      description: '人教版高中英语高二上册',
      category: WordbookCategory.seniorHigh,
      wordCount: 200,
      grade: 11,
      semester: 1,
      assetPath: 'assets/word_lists/senior_high/grade11_semester1.json',
      coverColor: 0xFFBB8FCE,
    ),
    Wordbook(
      id: 'senior_g11s2',
      name: '高二下册',
      description: '人教版高中英语高二下册',
      category: WordbookCategory.seniorHigh,
      wordCount: 200,
      grade: 11,
      semester: 2,
      assetPath: 'assets/word_lists/senior_high/grade11_semester2.json',
      coverColor: 0xFF7B2D8B,
    ),
    Wordbook(
      id: 'senior_g12s1',
      name: '高三上册',
      description: '人教版高中英语高三上册',
      category: WordbookCategory.seniorHigh,
      wordCount: 220,
      grade: 12,
      semester: 1,
      assetPath: 'assets/word_lists/senior_high/grade12_semester1.json',
      coverColor: 0xFF9B59B6,
    ),
    Wordbook(
      id: 'senior_g12s2',
      name: '高三下册',
      description: '人教版高中英语高三下册',
      category: WordbookCategory.seniorHigh,
      wordCount: 220,
      grade: 12,
      semester: 2,
      assetPath: 'assets/word_lists/senior_high/grade12_semester2.json',
      coverColor: 0xFFBB8FCE,
    ),
  ];

  final Future<int> Function(String assetPath) _loadWordCount;

  @override
  Future<List<Wordbook>> getWordbooks() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _hydrateWordCounts(_builtIn);
  }

  @override
  Future<List<Wordbook>> getBuiltInWordbooks() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _hydrateWordCounts(_builtIn);
  }

  @override
  Future<Wordbook?> getWordbookById(String id) async {
    final wordbooks = await getBuiltInWordbooks();
    for (final book in wordbooks) {
      if (book.id == id) {
        return book;
      }
    }
    return null;
  }

  Future<List<Wordbook>> _hydrateWordCounts(List<Wordbook> wordbooks) async {
    return Future.wait(
      wordbooks.map((book) async {
        final assetPath = book.assetPath;
        if (assetPath == null || assetPath.isEmpty) {
          return book;
        }

        final wordCount = await _loadWordCount(assetPath);
        return book.copyWith(wordCount: wordCount);
      }),
    );
  }

  static Future<int> _defaultLoadWordCount(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.length;
    }
    return 0;
  }
}
