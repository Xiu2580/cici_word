import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/word.dart';
import '../repositories/i_settings_repository.dart';

class SharedPreferencesSettingsRepository implements ISettingsRepository {
  static const String _prefix = 'cici_word.';
  static const String _legacyKey = 'cici_word_settings';

  Map<String, dynamic>? _cache;

  @override
  Future<Map<String, dynamic>> getSettings() async {
    await _ensureLoaded();
    return Map<String, dynamic>.from(_cache!);
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _ensureLoaded();

    final prefs = await SharedPreferences.getInstance();
    for (final entry in settings.entries) {
      final key = '$_prefix${entry.key}';
      final value = entry.value;

      _cache![entry.key] = value;

      if (value == null) {
        await prefs.remove(key);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      } else {
        await prefs.setString(key, jsonEncode(value));
      }
    }
  }

  Future<void> _ensureLoaded() async {
    if (_cache != null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _cache = <String, dynamic>{};

    // Migrate legacy single-key format if present
    final legacyRaw = prefs.getString(_legacyKey);
    if (legacyRaw != null && legacyRaw.isNotEmpty) {
      final decoded = _decodeJson(legacyRaw);
      if (decoded != null) {
        for (final entry in decoded.entries) {
          final key = '$_prefix${entry.key}';
          await _writeSingleValue(prefs, key, entry.value);
          _cache![entry.key] = entry.value;
        }
        await prefs.remove(_legacyKey);
        return;
      }
    }

    // Read individual keys
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final fullKey in keys) {
      final shortKey = fullKey.substring(_prefix.length);
      final value = prefs.get(fullKey);
      if (value != null) {
        _cache![shortKey] = _decodeComplexValue(value);
      }
    }
  }

  Future<void> _writeSingleValue(
    SharedPreferences prefs,
    String fullKey,
    dynamic value,
  ) async {
    if (value is bool) {
      await prefs.setBool(fullKey, value);
    } else if (value is int) {
      await prefs.setInt(fullKey, value);
    } else if (value is double) {
      await prefs.setDouble(fullKey, value);
    } else if (value is String) {
      await prefs.setString(fullKey, value);
    } else if (value is List<String>) {
      await prefs.setStringList(fullKey, value);
    } else {
      await prefs.setString(fullKey, jsonEncode(value));
    }
  }

  dynamic _decodeComplexValue(dynamic value) {
    if (value is! String) {
      return value;
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map((key, val) => MapEntry(key.toString(), val));
      }
      return decoded;
    } catch (_) {
      return value;
    }
  }

  @override
  Future<void> saveCustomWordbook({
    required String name,
    required List<Word> words,
  }) async {
    await _ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    final existing = _cache!['custom_wordbooks'] as List<dynamic>? ?? [];
    final wordList = words
        .map((w) => {
              'english': w.english,
              'chinese': w.chinese,
              'part_of_speech': w.partOfSpeech,
              'us_phonetic': w.usPhonetic,
              'uk_phonetic': w.ukPhonetic,
              'example_sentence_en': w.exampleSentenceEn,
              'example_sentence_cn': w.exampleSentenceCn,
              'inflection': w.inflection,
            })
        .toList();
    existing.add({
      'name': name,
      'words': wordList,
      'created_at': DateTime.now().toIso8601String(),
    });
    _cache!['custom_wordbooks'] = existing;
    await prefs.setString('${_prefix}custom_wordbooks', jsonEncode(existing));
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomWordbooks() async {
    await _ensureLoaded();
    final raw = _cache!['custom_wordbooks'];
    if (raw is List) {
      return raw.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Map<String, dynamic>? _decodeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
