import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_locales.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';

/// Cycles one real interface string through the supported languages.
///
/// It reads from the same dictionaries the interface uses, so it can never
/// show a language that is not genuinely supported.
class LanguagePreview extends StatefulWidget {
  final String stringKey;

  const LanguagePreview({super.key, this.stringKey = 'appSubtitle'});

  @override
  State<LanguagePreview> createState() => _LanguagePreviewState();
}

class _LanguagePreviewState extends State<LanguagePreview> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % kAppLocales.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final option = kAppLocales[_index];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 480),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(option.code),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${option.flag}  ${option.nativeName}',
            textAlign: TextAlign.center,
            style: text.labelMedium?.copyWith(color: appColors.glowSecondary),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            AppLocalizations.inLanguage(option.code, widget.stringKey),
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}
