/// 应用常量配置
class AppConstants {
  AppConstants._();

  // ============ 动画时长 ============
  /// 默认动画时长（用于一般过渡效果）
  static const animationDuration = Duration(milliseconds: 300);

  /// 卡片翻转动画时长（学习页面）
  static const cardFlipDuration = Duration(milliseconds: 400);

  /// 启动页显示时长
  static const splashDuration = Duration(seconds: 2);

  // ============ 学习相关 ============
  /// 默认每日学习目标（单词数）
  static const defaultDailyGoal = 20;

  // ============ 字体缩放范围（无障碍支持）===========
  /// 最大字体缩放因子
  static const maxFontScale = 1.4;

  /// 最小字体缩放因子
  static const minFontScale = 0.8;
}
