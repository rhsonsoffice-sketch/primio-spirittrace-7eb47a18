import 'package:uuid/uuid.dart';

/// Kinds of event the Trace Field is able to record. None of these imply
/// paranormal activity — they describe changes measured against a baseline.
enum FieldEventType { disturbance, unclassified, formation, pulse }

extension FieldEventTypeLabel on FieldEventType {
  String get label {
    switch (this) {
      case FieldEventType.disturbance:
        return 'FIELD DISTURBANCE';
      case FieldEventType.unclassified:
        return 'UNCLASSIFIED EVENT';
      case FieldEventType.formation:
        return 'POSSIBLE FORMATION';
      case FieldEventType.pulse:
        return 'TRACE PULSE';
    }
  }
}

enum FieldEventStatus { unreviewed, marked, dismissed }

extension FieldEventStatusLabel on FieldEventStatus {
  String get label {
    switch (this) {
      case FieldEventStatus.unreviewed:
        return 'UNREVIEWED';
      case FieldEventStatus.marked:
        return 'MARKED';
      case FieldEventStatus.dismissed:
        return 'DISMISSED';
    }
  }
}

enum FormationStrength { low, medium, high }

extension FormationStrengthLabel on FormationStrength {
  String get label {
    switch (this) {
      case FormationStrength.low:
        return 'LOW';
      case FormationStrength.medium:
        return 'MEDIUM';
      case FormationStrength.high:
        return 'HIGH';
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

/// A single recorded change within the Trace Field. Every numeric value here
/// comes from measured device input compared with the calibrated baseline.
class FieldEvent {
  final String id;
  final FieldEventType type;
  final DateTime timestamp;
  int? durationMs;

  /// Deviation from baseline for each available input (standard deviations).
  /// Null when that input is not available on the device.
  final double? audioDeviation;
  final double? motionDeviation;

  /// Coherence of the visual pattern in the Field (0-1). Formations only.
  final double? coherence;
  final String? resemblance;

  /// Plain-language description of the dominant measured input, or null when
  /// no single input clearly dominated.
  final String? likelyCause;

  final bool blindMode;
  final bool skepticMode;

  FieldEventStatus status;
  String? note;

  /// Pulse windows record what happened inside them.
  final int? pulseDisturbances;
  final int? pulseUnclassified;
  final int? pulseFormations;

  FieldEvent({
    String? id,
    required this.type,
    required this.timestamp,
    this.durationMs,
    this.audioDeviation,
    this.motionDeviation,
    this.coherence,
    this.resemblance,
    this.likelyCause,
    this.blindMode = false,
    this.skepticMode = false,
    this.status = FieldEventStatus.unreviewed,
    this.note,
    this.pulseDisturbances,
    this.pulseUnclassified,
    this.pulseFormations,
  }) : id = id ?? const Uuid().v4();

  bool get isFormation => type == FieldEventType.formation;
  bool get isMarked => status == FieldEventStatus.marked;
  bool get isDismissed => status == FieldEventStatus.dismissed;

  FormationStrength? get strength {
    final c = coherence;
    if (c == null) return null;
    if (c >= 0.92) return FormationStrength.high;
    if (c >= 0.86) return FormationStrength.medium;
    return FormationStrength.low;
  }

  String get timeLabel {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(timestamp.hour)}:${two(timestamp.minute)}:${two(timestamp.second)}';
  }

  String? get durationLabel {
    final ms = durationMs;
    if (ms == null || ms <= 0) return null;
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': _enumName(type),
        'timestamp': timestamp.toIso8601String(),
        'durationMs': durationMs,
        'audioDeviation': audioDeviation,
        'motionDeviation': motionDeviation,
        'coherence': coherence,
        'resemblance': resemblance,
        'likelyCause': likelyCause,
        'blindMode': blindMode,
        'skepticMode': skepticMode,
        'status': _enumName(status),
        'note': note,
        'pulseDisturbances': pulseDisturbances,
        'pulseUnclassified': pulseUnclassified,
        'pulseFormations': pulseFormations,
      };

  factory FieldEvent.fromJson(Map<String, dynamic> json) => FieldEvent(
        id: json['id'] as String?,
        type: _enumFrom(
          FieldEventType.values,
          json['type'],
          FieldEventType.disturbance,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        durationMs: (json['durationMs'] as num?)?.toInt(),
        audioDeviation: (json['audioDeviation'] as num?)?.toDouble(),
        motionDeviation: (json['motionDeviation'] as num?)?.toDouble(),
        coherence: (json['coherence'] as num?)?.toDouble(),
        resemblance: json['resemblance'] as String?,
        likelyCause: json['likelyCause'] as String?,
        blindMode: json['blindMode'] as bool? ?? false,
        skepticMode: json['skepticMode'] as bool? ?? false,
        status: _enumFrom(
          FieldEventStatus.values,
          json['status'],
          FieldEventStatus.unreviewed,
        ),
        note: json['note'] as String?,
        pulseDisturbances: (json['pulseDisturbances'] as num?)?.toInt(),
        pulseUnclassified: (json['pulseUnclassified'] as num?)?.toInt(),
        pulseFormations: (json['pulseFormations'] as num?)?.toInt(),
      );
}
