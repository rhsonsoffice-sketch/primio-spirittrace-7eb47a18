import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/trace_memory_provider.dart';
import '../repositories/investigation_repository.dart';
import '../theme/theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/home/global_intro_card.dart';
import '../widgets/home/language_indicator.dart';
import '../widgets/home/live_trace_strip.dart';
import '../widgets/home/particle_background.dart';
import '../widgets/home/system_status_cycler.dart';
import '../widgets/home/trace_memory_panel.dart';
import '../widgets/home/trace_scanner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _introFlag = 'global_intro_seen';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowIntro());
  }

  Future<void> _maybeShowIntro() async {
    final repo = context.read<InvestigationRepository>();
    if (await repo.getFlag(_introFlag)) return;
    if (!mounted) return;
    await showGlobalIntroCard(context);
    await repo.setFlag(_introFlag, true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final stats = context.watch<TraceMemoryProvider>().stats;
    final l10n = context.l10n;

    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingLg,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => context.go('/settings'),
                      icon: Icon(Icons.settings_outlined,
                          size: AppTheme.iconMd, color: appColors.subtleText),
                      tooltip: l10n.t('settings'),
                    ),
                    const Spacer(),
                    const Flexible(child: LanguageIndicator()),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text('SPIRIT TRACE', style: text.headlineMedium),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  l10n.t('appSubtitle'),
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    color: appColors.subtleText,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                const TraceScanner(),
                const SizedBox(height: AppTheme.spacingMd),
                const SystemStatusCycler(),
                const SizedBox(height: AppTheme.spacingLg),
                const LiveTraceStrip(),
                const SizedBox(height: AppTheme.spacingMd),
                TraceMemoryPanel(
                  stats: stats,
                  onTap: () => context.go('/past-investigations'),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                AppButton(
                  label: l10n.t('startInvestigation'),
                  icon: Icons.sensors,
                  pulse: true,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.go('/investigation');
                  },
                ),
                const SizedBox(height: AppTheme.spacingMd),
                AppButton(
                  label: l10n.t('pastInvestigations'),
                  icon: Icons.history,
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.go('/past-investigations'),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Text(
                  l10n.t('disclaimer'),
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(
                    color: appColors.subtleText,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
