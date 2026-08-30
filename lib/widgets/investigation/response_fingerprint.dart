import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    final rows = <_FactRow>[
      _FactRow('Timestamp',
          DateFormat('HH:mm:ss.SSS').format(response.timestamp)),
      _FactRow(
        'Response timing',
        response.latencyLabel ?? 'Not measured',
      ),
      _FactRow(
        'Audio duration',
        response.audioDurationMs != null
            ? '${(response.audioDurationMs! / 1000).toStringAsFixed(1)} s window'
            : 'Unavailable',
      ),
      _FactRow(
        'Confidence',
        response.confidenceAvailable && response.confidence != null
            ? '${(response.confidence! * 100).round()}%  •  CONFIDENCE AVAILABLE'
            : 'CONFIDENCE UNAVAILABLE',
      ),
      _FactRow(
        'Audio level',
        response.audioLevel != null
            ? response.audioLevel!.toStringAsFixed(2)
            : 'Unavailable',
      ),
      _FactRow(
        'Audio clip',
        response.audioPath != null ? 'Recorded' : 'Not available',
      ),
      _FactRow('Blind mode', response.blindMode ? 'Active' : 'Off'),
      _FactRow('Classification', response.classification.label),
      if (recurring)
        const _FactRow('Recurrence', 'Appeared earlier in this investigation'),
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
          Text('RECORDED DATA',
              style: text.labelSmall?.copyWith(color: appColors.subtleText)),
          const SizedBox(height: AppTheme.spacingXs),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      row.label,
                      style: text.labelSmall
                          ?.copyWith(color: appColors.subtleText),
                    ),
                  ),
                  Expanded(
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
                  Text('ENVIRONMENTAL CHANGE',
                      style: text.labelSmall
                          ?.copyWith(color: appColors.warning)),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'Audio characteristics differ from the recorded baseline.',
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
