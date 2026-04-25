import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/i_settings_repository.dart';

class SharedPreferencesSettingsRepository implements ISettingsRepository {
  static const String _storageKey = 'cici_word_settings';

  Map<String, dynamic>? _cache;

  @override
  Future<Map<String, dynamic>> getSettings() async {
    await _ensureLoaded();
    return Map<String, dynamic>.from(_cache!);
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _ensureLoaded();
    _cache!.addAll(settings);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_cache));
  }

  Future<void> _ensureLoaded() async {
    if (_cache != null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = <String, dynamic>{};
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      _cache = decoded;
      return;
    }
    if (decoded is Map) {
      _cache = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return;
    }

    _cache = <String, dynamic>{};
  }
}
