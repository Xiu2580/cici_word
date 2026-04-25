import '../models/word.dart';

/// 单词筛选条件枚举
///
/// 用于学习页面按熟悉度筛选单词:
/// - all: 全部
/// - unknown: 不认识
/// - fuzzy: 模糊
/// - known: 认识
/// - favorite: 收藏
enum StudyFilter { all, unknown, fuzzy, known, favorite }

/// 单词仓储层接口
///
/// 定义单词数据操作的标准接口
/// 实现类包括: LocalWordRepository（本地资源 + 本地持久化）
abstract class IWordRepository {
  /// 获取词库中的单词列表
  ///
  /// [bookId] 词库ID
  /// [filter] 筛选条件，默认为全部
  Future<List<Word>> getWords(String bookId, {StudyFilter filter = StudyFilter.all});

  /// 根据ID获取单词
  Future<Word?> getWordById(String id);

  /// 标记单词熟悉度
  Future<void> markWord(String id, Familiarity familiarity);

  /// 切换单词收藏状态
  Future<void> toggleFavorite(String id);

  /// 获取所有收藏的单词
  Future<List<Word>> getFavorites();

  /// 获取错题本（标记为 fuzzy 或 unknown 的单词）
  Future<List<Word>> getMistakes();

  /// 清空学习记录，将所有单词恢复为未学习状态
  Future<void> clearLearningRecords();
}
