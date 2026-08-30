import 'package:uuid/uuid.dart';

import 'field_event.dart';

export 'field_event.dart';

/// How the captured audio was interpreted. Never used to invent a word —
/// only to describe what the audio pipeline was able to establish.
enum AudioClassification {
  none,
  possibleResponse,
  possibleSpeech,
  humanVoice,
  uncertainAudio,
  backgroundNoise,
  music,
  impactClick,
}

extension AudioClassificationLabel on AudioClassification {
  String get label {
    switch (this) {
      case AudioClassification.none:
        return 'NO CLEAR RESPONSE DETECTED';
      case AudioClassification.possibleResponse:
        return 'POSSIBLE RESPONSE';
      case AudioClassification.possibleSpeech:
        return 'POSSIBLE SPEECH';
      case AudioClassification.humanVoice:
        return 'HUMAN VOICE';
      case AudioClassification.uncertainAudio:
        return 'UNCERTAIN AUDIO';
      case AudioClassification.backgroundNoise:
        return 'BACKGROUND NOISE';
      case AudioClassification.music:
        return 'MUSIC';
      case AudioClassification.impactClick:
        return 'IMPACT / CLICK';
    }
  }
}

/// Investigator review state for a captured event.
enum ResponseStatus {
  unreviewed,
  saved,
  unexplained,
  dismissed,
  backgroundNoise,
  explained,
}

extension ResponseStatusLabel on ResponseStatus {
  String get label {
    switch (this) {
      case ResponseStatus.unreviewed:
        return 'UNREVIEWED';
      case ResponseStatus.saved:
        return 'SAVED';
      case ResponseStatus.unexplained:
        return 'UNEXPLAINED';
      case ResponseStatus.dismissed:
        return 'DISMISSED';
      case ResponseStatus.backgroundNoise:
        return 'BACKGROUND NOISE';
      case ResponseStatus.explained:
        return 'EXPLAINED';
    }
  }
}

enum RepeatComparison { repeated, similar, different, inconclusive }

extension RepeatComparisonLabel on RepeatComparison {
  String get label {
    switch (this) {
      case RepeatComparison.repeated:
        return 'RESPONSE REPEATED';
      case RepeatComparison.similar:
        return 'SIMILAR RESPONSE';
      case RepeatComparison.different:
        return 'DIFFERENT RESPONSE';
      case RepeatComparison.inconclusive:
        return 'COMPARISON UNAVAILABLE';
    }
  }
}

T _enumFrom<T>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  for (final v in values) {
    if (v.toString().split('.').last == raw) return v;
  }
  return fallback;
}

String _enumName(Object e) => e.toString().split('.').last;

/// A single question and everything the app was able to record about the
/// audio captured in the response window that followed it.
class QuestionResponse {
  final String id;
  final String question;

  /// Moment the response window opened (question finished being asked).
  final DateTime questionEndedAt;

  /// Moment the event was captured / the window closed.
  final DateTime timestamp;

  String? detectedResponse;

  /// Recogniser confidence. Only meaningful when [confidenceAvailable].
  double? confidence;
  bool confidenceAvailable;

  String? audioPath;
  int? audioDurationMs;

  /// Peak audio level observed during the window (recogniser scale).
  double? audioLevel;

  /// Milliseconds between the end of the question and the detected event.
  int? responseLatencyMs;

  AudioClassification classification;

  final bool blindMode;
  final bool skepticMode;
  bool revealed;

  ResponseStatus status;
  String? note;

  final bool isRepeatTest;
  final String? repeatTestOriginalId;

  QuestionResponse({
    String? id,
    required this.question,
    required this.timestamp,
    DateTime? questionEndedAt,
    this.detectedResponse,
    this.confidence,
    this.confidenceAvailable = false,
    this.audioPath,
    this.audioDurationMs,
    this.audioLevel,
    this.responseLatencyMs,
    this.classification = AudioClassification.none,
    this.blindMode = false,
    this.skepticMode = false,
    this.revealed = false,
    this.status = ResponseStatus.unreviewed,
    this.note,
    this.isRepeatTest = false,
    this.repeatTestOriginalId,
  })  : id = id ?? const Uuid().v4(),
        questionEndedAt = questionEndedAt ?? timestamp;

