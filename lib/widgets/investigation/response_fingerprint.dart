import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/investigation.dart';
import '../../theme/theme.dart';

/// Displays the raw, recorded facts about a captured event. Everything here
/// comes from the audio pipeline — nothing is inferred or invented.
class ResponseFingerprint extends StatelessWidget {
  final QuestionResponse response;
  final bool environmentalChange;
  final bool recurring;

  const ResponseFingerprint({
    super.key,
    required this.response,
    this.environmentalChange = false,
    this.recurring = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final l10n = context.l10n;

    final latencyMs = response.responseLatencyMs;
    final timing = latencyMs != null && latencyMs > 0
        ? l10n.tf('latencyAfterQuestion',
            (latencyMs / 1000).toStringAsFixed(1))
        : l10n.t('notMeasured');

    final rows = <_FactRow>[
      _FactRow(l10n.t('fpTimestamp'),
          DateFormat('HH:mm:ss.SSS').format(response.timestamp)),
      _FactRow(l10n.t('fpTiming'), timing),
      _FactRow(
        l10n.t('fpDuration'),
        response.audioDurationMs != null
            ? '${(response.audioDurationMs! / 1000).toStringAsFixed(1)}'
                '${l10n.t('windowSuffix')}'
            : l10n.t('unavailable'),
      ),
      _FactRow(
        l10n.t('fpConfidence'),
        response.confidenceAvailable && response.confidence != null
            ? '${(response.confidence! * 100).round()}%  •  '
                '${l10n.t('confidenceAvailable')}'
            : l10n.t('confidenceUnavailable'),
      ),
      _FactRow(
        l10n.t('fpLevel'),
        response.audioLevel != null
            ? response.audioLevel!.toStringAsFixed(2)
            : l10n.t('unavailable'),
      ),
      _FactRow(
        l10n.t('fpClip'),
        response.audioPath != null
            ? l10n.t('recordedWord')
            : l10n.t('notAvailable'),
      ),
      _FactRow(l10n.t('fpBlind'),
          response.blindMode ? l10n.t('activeWord') : l10n.t('offLabel')),
      _FactRow(l10n.t('fpClassification'),
          l10n.label('cls', response.classification)),
      if (recurring)
        _FactRow(l10n.t('fpRecurrence'), l10n.t('recurrenceValue')),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest
            .withValues(alpha: AppTheme.opacitySubtle),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: colors.outline.withValues(alpha: AppTheme.opacitySubtle),
          width: AppTheme.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.t('recordedData'),
              style: text.labelSmall?.copyWith(color: appColors.subtleText)),
          const SizedBox(height: AppTheme.spacingXs),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      row.label,
                      style: text.labelSmall
                          ?.copyWith(color: appColors.subtleText),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    flex: 6,
                    child: Text(
                      row.value,
                      style: text.bodySmall?.copyWith(color: colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (environmentalChange) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: appColors.warning
                    .withValues(alpha: AppTheme.opacitySubtle),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('environmentalChange'),
                      style: text.labelSmall
                          ?.copyWith(color: appColors.warning)),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    l10n.t('environmentalChangeBody'),
                    style: text.bodySmall
                        ?.copyWith(color: appColors.subtleText),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FactRow {
  final String label;
  final String value;
  const _FactRow(this.label, this.value);
}
