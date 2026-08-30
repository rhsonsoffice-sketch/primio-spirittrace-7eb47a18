import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_locales.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../theme/theme.dart';

/// Opens the language selector. Selecting an entry changes the interface
/// language immediately and stores the choice.
Future<void> showLanguageSelector(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final provider = context.watch<LocaleProvider>();
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge),
          ),
          border: Border.all(
            color: appColors.glow.withValues(alpha: AppTheme.opacitySubtle),
            width: AppTheme.borderDefault,
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, size: AppTheme.iconMd, color: appColors.glow),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    l10n.t('chooseLanguage'),
                    style: text.titleMedium?.copyWith(color: appColors.glow),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              l10n.t('globalTagline'),
              style: text.bodySmall?.copyWith(color: appColors.subtleText),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _LanguageTile(
                    flag: '🌐',
                    name: l10n.t('systemDefault'),
                    selected: provider.selectedCode == null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      provider.setLanguage(null);
                      Navigator.pop(context);
                    },
                  ),
                  ...kAppLocales.map(
                    (option) => _LanguageTile(
                      flag: option.flag,
                      name: option.nativeName,
                      selected: provider.selectedCode == option.code,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider.setLanguage(option.code);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flag,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingMd,
          ),
          decoration: BoxDecoration(
            color: selected
                ? appColors.cardHighlight
                : colors.surfaceContainerHighest
                    .withValues(alpha: AppTheme.opacityOverlay),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected
                  ? appColors.glow
                  : colors.outline.withValues(alpha: AppTheme.opacitySubtle),
              width: selected ? AppTheme.borderSelected : AppTheme.borderDefault,
            ),
          ),
          child: Row(
            children: [
              Text(flag, style: text.titleMedium),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  name,
                  style: text.titleSmall?.copyWith(
                    color: selected ? appColors.glow : colors.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle,
                    size: AppTheme.iconMd, color: appColors.glow),
            ],
          ),
        ),
      ),
    );
  }
}
