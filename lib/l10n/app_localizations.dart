import 'package:flutter/widgets.dart';

import 'app_locales.dart';
import 'app_strings.dart';
import 'app_strings_field.dart';
import 'app_strings_investigation.dart';
import 'app_strings_pro.dart';

/// All dictionaries merged per language code, built once at startup.
/// Split across files purely for readability — lookup order is identical
/// for every key.
final Map<String, Map<String, String>> _merged = () {
  final out = <String, Map<String, String>>{};
  for (final source in [
    kAppStrings,
    kInvestigationStrings,
    kFieldStrings,
    kProStrings,
  ]) {
    source.forEach((code, map) {
      out.putIfAbsent(code, () => <String, String>{}).addAll(map);
    });
  }
  return out;
}();

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
      _merged[locale.languageCode]?[key] ?? _merged['en']?[key] ?? key;

  /// Convenience for the single-placeholder (`%s`) strings.
  String f(String key, String value) => t(key).replaceFirst('%s', value);

  /// Alias of [f] used by the investigation widgets.
  String tf(String key, String value) => f(key, value);

  /// Localized label for an enum value; keys follow `<prefix>_<enumName>`.
  String label(String prefix, Enum value) => t('${prefix}_${value.name}');

  /// Translation of [key] in an arbitrary supported language, used by the
  /// language preview animation.
  static String inLanguage(String languageCode, String key) =>
      _merged[languageCode]?[key] ?? _merged['en']?[key] ?? key;
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
