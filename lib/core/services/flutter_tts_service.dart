import 'package:flutter_tts/flutter_tts.dart';

import 'i_tts_service.dart';

class FlutterTtsService implements ITtsService {
  FlutterTtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _initFuture = _configure();
  }

  final FlutterTts _tts;
  late final Future<void> _initFuture;

  Future<void> _configure() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.45);
  }

  @override
  Future<void> speakEnglish(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    await _initFuture;
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _initFuture;
    await _tts.stop();
  }
}
