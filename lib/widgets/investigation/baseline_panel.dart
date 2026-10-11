import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../common/app_button.dart';
import '../common/glowing_card.dart';

class BaselinePanel extends StatelessWidget {
  final bool running;
  final int secondsRemaining;
  final double progress;
  final VoidCallback onStart;
  final VoidCallback onSkip;
  final VoidCallback onCancel;

  const BaselinePanel({
    super.key,
    required this.running,
    required this.secondsRemaining,
    required this.progress,
    required this.onStart,
    required this.onSkip,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final l10n = context.l10n;

    return GlowingCard(
      glowColor: colors.secondary,
      glowIntensity: running ? 0.25 : 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.graphic_eq,
                  size: AppTheme.iconMd, color: colors.secondary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(l10n.t('baselineScanTitle'),
                    style: text.labelLarge?.copyWith(color: colors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            running
                ? l10n.tf('baselineRunning', '$secondsRemaining')
                : l10n.t('baselineIdle'),
            style: text.bodySmall?.copyWith(color: appColors.subtleText),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (running) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: AppTheme.spacingXs,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colors.secondary),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            AppButton(
              label: l10n.t('cancelBaseline'),
              variant: AppButtonVariant.outline,
              onPressed: onCancel,
            ),
          ] else ...[
            AppButton(
              label: l10n.t('startBaselineScan'),
              icon: Icons.graphic_eq,
              onPressed: onStart,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextButton(
              onPressed: onSkip,
              child: Text(l10n.t('skipBaseline'),
                  style:
                      text.bodySmall?.copyWith(color: appColors.subtleText)),
            ),
          ],
        ],
      ),
    );
  }
}
