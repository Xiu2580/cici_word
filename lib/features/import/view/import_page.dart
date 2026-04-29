import 'dart:convert';
import 'dart:io';

import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:cici_word/core/theme/app_colors.dart';
import 'package:cici_word/data/models/word.dart';
import 'package:cici_word/data/repositories/i_settings_repository.dart';
import 'package:file_picker/file_picker.dart';
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

  List<Word> _previewWords = const [];
  String? _errorText;
  String? _loadedFileName;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String content;
      if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else {
        return;
      }

      final words = _parseJsonContent(content);
      final name = file.name.replaceAll('.json', '');
      _nameController.text = name;
      setState(() {
        _previewWords = words;
        _errorText = null;
        _loadedFileName = file.name;
      });
    } on Exception catch (e) {
      setState(() {
        _previewWords = const [];
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文件读取失败，请检查文件格式')),
      );
    }
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
        'english', 'word', 'name', 'en', 'term', 'entry', 'title',
      ]);
      final chinese = _readString(item, const [
        'chinese', 'meaning', 'translation', 'trans', 'cn', 'zh',
        'definition', 'def',
      ]);
      if (english.isEmpty || chinese.isEmpty) {
        throw Exception('第 ${index + 1} 个 JSON 项缺少单词或释义');
      }

      words.add(Word(
        id: 'import_${index}_${english.toLowerCase()}',
        english: english,
        chinese: chinese,
        partOfSpeech: _readString(item, const [
          'part_of_speech', 'partOfSpeech', 'pos', 'type', 'category',
        ]),
        usPhonetic: _readString(item, const [
          'us_phonetic', 'usPhonetic', 'phonetic_us', 'pronunciation_us',
        ]),
        ukPhonetic: _readString(item, const [
          'uk_phonetic', 'ukPhonetic', 'phonetic_uk', 'pronunciation_uk',
        ]),
        exampleSentenceEn: _readString(item, const [
          'example_sentence_en', 'exampleSentenceEn', 'example_en',
          'sentence_en', 'example',
        ]),
        exampleSentenceCn: _readString(item, const [
          'example_sentence_cn', 'exampleSentenceCn', 'example_cn',
          'sentence_cn',
        ]),
        inflection: _readString(item, const [
          'inflection', 'inflections', 'forms', 'word_forms',
        ]),
      ));
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

  Future<void> _submitImport() async {
    if (_previewWords.isEmpty) return;

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
        SnackBar(content: Text('已导入 ${draft.words.length} 个单词：${draft.name}')),
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
        SnackBar(content: Text('已导入 ${draft.words.length} 个单词：${draft.name}')),
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
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.file_open),
            label: const Text('选择 JSON 文件导入'),
          ),
          if (_loadedFileName != null) ...[
            const SizedBox(height: 8),
            Text(
              '已加载: $_loadedFileName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '预览结果',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _previewWords.isEmpty ? null : _submitImport,
                child: Text(
                  _previewWords.isEmpty ? '请先选择文件' : '确认导入 (${_previewWords.length} 词)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_previewWords.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '请选择一个 JSON 格式的词书文件',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0;
                        index < _previewWords.take(8).length;
                        index++) ...[
                      _PreviewRow(word: _previewWords[index]),
                      if (index != _previewWords.take(8).length - 1)
                        const Divider(
                            height: 20, color: AppColors.dividerLight),
                    ],
                    if (_previewWords.length > 8) ...[
                      const SizedBox(height: 8),
                      Text(
                        '... 还有 ${_previewWords.length - 8} 个单词',
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
