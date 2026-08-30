import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../common/app_button.dart';

class _Slide {
  final String title;
  final String body;
  final String action;
  const _Slide(this.title, this.body, this.action);
}

const _slides = [
  _Slide(
    'WHAT IS TRACE FIELD?',
    'Trace Field gives you a visual way to observe changes during a paranormal '
        'investigation.\n\nInstead of only listening for responses, you can watch '
        'the Field for unusual changes and temporary patterns.',
    'NEXT',
  ),
  _Slide(
    'HOW IT WORKS',
    'First, Trace Field establishes a baseline for your surroundings.\n\n'
        'It then monitors supported device inputs and turns significant changes '
        'into visual activity within the Field.\n\nBASELINE → CHANGE → FIELD RESPONSE',
    'NEXT',
  ),
  _Slide(
    'WHAT SHOULD I DO?',
    'Place your phone somewhere stable.\n\nAsk your questions clearly.\n\n'
        'Then remain as still and quiet as possible.\n\nWatch the Field.',
    'NEXT',
  ),
  _Slide(
    'WHAT AM I LOOKING FOR?',
    'Most of the time the Field will remain stable.\n\nOccasionally you may see '
        'a disturbance or an unusual temporary formation.\n\nThese events are not '
        'proof of paranormal activity. They are something to investigate and, '
        'where possible, repeat.',
    'ENTER TRACE FIELD',
  ),
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
    if (_index == _slides.length - 1) {
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

    return Dialog(
      insetPadding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 260,
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: text.titleLarge),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          s.body,
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
              children: List.generate(_slides.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXs),
                  width: active ? AppTheme.spacingMd : AppTheme.spacingSm,
                  height: AppTheme.spacingSm,
                  decoration: BoxDecoration(
                    color: active ? colors.primary : appColors.subtleText,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            AppButton(label: _slides[_index].action, onPressed: _next),
          ],
        ),
      ),
    );
  }
}

class _HelpItem {
  final String q;
  final String a;
  const _HelpItem(this.q, this.a);
}

const _help = [
  _HelpItem('What is Trace Field?',
      'A visual way to watch your surroundings for measurable changes during an investigation.'),
  _HelpItem('How does calibration work?',
      'The app samples the microphone level and device motion for a few seconds to learn what "normal" looks like where you are.'),
  _HelpItem('What does Field Stable mean?',
      'Current readings are close to the baseline. The Field keeps moving gently because it is still monitoring.'),
  _HelpItem('What is a Field Disturbance?',
      'A measured change clearly above the baseline, with the input that changed shown where it can be identified.'),
  _HelpItem('What is a Possible Formation?',
      'The particles in the Field genuinely converged into a coherent shape. It is a visual pattern, not evidence of anything.'),
  _HelpItem('What does Pulse do?',
      'Opens a focused 30 second observation window and summarises everything recorded inside it.'),
  _HelpItem('What does Skeptic Mode do?',
      'Adds measured context and ordinary explanations to every event so you can judge it critically.'),
  _HelpItem('What does Blind Mode do?',
      'Hides interpretation — causes, resemblance and strength — until you choose Reveal Trace.'),
  _HelpItem('How do I save an investigation?',
      'Press Stop on the investigation screen, then choose Save Investigation.'),
  _HelpItem('How do I review Past Investigations?',
      'Open Past Investigations from the home screen and tap any saved session.'),
];

Future<void> showTraceFieldHelp(BuildContext context) {
  final text = Theme.of(context).textTheme;
  final appColors = Theme.of(context).extension<AppColorsExtension>()!;
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
          Text('TRACE FIELD HELP', style: text.titleLarge),
          const SizedBox(height: AppTheme.spacingMd),
          for (final h in _help) ...[
            Text(h.q, style: text.titleSmall),
            const SizedBox(height: AppTheme.spacingXs),
            Text(h.a,
                style: text.bodySmall?.copyWith(
                  color: appColors.subtleText,
                  height: 1.5,
                )),
            const SizedBox(height: AppTheme.spacingMd),
          ],
          Text(
            'Trace Field records changes and visual patterns. It does not detect '
            'spirits and results are not scientifically verified.',
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
