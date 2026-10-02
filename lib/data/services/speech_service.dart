import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../features/developer/logs/log_viewer_screen.dart';

class SpeechService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _listening = false;
  bool get isListening => _listening;

  String _lastHeard = '';
  String get lastHeard => _lastHeard;

  Future<bool> init() async {
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.45);
    final available = await _stt.initialize(
      onStatus: _handleStatus,
      onError: (error) {
        _listening = false;
        LogViewerScreen.log('speech error: ${error.errorMsg}');
        notifyListeners();
      },
    );
    if (!available) LogViewerScreen.log('speech: STT unavailable');
    notifyListeners();
    return available;
  }

  Future<void> listen(void Function(String text) onResult) async {
    if (_listening) return;
    final available = await _stt.initialize(
      onStatus: _handleStatus,
      onError: (error) {
        _listening = false;
        LogViewerScreen.log('speech error: ${error.errorMsg}');
        notifyListeners();
      },
    );
    if (!available) {
      LogViewerScreen.log('speech: STT unavailable');
      return;
    }

    _listening = true;
    notifyListeners();

    await _stt.listen(
      localeId: 'ar_SA',
      listenMode: ListenMode.confirmation,
      onResult: (r) {
        _lastHeard = r.recognizedWords;
        if (r.finalResult) {
          _listening = false;
          notifyListeners();
          onResult(_lastHeard);
        }
      },
    );
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_listening) {
        _listening = false;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    await _stt.stop();
    _listening = false;
    notifyListeners();
  }

  Future<void> speak(String text) => _tts.speak(text);

  Future<void> stopSpeaking() => _tts.stop();
}
