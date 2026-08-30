import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_locales.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/language_preview.dart';
import '../widgets/common/language_selector.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final provider = context.watch<LocaleProvider>();
    final l10n = context.l10n;
    final option = localeOptionFor(provider.resolvedCode(context));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(l10n.t('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingXs,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              side: BorderSide(
                color: colors.outline.withValues(alpha: AppTheme.opacitySubtle),
                width: AppTheme.borderDefault,
              ),
            ),
            leading: Icon(Icons.language,
                color: appColors.glow, size: AppTheme.iconMd),
            title: Text(l10n.t('language'), style: text.labelMedium),
            subtitle: Text(
              provider.selectedCode == null
                  ? '${option.flag}  ${option.nativeName} · ${l10n.t('systemDefault')}'
                  : '${option.flag}  ${option.nativeName}',
              style: text.bodySmall?.copyWith(color: appColors.subtleText),
            ),
            trailing: Icon(Icons.chevron_right,
                color: appColors.subtleText, size: AppTheme.iconMd),
            onTap: () => showLanguageSelector(context),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: appColors.cardHighlight
                  .withValues(alpha: AppTheme.opacityOverlay),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: appColors.glow.withValues(alpha: AppTheme.opacitySubtle),
                width: AppTheme.borderDefault,
              ),
            ),
            child: Column(
              children: [
                Text(
                  l10n.t('globalOneApp'),
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(color: appColors.glow),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                const LanguagePreview(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
