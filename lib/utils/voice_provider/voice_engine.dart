import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceEngine {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setSharedInstance(true);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true); // makes speak() wait for actual finish
    _initialized = true;
  }

  Future<void> speak(String text, String bcp47) async {
    if (!_initialized) await init();
    await _tts.stop();
    if (kIsWeb) {
      // On web flutter_tts may not work — silently skip
      return;
    }
    await _tts.setLanguage(bcp47);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}