import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_locales.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../theme/theme.dart';
import '../common/language_selector.dart';

/// Compact globe control that opens the real language selector.
class LanguageIndicator extends StatelessWidget {
  const LanguageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final provider = context.watch<LocaleProvider>();
    final option = localeOptionFor(provider.resolvedCode(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InkWell(
          onTap: () => showLanguageSelector(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: AppTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: appColors.glow.withValues(alpha: AppTheme.opacitySubtle),
                width: AppTheme.borderDefault,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language,
                    size: AppTheme.iconSm, color: appColors.glowSecondary),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  option.nativeName,
                  style: text.labelSmall?.copyWith(color: colors.onSurface),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          context.l10n.t('availableInLanguages'),
          style: text.labelSmall?.copyWith(color: appColors.subtleText),
        ),
      ],
    );
  }
}
