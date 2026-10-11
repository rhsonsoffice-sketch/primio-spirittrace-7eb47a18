import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/investigation.dart';
import '../../theme/theme.dart';
import '../common/app_button.dart';
import '../common/glowing_card.dart';

class SessionEndedView extends StatelessWidget {
  final Investigation investigation;
  final int patternCount;
  final bool blindMode;
  final bool skepticMode;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const SessionEndedView({
    super.key,
    required this.investigation,
    required this.patternCount,
    required this.blindMode,
    required this.skepticMode,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final l10n = context.l10n;
    final dur = investigation.duration;
    final durStr = '${dur.inMinutes}m ${dur.inSeconds % 60}s';
    final on = l10n.t('onLabel');
    final off = l10n.t('offLabel');

    Widget row(String label, String value, Color color) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: text.bodyMedium)),
              const SizedBox(width: AppTheme.spacingSm),
              Text(value, style: text.titleSmall?.copyWith(color: color)),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        children: [
          Text(l10n.t('investigationEnded'),
              style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            l10n.t('endedBody'),
            style: text.bodySmall?.copyWith(color: appColors.subtleText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          GlowingCard(
            child: Column(
              children: [
                row(l10n.t('durationLabel'), durStr, colors.onSurface),
                row(l10n.t('questions'), '${investigation.questionCount}',
                    colors.onSurface),
                row(l10n.t('possibleResponsesLbl'),
                    '${investigation.responseCount}', appColors.glowSecondary),
                row(l10n.t('possiblePatternsLbl'), '$patternCount',
                    appColors.glow),
                row(l10n.t('blindModeLabel'), blindMode ? on : off,
                    blindMode ? appColors.warning : appColors.subtleText),
                row(l10n.t('skepticModeLabel'), skepticMode ? on : off,
                    skepticMode ? colors.secondary : appColors.subtleText),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          AppButton(
            label: l10n.t('saveInvestigation'),
            icon: Icons.save_outlined,
            onPressed: onSave,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          AppButton(
            label: l10n.t('discard'),
            icon: Icons.delete_outline,
            variant: AppButtonVariant.outline,
            onPressed: onDiscard,
          ),
        ],
      ),
    );
  }
}
