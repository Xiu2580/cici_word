import '../models/review_item.dart';

/// 复习仓储层接口
///
/// 定义复习相关数据操作的标准接口
abstract class IReviewRepository {
  /// 获取今日需要复习的单词列表
  Future<List<ReviewItem>> getTodayReview();

  /// 标记复习结果
  ///
  /// [reviewItemId] 复习项ID
  /// [correct] 是否回答正确
  Future<void> markReviewed(String reviewItemId, bool correct);
}