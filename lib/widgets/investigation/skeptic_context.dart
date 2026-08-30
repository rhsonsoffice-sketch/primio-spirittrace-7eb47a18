import 'package:flutter/material.dart';

import '../../models/investigation.dart';
import '../../theme/theme.dart';

/// Alternative explanations surfaced while Skeptic Mode is active.
/// Every line is derived from what was actually recorded — none of it
/// determines whether an event is paranormal.
class SkepticContext extends StatelessWidget {
  final QuestionResponse response;
  final bool environmentalChange;
  final bool recurring;

  const SkepticContext({
    super.key,
    required this.response,
    this.environmentalChange = false,
    this.recurring = false,
  });

  List<String> _considerations() {
    final points = <String>[];

    if (!response.confidenceAvailable) {
      points.add(
        'Insufficient information — no recogniser confidence was reported for '
        'this event.',
      );
    } else if ((response.confidence ?? 0) < 0.6) {
      points.add(
        'Low recogniser confidence — the wording may not match what was said.',
      );
    }

    if (response.isUncertain || !response.hasResponse) {
      points.add(
        'Unusual / anomalous result — audio was captured but no reliable wording '
        'could be established.',
      );
    }

    if (environmentalChange) {
      points.add(
        'Environmental noise / interference — the audio level differs from the '
        'recorded baseline.',
      );
    }

    if (recurring) {
      points.add(
        'Possible coincidence — common words recur naturally in speech and in '
        'background audio.',
      );
    }

    final latency = response.responseLatencyMs;
    if (latency != null && latency < 700) {
      points.add(
        'Possible random response — the event began very soon after the question '
        'ended and may overlap with it.',
      );
    }

    if (points.isEmpty) {
      points.add(
        'Consider repeating this question before attaching any significance to '
        'the result.',
      );
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final points = _considerations();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: AppTheme.opacityFaint),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: colors.secondary.withValues(alpha: AppTheme.opacitySubtle),
          width: AppTheme.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined,
                  size: AppTheme.iconSm, color: colors.secondary),
              const SizedBox(width: AppTheme.spacingXs),
              Text('CONSIDER OTHER EXPLANATIONS',
                  style: text.labelSmall?.copyWith(color: colors.secondary)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingXs),
              child: Text(
                '• $p',
                style: text.bodySmall?.copyWith(color: appColors.subtleText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
