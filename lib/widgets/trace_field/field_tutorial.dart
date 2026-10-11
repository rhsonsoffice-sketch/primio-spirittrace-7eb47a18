import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../common/app_button.dart';

const _slideKeys = [
  ['tutT1', 'tutB1', 'next'],
  ['tutT2', 'tutB2', 'next'],
  ['tutT3', 'tutB3', 'next'],
  ['tutT4', 'tutB4', 'enterTraceField'],
];

Future<void> showTraceFieldTutorial(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _TutorialDialog(),
  );
}

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog();

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _slideKeys.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final l10n = context.l10n;

    return Dialog(
      insetPadding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _controller,
                itemCount: _slideKeys.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = _slideKeys[i];
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.t(s[0]), style: text.titleLarge),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          l10n.t(s[1]),
                          style: text.bodyMedium?.copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slideKeys.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXs),
                  width: active ? AppTheme.spacingMd : AppTheme.spacingSm,
                  height: AppTheme.spacingSm,
                  decoration: BoxDecoration(
                    color: active ? colors.primary : appColors.subtleText,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            AppButton(
              label: l10n.t(_slideKeys[_index][2]),
              onPressed: _next,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showTraceFieldHelp(BuildContext context) {
  final text = Theme.of(context).textTheme;
  final appColors = Theme.of(context).extension<AppColorsExtension>()!;
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          Text(l10n.t('helpTitle'), style: text.titleLarge),
          const SizedBox(height: AppTheme.spacingMd),
          for (var i = 1; i <= 10; i++) ...[
            Text(l10n.t('hq$i'), style: text.titleSmall),
            const SizedBox(height: AppTheme.spacingXs),
            Text(l10n.t('ha$i'),
                style: text.bodySmall?.copyWith(
                  color: appColors.subtleText,
                  height: 1.5,
                )),
            const SizedBox(height: AppTheme.spacingMd),
          ],
          Text(
            l10n.t('helpNote'),
            style: text.labelSmall?.copyWith(
              color: appColors.subtleText,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}
