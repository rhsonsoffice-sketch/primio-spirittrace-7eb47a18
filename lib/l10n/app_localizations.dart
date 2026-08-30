import 'package:flutter/widgets.dart';

import 'app_locales.dart';
import 'app_strings.dart';

/// Resolves user-facing strings for the active locale.
///
/// Falls back to English for any key that has not been translated yet, so a
/// missing entry can never produce an empty or broken interface.
class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('en'));

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String t(String key) =>
      kAppStrings[locale.languageCode]?[key] ?? kAppStrings['en']?[key] ?? key;

  /// Translation of [key] in an arbitrary supported language, used by the
  /// language preview animation.
  static String inLanguage(String languageCode, String key) =>
      kAppStrings[languageCode]?[key] ?? kAppStrings['en']?[key] ?? key;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      kAppLocales.any((o) => o.code == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
