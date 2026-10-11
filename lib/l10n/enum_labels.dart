import '../models/investigation.dart';
import 'app_localizations.dart';

/// Localized display labels for the analysis enums. The enum extensions in the
/// models stay untouched — they remain the canonical English wording used for
/// exported case files.
extension EnumLabels on AppLocalizations {
  String classificationLabel(AudioClassification c) {
    switch (c) {
      case AudioClassification.none:
        return t('cls_none');
      case AudioClassification.possibleResponse:
        return t('cls_possibleResponse');
      case AudioClassification.possibleSpeech:
        return t('cls_possibleSpeech');
      case AudioClassification.humanVoice:
        return t('cls_humanVoice');
      case AudioClassification.uncertainAudio:
        return t('cls_uncertainAudio');
      case AudioClassification.backgroundNoise:
        return t('cls_backgroundNoise');
      case AudioClassification.music:
        return t('cls_music');
      case AudioClassification.impactClick:
        return t('cls_impactClick');
    }
  }

  String statusLabel(ResponseStatus s) {
    switch (s) {
      case ResponseStatus.unreviewed:
        return t('st_unreviewed');
      case ResponseStatus.saved:
        return t('st_saved');
      case ResponseStatus.unexplained:
        return t('st_unexplained');
      case ResponseStatus.dismissed:
        return t('st_dismissed');
      case ResponseStatus.backgroundNoise:
        return t('st_backgroundNoise');
      case ResponseStatus.explained:
        return t('st_explained');
    }
  }

  String comparisonLabel(RepeatComparison r) {
    switch (r) {
      case RepeatComparison.repeated:
        return t('rc_repeated');
      case RepeatComparison.similar:
        return t('rc_similar');
      case RepeatComparison.different:
        return t('rc_different');
      case RepeatComparison.inconclusive:
        return t('rc_inconclusive');
    }
  }

  String fieldTypeLabel(FieldEventType type) {
    switch (type) {
      case FieldEventType.disturbance:
        return t('fet_disturbance');
      case FieldEventType.unclassified:
        return t('fet_unclassified');
      case FieldEventType.formation:
        return t('fet_formation');
      case FieldEventType.pulse:
        return t('fet_pulse');
    }
  }

  String strengthLabel(FormationStrength s) {
    switch (s) {
      case FormationStrength.low:
        return t('fs_low');
      case FormationStrength.medium:
        return t('fs_medium');
      case FormationStrength.high:
        return t('fs_high');
    }
  }

  /// Response latency rendered in the active language.
  String latencyLabel(int milliseconds) =>
      f('latencyAfterQuestion', (milliseconds / 1000).toStringAsFixed(1));
}
