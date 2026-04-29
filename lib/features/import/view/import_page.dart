import 'dart:convert';

import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:cici_word/core/theme/app_colors.dart';
import 'package:cici_word/data/models/word.dart';
import 'package:cici_word/data/repositories/i_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ImportedWordbookDraft {
  const ImportedWordbookDraft({
    required this.name,
    required this.words,
  });

  final String name;
  final List<Word> words;
}

class ImportPage extends StatefulWidget {
  const ImportPage({
    super.key,
    this.onImport,
  });

  final ValueChanged<ImportedWordbookDraft>? onImport;

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  List<Word> _previewWords = const [];
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _buildPreview() {
    final raw = _contentController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _previewWords = const [];
        _errorText = '请先输入词表内容';
      });
      return;
    }

    try {
      final words = _parseContent(raw);
      setState(() {
        _previewWords = words;
        _errorText = null;
      });
    } catch (error) {
      setState(() {
        _previewWords = const [];
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Word> _parseContent(String raw) {
    final normalized = raw.trimLeft();
    if (normalized.startsWith('[') || normalized.startsWith('{')) {
      return _parseJsonContent(raw);
    }
    return _parseTextContent(raw);
  }

  List<Word> _parseTextContent(String raw) {
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw Exception('请先输入词表内容');
    }

    final words = <Word>[];
    for (var index = 0; index < lines.length; index++) {
      final parts = lines[index]
          .split('|')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();

      if (parts.length < 2) {
        throw Exception('第 ${index + 1} 行格式不正确，请使用：英文 | 中文 | 词性');
      }

      words.add(
        _buildWord(
          index: index,
          english: parts[0],
          chinese: parts[1],
          partOfSpeech: parts.length >= 3 ? parts[2] : '',
        ),
      );
    }
    return words;
  }

  List<Word> _parseJsonContent(String raw) {
    final decoded = jsonDecode(raw);
    final items = switch (decoded) {
      List<dynamic> value => value,
      Map<String, dynamic> value when value['words'] is List<dynamic> =>
        value['words'] as List<dynamic>,
      Map value when value['words'] is List<dynamic> =>
        value['words'] as List<dynamic>,
      _ => throw Exception('JSON 格式不正确，请使用数组或包含 words 的对象'),
    };

    if (items.isEmpty) {
      throw Exception('JSON 中没有可导入的单词');
    }

    final words = <Word>[];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (item is! Map) {
        throw Exception('第 ${index + 1} 个 JSON 项格式不正确');
      }

      final english = _readString(item, const [
        'english',
        'word',
      ]);
      final chinese = _readString(item, const [
        'chinese',
        'meaning',
        'translation',
      ]);
      final partOfSpeech = _readOptionalString(item, const [
        'part_of_speech',
        'partOfSpeech',
        'pos',
      ]);

      if (english.isEmpty || chinese.isEmpty) {
        throw Exception('第 ${index + 1} 个 JSON 项缺少 english 或 chinese');
      }

      words.add(
        _buildWord(
          index: index,
          english: english,
          chinese: chinese,
          partOfSpeech: partOfSpeech,
        ),
      );
    }
    return words;
  }

  String _readString(Map item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  String _readOptionalString(Map item, List<String> keys) {
    return _readString(item, keys);
  }

  Word _buildWord({
    required int index,
    required String english,
    required String chinese,
    required String partOfSpeech,
  }) {
    return Word(
      id: 'import_${index}_${english.toLowerCase()}',
      english: english,
      chinese: chinese,
      partOfSpeech: partOfSpeech,
      usPhonetic: '',
      ukPhonetic: '',
      exampleSentenceEn: '',
      exampleSentenceCn: '',
      inflection: '',
    );
  }

  Future<void> _submitImport() async {
    if (_previewWords.isEmpty) {
      _buildPreview();
      return;
    }

    final draft = ImportedWordbookDraft(
      name: _nameController.text.trim().isEmpty
          ? '我的导入词书'
          : _nameController.text.trim(),
      words: List.unmodifiable(_previewWords),
    );

    if (widget.onImport != null) {
      widget.onImport!(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导入 ${draft.words.length} 个单词：${draft.name}'),
        ),
      );
      return;
    }

    try {
      final settingsRepo = context.read<ISettingsRepository>();
      await settingsRepo.saveCustomWordbook(
        name: draft.name,
        words: draft.words,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导入 ${draft.words.length} 个单词：${draft.name}'),
        ),
      );
      if (!mounted) return;
      context.go('/wordbook');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入失败，请稍后重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => popOrGo(context, '/wordbook'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('导入词书'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('词书名称', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: '例如：我的高频词书',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('词表内容', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            minLines: 8,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText:
                  '文本格式：apple | 苹果 | n.\n或 JSON 格式：[{"english":"apple","chinese":"苹果"}]',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _buildPreview,
                  child: const Text('生成预览'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitImport,
                  child: const Text('确认导入'),
                ),
              ),
            ],
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.unknown,
                  ),
            ),
          ],
          const SizedBox(height: 20),
          Text('预览结果', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_previewWords.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('暂无预览内容'),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('共解析 ${_previewWords.length} 个单词'),
                    const SizedBox(height: 12),
                    for (var index = 0; index < _previewWords.take(8).length; index++) ...[
                      _PreviewRow(word: _previewWords[index]),
                      if (index != _previewWords.take(8).length - 1)
                        const Divider(height: 20, color: AppColors.dividerLight),
                    ],
                    if (_previewWords.length > 8) ...[
                      const SizedBox(height: 8),
                      Text(
                        '仅展示前 8 个单词',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            word.english,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(word.chinese)),
        if (word.partOfSpeech.trim().isNotEmpty) ...[
          const SizedBox(width: 12),
          Text(
            word.partOfSpeech,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
