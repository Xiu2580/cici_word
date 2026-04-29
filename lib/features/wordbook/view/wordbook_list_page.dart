import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:cici_word/data/models/wordbook.dart';
import 'package:cici_word/data/repositories/i_wordbook_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WordbookListPage extends StatefulWidget {
  const WordbookListPage({super.key});

  @override
  State<WordbookListPage> createState() => _WordbookListPageState();
}

class _WordbookListPageState extends State<WordbookListPage> {
  bool _isLoading = true;
  String? _error;
  List<Wordbook> _books = const [];
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (_isLoading || _hasLoaded) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<IWordbookRepository>();
      final books = await repo.getWordbooks();
      if (!mounted) {
        return;
      }
      setState(() {
        _books = books;
        _hasLoaded = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '词库加载失败，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: const Text('词库'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('词库', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      '共 ${_books.length} 本',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    for (final book in _books) ...[
                      Card(
                        child: ListTile(
                          title: Text(book.name),
                          subtitle: Text(book.description),
                          trailing: Text('${book.wordCount} 词'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
    );
  }
}
