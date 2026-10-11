import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import 'glowing_card.dart';

/// Placeholder shown where a Pro-only feature would appear.
class ProLockCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const ProLockCard({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return GlowingCard(
      onTap: onTap,
      glowColor: appColors.glow,
      glowIntensity: AppTheme.opacitySubtle,
      child: Row(
        children: [
          Icon(Icons.lock_outline,
              size: AppTheme.iconMd, color: appColors.glow),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium?.copyWith(color: appColors.glow)),
                const SizedBox(height: AppTheme.spacingXs),
                Text(context.l10n.t('proLockedHint'),
                    style:
                        text.labelSmall?.copyWith(color: appColors.subtleText)),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              size: AppTheme.iconSm, color: appColors.subtleText),
        ],
      ),
    );
  }
}