  bool get hasResponse =>
      detectedResponse != null && detectedResponse!.trim().isNotEmpty;

  bool get saved => status == ResponseStatus.saved;

  bool get isDismissed =>
      status == ResponseStatus.dismissed ||
      status == ResponseStatus.explained ||
      status == ResponseStatus.backgroundNoise;

  bool get isUncertain => classification == AudioClassification.uncertainAudio;

  /// Response latency formatted for display, if measured.
  String? get latencyLabel {
    final ms = responseLatencyMs;
    if (ms == null || ms <= 0) return null;
    return '${(ms / 1000).toStringAsFixed(1)} seconds after question';
  }

  QuestionResponse copyWith({
    String? detectedResponse,
    double? confidence,
    bool? confidenceAvailable,
    String? audioPath,
    int? audioDurationMs,
    double? audioLevel,
    int? responseLatencyMs,
    AudioClassification? classification,
    bool? revealed,
    ResponseStatus? status,
    String? note,
  }) =>
      QuestionResponse(
        id: id,
        question: question,
        timestamp: timestamp,
        questionEndedAt: questionEndedAt,
        detectedResponse: detectedResponse ?? this.detectedResponse,
        confidence: confidence ?? this.confidence,
        confidenceAvailable: confidenceAvailable ?? this.confidenceAvailable,
        audioPath: audioPath ?? this.audioPath,
        audioDurationMs: audioDurationMs ?? this.audioDurationMs,
        audioLevel: audioLevel ?? this.audioLevel,
        responseLatencyMs: responseLatencyMs ?? this.responseLatencyMs,
        classification: classification ?? this.classification,
        blindMode: blindMode,
        skepticMode: skepticMode,
        revealed: revealed ?? this.revealed,
        status: status ?? this.status,
        note: note ?? this.note,
        isRepeatTest: isRepeatTest,
        repeatTestOriginalId: repeatTestOriginalId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'timestamp': timestamp.toIso8601String(),
        'questionEndedAt': questionEndedAt.toIso8601String(),
        'detectedResponse': detectedResponse,
        'confidence': confidence,
        'confidenceAvailable': confidenceAvailable,
        'audioPath': audioPath,
        'audioDurationMs': audioDurationMs,
        'audioLevel': audioLevel,
        'responseLatencyMs': responseLatencyMs,
        'classification': _enumName(classification),
        'blindMode': blindMode,
        'skepticMode': skepticMode,
        'revealed': revealed,
        'status': _enumName(status),
        'note': note,
        'isRepeatTest': isRepeatTest,
        'repeatTestOriginalId': repeatTestOriginalId,
      };

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    final ts = DateTime.parse(json['timestamp'] as String);
    return QuestionResponse(
      id: json['id'] as String,
      question: json['question'] as String,
      timestamp: ts,
      questionEndedAt: json['questionEndedAt'] != null
          ? DateTime.parse(json['questionEndedAt'] as String)
          : ts,
      detectedResponse: json['detectedResponse'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      confidenceAvailable: json['confidenceAvailable'] as bool? ?? false,
      audioPath: json['audioPath'] as String?,
      audioDurationMs: (json['audioDurationMs'] as num?)?.toInt(),
      audioLevel: (json['audioLevel'] as num?)?.toDouble(),
      responseLatencyMs: (json['responseLatencyMs'] as num?)?.toInt(),
      classification: _enumFrom(
        AudioClassification.values,
        json['classification'],
        json['detectedResponse'] != null
            ? AudioClassification.possibleResponse
            : AudioClassification.none,
      ),
      blindMode: json['blindMode'] as bool? ?? false,
      skepticMode: json['skepticMode'] as bool? ?? false,
      revealed: json['revealed'] as bool? ?? false,
      status: _enumFrom(
        ResponseStatus.values,
        json['status'],
        (json['saved'] as bool? ?? false)
            ? ResponseStatus.saved
            : ResponseStatus.unreviewed,
      ),
      note: json['note'] as String?,
      isRepeatTest: json['isRepeatTest'] as bool? ?? false,
      repeatTestOriginalId: json['repeatTestOriginalId'] as String?,
    );
  }
}

