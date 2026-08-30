import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../common/app_button.dart';
import '../common/language_preview.dart';
import '../common/language_selector.dart';

/// First-launch card introducing the worldwide language support.
Future<void> showGlobalIntroCard(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      final appColors = Theme.of(ctx).extension<AppColorsExtension>()!;
      final l10n = ctx.l10n;

      return AlertDialog(
        title: Column(
          children: [
            Text('🌍', style: text.headlineMedium),
            const SizedBox(height: AppTheme.spacingXs),
            Text('SPIRIT TRACE',
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(color: appColors.glow)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.t('globalHeadline'),
                textAlign: TextAlign.center,
                style: text.labelMedium?.copyWith(color: appColors.glowSecondary),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                l10n.t('globalTagline'),
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: appColors.subtleText),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              const SizedBox(height: AppTheme.spacingXs),
              const LanguagePreview(),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                l10n.t('globalOneApp'),
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(color: appColors.glow),
              ),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: l10n.t('chooseLanguage'),
            variant: AppButtonVariant.outline,
            onPressed: () {
              Navigator.pop(ctx);
              showLanguageSelector(context);
            },
          ),
          const SizedBox(height: AppTheme.spacingSm),
          AppButton(
            label: l10n.t('gotIt'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      );
    },
  );
}
