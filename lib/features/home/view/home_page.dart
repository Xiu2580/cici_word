import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('词词不忘')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('词词不忘', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '从这里快速进入常用功能',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          _QuickEntryCard(
            title: '词书',
            subtitle: '选择词书，查看单词列表',
            icon: Icons.menu_book_outlined,
            onTap: () => context.go('/wordbook'),
          ),
          const SizedBox(height: 12),
          _QuickEntryCard(
            title: '学习',
            subtitle: '正面看英文，翻卡看中文和例句',
            icon: Icons.style_outlined,
            onTap: () => context.go('/learn'),
          ),
          const SizedBox(height: 12),
          _QuickEntryCard(
            title: '默写',
            subtitle: '完整默写或提示默写',
            icon: Icons.keyboard_outlined,
            onTap: () => context.go('/dictation'),
          ),
          const SizedBox(height: 12),
          _QuickEntryCard(
            title: '复习',
            subtitle: '集中处理错词和薄弱词',
            icon: Icons.refresh_outlined,
            onTap: () => context.go('/review'),
          ),
          const SizedBox(height: 12),
          _QuickEntryCard(
            title: '搜索',
            subtitle: '快速查找英文、中文和词性',
            icon: Icons.search,
            onTap: () => context.go('/search'),
          ),
        ],
      ),
    );
  }
}

class _QuickEntryCard extends StatelessWidget {
  const _QuickEntryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
