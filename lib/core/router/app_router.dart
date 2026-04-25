import 'package:go_router/go_router.dart';

import '../../features/dictation/view/dictation_home_page.dart';
import '../../features/dictation/view/dictation_mode_page.dart';
import '../../features/dictation/view/dictation_session_page.dart';
import '../../features/favorites/view/favorites_page.dart';
import '../../features/import/view/import_page.dart';
import '../../features/learn/view/learn_home_page.dart';
import '../../features/review/view/review_mistakes_page.dart';
import '../../features/review/view/review_page.dart';
import '../../features/search/view/search_page.dart';
import '../../features/settings/view/settings_page.dart';
import '../../features/splash/view/splash_page.dart';
import '../../features/study/view/study_page.dart';
import '../../features/wordbook/view/wordbook_detail_page.dart';
import '../../features/wordbook/view/wordbook_v2_page.dart';
import '../../shared/widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/wordbook',
          builder: (_, __) => const WordbookV2Page(),
          routes: [
            GoRoute(
              path: ':bookId',
              builder: (_, state) => WordbookDetailPage(
                bookId: state.pathParameters['bookId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/learn',
          builder: (_, __) => const LearnHomePage(),
        ),
        GoRoute(
          path: '/dictation',
          builder: (_, __) => const DictationHomePage(),
        ),
        GoRoute(
          path: '/search',
          builder: (_, __) => const SearchPage(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (_, __) => const FavoritesPage(),
        ),
        GoRoute(
          path: '/review',
          builder: (_, __) => const ReviewPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/study/:bookId',
      builder: (_, state) => StudyPage(
        bookId: state.pathParameters['bookId']!,
      ),
    ),
    GoRoute(
      path: '/dictation/mode/:bookId',
      builder: (_, state) => DictationModePage(
        bookId: state.pathParameters['bookId']!,
      ),
    ),
    GoRoute(
      path: '/dictation/session/:bookId',
      builder: (_, state) => DictationSessionPage(
        bookId: state.pathParameters['bookId']!,
        mode: 'full',
      ),
    ),
    GoRoute(
      path: '/dictation/session/:bookId/:mode',
      builder: (_, state) => DictationSessionPage(
        bookId: state.pathParameters['bookId']!,
        mode: state.pathParameters['mode']!,
      ),
    ),
    GoRoute(
      path: '/review/mistakes',
      builder: (_, __) => const ReviewMistakesPage(),
    ),
    GoRoute(
      path: '/import',
      builder: (_, __) => const ImportPage(),
    ),
  ],
);
