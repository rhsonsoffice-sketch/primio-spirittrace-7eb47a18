import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class InvestigationStatusBar extends StatelessWidget {
  final String status;
  final bool active;
  final String liveText;
  final double level;
  final double? baselineLevel;
  final bool listening;
  final String? timerLabel;

  const InvestigationStatusBar({
    super.key,
    required this.status,
    required this.active,
    required this.liveText,
    required this.level,
    required this.listening,
    this.baselineLevel,
    this.timerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final statusColor = active ? appColors.glowSecondary : appColors.subtleText;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppTheme.spacingSm,
                height: AppTheme.spacingSm,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: statusColor
                                .withValues(alpha: AppTheme.opacityHint),
                            blurRadius: AppTheme.spacingSm,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(status,
                  style: text.labelLarge?.copyWith(color: statusColor)),
              if (timerLabel != null) ...[
                const SizedBox(width: AppTheme.spacingSm),
                Text(timerLabel!,
                    style: text.labelLarge?.copyWith(color: colors.onSurface)),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                listening ? Icons.mic : Icons.mic_off,
                size: AppTheme.iconSm,
                color: listening ? appColors.success : appColors.danger,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                listening ? 'MICROPHONE ACTIVE' : 'MICROPHONE UNAVAILABLE',
                style: text.labelSmall?.copyWith(color: appColors.subtleText),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'LVL ${level.toStringAsFixed(1)}'
                '${baselineLevel != null ? ' / BASE ${baselineLevel!.toStringAsFixed(1)}' : ''}',
                style: text.labelSmall?.copyWith(color: appColors.subtleText),
              ),
            ],
          ),
          if (active && liveText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingXs),
              child: Text(
                liveText,
                style: text.bodySmall?.copyWith(color: colors.secondary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
