import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _isSpeaking = false;

  VoiceService() {
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
    });
  }

  // Initialize speech to text
  Future<bool> initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );
    return available;
  }

  // Start listening
  Future<String?> startListening({
    required Function(String) onResult,
    Function()? onListeningStarted,
    Function()? onListeningStopped,
  }) async {
    if (!_isListening) {
      _isListening = true;
      onListeningStarted?.call();

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            _isListening = false;
            onListeningStopped?.call();
          }
        },
        localeId: 'ml_IN', // Malayalam locale
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      );
    }
    return null;
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  // Text to Speech
  Future<void> speak(String text) async {
    await _tts.setLanguage("ml-IN"); // Malayalam
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  // Check if currently speaking
  bool isSpeaking() {
    return _isSpeaking;
  }

  // Dispose resources
  void dispose() {
    _speech.cancel();
    _tts.stop();
  }
}
