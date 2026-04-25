import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DictationModePage extends StatelessWidget {
  const DictationModePage({
    super.key,
    required this.bookId,
    this.onSelectMode,
  });

  final String bookId;
  final ValueChanged<String>? onSelectMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => popOrGo(context, '/wordbook/$bookId'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('选择默写模式'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () => _handleSelect(context, 'full'),
                child: const Text('完整默写'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _handleSelect(context, 'hint'),
                child: const Text('提示默写'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSelect(BuildContext context, String mode) {
    if (onSelectMode != null) {
      onSelectMode!(mode);
      return;
    }
    context.go('/dictation/session/$bookId/$mode');
  }
}
