import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/investigation.dart';
import '../../services/trace_field_engine.dart';
import '../../theme/theme.dart';
import '../common/app_button.dart';
import 'field_event_card.dart';
import 'field_painter.dart';

/// Chronological list of everything the Field recorded.
Future<void> showFieldTimeline(
  BuildContext context, {
  required List<FieldEvent> events,
  required bool blindActive,
  required bool skepticMode,
  void Function(FieldEvent event)? onReplay,
  void Function(FieldEvent event)? onShare,
}) {
  final text = Theme.of(context).textTheme;
  final appColors = Theme.of(context).extension<AppColorsExtension>()!;
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          Text(l10n.t('fieldTimeline'), style: text.titleLarge),
          const SizedBox(height: AppTheme.spacingMd),
          if (events.isEmpty)
            Text(
              l10n.t('noFieldEvents'),
              style: text.bodyMedium?.copyWith(color: appColors.subtleText),
            )
          else
            for (final e in events) ...[
              FieldEventCard(
                event: e,
                blindActive: blindActive,
                skepticMode: skepticMode,
                onReplay: e.isFormation && onReplay != null
                    ? () => onReplay(e)
                    : null,
                onShare: onShare != null ? () => onShare(e) : null,
              ),
              const SizedBox(height: AppTheme.spacingSm),
            ],
        ],
      ),
    ),
  );
}

/// Replays the recorded frames of a formation exactly as they occurred.
Future<void> showFormationReplay(
  BuildContext context, {
  required FieldEvent event,
  required List<List<Offset>> frames,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReplaySheet(event: event, frames: frames),
  );
}

class _ReplaySheet extends StatefulWidget {
  final FieldEvent event;
  final List<List<Offset>> frames;
  const _ReplaySheet({required this.event, required this.frames});

  @override
  State<_ReplaySheet> createState() => _ReplaySheetState();
}

class _ReplaySheetState extends State<_ReplaySheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final TraceFieldEngine _engine = TraceFieldEngine(particleCount: 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100 * widget.frames.length.clamp(1, 80)),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.t('formationReplay'),
              textAlign: TextAlign.center, style: text.titleLarge),
          const SizedBox(height: AppTheme.spacingXs),
          Text(widget.event.timeLabel,
              style: text.labelSmall?.copyWith(color: appColors.subtleText)),
          const SizedBox(height: AppTheme.spacingMd),
          AspectRatio(
            aspectRatio: 1,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (widget.frames.isEmpty) {
                  return const SizedBox.shrink();
                }
                final i = (_controller.value * widget.frames.length)
                    .floor()
                    .clamp(0, widget.frames.length - 1);
                return FieldSurface(
                  engine: _engine,
                  repaint: _controller,
                  replayFrame: widget.frames[i],
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            l10n.t('replayNote'),
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(
              color: appColors.subtleText,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          AppButton(
            label: l10n.t('close'),
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// Shareable event card.
Future<void> showShareTrace(BuildContext context, FieldEvent event) {
  final text = Theme.of(context).textTheme;
  final colors = Theme.of(context).colorScheme;
  final appColors = Theme.of(context).extension<AppColorsExtension>()!;
  final l10n = context.l10n;

  final lines = <String>[
    'SPIRIT TRACE — ${l10n.t('traceFieldEvent')}',
    '${l10n.t('fieldTimeline')}: ${l10n.t(event.type.key)}',
    '${l10n.t('timeWord')}: ${event.timeLabel}',
    if (event.durationLabel != null)
      '${l10n.t('durationLabel')}: ${event.durationLabel}',
    if (event.strength != null)
      '${l10n.t('strengthWord')}: ${l10n.t(event.strength!.key)}',
    if (event.resemblance != null)
      '${l10n.t('resemblanceWord')}: ${event.resemblance}',
    l10n.t('shareNote'),
  ];

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withValues(alpha: AppTheme.opacitySubtle),
                  appColors.deepBackground,
                ],
                stops: const [0.0, 1.0],
              ),
              border: Border.all(
                color: colors.primary.withValues(alpha: AppTheme.opacityHint),
                width: AppTheme.borderDefault,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SPIRIT TRACE', style: text.titleMedium),
                Text(l10n.t('traceFieldEvent'),
                    style: text.labelSmall
                        ?.copyWith(color: appColors.glowSecondary)),
                const SizedBox(height: AppTheme.spacingLg),
                Text(l10n.t(event.type.key),
                    style: text.headlineSmall?.copyWith(color: colors.primary)),
                const SizedBox(height: AppTheme.spacingSm),
                Text('${l10n.t('timeWord')}  ${event.timeLabel}',
                    style: text.bodySmall),
                if (event.durationLabel != null)
                  Text(
                      '${l10n.t('durationLabel')}  ${event.durationLabel}',
                      style: text.bodySmall),
                if (event.strength != null)
                  Text(
                      '${l10n.t('strengthWord')}  ${l10n.t(event.strength!.key)}',
                      style: text.bodySmall),
                if (event.resemblance != null)
                  Text(
                      '${l10n.t('resemblanceWord')}  ${event.resemblance}',
                      style: text.bodySmall),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  l10n.t('shareNote'),
                  style: text.labelSmall?.copyWith(
                    color: appColors.subtleText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          AppButton(
            label: l10n.t('copyEventDetails'),
            icon: Icons.copy_all,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: lines.join('\n')));
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: AppTheme.spacingSm),
          AppButton(
            label: l10n.t('close'),
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    ),
  );
}
