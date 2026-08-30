import 'package:flutter/material.dart';

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

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('READY TO INVESTIGATE',
              style: text.headlineSmall?.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            micUnavailable
                ? 'The microphone is unavailable on this device. You can still '
                    'record questions and notes.'
                : 'Choose your modes, then start the session. Nothing is '
                    'recorded or analysed until you begin.',
            style: text.bodySmall?.copyWith(color: appColors.subtleText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          AppButton(
            label: 'START INVESTIGATION',
            icon: Icons.play_arrow,
            pulse: true,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
