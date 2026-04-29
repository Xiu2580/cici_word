import '../models/word.dart';

/// 设置仓储层接口
///
/// 定义用户设置数据操作的标准接口
abstract class ISettingsRepository {
  /// 获取所有设置
  ///
  /// 返回 Map 包含所有键值对设置
  Future<Map<String, dynamic>> getSettings();

  /// 保存设置
  ///
  /// [settings] 要保存的设置键值对
  Future<void> saveSettings(Map<String, dynamic> settings);

  /// 保存自定义词书
  Future<void> saveCustomWordbook({
    required String name,
    required List<Word> words,
  });

  /// 获取所有自定义词书
  Future<List<Map<String, dynamic>>> getCustomWordbooks();
}
