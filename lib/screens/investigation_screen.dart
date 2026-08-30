import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/investigation.dart';
import '../providers/investigation_provider.dart';
import '../providers/trace_field_provider.dart';
import '../services/audio_service.dart';
import '../services/investigation_service.dart';
import '../theme/theme.dart';
import 'trace_field_screen.dart';
import '../widgets/common/app_button.dart';
import '../widgets/investigation/baseline_panel.dart';
import '../widgets/investigation/investigation_sheets.dart';
import '../widgets/investigation/investigation_status_bar.dart';
import '../widgets/investigation/investigation_top_bar.dart';
import '../widgets/investigation/mode_info_dialogs.dart';
import '../widgets/investigation/pattern_card.dart';
import '../widgets/investigation/response_card.dart';
import '../widgets/investigation/session_ended_view.dart';
import '../widgets/investigation/session_ready_view.dart';
import '../widgets/investigation/timeline_item.dart';
import '../widgets/investigation/waveform_painter.dart';

class InvestigationScreen extends StatefulWidget {
  const InvestigationScreen({super.key});

  @override
  State<InvestigationScreen> createState() => _InvestigationScreenState();
}

class _InvestigationScreenState extends State<InvestigationScreen> {
  bool _baselineDismissed = false;

  Future<void> _toggleBlind() async {
    final provider = context.read<InvestigationProvider>();
    final turningOn = !provider.blindMode;
    provider.toggleBlindMode();
    HapticFeedback.selectionClick();
    if (turningOn && !provider.blindIntroSeen) {
      await showBlindModeInfo(context);
      await provider.acknowledgeBlindIntro();
    }
  }

  Future<void> _toggleSkeptic() async {
    final provider = context.read<InvestigationProvider>();
    final turningOn = !provider.skepticMode;
    provider.toggleSkepticMode();
    HapticFeedback.selectionClick();
    if (turningOn && !provider.skepticIntroSeen) {
      await showSkepticModeInfo(context);
      await provider.acknowledgeSkepticIntro();
    }
  }

  Future<void> _ask({String? prefill, String? repeatOriginalId}) async {
    final provider = context.read<InvestigationProvider>();
    final question = await showQuestionSheet(
      context,
      prefill: prefill,
      title: repeatOriginalId != null ? 'REPEAT TEST' : 'ASK A QUESTION',
    );
    if (question == null || !mounted) return;
    await provider.askQuestion(question, repeatOriginalId: repeatOriginalId);
    if (!mounted || repeatOriginalId == null) return;

    final responses = provider.investigation?.responses ?? [];
    if (responses.isEmpty) return;
    final second = responses.last;
    final first = provider.responseById(repeatOriginalId);
    if (first == null) return;
    await showComparisonSheet(
      context,
      first: first,
      second: second,
      result: provider.compareRepeat(first.id, second.id),
      onPlay: (r) => provider.playResponseAudio(r.id),
    );
  }

  Future<void> _mark(QuestionResponse r) async {
    final provider = context.read<InvestigationProvider>();
    final status = await showStatusSheet(context, current: r.status);
    if (status == null) return;
    provider.setStatus(r.id, status);
    HapticFeedback.selectionClick();
  }

  Future<void> _note(QuestionResponse r) async {
    final provider = context.read<InvestigationProvider>();
    final note = await showNoteSheet(context, initial: r.note);
    if (note == null) return;
    provider.setNote(r.id, note);
  }

  Future<void> _openPattern(PatternResult pattern) async {
    final provider = context.read<InvestigationProvider>();
    await showOccurrencesSheet(
      context,
      pattern: pattern,
      occurrences: provider.occurrencesOf(pattern),
      onPlay: (r) => provider.playResponseAudio(r.id),
    );
  }

