import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/trace_memory_provider.dart';
import '../../theme/theme.dart';

class TraceMemoryPanel extends StatelessWidget {
  final TraceMemoryStats stats;
  final VoidCallback? onTap;

  const TraceMemoryPanel({super.key, required this.stats, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: appColors.cardHighlight.withOpacity(AppTheme.opacityOverlay),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: appColors.glow.withOpacity(AppTheme.opacitySubtle),
            width: AppTheme.borderDefault,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory,
                    size: AppTheme.iconSm, color: appColors.glow),
                const SizedBox(width: AppTheme.spacingSm),
                Flexible(
                  child: Text(context.l10n.t('traceMemory'),
                      style: text.labelSmall?.copyWith(color: appColors.glow)),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(Icons.chevron_right,
                      size: AppTheme.iconSm, color: appColors.subtleText),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                _Stat(
                  value: stats.investigations,
                  label: context.l10n.t('statInvestigations'),
                ),
                _Stat(
                  value: stats.possibleResponses,
                  label: context.l10n.t('statResponses'),
                  color: colors.secondary,
                ),
                _Stat(
                  value: stats.repeatedResponses,
                  label: context.l10n.t('statRepeats'),
                  color: appColors.success,
                ),
                _Stat(
                  value: stats.patterns,
                  label: context.l10n.t('statPatterns'),
                  color: appColors.glow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final Color? color;

  const _Stat({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Expanded(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: value.toDouble()),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              v.round().toString(),
              style: text.headlineSmall
                  ?.copyWith(color: color ?? colors.onSurface),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            style: text.labelSmall?.copyWith(color: appColors.subtleText),
          ),
        ],
      ),
    );
  }
}
