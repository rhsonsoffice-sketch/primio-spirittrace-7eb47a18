import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/investigation.dart';
import '../providers/past_investigations_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/glowing_card.dart';

class PastInvestigationsScreen extends StatelessWidget {
  const PastInvestigationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PastInvestigationsProvider>();
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(context.l10n.t('pastInvestigations')),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.investigations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: AppTheme.spacingXxl, color: appColors.subtleText),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(context.l10n.t('noInvestigations'),
                          textAlign: TextAlign.center,
                          style: text.titleMedium?.copyWith(color: appColors.subtleText)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: provider.investigations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingSm),
                  itemBuilder: (context, index) {
                    final inv = provider.investigations[index];
                    return Dismissible(
                      key: ValueKey(inv.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => confirmDeleteInvestigation(context),
                      onDismissed: (_) => provider.deleteInvestigation(inv.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          color: appColors.danger
                              .withValues(alpha: AppTheme.opacitySubtle),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline,
                                color: appColors.danger,
                                size: AppTheme.iconMd),
                            const SizedBox(width: AppTheme.spacingSm),
                            Text(context.l10n.t('delete'),
                                style: text.labelMedium
                                    ?.copyWith(color: appColors.danger)),
                          ],
                        ),
                      ),
                      child: _InvestigationCard(
                        investigation: inv,
                        patterns: provider.patternsFor(inv),
                        onTap: () =>
                            context.go('/investigation-detail/${inv.id}'),
                        onDelete: () async {
                          final ok = await confirmDeleteInvestigation(context);
                          if (ok) await provider.deleteInvestigation(inv.id);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

Future<bool> confirmDeleteInvestigation(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.t('deleteTitle')),
      content: Text(ctx.l10n.t('deleteBody')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.t('delete')),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _InvestigationCard extends StatelessWidget {
  final Investigation investigation;
  final List<PatternResult> patterns;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const _InvestigationCard({
    required this.investigation,
    required this.patterns,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final date = DateFormat('MMM d, yyyy • HH:mm').format(investigation.startTime);
    final dur = investigation.duration;
    final durStr = '${dur.inMinutes}m ${dur.inSeconds % 60}s';

    return GlowingCard(
      onTap: onTap,
      glowColor: patterns.isNotEmpty ? appColors.glow : colors.outline,
      glowIntensity: patterns.isNotEmpty ? 0.15 : 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(date, style: text.titleSmall)),
              Text(durStr, style: text.labelSmall?.copyWith(color: appColors.subtleText)),
              const SizedBox(width: AppTheme.spacingSm),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz,
                    size: AppTheme.iconMd, color: appColors.subtleText),
                onSelected: (_) => onDelete(),
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(context.l10n.t('deleteMenu')),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: AppTheme.spacingMd,
            runSpacing: AppTheme.spacingXs,
            children: [
              _Stat(label: context.l10n.t('questions'), value: '${investigation.questionCount}', text: text, color: appColors.subtleText),
              _Stat(label: context.l10n.t('responses'), value: '${investigation.responseCount}', text: text, color: appColors.glowSecondary),
              _Stat(label: context.l10n.t('repeats'), value: '${investigation.repeatResponseCount}', text: text, color: colors.secondary),
              _Stat(label: context.l10n.t('patterns'), value: '${patterns.length}', text: text, color: appColors.glow),
            ],
          ),
          if (patterns.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingXs,
              children: patterns.take(3).map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 2),
                    decoration: BoxDecoration(
                      color: appColors.glow.withOpacity(AppTheme.opacitySubtle),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text('"${p.word}" ×${p.count}',
                        style: text.labelSmall?.copyWith(color: appColors.glow)),
                  )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final TextTheme text;
  final Color color;
  const _Stat({required this.label, required this.value, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: text.titleSmall?.copyWith(color: color)),
        const SizedBox(width: AppTheme.spacingXs),
        Text(label, style: text.labelSmall),
      ],
    );
  }
}
