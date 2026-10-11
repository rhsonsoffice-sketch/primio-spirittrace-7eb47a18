import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/investigation.dart';
import '../providers/past_investigations_provider.dart';
import '../providers/pro_provider.dart';
import '../theme/theme.dart';
import 'pro_screen.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/glowing_card.dart';
import '../widgets/investigation/investigation_sheets.dart';
import '../widgets/trace_field/field_sheets.dart';

class InvestigationSummaryScreen extends StatefulWidget {
  final String investigationId;
  const InvestigationSummaryScreen({super.key, required this.investigationId});

  @override
  State<InvestigationSummaryScreen> createState() =>
      _InvestigationSummaryScreenState();
}

class _InvestigationSummaryScreenState
    extends State<InvestigationSummaryScreen> {
  Investigation? _investigation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final inv = await context
          .read<PastInvestigationsProvider>()
          .getById(widget.investigationId);
      if (mounted) setState(() => _investigation = inv);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final l10n = context.l10n;
    final isPro = context.watch<ProProvider>().isPro;

    if (_investigation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final inv = _investigation!;
    final provider = context.read<PastInvestigationsProvider>();
    final patterns = provider.patternsFor(inv);
    final connections = provider.connectionsFor(inv);
    final dur = inv.duration;
    final durStr = '${dur.inMinutes}m ${dur.inSeconds % 60}s';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            children: [
              const SizedBox(height: AppTheme.spacingLg),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      colors.primary.withValues(alpha: AppTheme.opacitySubtle),
                  border: Border.all(
                    color:
                        colors.primary.withValues(alpha: AppTheme.opacityHint),
                    width: AppTheme.borderDefault,
                  ),
                ),
                child: Icon(Icons.check,
                    size: AppTheme.iconLg, color: colors.primary),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(l10n.t('investigationComplete'),
                  textAlign: TextAlign.center, style: text.headlineSmall),
              const SizedBox(height: AppTheme.spacingXl),
              GlowingCard(
                child: Column(
                  children: [
                    _SummaryStat(
                        label: l10n.t('durationLabel'),
                        value: durStr,
                        color: colors.onSurface),
                    _SummaryStat(
                        label: l10n.t('questionsAsked'),
                        value: '${inv.questionCount}',
                        color: colors.onSurface),
                    _SummaryStat(
                        label: l10n.t('possibleResponsesLbl'),
                        value: '${inv.responseCount}',
                        color: appColors.glowSecondary),
                    _SummaryStat(
                        label: l10n.t('repeatTests'),
                        value: '${inv.repeatTestCount}',
                        color: colors.secondary),
                    _SummaryStat(
                        label: l10n.t('repeatedResponses'),
                        value: '${inv.repeatResponseCount}',
                        color: colors.secondary),
                    _SummaryStat(
                        label: l10n.t('possiblePatternsLbl'),
                        value: '${patterns.length}',
                        color: appColors.glow),
                    _SummaryStat(
                        label: l10n.t('possibleConnections'),
                        value: '${connections.length}',
                        color: appColors.glow),
                    _SummaryStat(
                        label: l10n.t('dismissedExplained'),
                        value: '${inv.dismissedCount}',
                        color: appColors.subtleText),
                    _SummaryStat(
                        label: l10n.t('investigatorNotes'),
                        value: '${inv.noteCount}',
                        color: appColors.subtleText),
                  ],
                ),
              ),
              if (inv.hasFieldData) ...[
                const SizedBox(height: AppTheme.spacingMd),
                GlowingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.t('traceField'),
                          style: text.labelMedium
                              ?.copyWith(color: appColors.glowSecondary)),
                      const SizedBox(height: AppTheme.spacingSm),
                      _SummaryStat(
                          label: l10n.t('fieldDisturbances'),
                          value: '${inv.fieldDisturbanceCount}',
                          color: colors.onSurface),
                      _SummaryStat(
                          label: l10n.t('unclassifiedEvents'),
                          value: '${inv.fieldUnclassifiedCount}',
                          color: appColors.warning),
                      _SummaryStat(
                          label: l10n.t('possibleFormations'),
                          value: '${inv.fieldFormationCount}',
                          color: appColors.glow),
                      _SummaryStat(
                          label: l10n.t('markedEvents'),
                          value: '${inv.fieldMarkedCount}',
                          color: appColors.success),
                      _SummaryStat(
                          label: l10n.t('pulseSessions'),
                          value: '${inv.fieldPulseCount}',
                          color: appColors.subtleText),
                      const SizedBox(height: AppTheme.spacingMd),
                      AppButton(
                        label: l10n.t('reviewTrace'),
                        icon: Icons.blur_on,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => showFieldTimeline(
                          context,
                          events: inv.fieldEvents.reversed.toList(),
                          blindActive: false,
                          skepticMode: inv.skepticMode,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingXl),
              AppButton(
                label: l10n.t('viewResults'),
                icon: Icons.timeline,
                onPressed: () => context.go('/investigation-detail/${inv.id}'),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              AppButton(
                label: l10n.t('exportCaseFile'),
                icon: isPro ? Icons.ios_share : Icons.lock_outline,
                variant: AppButtonVariant.secondary,
                onPressed: () => isPro
                    ? showCaseFileSheet(context, provider.caseFileFor(inv))
                    : openProScreen(context),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              AppButton(
                label: l10n.t('startNewInvestigation'),
                icon: Icons.sensors,
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/investigation'),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(l10n.t('backToHome'),
                    style:
                        text.bodyMedium?.copyWith(color: appColors.subtleText)),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                l10n.t('notVerifiedShort'),
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(
                    color: appColors.subtleText, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          const SizedBox(width: AppTheme.spacingSm),
          Text(value, style: text.titleMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}
