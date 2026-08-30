import 'package:flutter/material.dart';

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
              Text('BASELINE SCAN',
                  style: text.labelLarge?.copyWith(color: colors.secondary)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            running
                ? 'Recording the room. Stay quiet for $secondsRemaining more seconds.'
                : 'Record about 30 seconds of the surrounding audio before questioning. '
                    'This is used to compare the environment later.',
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
              label: 'CANCEL BASELINE',
              variant: AppButtonVariant.outline,
              onPressed: onCancel,
            ),
          ] else ...[
            AppButton(
              label: 'START BASELINE SCAN',
              icon: Icons.graphic_eq,
              onPressed: onStart,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextButton(
              onPressed: onSkip,
              child: Text('Skip baseline',
                  style:
                      text.bodySmall?.copyWith(color: appColors.subtleText)),
            ),
          ],
        ],
      ),
    );
  }
}
