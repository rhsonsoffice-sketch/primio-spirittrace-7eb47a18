import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/investigation.dart';
import '../providers/past_investigations_provider.dart';
import '../theme/theme.dart';
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
        title: const Text('CASE FILE'),
        actions: [
          IconButton(
            tooltip: 'Export / share case file',
            icon: const Icon(Icons.ios_share),
            onPressed: () =>
                showCaseFileSheet(context, provider.caseFileFor(inv)),
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
              Text('${inv.questionCount} questions', style: text.bodySmall),
              Text('${inv.responseCount} possible responses',
                  style: text.bodySmall
                      ?.copyWith(color: appColors.glowSecondary)),
              Text('${inv.repeatTestCount} repeat tests', style: text.bodySmall),
              Text('${patterns.length} patterns',
                  style: text.bodySmall?.copyWith(color: appColors.glow)),
              Text('${inv.dismissedCount} dismissed/explained',
                  style: text.bodySmall
                      ?.copyWith(color: appColors.subtleText)),
              Text(
                inv.hasBaseline
                    ? 'Baseline ${inv.baselineLevel?.toStringAsFixed(1) ?? "—"}'
                    : 'No baseline recorded',
                style: text.bodySmall?.copyWith(color: appColors.subtleText),
              ),
            ],
          ),
          if (patterns.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            PatternCard(
              patterns: patterns,
              connections: connections,
              onPatternTap: (p) => showOccurrencesSheet(
                context,
                pattern: p,
                occurrences: provider.occurrencesFor(inv, p),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingLg),
          Text('INVESTIGATION REPLAY', style: text.labelLarge),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Recorded audio and the app\'s interpretation of it, in order.',
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
