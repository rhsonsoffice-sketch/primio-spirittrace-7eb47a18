import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/investigation.dart';
import '../providers/past_investigations_provider.dart';
import '../providers/pro_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/pro_lock_card.dart';
import 'pro_screen.dart';
import '../widgets/investigation/investigation_sheets.dart';
import '../widgets/investigation/pattern_card.dart';
import '../widgets/investigation/response_card.dart';
import '../widgets/investigation/timeline_item.dart';

class InvestigationDetailScreen extends StatefulWidget {
  final String investigationId;
  const InvestigationDetailScreen({super.key, required this.investigationId});

  @override
  State<InvestigationDetailScreen> createState() =>
      _InvestigationDetailScreenState();
}

class _InvestigationDetailScreenState extends State<InvestigationDetailScreen> {
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
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final provider = context.read<PastInvestigationsProvider>();
    final l10n = context.l10n;
    final isPro = context.watch<ProProvider>().isPro;

    if (_investigation == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final inv = _investigation!;
    final patterns = provider.patternsFor(inv);
    final connections = provider.connectionsFor(inv);
    final date = DateFormat('MMM d, yyyy • HH:mm').format(inv.startTime);
    final dur = inv.duration;
    final durStr = '${dur.inMinutes}m ${dur.inSeconds % 60}s';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/past-investigations'),
        ),
        title: Text(l10n.t('caseFile')),
        actions: [
          IconButton(
            tooltip: l10n.t('exportTooltip'),
            icon: Icon(isPro ? Icons.ios_share : Icons.lock_outline),
            onPressed: () => isPro
                ? showCaseFileSheet(context, provider.caseFileFor(inv))
                : openProScreen(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          Row(
            children: [
              Expanded(child: Text(date, style: text.titleSmall)),
              Text(durStr,
                  style:
                      text.labelMedium?.copyWith(color: appColors.subtleText)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: AppTheme.spacingMd,
            runSpacing: AppTheme.spacingXs,
            children: [
              Text('${inv.questionCount} ${l10n.t('questionsWord')}',
                  style: text.bodySmall),
              Text('${inv.responseCount} ${l10n.t('responsesWord')}',
                  style: text.bodySmall
                      ?.copyWith(color: appColors.glowSecondary)),
              Text('${inv.repeatTestCount} ${l10n.t('repeatTestsWord')}',
                  style: text.bodySmall),
              Text('${patterns.length} ${l10n.t('patternsWord')}',
                  style: text.bodySmall?.copyWith(color: appColors.glow)),
              Text('${inv.dismissedCount} ${l10n.t('dismissedWord')}',
                  style: text.bodySmall
                      ?.copyWith(color: appColors.subtleText)),
              Text(
                inv.hasBaseline
                    ? '${l10n.t('baselineWord')} ${inv.baselineLevel?.toStringAsFixed(1) ?? "—"}'
                    : l10n.t('noBaseline'),
                style: text.bodySmall?.copyWith(color: appColors.subtleText),
              ),
            ],
          ),
          if (patterns.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            if (isPro)
              PatternCard(
                patterns: patterns,
                connections: connections,
                onPatternTap: (p) => showOccurrencesSheet(
                  context,
                  pattern: p,
                  occurrences: provider.occurrencesFor(inv, p),
                ),
              )
            else
              ProLockCard(
                title: l10n.t('proBenefitPatterns'),
                onTap: () => openProScreen(context),
              ),
          ],
          const SizedBox(height: AppTheme.spacingLg),
          Text(l10n.t('investigationReplay'), style: text.labelLarge),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            l10n.t('replaySubtitle'),
            style: text.labelSmall?.copyWith(color: appColors.subtleText),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...List.generate(inv.responses.length, (i) {
            final r = inv.responses[i];
            final recurring = patterns.any(
              (p) => p.responseIds.contains(r.id),
            );
            return TimelineConnector(
              hasResponse: r.hasResponse,
              isFirst: i == 0,
              isLast: i == inv.responses.length - 1,
              child: ResponseCard(
                response: r.copyWith(revealed: true),
                isRepeated: recurring,
                expandDetails: true,
                environmentalChange: provider.isEnvironmentalChange(inv, r),
              ),
            );
          }),
        ],
      ),
    );
  }
}
