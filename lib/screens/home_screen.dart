import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/trace_memory_provider.dart';
import '../repositories/investigation_repository.dart';
import '../services/purchase_service.dart';
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
WidgetsBinding.instance
.addPostFrameCallback((_) => _maybeShowIntro());
}

Future<void> _maybeShowIntro() async {
final repo = context.read<InvestigationRepository>();

if (await repo.getFlag(_introFlag)) {
return;
}

if (!mounted) {
return;
}

await showGlobalIntroCard(context);
await repo.setFlag(_introFlag, true);
}

@override
Widget build(BuildContext context) {
final text = Theme.of(context).textTheme;

final appColors =
Theme.of(context).extension<AppColorsExtension>()!;

final stats =
context.watch<TraceMemoryProvider>().stats;

final purchase =
context.watch<PurchaseService>();

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
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
IconButton(
onPressed: () =>
context.go('/settings'),
icon: Icon(
Icons.settings_outlined,
size: AppTheme.iconMd,
color: appColors.subtleText,
),
tooltip: l10n.t('settings'),
),
const Spacer(),
const Flexible(
child: LanguageIndicator(),
),
],
),

const SizedBox(
height: AppTheme.spacingSm,
),

Text(
'SPIRIT TRACE',
style: text.headlineMedium,
),

const SizedBox(
height: AppTheme.spacingXs,
),

Text(
l10n.t('appSubtitle'),
textAlign: TextAlign.center,
style: text.bodySmall?.copyWith(
color: appColors.subtleText,
letterSpacing: 1.0,
),
),

const SizedBox(
height: AppTheme.spacingMd,
),

const TraceScanner(),

const SizedBox(
height: AppTheme.spacingMd,
),

const SystemStatusCycler(),

const SizedBox(
height: AppTheme.spacingLg,
),

const LiveTraceStrip(),

const SizedBox(
height: AppTheme.spacingMd,
),

TraceMemoryPanel(
stats: stats,
onTap: () =>
context.go('/past-investigations'),
),

const SizedBox(
height: AppTheme.spacingMd,
),

// --------------------------------------
// SPIRIT TRACE PRO
// --------------------------------------
if (!purchase.isPro)
Container(
width: double.infinity,
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
borderRadius:
BorderRadius.circular(18),
border: Border.all(
color: Theme.of(context)
.colorScheme
.primary
.withOpacity(0.45),
width: 1,
),
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
Theme.of(context)
.colorScheme
.primary
.withOpacity(0.12),
Theme.of(context)
.colorScheme
.secondary
.withOpacity(0.06),
],
),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(
Icons.auto_awesome,
color: Theme.of(context)
.colorScheme
.primary,
size: 22,
),
const SizedBox(width: 10),
Expanded(
child: Text(
'SPIRIT TRACE PRO',
style: text.titleMedium?.copyWith(
color: Theme.of(context)
.colorScheme
.primary,
fontWeight:
FontWeight.w700,
letterSpacing: 1.2,
),
),
),
],
),

const SizedBox(height: 10),

Text(
'Unlock the full Trace system.',
style: text.bodyMedium?.copyWith(
fontWeight:
FontWeight.w600,
),
),

const SizedBox(height: 8),

Text(
'Trace Memory • Pattern Detection • '
'Connections • Repeat Testing • '
'Trace Pulse • Full Case Files',
style: text.bodySmall?.copyWith(
color:
appColors.subtleText,
height: 1.5,
),
),

const SizedBox(height: 14),

Row(
children: [
Expanded(
child: Text(
'ONE-TIME £3.99',
style: text.labelLarge?.copyWith(
fontWeight:
FontWeight.w700,
),
),
),

const SizedBox(width: 12),

SizedBox(
height: 44,
child: FilledButton(
onPressed:
purchase.isLoading
? null
: () async {
HapticFeedback
.mediumImpact();

await purchase
.buyPro();
},
child: Text(
purchase.isLoading
? 'LOADING...'
: 'UNLOCK PRO',
),
),
),
],
),
],
),
),

if (!purchase.isPro)
const SizedBox(
height: AppTheme.spacingLg,
),

// --------------------------------------
// START INVESTIGATION
// --------------------------------------
AppButton(
label:
l10n.t('startInvestigation'),
icon: Icons.sensors,
pulse: true,
onPressed: () {
HapticFeedback.mediumImpact();
context.go('/investigation');
},
),

const SizedBox(
height: AppTheme.spacingMd,
),

AppButton(
label:
l10n.t('pastInvestigations'),
icon: Icons.history,
variant:
AppButtonVariant.outline,
onPressed: () => context.go(
'/past-investigations',
),
),

const SizedBox(
height: AppTheme.spacingLg,
),

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

