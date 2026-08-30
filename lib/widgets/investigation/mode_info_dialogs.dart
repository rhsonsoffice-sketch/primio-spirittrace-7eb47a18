import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../common/app_button.dart';

Future<void> _showModeInfo(
  BuildContext context, {
  required String title,
  required String intro,
  required String sectionTitle,
  required List<String> points,
  required Color accent,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      final colors = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(title, style: text.titleLarge?.copyWith(color: accent)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(intro, style: text.bodyMedium),
              const SizedBox(height: AppTheme.spacingMd),
              Text(sectionTitle,
                  style: text.labelMedium?.copyWith(color: accent)),
              const SizedBox(height: AppTheme.spacingSm),
              ...points.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle,
                          size: AppTheme.spacingXs, color: accent),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          p,
                          style: text.bodySmall
                              ?.copyWith(color: colors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: ctx.l10n.t('gotIt'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      );
    },
  );
}

Future<void> showSkepticModeInfo(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  final l10n = context.l10n;
  return _showModeInfo(
    context,
    title: l10n.t('skepticTitle'),
    accent: colors.secondary,
    intro: l10n.t('skepticIntro'),
    sectionTitle: l10n.t('skepticHow'),
    points: [
      l10n.t('skepticP1'),
      l10n.t('skepticP2'),
      l10n.t('skepticP3'),
      l10n.t('skepticP4'),
    ],
  );
}

Future<void> showBlindModeInfo(BuildContext context) {
  final appColors = Theme.of(context).extension<AppColorsExtension>()!;
  final l10n = context.l10n;
  return _showModeInfo(
    context,
    title: l10n.t('blindTitle'),
    accent: appColors.warning,
    intro: l10n.t('blindIntro'),
    sectionTitle: l10n.t('blindWhy'),
    points: [
      l10n.t('blindP1'),
      l10n.t('blindP2'),
      l10n.t('blindP3'),
      l10n.t('blindP4'),
    ],
  );
}
