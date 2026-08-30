import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class GlowingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? glowColor;
  final VoidCallback? onTap;
  final double glowIntensity;

  const GlowingCard({
    super.key,
    required this.child,
    this.padding,
    this.glowColor,
    this.onTap,
    this.glowIntensity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final effectiveGlow = glowColor ?? colors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: appColors.cardHighlight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: effectiveGlow.withOpacity(glowIntensity),
            width: AppTheme.borderDefault,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveGlow.withOpacity(glowIntensity * 0.5),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
