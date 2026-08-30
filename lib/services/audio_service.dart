import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AudioService {
  final SpeechToText _speech = SpeechToText();
  AudioRecorder? _recorder;
  AudioPlayer? _player;

  bool _speechAvailable = false;
  bool _recordAvailable = false;
  bool _isInitialized = false;

  bool get speechAvailable => _speechAvailable;
  bool get recordAvailable => _recordAvailable;
  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_isInitialized) return _speechAvailable;
    try {
      _speechAvailable = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
    } catch (_) {
      _speechAvailable = false;
    }

    if (!kIsWeb) {
      try {
        _recorder = AudioRecorder();
        _recordAvailable = await _recorder!.hasPermission();
      } catch (_) {
        _recordAvailable = false;
      }
    }

    _player = AudioPlayer();
    _isInitialized = true;
    return _speechAvailable;
  }

  Future<void> startListening({
    required void Function(String text, double confidence, bool isFinal) onResult,
    void Function(double level)? onLevel,
    Duration listenFor = const Duration(seconds: 15),
  }) async {
    if (!_speechAvailable) return;
    try {
      await _speech.listen(
        onResult: (result) {
          onResult(
            result.recognizedWords,
            result.confidence,
            result.finalResult,
          );
        },
        onSoundLevelChange: onLevel,
        listenFor: listenFor,
        pauseFor: const Duration(seconds: 5),
      );
    } catch (_) {}
  }

  /// Listens purely to measure the ambient audio level. Recognition results
  /// are ignored — this only samples the environment.
  Future<void> startLevelScan({
    required void Function(double level) onLevel,
    Duration duration = const Duration(seconds: 30),
  }) async {
    if (!_speechAvailable) return;
    try {
      await _speech.listen(
        onResult: (_) {},
        onSoundLevelChange: onLevel,
        listenFor: duration,
        pauseFor: duration,
      );
    } catch (_) {}
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<String?> startRecording() async {
    if (!_recordAvailable || _recorder == null) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/st_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder!.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: path,
      );
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      return await _recorder?.stop();
    } catch (_) {
      return null;
    }
  }

  Future<void> playAudio(String path) async {
    try {
      await _player?.setFilePath(path);
      await _player?.play();
    } catch (_) {}
  }

  Future<void> stopPlayback() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  void dispose() {
    _speech.stop();
    _recorder?.dispose();
    _player?.dispose();
  }
}