  Future<void> _openTraceField() async {
    final provider = context.read<InvestigationProvider>();
    final inv = provider.investigation;
    if (inv == null) return;
    final service = context.read<InvestigationService>();
    final audio = context.read<AudioService>();
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<InvestigationProvider>.value(
              value: provider,
            ),
            ChangeNotifierProvider(
              create: (_) => TraceFieldProvider(
                service: service,
                audioService: audio,
                investigation: inv,
              ),
            ),
          ],
          child: const TraceFieldScreen(),
        ),
      ),
    );
  }

  Future<void> _stop() async {
    await context.read<InvestigationProvider>().stopInvestigation();
    HapticFeedback.mediumImpact();
  }

  Future<void> _save() async {
    final provider = context.read<InvestigationProvider>();
    final inv = await provider.saveCurrentInvestigation();
    if (!mounted || inv == null) return;
    context.go('/investigation-summary/${inv.id}');
  }

  Future<void> _discard() async {
    final provider = context.read<InvestigationProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DISCARD INVESTIGATION?'),
        content: const Text(
          'This session will not be saved and cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DISCARD'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.discardCurrentInvestigation();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvestigationProvider>();
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final micUnavailable =
        !provider.speechAvailable && provider.audioInitialized;

    final topBar = InvestigationTopBar(
      blindMode: provider.blindMode,
      skepticMode: provider.skepticMode,
      micUnavailable: micUnavailable,
      sessionActive: provider.isActive,
      onToggleBlind: _toggleBlind,
      onToggleSkeptic: _toggleSkeptic,
      onBlindInfo: () => showBlindModeInfo(context),
      onSkepticInfo: () => showSkepticModeInfo(context),
      onStop: _stop,
      onExit: provider.isActive ? null : () => context.go('/'),
    );

    Widget body;
    if (provider.session == SessionState.ready) {
      body = Column(
        children: [
          topBar,
          const WaveformDisplay(isActive: false, intensity: 0.25),
          Expanded(
            child: SessionReadyView(
              micUnavailable: micUnavailable,
              onStart: () {
                provider.startInvestigation();
                HapticFeedback.mediumImpact();
              },
            ),
          ),
        ],
      );
    } else if (provider.session == SessionState.ended) {
      final inv = provider.investigation;
      body = Column(
        children: [
          topBar,
          Expanded(
            child: inv == null
                ? const SizedBox.shrink()
                : SessionEndedView(
                    investigation: inv,
                    patternCount: provider.patterns.length,
                    blindMode: provider.blindMode,
                    skepticMode: provider.skepticMode,
                    onSave: _save,
                    onDiscard: _discard,
                  ),
          ),
        ],
      );
    } else {
      final isScanning = provider.phase == InvestigationPhase.scanning;
      final isBaseline = provider.phase == InvestigationPhase.baseline;
      final responses = provider.investigation?.responses ?? [];
      final showBaseline =
          !provider.hasBaseline && !_baselineDismissed && responses.isEmpty;

      body = Column(
        children: [
          topBar,
          WaveformDisplay(
            isActive: isScanning || isBaseline,
            intensity: isScanning ? 1.0 : (isBaseline ? 0.6 : 0.3),
          ),
          InvestigationStatusBar(
            status: isScanning
                ? 'SCANNING'
                : isBaseline
                    ? 'BASELINE SCAN'
                    : 'INVESTIGATION ACTIVE',
            active: true,
            timerLabel: provider.elapsedLabel,
            liveText: provider.blindMode ? '' : provider.liveText,
            level: provider.currentLevel,
            baselineLevel:
                provider.blindMode ? null : provider.investigation?.baselineLevel,
            listening: provider.speechAvailable,
          ),
          if (showBaseline || isBaseline)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: BaselinePanel(
                running: isBaseline,
                secondsRemaining: provider.baselineRemaining,
                progress: provider.baselineProgress,
                onStart: provider.startBaselineScan,
                onSkip: () => setState(() => _baselineDismissed = true),
                onCancel: provider.cancelBaselineScan,
              ),
            ),
          if (provider.patterns.isNotEmpty && !provider.blindMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spacingMd,
                  AppTheme.spacingSm, AppTheme.spacingMd, 0),
              child: PatternCard(
                patterns: provider.patterns,
                connections: provider.connections,
                onPatternTap: _openPattern,
                onInvestigate: (p) => _ask(
                  prefill: provider.suggestedQuestionFor(p.word),
                ),
              ),
            ),
          if (provider.blindMode && provider.patterns.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingXs),
              child: Text(
                'PATTERN ANALYSIS HIDDEN WHILE BLIND MODE IS ACTIVE',
                style: text.labelSmall?.copyWith(color: appColors.warning),
              ),
            ),
          Expanded(
            child: responses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Text(
                        'Ask a question to open a response window',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium
                            ?.copyWith(color: appColors.subtleText),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm),
                    itemCount: responses.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final r = responses[responses.length - 1 - index];
                      final comparison =
                          r.isRepeatTest && r.repeatTestOriginalId != null
                              ? provider.compareRepeat(
                                  r.repeatTestOriginalId!, r.id)
                              : null;
                      return TimelineConnector(
                        hasResponse: r.hasResponse,
                        isFirst: index == 0,
                        isLast: index == responses.length - 1,
                        child: ResponseCard(
                          response: r,
                          comparison: provider.blindMode ? null : comparison,
                          isRepeated: !provider.blindMode &&
                              comparison == RepeatComparison.repeated,
                          environmentalChange: provider.isEnvironmentalChange(r),
                          expandDetails: provider.skepticMode,
                          skepticMode: provider.skepticMode,
                          blindActive: provider.blindMode,
                          onReveal: () => provider.revealResponse(r.id),
                          onPlay: () => provider.playResponseAudio(r.id),
                          onMark: () => _mark(r),
                          onNote: () => _note(r),
                          onRepeatTest: r.hasResponse
                              ? () => _ask(
                                    prefill: r.question,
                                    repeatOriginalId: r.id,
                                  )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              children: [
                isScanning
                    ? AppButton(
                        label: 'SCANNING... ${provider.scanTimeRemaining}s',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.sensors,
                        onPressed: null,
                      )
                    : AppButton(
                        label: 'ASK QUESTION',
                        icon: Icons.mic,
                        onPressed: isBaseline ? null : () => _ask(),
                      ),
                const SizedBox(height: AppTheme.spacingSm),
                AppButton(
                  label: 'TRACE FIELD',
                  icon: Icons.blur_on,
                  variant: AppButtonVariant.outline,
                  onPressed:
                      isScanning || isBaseline ? null : _openTraceField,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingXs),
                  child: Text(
                    'Watch the environment for unusual patterns and interactions.',
                    textAlign: TextAlign.center,
                    style: text.labelSmall
                        ?.copyWith(color: appColors.subtleText),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(body: SafeArea(child: body));
  }
}
