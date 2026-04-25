import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const List<_ShellTab> _tabs = [
    _ShellTab(
      route: '/wordbook',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: '词库',
    ),
    _ShellTab(
      route: '/search',
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      label: '搜索',
    ),
    _ShellTab(
      route: '/favorites',
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      label: '收藏',
    ),
    _ShellTab(
      route: '/review',
      icon: Icons.refresh_outlined,
      activeIcon: Icons.refresh,
      label: '复习',
    ),
    _ShellTab(
      route: '/settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: '设置',
    ),
  ];

  @visibleForTesting
  static List<String> get tabRoutes =>
      _tabs.map((tab) => tab.route).toList(growable: false);

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri;
    for (var i = 0; i < _tabs.length; i++) {
      if (_tabs[i].matches(location)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => context.go(_tabs[index].route),
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                activeIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  bool matches(Uri location) {
    final routePath = Uri.parse(route).pathSegments;
    final locationPath = location.pathSegments;
    if (routePath.isEmpty || locationPath.isEmpty) {
      return route == location.path;
    }
    return routePath.first == locationPath.first;
  }
}
