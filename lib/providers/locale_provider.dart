import 'package:flutter/widgets.dart';

import '../l10n/app_locales.dart';
import '../repositories/investigation_repository.dart';

/// Holds the investigator's language preference.
///
/// When no manual choice has been made the provider returns null, which lets
/// Flutter resolve the device language against [kSupportedLocales] and fall
/// back to English when the device language is not supported.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'locale_code';

  final InvestigationRepository repository;
  String? _code;
  bool _loaded = false;

  LocaleProvider({required this.repository});

  bool get isLoaded => _loaded;

  /// The manually selected language code, or null when following the device.
  String? get selectedCode => _code;

  Locale? get locale => _code == null ? null : Locale(_code!);

  Future<void> load() async {
    _code = await repository.getString(_key);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(String? code) async {
    if (_code == code) return;
    _code = code;
    notifyListeners();
    await repository.setString(_key, code);
  }

  /// The language actually being displayed, used for the settings summary.
  String resolvedCode(BuildContext context) {
    if (_code != null) return _code!;
    final device = Localizations.maybeLocaleOf(context)?.languageCode;
    if (device != null && kAppLocales.any((o) => o.code == device)) {
      return device;
    }
    return kAppLocales.first.code;
  }
}
