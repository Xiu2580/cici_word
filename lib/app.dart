import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/services/flutter_tts_service.dart';
import 'core/services/i_tts_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/local_word_repository.dart';
import 'data/local/local_wordbook_repository.dart';
import 'data/local/shared_preferences_settings_repository.dart';
import 'data/repositories/i_settings_repository.dart';
import 'data/repositories/i_word_repository.dart';
import 'data/repositories/i_wordbook_repository.dart';
import 'features/review/viewmodel/review_mistake_store.dart';
import 'features/settings/viewmodel/settings_viewmodel.dart';
import 'features/settings/viewmodel/theme_viewmodel.dart';
import 'features/stats/viewmodel/stat_viewmodel.dart';
import 'features/wordbook/viewmodel/current_wordbook_viewmodel.dart';

class CiciWordApp extends StatelessWidget {
  const CiciWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ISettingsRepository>(
          create: (_) => SharedPreferencesSettingsRepository(),
        ),
        Provider<IWordRepository>(
          create: (context) =>
              LocalWordRepository(context.read<ISettingsRepository>()),
        ),
        Provider<IWordbookRepository>(
          create: (_) => LocalWordbookRepository(),
        ),
        Provider<ITtsService>(create: (_) => FlutterTtsService()),
        ChangeNotifierProvider(
          create: (context) => ThemeViewModel(
            context.read<ISettingsRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CurrentWordbookViewModel(
            context.read<ISettingsRepository>(),
            context.read<IWordbookRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ReviewMistakeStore(
            context.read<ISettingsRepository>(),
            context.read<IWordRepository>(),
          )..ensureLoaded(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SettingsViewModel(
            ctx.read<ISettingsRepository>(),
            ctx.read<IWordRepository>(),
            ctx.read<ReviewMistakeStore>(),
          ),
        ),
        ChangeNotifierProxyProvider2<IWordRepository, IWordbookRepository,
            StatViewModel>(
          create: (ctx) => StatViewModel(
            ctx.read<IWordRepository>(),
            ctx.read<IWordbookRepository>(),
          ),
          update: (_, wordRepo, wordbookRepo, vm) =>
              vm ?? StatViewModel(wordRepo, wordbookRepo),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVm, _) {
          final fontScale = themeVm.fontScale;
          return MaterialApp.router(
            title: '词词不忘',
            theme: AppTheme.light(fontScale: fontScale),
            darkTheme: AppTheme.dark(fontScale: fontScale),
            themeMode: themeVm.mode,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
