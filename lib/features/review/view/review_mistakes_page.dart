import 'package:cici_word/core/router/navigation_helpers.dart';
import 'package:cici_word/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/review_mistake_store.dart';

class ReviewMistakesPage extends StatelessWidget {
  const ReviewMistakesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ReviewMistakeStore>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => popOrGo(context, '/review'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('错词强化'),
      ),
      body: store.isEmpty
          ? const Center(child: Text('暂无错词'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: store.words.length,
              itemBuilder: (context, index) {
                final word = store.words[index];
                return _MistakeWordRow(
                  index: index + 1,
                  english: word.english,
                  partOfSpeech: word.partOfSpeech,
                  chinese: word.chinese,
                );
              },
            ),
    );
  }
}

class _MistakeWordRow extends StatelessWidget {
  const _MistakeWordRow({
    required this.index,
    required this.english,
    required this.partOfSpeech,
    required this.chinese,
  });

  final int index;
  final String english;
  final String partOfSpeech;
  final String chinese;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$index',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  english,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (partOfSpeech.trim().isNotEmpty)
                  Text(
                    partOfSpeech,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                Text(
                  chinese,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
