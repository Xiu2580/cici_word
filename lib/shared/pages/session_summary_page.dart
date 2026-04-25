import 'package:cici_word/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SessionSummaryPage extends StatelessWidget {
  const SessionSummaryPage({
    super.key,
    this.knownCount = 0,
    this.fuzzyCount = 0,
    this.unknownCount = 0,
    this.onRestart,
    this.onBackToWordbook,
  });

  final int knownCount;
  final int fuzzyCount;
  final int unknownCount;
  final VoidCallback? onRestart;
  final VoidCallback? onBackToWordbook;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBackToWordbook,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('本轮已完成'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: AppColors.known,
              ),
              const SizedBox(height: 16),
              Text(
                '本轮已完成',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '做得不错，继续保持今天的节奏。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryStat(
                        label: '认识',
                        value: '$knownCount',
                        color: AppColors.known,
                      ),
                      _SummaryStat(
                        label: '不认识',
                        value: '$unknownCount',
                        color: AppColors.unknown,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: onBackToWordbook,
                child: const Text('返回词表'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRestart,
                child: const Text('再来一轮'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
