import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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

  List<String> _considerationKeys() {
    final keys = <String>[];

    if (!response.confidenceAvailable) {
      keys.add('sk1');
    } else if ((response.confidence ?? 0) < 0.6) {
      keys.add('sk2');
    }
    if (response.isUncertain || !response.hasResponse) keys.add('sk3');
    if (environmentalChange) keys.add('sk4');
    if (recurring) keys.add('sk5');

    final latency = response.responseLatencyMs;
    if (latency != null && latency < 700) keys.add('sk6');

    if (keys.isEmpty) keys.add('sk7');
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final l10n = context.l10n;

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
              Expanded(
                child: Text(l10n.t('considerOther'),
                    style: text.labelSmall?.copyWith(color: colors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          ..._considerationKeys().map(
            (k) => Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingXs),
              child: Text(
                '• ${l10n.t(k)}',
                style: text.bodySmall?.copyWith(color: appColors.subtleText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
