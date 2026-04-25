import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../data/repositories/i_settings_repository.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel([this._settingsRepository]) {
    _load();
  }

  final ISettingsRepository? _settingsRepository;

  ThemeMode _mode = ThemeMode.system;
  double _fontScale = 1.0;
  bool _animationsEnabled = true;

  ThemeMode get mode => _mode;
  double get fontScale => _fontScale;
  bool get animationsEnabled => _animationsEnabled;

  Future<void> _load() async {
    final settings =
        await _settingsRepository?.getSettings() ?? const <String, dynamic>{};
    _mode = _parseThemeMode(settings['theme_mode'] as String?);
    _fontScale = (settings['font_scale'] as num?)?.toDouble() ?? 1.0;
    _animationsEnabled = settings['animations_enabled'] as bool? ?? true;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    _settingsRepository?.saveSettings({'theme_mode': mode.name});
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void setFontScale(double scale) {
    final next =
        scale.clamp(AppConstants.minFontScale, AppConstants.maxFontScale);
    if (_fontScale == next) {
      return;
    }
    _fontScale = next;
    _settingsRepository?.saveSettings({'font_scale': next});
    notifyListeners();
  }

  void toggleAnimations() {
    setAnimationsEnabled(!_animationsEnabled);
  }

  void setAnimationsEnabled(bool enabled) {
    if (_animationsEnabled == enabled) {
      return;
    }
    _animationsEnabled = enabled;
    _settingsRepository?.saveSettings({'animations_enabled': enabled});
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String? value) {
    return ThemeMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}
