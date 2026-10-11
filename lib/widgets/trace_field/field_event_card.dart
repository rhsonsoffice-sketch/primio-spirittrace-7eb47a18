import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/investigation.dart';
import '../../theme/theme.dart';
import '../common/glowing_card.dart';

class FieldEventCard extends StatelessWidget {
  final FieldEvent event;
  final bool blindActive;
  final bool skepticMode;
  final VoidCallback? onMark;
  final VoidCallback? onDismiss;
  final VoidCallback? onReplay;
  final VoidCallback? onShare;
  final VoidCallback? onClose;

  const FieldEventCard({
    super.key,
    required this.event,
    this.blindActive = false,
    this.skepticMode = false,
    this.onMark,
    this.onDismiss,
    this.onReplay,
    this.onShare,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final l10n = context.l10n;
    final accent = event.isFormation ? colors.primary : appColors.glowSecondary;
    final hideAnalysis = blindActive;

    return GlowingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                event.isFormation ? Icons.blur_on : Icons.graphic_eq,
                size: AppTheme.iconSm,
                color: accent,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(l10n.label('fet', event.type),
                    style: text.labelMedium?.copyWith(color: accent)),
              ),
              Text(event.timeLabel,
                  style:
                      text.labelSmall?.copyWith(color: appColors.subtleText)),
              if (onClose != null)
                GestureDetector(
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spacingSm),
                    child: Icon(Icons.close,
                        size: AppTheme.iconSm, color: appColors.subtleText),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (event.type == FieldEventType.pulse)
            Text(
              '${event.pulseDisturbances ?? 0} '
              '${l10n.t('disturbancesWord')} · '
              '${event.pulseUnclassified ?? 0} '
              '${l10n.t('unclassifiedWord')} · '
              '${event.pulseFormations ?? 0} '
              '${l10n.t('formationsWord')}',
              style: text.bodySmall,
            )
          else if (event.type == FieldEventType.unclassified)
            Text(l10n.t('unclassifiedBody'),
                style: text.bodySmall?.copyWith(height: 1.5))
          else if (event.isFormation)
            Text(l10n.t('formationBody'),
                style: text.bodySmall?.copyWith(height: 1.5))
          else
            Text(l10n.t('changeDetected'), style: text.bodySmall),
          const SizedBox(height: AppTheme.spacingSm),
          if (hideAnalysis)
            Text(l10n.t('analysisHidden'),
                style: text.labelSmall?.copyWith(color: appColors.warning))
          else ...[
            if (event.durationLabel != null)
              _Row(
                  label: l10n.t('durationLabel'),
                  value: event.durationLabel!),
            if (event.isFormation && event.strength != null)
              _Row(
                  label: l10n.t('formationStrength'),
                  value: l10n.label('fs', event.strength!),
                  color: accent),
            if (event.isFormation && event.resemblance != null)
              _Row(
                  label: l10n.t('patternResemblance'),
                  value: event.resemblance!),
            if (event.likelyCause != null)
              _Row(
                  label: l10n.t('possibleExplanation'),
                  value: l10n.t(event.likelyCause!)),
          ],
          if (skepticMode && !hideAnalysis) ...[
            const SizedBox(height: AppTheme.spacingSm),
            if (event.audioDeviation != null)
              _Row(
                  label: l10n.t('audioVsBaseline'),
                  value: '${event.audioDeviation!.toStringAsFixed(1)}σ'),
            if (event.motionDeviation != null)
              _Row(
                  label: l10n.t('motionVsBaseline'),
                  value: '${event.motionDeviation!.toStringAsFixed(1)}σ'),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              l10n.t('skepticNote'),
              style: text.labelSmall?.copyWith(
                color: colors.secondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingXs,
            children: [
              if (onMark != null)
                _Action(
                  icon: Icons.bookmark_border,
                  label: l10n.t(event.isMarked ? 'markedWord' : 'markEvent'),
                  color: event.isMarked ? appColors.success : accent,
                  onTap: onMark!,
                ),
              if (onDismiss != null)
                _Action(
                  icon: Icons.block,
                  label:
                      l10n.t(event.isDismissed ? 'dismissedWord' : 'dismiss'),
                  color: appColors.subtleText,
                  onTap: onDismiss!,
                ),
              if (onReplay != null)
                _Action(
                  icon: Icons.play_arrow,
                  label: l10n.t('replay'),
                  color: colors.secondary,
                  onTap: onReplay!,
                ),
              if (onShare != null)
                _Action(
                  icon: Icons.ios_share,
                  label: l10n.t('shareTrace'),
                  color: appColors.glow,
                  onTap: onShare!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Row({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label,
                style:
                    text.labelSmall?.copyWith(color: appColors.subtleText)),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: text.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppTheme.opacityFaint),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: color.withValues(alpha: AppTheme.opacitySubtle),
            width: AppTheme.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppTheme.iconSm, color: color),
            const SizedBox(width: AppTheme.spacingXs),
            Text(label, style: text.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
