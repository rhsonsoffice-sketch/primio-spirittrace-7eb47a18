import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/investigation.dart';
import '../providers/investigation_provider.dart';
import '../providers/trace_field_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/trace_field/field_event_card.dart';
import '../widgets/trace_field/field_painter.dart';
import '../widgets/trace_field/field_sheets.dart';
import '../widgets/trace_field/field_tutorial.dart';

class TraceFieldScreen extends StatefulWidget {
  const TraceFieldScreen({super.key});

  @override
  State<TraceFieldScreen> createState() => _TraceFieldScreenState();
}

class _TraceFieldScreenState extends State<TraceFieldScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final field = context.read<TraceFieldProvider>();
    final inv = context.read<InvestigationProvider>();
    field.applyModes(blind: inv.blindMode, skeptic: inv.skepticMode);
    await field.init();
    if (!mounted) return;
    if (!field.introSeen) {
      await showTraceFieldTutorial(context);
      await field.acknowledgeIntro();
    }
    if (!mounted) return;
    await field.startCalibration();
  }

  Future<void> _exit() async {
    final field = context.read<TraceFieldProvider>();
    await field.stopField();
    if (mounted) Navigator.of(context).pop();
  }

  void _replay(FieldEvent e) {
    final frames = context.read<TraceFieldProvider>().replayFor(e.id);
    if (frames == null || frames.isEmpty) return;
    showFormationReplay(context, event: e, frames: frames);
  }

  @override
  Widget build(BuildContext context) {
    final field = context.watch<TraceFieldProvider>();
    final inv = context.watch<InvestigationProvider>();
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    final blindActive = inv.blindMode && !field.revealed;
    final latest = field.latestEvent;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        backgroundColor: appColors.deepBackground,
        body: Stack(
          children: [
            Positioned.fill(
              child: FieldSurface(engine: field.engine, repaint: field.frame),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm,
                      vertical: AppTheme.spacingXs,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _exit,
                          icon: Icon(Icons.arrow_back,
                              color: appColors.subtleText),
                        ),
                        Expanded(
                          child: Text('TRACE FIELD',
                              textAlign: TextAlign.center,
                              style: text.titleMedium),
                        ),
                        IconButton(
                          onPressed: () => showTraceFieldHelp(context),
                          icon: Icon(Icons.info_outline,
                              color: appColors.subtleText),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLg),
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          child: Text(
                            field.statusTitle,
                            key: ValueKey(field.statusTitle),
                            style: text.titleLarge?.copyWith(
                              color: field.formationVisible
                                  ? colors.primary
                                  : colors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          field.statusDetail,
                          textAlign: TextAlign.center,
                          style: text.bodySmall
                              ?.copyWith(color: appColors.subtleText),
                        ),
                        if (field.state == FieldState.calibrating) ...[
                          const SizedBox(height: AppTheme.spacingSm),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            child: LinearProgressIndicator(
                              value: field.calibrationProgress,
                              backgroundColor: colors.surfaceContainerHighest,
                              color: colors.primary,
                            ),
                          ),
                        ],
                        if (field.pulseActive) ...[
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(
                            '${field.pulseRemaining}s',
                            style: text.headlineSmall
                                ?.copyWith(color: appColors.glowSecondary),
                          ),
                        ],
                        if (!field.motionAvailable &&
                            field.state != FieldState.idle)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: AppTheme.spacingXs),
                            child: Text(
                              'MOTION SENSOR UNAVAILABLE — AUDIO INPUT ONLY',
                              style: text.labelSmall
                                  ?.copyWith(color: appColors.warning),
                            ),
                          ),
                        if (blindActive)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: AppTheme.spacingXs),
                            child: Text('BLIND MODE ACTIVE',
                                style: text.labelSmall
                                    ?.copyWith(color: appColors.warning)),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (field.prompt != null && !field.formationVisible)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLg),
                      child: GestureDetector(
                        onTap: field.dismissPrompt,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTheme.spacingSm),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest
                                .withValues(alpha: AppTheme.opacityOverlay),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(field.prompt!,
                              textAlign: TextAlign.center,
                              style: text.bodySmall),
                        ),
                      ),
                    ),
                  if (latest != null && !field.formationVisible)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppTheme.spacingMd,
                          AppTheme.spacingSm,
                          AppTheme.spacingMd,
                          0),
                      child: FieldEventCard(
                        event: latest,
                        blindActive: blindActive,
                        skepticMode: inv.skepticMode,
                        onMark: () {
                          field.markEvent(latest.id);
                          HapticFeedback.selectionClick();
                        },
                        onDismiss: () => field.dismissEvent(latest.id),
                        onReplay: latest.isFormation
                            ? () => _replay(latest)
                            : null,
                        onShare: () => showShareTrace(context, latest),
                        onClose: field.clearLatest,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      children: [
                        if (blindActive && field.events.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppTheme.spacingSm),
                            child: AppButton(
                              label: 'REVEAL TRACE',
                              icon: Icons.lock_open,
                              variant: AppButtonVariant.secondary,
                              onPressed: field.revealTrace,
                            ),
                          ),
                        AppButton(
                          label: field.pulseActive
                              ? 'PULSE ${field.pulseRemaining}s'
                              : 'PULSE',
                          icon: Icons.radio_button_checked,
                          pulse: !field.pulseActive,
                          onPressed:
                              field.state == FieldState.monitoring &&
                                      !field.pulseActive
                                  ? () {
                                      field.startPulse();
                                      HapticFeedback.mediumImpact();
                                    }
                                  : null,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        AppButton(
                          label: 'FIELD TIMELINE (${field.events.length})',
                          icon: Icons.timeline,
                          variant: AppButtonVariant.outline,
                          onPressed: () => showFieldTimeline(
                            context,
                            events: field.events.reversed.toList(),
                            blindActive: blindActive,
                            skepticMode: inv.skepticMode,
                            onReplay: _replay,
                            onShare: (e) => showShareTrace(context, e),
                          ),
                        ),
                      ],
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