class Investigation {
  final String id;
  String name;
  final DateTime startTime;
  DateTime? endTime;
  final List<QuestionResponse> responses;

  /// Events recorded by the Trace Field during this investigation.
  final List<FieldEvent> fieldEvents;

  /// Average environmental audio level captured before questioning began.
  double? baselineLevel;
  DateTime? baselineCompletedAt;
  int? baselineDurationMs;

  bool skepticMode;

  Investigation({
    String? id,
    this.name = 'Investigation',
    required this.startTime,
    this.endTime,
    List<QuestionResponse>? responses,
    List<FieldEvent>? fieldEvents,
    this.baselineLevel,
    this.baselineCompletedAt,
    this.baselineDurationMs,
    this.skepticMode = false,
  })  : id = id ?? const Uuid().v4(),
        responses = responses ?? [],
        fieldEvents = fieldEvents ?? [];

  List<FieldEvent> get activeFieldEvents =>
      fieldEvents.where((e) => !e.isDismissed).toList();

  int get fieldDisturbanceCount => fieldEvents
      .where((e) => e.type == FieldEventType.disturbance && !e.isDismissed)
      .length;

  int get fieldUnclassifiedCount => fieldEvents
      .where((e) => e.type == FieldEventType.unclassified && !e.isDismissed)
      .length;

  int get fieldFormationCount =>
      fieldEvents.where((e) => e.isFormation && !e.isDismissed).length;

  int get fieldMarkedCount => fieldEvents.where((e) => e.isMarked).length;

  int get fieldPulseCount =>
      fieldEvents.where((e) => e.type == FieldEventType.pulse).length;

  bool get hasFieldData => fieldEvents.isNotEmpty;

  bool get isComplete => endTime != null;
  bool get hasBaseline => baselineCompletedAt != null;
  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  int get questionCount => responses.length;
  int get responseCount => responses.where((r) => r.hasResponse).length;
  int get savedCount => responses.where((r) => r.saved).length;
  int get dismissedCount => responses.where((r) => r.isDismissed).length;
  int get noteCount => responses.where((r) => (r.note ?? '').isNotEmpty).length;
  int get repeatTestCount => responses.where((r) => r.isRepeatTest).length;

  int get repeatResponseCount =>
      responses.where((r) => r.isRepeatTest && r.hasResponse).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'baselineLevel': baselineLevel,
        'baselineCompletedAt': baselineCompletedAt?.toIso8601String(),
        'baselineDurationMs': baselineDurationMs,
        'skepticMode': skepticMode,
        'responses': responses.map((r) => r.toJson()).toList(),
        'fieldEvents': fieldEvents.map((e) => e.toJson()).toList(),
      };

  factory Investigation.fromJson(Map<String, dynamic> json) => Investigation(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Investigation',
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        baselineLevel: (json['baselineLevel'] as num?)?.toDouble(),
        baselineCompletedAt: json['baselineCompletedAt'] != null
            ? DateTime.parse(json['baselineCompletedAt'] as String)
            : null,
        baselineDurationMs: (json['baselineDurationMs'] as num?)?.toInt(),
        skepticMode: json['skepticMode'] as bool? ?? false,
        responses: (json['responses'] as List<dynamic>?)
                ?.map((r) => QuestionResponse.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        fieldEvents: (json['fieldEvents'] as List<dynamic>?)
                ?.map((e) => FieldEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// A group of similar detected words treated as one possible response.
/// This is a similarity analysis only — it does not imply a single source.
class PatternResult {
  final String word;
  final int count;
  final List<String> responseIds;
  final List<String> variants;

  const PatternResult({
    required this.word,
    required this.count,
    required this.responseIds,
    this.variants = const [],
  });

  bool get hasVariants => variants.length > 1;
}

class ConnectionResult {
  final String word1;
  final String word2;
  final String reason;
  final List<String> responseIds;

  const ConnectionResult({
    required this.word1,
    required this.word2,
    this.reason = 'Both appear more than once in this investigation',
    this.responseIds = const [],
  });
}
