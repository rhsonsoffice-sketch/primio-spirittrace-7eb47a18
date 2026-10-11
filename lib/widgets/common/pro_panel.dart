import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import 'app_button.dart';
import 'glowing_card.dart';

enum ProMessageTone { info, success, error }

const _benefitKeys = [
  'proBenefitMemory',
  'proBenefitPatterns',
  'proBenefitConnections',
  'proBenefitRepeat',
  'proBenefitPulse',
  'proBenefitCaseFiles',
];

class ProPanel extends StatelessWidget {
  final bool isPro;
  final bool storeSupported;
  final bool loading;
  final bool busy;
  final bool restoring;
  final String? price;
  final String? message;
  final ProMessageTone tone;
  final VoidCallback? onBuy;
  final VoidCallback? onRestore;
  final VoidCallback? onRetry;

  const ProPanel({
    super.key,
    required this.isPro,
    required this.storeSupported,
    required this.loading,
    required this.busy,
    required this.restoring,
    this.price,
    this.message,
    this.tone = ProMessageTone.info,
    this.onBuy,
    this.onRestore,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final header = Row(
      children: [
        Icon(isPro ? Icons.verified : Icons.auto_awesome,
            size: AppTheme.iconSm,
            color: isPro ? appColors.success : appColors.glow),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(l10n.t('proTitle'),
              style: text.labelLarge?.copyWith(color: appColors.glow)),
        ),
      ],
    );

    if (isPro) {
      return GlowingCard(
        glowColor: appColors.success,
        glowIntensity: AppTheme.opacitySubtle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: AppTheme.spacingSm),
            Text(l10n.t('proUnlocked'),
                style: text.titleMedium?.copyWith(color: appColors.success)),
            const SizedBox(height: AppTheme.spacingXs),
            Text(l10n.t('proUnlockedBody'),
                style: text.bodySmall?.copyWith(color: appColors.subtleText)),
          ],
        ),
      );
    }

    final messageColor = switch (tone) {
      ProMessageTone.error => appColors.danger,
      ProMessageTone.success => appColors.success,
      ProMessageTone.info => appColors.warning,
    };

    return GlowingCard(
      glowColor: appColors.glow,
      glowIntensity: AppTheme.opacityHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: AppTheme.spacingSm),
          Text(l10n.t('proDesc'),
              style: text.bodySmall?.copyWith(color: colors.onSurface)),
          const SizedBox(height: AppTheme.spacingSm),
          for (final key in _benefitKeys)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check,
                      size: AppTheme.iconSm, color: appColors.glowSecondary),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(child: Text(l10n.t(key), style: text.bodySmall)),
                ],
              ),
            ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(l10n.t('proLifetime'),
              style: text.labelSmall?.copyWith(color: appColors.subtleText)),
          const SizedBox(height: AppTheme.spacingMd),
          if (!storeSupported)
            Text(l10n.t('proIosOnly'),
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: appColors.subtleText))
          else if (loading)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: AppTheme.iconSm,
                  height: AppTheme.iconSm,
                  child: CircularProgressIndicator(
                      strokeWidth: AppTheme.borderSelected),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Flexible(
                  child: Text(l10n.t('proLoading'),
                      style: text.bodySmall
                          ?.copyWith(color: appColors.subtleText)),
                ),
              ],
            )
          else if (price != null)
            Text(price!,
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(color: colors.onSurface)),
          const SizedBox(height: AppTheme.spacingSm),
          AppButton(
            label: l10n.t('proUnlockBtn'),
            icon: busy ? Icons.hourglass_top : Icons.lock_open,
            onPressed: onBuy,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          TextButton(
            onPressed: onRestore,
            child: Text(
              restoring ? '${l10n.t('proRestoreBtn')}…' : l10n.t('proRestoreBtn'),
              textAlign: TextAlign.center,
              style: text.labelMedium?.copyWith(color: appColors.glowSecondary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(message!,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: messageColor)),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            AppButton(
              label: l10n.t('proRetry'),
              icon: Icons.refresh,
              variant: AppButtonVariant.outline,
              compact: true,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
