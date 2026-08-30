import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/investigation.dart';
import '../services/audio_service.dart';
import '../services/investigation_service.dart';

enum InvestigationPhase { idle, baseline, scanning, detected }

/// Lifecycle of the investigation session itself. Nothing runs until the
/// investigator deliberately moves from [ready] to [active].
enum SessionState { ready, active, ended }

class InvestigationProvider extends ChangeNotifier {
  final InvestigationService _service;
  final AudioService _audioService;

  InvestigationProvider({
    required InvestigationService service,
    required AudioService audioService,
  })  : _service = service,
        _audioService = audioService;

  static const int scanWindowSeconds = 15;
  static const int baselineSeconds = 30;
  static const String blindFlag = 'blind_intro_seen';
  static const String skepticFlag = 'skeptic_intro_seen';

  Investigation? _investigation;
  Investigation? get investigation => _investigation;

  SessionState _session = SessionState.ready;
  SessionState get session => _session;

  bool get isActive => _session == SessionState.active;
  bool get isEnded => _session == SessionState.ended;

  InvestigationPhase _phase = InvestigationPhase.idle;
  InvestigationPhase get phase => _phase;

  bool _blindMode = false;
  bool get blindMode => _blindMode;

  bool _skepticMode = false;
  bool get skepticMode => _skepticMode;

  bool _blindIntroSeen = false;
  bool get blindIntroSeen => _blindIntroSeen;

