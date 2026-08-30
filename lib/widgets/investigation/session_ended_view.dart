import 'package:flutter/material.dart';

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
    final dur = investigation.duration;
    final durStr = '${dur.inMinutes}m ${dur.inSeconds % 60}s';

    Widget row(String label, String value, Color color) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: text.bodyMedium),
              Text(value, style: text.titleSmall?.copyWith(color: color)),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        children: [
          Text('INVESTIGATION ENDED',
              style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Nothing is running. Choose whether to keep this session.',
            style: text.bodySmall?.copyWith(color: appColors.subtleText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          GlowingCard(
            child: Column(
              children: [
                row('Duration', durStr, colors.onSurface),
                row('Questions', '${investigation.questionCount}',
                    colors.onSurface),
                row('Possible Responses', '${investigation.responseCount}',
                    appColors.glowSecondary),
                row('Possible Patterns', '$patternCount', appColors.glow),
                row('Blind Mode', blindMode ? 'ON' : 'OFF',
                    blindMode ? appColors.warning : appColors.subtleText),
                row('Skeptic Mode', skepticMode ? 'ON' : 'OFF',
                    skepticMode ? colors.secondary : appColors.subtleText),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          AppButton(
            label: 'SAVE INVESTIGATION',
            icon: Icons.save_outlined,
            onPressed: onSave,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          AppButton(
            label: 'DISCARD',
            icon: Icons.delete_outline,
            variant: AppButtonVariant.outline,
            onPressed: onDiscard,
          ),
        ],
      ),
    );
  }
}
