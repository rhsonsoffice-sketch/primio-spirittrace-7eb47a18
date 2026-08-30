import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/investigation.dart';
import '../../theme/theme.dart';
import '../common/app_button.dart';

Widget _sheetShell(BuildContext ctx, List<Widget> children) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        MediaQuery.of(ctx).viewInsets.bottom + AppTheme.spacingLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );

/// Asks (or edits) a question before opening a response window.
Future<String?> showQuestionSheet(
  BuildContext context, {
  String? prefill,
  String title = 'ASK A QUESTION',
  String actionLabel = 'START LISTENING',
}) {
  final controller = TextEditingController(text: prefill);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _sheetShell(ctx, [
      Text(title, style: Theme.of(ctx).textTheme.titleLarge),
      const SizedBox(height: AppTheme.spacingMd),
      TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Type your question...'),
      ),
      const SizedBox(height: AppTheme.spacingMd),
      AppButton(
        label: actionLabel,
        icon: Icons.mic,
        onPressed: () {
          final q = controller.text.trim();
          if (q.isEmpty) return;
          Navigator.pop(ctx, q);
        },
      ),
    ]),
  );
}

/// Adds or edits an investigator note for a timeline event.
Future<String?> showNoteSheet(BuildContext context, {String? initial}) {
  final controller = TextEditingController(text: initial);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _sheetShell(ctx, [
      Text('INVESTIGATION NOTE', style: Theme.of(ctx).textTheme.titleLarge),
      const SizedBox(height: AppTheme.spacingSm),
      Text(
        'Record anything you observed, e.g. a car passing or a knock in the hallway.',
        style: Theme.of(ctx).textTheme.bodySmall,
      ),
      const SizedBox(height: AppTheme.spacingMd),
      TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Add a note...'),
      ),
      const SizedBox(height: AppTheme.spacingMd),
      AppButton(
        label: 'SAVE NOTE',
        icon: Icons.check,
        onPressed: () => Navigator.pop(ctx, controller.text),
      ),
    ]),
  );
}

/// Lets the investigator classify an event, including explaining it away.
Future<ResponseStatus?> showStatusSheet(
  BuildContext context, {
  required ResponseStatus current,
}) {
  return showModalBottomSheet<ResponseStatus>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      final colors = Theme.of(ctx).colorScheme;
      return _sheetShell(ctx, [
        Text('MARK THIS EVENT', style: text.titleLarge),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'Marked events stay in the investigation record.',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...ResponseStatus.values.where((s) => s != ResponseStatus.unreviewed).map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  s == current ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: s == current ? colors.primary : colors.outline,
                ),
                title: Text(s.label, style: text.bodyMedium),
                onTap: () => Navigator.pop(ctx, s),
              ),
            ),
      ]);
    },
  );
}

/// Shows every timeline occurrence behind a detected pattern.
Future<void> showOccurrencesSheet(
  BuildContext context, {
  required PatternResult pattern,
  required List<QuestionResponse> occurrences,
  void Function(QuestionResponse response)? onPlay,
}) {
  final fmt = DateFormat('HH:mm:ss');
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      final appColors = Theme.of(ctx).extension<AppColorsExtension>()!;
      return _sheetShell(ctx, [
        Text('POSSIBLE RESPONSE CLUSTER', style: text.labelMedium),
        const SizedBox(height: AppTheme.spacingXs),
        Text('"${pattern.word}"', style: text.headlineSmall),
        Text('${pattern.count} occurrences',
            style: text.bodySmall?.copyWith(color: appColors.subtleText)),
        const SizedBox(height: AppTheme.spacingMd),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.45,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: occurrences.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTheme.spacingSm),
            itemBuilder: (_, i) {
              final r = occurrences[i];
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (r.detectedResponse ?? '').toUpperCase(),
                          style: text.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${fmt.format(r.timestamp)} • ${r.question}',
                          style: text.labelSmall
                              ?.copyWith(color: appColors.subtleText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (r.audioPath != null && onPlay != null)
                    IconButton(
                      onPressed: () => onPlay(r),
                      icon: Icon(Icons.play_arrow,
                          color: appColors.glowSecondary),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'Grouped by word similarity. This does not show that the same source '
          'produced each occurrence.',
          style: text.labelSmall?.copyWith(
            color: appColors.subtleText,
            fontStyle: FontStyle.italic,
          ),
        ),
      ]);
    },
  );
}

/// Side-by-side comparison of a repeat test against the original response.
Future<void> showComparisonSheet(
  BuildContext context, {
  required QuestionResponse first,
  required QuestionResponse second,
  required RepeatComparison result,
  void Function(QuestionResponse response)? onPlay,
}) {
  final fmt = DateFormat('HH:mm:ss');
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      final appColors = Theme.of(ctx).extension<AppColorsExtension>()!;
      final color = result == RepeatComparison.repeated
          ? appColors.success
          : result == RepeatComparison.similar
              ? appColors.warning
              : appColors.subtleText;

      Widget block(String label, QuestionResponse r) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      text.labelSmall?.copyWith(color: appColors.subtleText)),
              const SizedBox(height: AppTheme.spacingXs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (r.detectedResponse ?? 'NO CLEAR RESPONSE').toUpperCase(),
                      style: text.titleMedium,
                    ),
                  ),
                  Text(fmt.format(r.timestamp), style: text.labelSmall),
                  if (r.audioPath != null && onPlay != null)
                    IconButton(
                      onPressed: () => onPlay(r),
                      icon: Icon(Icons.play_arrow,
                          color: appColors.glowSecondary),
                    ),
                ],
              ),
            ],
          );

      return _sheetShell(ctx, [
        Text('RESPONSE COMPARISON', style: text.titleLarge),
        const SizedBox(height: AppTheme.spacingMd),
        block('FIRST RESPONSE', first),
        const SizedBox(height: AppTheme.spacingMd),
        block('SECOND RESPONSE', second),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: color.withValues(alpha: AppTheme.opacitySubtle),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Text('RESULT: ${result.label}',
              style: text.labelLarge?.copyWith(color: color)),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'A repeated result is an observation about the recorded audio, not '
          'scientific proof.',
          style: text.labelSmall?.copyWith(
            color: appColors.subtleText,
            fontStyle: FontStyle.italic,
          ),
        ),
      ]);
    },
  );
}

/// Displays the generated case file with a copy action.
Future<void> showCaseFileSheet(BuildContext context, String report) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      return _sheetShell(ctx, [
        Text('CASE FILE', style: text.titleLarge),
        const SizedBox(height: AppTheme.spacingMd),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.55,
          ),
          child: SingleChildScrollView(
            child: SelectableText(report, style: text.bodySmall),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        AppButton(
          label: 'COPY REPORT',
          icon: Icons.copy_all,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: report));
            Navigator.pop(ctx);
          },
        ),
      ]);
    },
  );
}
