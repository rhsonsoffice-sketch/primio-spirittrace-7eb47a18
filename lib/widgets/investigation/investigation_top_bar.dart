import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class InvestigationTopBar extends StatelessWidget {
  final bool blindMode;
  final bool skepticMode;
  final bool micUnavailable;
  final bool sessionActive;
  final VoidCallback onToggleBlind;
  final VoidCallback onToggleSkeptic;
  final VoidCallback onBlindInfo;
  final VoidCallback onSkepticInfo;
  final VoidCallback? onStop;
  final VoidCallback? onExit;

  const InvestigationTopBar({
    super.key,
    required this.blindMode,
    required this.skepticMode,
    required this.micUnavailable,
    required this.sessionActive,
    required this.onToggleBlind,
    required this.onToggleSkeptic,
    required this.onBlindInfo,
    required this.onSkepticInfo,
    this.onStop,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Toggle(
                icon: blindMode ? Icons.visibility_off : Icons.visibility,
                label: 'BLIND',
                active: blindMode,
                activeColor: appColors.warning,
                onTap: onToggleBlind,
                onInfo: onBlindInfo,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _Toggle(
                icon: Icons.science_outlined,
                label: 'SKEPTIC',
                active: skepticMode,
                activeColor: colors.secondary,
                onTap: onToggleSkeptic,
                onInfo: onSkepticInfo,
              ),
              const Spacer(),
              if (micUnavailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: appColors.danger
                        .withValues(alpha: AppTheme.opacitySubtle),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text('MIC UNAVAILABLE',
                      style:
                          text.labelSmall?.copyWith(color: appColors.danger)),
                ),
              if (sessionActive && onStop != null)
                TextButton.icon(
                  onPressed: onStop,
                  icon: Icon(Icons.stop_circle,
                      color: appColors.danger, size: AppTheme.iconMd),
                  label: Text('STOP',
                      style:
                          text.labelMedium?.copyWith(color: appColors.danger)),
                )
              else if (onExit != null)
                IconButton(
                  onPressed: onExit,
                  icon: Icon(Icons.close, color: appColors.subtleText),
                ),
            ],
          ),
          if (blindMode || skepticMode)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingXs),
              child: Wrap(
                spacing: AppTheme.spacingSm,
                children: [
                  if (skepticMode)
                    _ActiveBadge(
                      label: 'SKEPTIC MODE ACTIVE',
                      color: colors.secondary,
                    ),
                  if (blindMode)
                    _ActiveBadge(
                      label: 'BLIND MODE ACTIVE',
                      color: appColors.warning,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ActiveBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: AppTheme.spacingXs, color: color),
        const SizedBox(width: AppTheme.spacingXs),
        Text(label, style: text.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  const _Toggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final color = active ? activeColor : appColors.subtleText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: active
            ? activeColor.withValues(alpha: AppTheme.opacitySubtle)
            : colors.surfaceContainerHighest
                .withValues(alpha: AppTheme.opacitySubtle),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: active
              ? activeColor.withValues(alpha: AppTheme.opacityHint)
              : colors.outline.withValues(alpha: AppTheme.opacitySubtle),
          width: active ? AppTheme.borderSelected : AppTheme.borderDefault,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppTheme.iconSm, color: color),
                const SizedBox(width: AppTheme.spacingXs),
                Text('$label ${active ? 'ON' : 'OFF'}',
                    style: text.labelSmall?.copyWith(color: color)),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingXs),
          GestureDetector(
            onTap: onInfo,
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.info_outline,
                size: AppTheme.iconSm, color: appColors.subtleText),
          ),
        ],
      ),
    );
  }
}
