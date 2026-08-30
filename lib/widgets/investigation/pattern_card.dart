import 'package:flutter/material.dart';

import '../../models/investigation.dart';
import '../../theme/theme.dart';
import '../common/glowing_card.dart';

class PatternCard extends StatelessWidget {
  final List<PatternResult> patterns;
  final List<ConnectionResult> connections;
  final void Function(PatternResult pattern)? onPatternTap;
  final void Function(PatternResult pattern)? onInvestigate;

  const PatternCard({
    super.key,
    required this.patterns,
    required this.connections,
    this.onPatternTap,
    this.onInvestigate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    if (patterns.isEmpty) return const SizedBox.shrink();
    final top = patterns.first;

    return GlowingCard(
      glowColor: appColors.glow,
      glowIntensity: 0.25,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: AppTheme.iconMd, color: appColors.glow),
              const SizedBox(width: AppTheme.spacingSm),
              Text('PATTERN ANALYSIS',
                  style: text.labelLarge?.copyWith(color: appColors.glow)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text('PATTERN FOUND',
              style: text.labelSmall?.copyWith(color: appColors.subtleText)),
          const SizedBox(height: AppTheme.spacingSm),
          ...patterns.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: GestureDetector(
                onTap: onPatternTap == null ? null : () => onPatternTap!(p),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: AppTheme.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: appColors.glow
                            .withValues(alpha: AppTheme.opacitySubtle),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text('"${p.word}"',
                          style: text.titleMedium
                              ?.copyWith(color: appColors.glow)),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${p.count} occurrences',
                              style: text.bodySmall
                                  ?.copyWith(color: appColors.subtleText)),
                          if (p.hasVariants)
                            Text(
                              'Cluster: ${p.variants.join(", ")}',
                              style: text.labelSmall
                                  ?.copyWith(color: appColors.subtleText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (onPatternTap != null)
                      Icon(Icons.chevron_right,
                          size: AppTheme.iconSm, color: appColors.subtleText),
                  ],
                ),
              ),
            ),
          ),
          if (connections.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            TweenAnimationBuilder<double>(
              key: ValueKey('connections-${connections.length}'),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, (1 - v) * AppTheme.spacingMd),
                  child: child,
                ),
              ),
              child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color:
                    colors.secondary.withValues(alpha: AppTheme.opacitySubtle),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: colors.secondary
                      .withValues(alpha: AppTheme.opacitySubtle),
                  width: AppTheme.borderDefault,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('POSSIBLE CONNECTION',
                      style:
                          text.labelSmall?.copyWith(color: colors.secondary)),
                  const SizedBox(height: AppTheme.spacingXs),
                  ...connections.take(4).map(
                        (c) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTheme.spacingXs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${c.word1} ↔ ${c.word2}',
                                  style: text.titleMedium
                                      ?.copyWith(color: colors.secondary)),
                              Text(c.reason,
                                  style: text.labelSmall
                                      ?.copyWith(color: appColors.subtleText)),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
              ),
            ),
          ],
          if (onInvestigate != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onInvestigate!(top),
                icon: const Icon(Icons.search, size: AppTheme.iconSm),
                label: const Text('INVESTIGATE CONNECTION'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: appColors.glow,
                  side: BorderSide(
                    color: appColors.glow
                        .withValues(alpha: AppTheme.opacitySubtle),
                    width: AppTheme.borderDefault,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Similarity analysis of recorded audio only. A possible pattern or '
            'connection is not proof of paranormal communication.',
            style: text.labelSmall?.copyWith(
              color: appColors.subtleText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