  bool _skepticIntroSeen = false;
  bool get skepticIntroSeen => _skepticIntroSeen;

  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  String get elapsedLabel {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int _scanTimeRemaining = 0;
  int get scanTimeRemaining => _scanTimeRemaining;

  int _baselineRemaining = 0;
  int get baselineRemaining => _baselineRemaining;

  double get baselineProgress =>
      _baselineRemaining <= 0 ? 0 : 1 - (_baselineRemaining / baselineSeconds);

  bool get hasBaseline => _investigation?.hasBaseline ?? false;

  String _liveText = '';
  String get liveText => _liveText;

  double _currentLevel = 0;
  double get currentLevel => _currentLevel;

  String? _error;
  String? get error => _error;

  bool _audioInitialized = false;
  bool get audioInitialized => _audioInitialized;

  bool get speechAvailable => _audioService.speechAvailable;

  Timer? _scanTimer;
  Timer? _baselineTimer;
  Timer? _sessionTimer;
  String? _currentAudioPath;
  String? _currentQuestion;
  String? _repeatOriginalId;
  DateTime? _questionEndedAt;
  DateTime? _firstEventAt;
  double _peakLevel = 0;
  final List<double> _levelSamples = [];

  List<PatternResult> get clusters =>
      _investigation != null ? _service.buildClusters(_investigation!) : [];

  List<PatternResult> get patterns =>
      clusters.where((c) => c.count > 1).toList();

  List<ConnectionResult> get connections => _service.detectConnections(patterns);

  String get suggestedQuestion => _service.suggestFollowUpQuestion(patterns);

  String suggestedQuestionFor(String word) =>
      _service.suggestFollowUpQuestionFor(word);

  List<QuestionResponse> occurrencesOf(PatternResult pattern) =>
      _investigation == null
          ? []
          : _service.occurrencesOf(_investigation!, pattern);

  bool isEnvironmentalChange(QuestionResponse r) =>
      _investigation != null &&
      _service.isEnvironmentalChange(_investigation!, r);

  String get caseFileReport =>
      _investigation == null ? '' : _service.buildCaseFile(_investigation!);

  Future<void> initAudio() async {
    _blindIntroSeen = await _service.getFlag(blindFlag);
    _skepticIntroSeen = await _service.getFlag(skepticFlag);
    _audioInitialized = await _audioService.initialize();
    if (!_audioInitialized) {
      _error = 'Microphone or speech recognition is unavailable on this device.';
    }
    notifyListeners();
  }

  // --------------------------------------------------------------- lifecycle

  void startInvestigation() {
    if (_session == SessionState.active) return;
    _investigation = Investigation(
      startTime: DateTime.now(),
      skepticMode: _skepticMode,
    );
    _session = SessionState.active;
    _phase = InvestigationPhase.idle;
    _elapsed = Duration.zero;
    _error = null;
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final inv = _investigation;
      if (inv == null) return;
      _elapsed = DateTime.now().difference(inv.startTime);
      notifyListeners();
    });
    notifyListeners();
  }

  /// Stops every running process. Nothing is written to storage here — the
  /// investigator decides afterwards whether to keep the session.
  Future<void> stopInvestigation() async {
    if (_session != SessionState.active) return;
    _scanTimer?.cancel();
    _baselineTimer?.cancel();
    _sessionTimer?.cancel();
    _scanTimer = null;
    _baselineTimer = null;
    _sessionTimer = null;
    await _audioService.stopListening();
    await _audioService.stopRecording();

    final inv = _investigation;
    if (inv != null) {
      inv.endTime = DateTime.now();
      inv.skepticMode = _skepticMode;
      _elapsed = inv.duration;
    }
    _phase = InvestigationPhase.idle;
    _scanTimeRemaining = 0;
    _baselineRemaining = 0;
    _liveText = '';
    _currentLevel = 0;
    _session = SessionState.ended;
    notifyListeners();
  }

  /// Persists the finished session and returns it.
  Future<Investigation?> saveCurrentInvestigation() async {
    final inv = _investigation;
    if (inv == null) return null;
    inv.endTime ??= DateTime.now();
    await _service.saveInvestigation(inv);
    return inv;
  }

  /// Throws away the finished session without persisting anything.
  Future<void> discardCurrentInvestigation() async {
    final inv = _investigation;
    if (inv != null) {
      await _service.deleteInvestigation(inv.id);
    }
    _investigation = null;
    _session = SessionState.ready;
    _phase = InvestigationPhase.idle;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  void resetToReady() {
    _investigation = null;
    _session = SessionState.ready;
    _phase = InvestigationPhase.idle;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  // -------------------------------------------------------------------- modes

  void toggleBlindMode() {
    _blindMode = !_blindMode;
    notifyListeners();
  }

  void toggleSkepticMode() {
    _skepticMode = !_skepticMode;
    _investigation?.skepticMode = _skepticMode;
    notifyListeners();
  }

  Future<void> acknowledgeBlindIntro() async {
    _blindIntroSeen = true;
    await _service.setFlag(blindFlag, true);
    notifyListeners();
  }

  Future<void> acknowledgeSkepticIntro() async {
    _skepticIntroSeen = true;
    await _service.setFlag(skepticFlag, true);
    notifyListeners();
  }

  void renameInvestigation(String name) {
    final inv = _investigation;
    if (inv == null || name.trim().isEmpty) return;
    inv.name = name.trim();
    notifyListeners();
  }

  // ---------------------------------------------------------------- baseline

  Future<void> startBaselineScan() async {
    if (!isActive || _phase != InvestigationPhase.idle) return;
    _phase = InvestigationPhase.baseline;
    _baselineRemaining = baselineSeconds;
    _levelSamples.clear();
    _currentLevel = 0;
    notifyListeners();

    await _audioService.startLevelScan(
      duration: const Duration(seconds: baselineSeconds),
      onLevel: (level) {
        _currentLevel = level;
        _levelSamples.add(level);
        notifyListeners();
      },
    );

    _baselineTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _baselineRemaining--;
      notifyListeners();
      if (_baselineRemaining <= 0) {
        timer.cancel();
        _finishBaseline();
      }
    });
  }

  Future<void> _finishBaseline() async {
    await _audioService.stopListening();
    final inv = _investigation;
    if (inv != null) {
      inv.baselineLevel = _levelSamples.isEmpty
          ? null
          : _levelSamples.reduce((a, b) => a + b) / _levelSamples.length;
      inv.baselineCompletedAt = DateTime.now();
      inv.baselineDurationMs = baselineSeconds * 1000;
    }
    _phase = InvestigationPhase.idle;
    _currentLevel = 0;
    notifyListeners();
  }

  void cancelBaselineScan() {
    _baselineTimer?.cancel();
    _audioService.stopListening();
    _phase = InvestigationPhase.idle;
    _baselineRemaining = 0;
    notifyListeners();
  }

  // --------------------------------------------------------------- questions

  Future<void> askQuestion(String question, {String? repeatOriginalId}) async {
    if (!isActive || _investigation == null) return;
    _currentQuestion = question;
    _repeatOriginalId = repeatOriginalId;
    _phase = InvestigationPhase.scanning;
    _liveText = '';
    _peakLevel = 0;
    _firstEventAt = null;
    _scanTimeRemaining = scanWindowSeconds;
    _questionEndedAt = DateTime.now();
    notifyListeners();

    _currentAudioPath = await _audioService.startRecording();

    await _audioService.startListening(
      listenFor: const Duration(seconds: scanWindowSeconds),
      onLevel: (level) {
        _currentLevel = level;
        if (level > _peakLevel) _peakLevel = level;
        if (_firstEventAt == null && level > 1.0) {
          _firstEventAt = DateTime.now();
        }
        notifyListeners();
      },
      onResult: (text, confidence, isFinal) {
        if (text.isNotEmpty) _firstEventAt ??= DateTime.now();
        _liveText = text;
        notifyListeners();
        if (isFinal && text.isNotEmpty) {
          _scanTimer?.cancel();
          _completeWindow(text, confidence);
        }
      },
    );

    _scanTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _scanTimeRemaining--;
      notifyListeners();
      if (_scanTimeRemaining <= 0) {
        timer.cancel();
        _completeWindow(_liveText, null);
      }
    });
  }

  AudioClassification _classify(String text, double? confidence) {
    if (text.trim().isEmpty) {
      final baseline = _investigation?.baselineLevel;
      final aboveBaseline = baseline != null && (_peakLevel - baseline) >= 2.5;
      if (aboveBaseline || _peakLevel > 5.0) {
        return AudioClassification.uncertainAudio;
      }
      return AudioClassification.none;
    }
    if (confidence == null || confidence <= 0) {
      return AudioClassification.possibleSpeech;
    }
    if (confidence >= 0.6) return AudioClassification.possibleResponse;
    if (confidence >= 0.35) return AudioClassification.possibleSpeech;
    return AudioClassification.uncertainAudio;
  }

  Future<void> _completeWindow(String text, double? confidence) async {
    await _audioService.stopListening();
    final recorded = await _audioService.stopRecording();
    if (_session != SessionState.active) return;

    final now = DateTime.now();
    final trimmed = text.trim();
    final hasText = trimmed.isNotEmpty;
    final confidenceAvailable = confidence != null && confidence > 0;

    final eventAt = _firstEventAt;
    final latency = eventAt != null && _questionEndedAt != null
        ? eventAt.difference(_questionEndedAt!).inMilliseconds
        : null;
    final windowMs = _questionEndedAt != null
        ? now.difference(_questionEndedAt!).inMilliseconds
        : null;

    final response = QuestionResponse(
      question: _currentQuestion ?? '',
      timestamp: now,
      questionEndedAt: _questionEndedAt ?? now,
      detectedResponse: hasText ? trimmed : null,
      confidence: confidenceAvailable ? confidence : null,
      confidenceAvailable: confidenceAvailable,
      audioPath: recorded ?? _currentAudioPath,
      audioDurationMs: windowMs,
      audioLevel: _peakLevel > 0 ? _peakLevel : null,
      responseLatencyMs: latency,
      classification: _classify(trimmed, confidence),
      blindMode: _blindMode,
      skepticMode: _skepticMode,
      isRepeatTest: _repeatOriginalId != null,
      repeatTestOriginalId: _repeatOriginalId,
    );

    _investigation?.responses.add(response);
    _phase = hasText ? InvestigationPhase.detected : InvestigationPhase.idle;
    _liveText = '';
    _currentLevel = 0;
    _repeatOriginalId = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------ review

  QuestionResponse? responseById(String id) {
    final list = _investigation?.responses ?? const <QuestionResponse>[];
    for (final r in list) {
      if (r.id == id) return r;
    }
    return null;
  }

  void revealResponse(String responseId) {
    final r = responseById(responseId);
    if (r == null) return;
    r.revealed = true;
    notifyListeners();
  }

  void setStatus(String responseId, ResponseStatus status) {
    final r = responseById(responseId);
    if (r == null) return;
    r.status = r.status == status ? ResponseStatus.unreviewed : status;
    notifyListeners();
  }

  void toggleSaveResponse(String responseId) =>
      setStatus(responseId, ResponseStatus.saved);

  void setNote(String responseId, String? note) {
    final r = responseById(responseId);
    if (r == null) return;
    r.note = (note ?? '').trim().isEmpty ? null : note!.trim();
    notifyListeners();
  }

  void dismissDetection() {
    _phase = InvestigationPhase.idle;
    notifyListeners();
  }

  RepeatComparison compareRepeat(String originalId, String repeatId) {
    final original = responseById(originalId);
    final repeat = responseById(repeatId);
    if (original == null || repeat == null) {
      return RepeatComparison.inconclusive;
    }
    return _service.compareRepeatTest(original, repeat);
  }

  Future<void> playResponseAudio(String responseId) async {
    final r = responseById(responseId);
    if (r?.audioPath != null) {
      await _audioService.playAudio(r!.audioPath!);
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _baselineTimer?.cancel();
    _sessionTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
