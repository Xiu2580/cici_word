import 'package:cici_word/features/settings/viewmodel/settings_viewmodel.dart';

String buildDefaultDictationRoute({
  required String bookId,
  SettingsViewModel? settings,
}) {
  final mode = settings?.dictationMode ?? 'hint';
  return '/dictation/session/$bookId/$mode';
}
