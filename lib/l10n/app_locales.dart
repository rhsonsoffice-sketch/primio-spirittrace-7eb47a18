import 'package:flutter/widgets.dart';

/// A language Spirit Trace has been fully translated into.
///
/// Adding a new language requires two steps only: append an option here and
/// add the matching map in `app_strings.dart`. No other file changes.
class AppLocaleOption {
  final String code;
  final String nativeName;
  final String flag;

  const AppLocaleOption({
    required this.code,
    required this.nativeName,
    required this.flag,
  });

  Locale get locale => Locale(code);
}

const List<AppLocaleOption> kAppLocales = [
  AppLocaleOption(code: 'en', nativeName: 'English', flag: '🇬🇧'),
  AppLocaleOption(code: 'fr', nativeName: 'Français', flag: '🇫🇷'),
  AppLocaleOption(code: 'de', nativeName: 'Deutsch', flag: '🇩🇪'),
  AppLocaleOption(code: 'es', nativeName: 'Español', flag: '🇪🇸'),
  AppLocaleOption(code: 'it', nativeName: 'Italiano', flag: '🇮🇹'),
  AppLocaleOption(code: 'pt', nativeName: 'Português', flag: '🇵🇹'),
  AppLocaleOption(code: 'nl', nativeName: 'Nederlands', flag: '🇳🇱'),
  AppLocaleOption(code: 'ja', nativeName: '日本語', flag: '🇯🇵'),
  AppLocaleOption(code: 'ko', nativeName: '한국어', flag: '🇰🇷'),
  AppLocaleOption(code: 'zh', nativeName: '简体中文', flag: '🇨🇳'),
];

List<Locale> get kSupportedLocales =>
    kAppLocales.map((o) => o.locale).toList(growable: false);

AppLocaleOption localeOptionFor(String code) => kAppLocales.firstWhere(
      (o) => o.code == code,
      orElse: () => kAppLocales.first,
    );
