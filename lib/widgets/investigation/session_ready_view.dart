import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../common/app_button.dart';

/// Nothing is running in this state — no timer, no microphone, no detection.
class SessionReadyView extends StatelessWidget {
  final VoidCallback onStart;
  final bool micUnavailable;

  const SessionReadyView({
    super.key,
    required this.onStart,
    this.micUnavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.t('statusReady'),
              style: text.headlineSmall?.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            l10n.t(micUnavailable ? 'readyBodyNoMic' : 'readyBody'),
            style: text.bodySmall?.copyWith(color: appColors.subtleText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          AppButton(
            label: l10n.t('startInvestigation'),
            icon: Icons.play_arrow,
            pulse: true,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
