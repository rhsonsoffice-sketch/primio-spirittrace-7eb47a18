import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/investigation.dart';
import '../providers/past_investigations_provider.dart';
import '../services/purchase_service.dart';
import '../theme/theme.dart';
import '../widgets/investigation/investigation_sheets.dart';
import '../widgets/investigation/pattern_card.dart';
import '../widgets/investigation/response_card.dart';
import '../widgets/investigation/timeline_item.dart';

class InvestigationDetailScreen extends StatefulWidget {
final String investigationId;

const InvestigationDetailScreen({
super.key,
required this.investigationId,
});

@override
State<InvestigationDetailScreen> createState() =>
_InvestigationDetailScreenState();
}

class _InvestigationDetailScreenState
extends State<InvestigationDetailScreen> {
Investigation? _investigation;

@override
void initState() {
super.initState();

WidgetsBinding.instance.addPostFrameCallback((_) async {
final inv = await context
.read<PastInvestigationsProvider>()
.getById(widget.investigationId);

if (mounted) {
setState(() => _investigation = inv);
}
});
}

void _showProRequired(String feature) {
showDialog<void>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('SPIRIT TRACE PRO'),
content: Text(
'$feature is part of the full SPIRIT TRACE analysis system.\n\n'
'Upgrade to PRO to unlock advanced pattern detection, '
'connections, repeatability analysis and full case files.',
),
actions: [
TextButton(
onPressed: () => Navigator.of(dialogContext).pop(),
child: const Text('CLOSE'),
),
FilledButton(
onPressed: () {
Navigator.of(dialogContext).pop();
context.go('/settings');
},
child: const Text('VIEW PRO'),
),
],
);
},
);
}

@override
Widget build(BuildContext context) {
final text = Theme.of(context).textTheme;
final appColors =
Theme.of(context).extension<AppColorsExtension>()!;

final provider = context.read<PastInvestigationsProvider>();
final purchase = context.watch<PurchaseService>();

if (_investigation == null) {
return Scaffold(
appBar: AppBar(
leading: const BackButton(),
),
body: const Center(
child: CircularProgressIndicator(),
),
);
}

final inv = _investigation!;

// PREMIUM ANALYSIS
final patterns = purchase.isPro
? provider.patternsFor(context, inv)
: <PatternResult>[];

final connections = purchase.isPro
? provider.connectionsFor(context, inv)
: <ConnectionResult>[];

final date =
DateFormat('MMM d, yyyy • HH:mm').format(inv.startTime);

final dur = inv.duration;
final durStr =
'${dur.inMinutes}m ${dur.inSeconds % 60}s';

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
onPressed: () {
if (!purchase.isPro) {
_showProRequired('Full Case File export');
return;
}

final caseFile =
provider.caseFileFor(context, inv);

if (caseFile == null) {
_showProRequired('Full Case File export');
return;
}

showCaseFileSheet(
context,
caseFile,
);
},
),
],
),
body: ListView(
padding: const EdgeInsets.all(AppTheme.spacingMd),
children: [
Row(
children: [
Expanded(
child: Text(
date,
style: text.titleSmall,
),
),
Text(
durStr,
style: text.labelMedium?.copyWith(
color: appColors.subtleText,
),
),
],
),

const SizedBox(height: AppTheme.spacingSm),

Wrap(
spacing: AppTheme.spacingMd,
runSpacing: AppTheme.spacingXs,
children: [
Text(
'${inv.questionCount} questions',
style: text.bodySmall,
),
Text(
'${inv.responseCount} possible responses',
style: text.bodySmall?.copyWith(
color: appColors.glowSecondary,
),
),
Text(
'${inv.repeatTestCount} repeat tests',
style: text.bodySmall,
),
Text(
purchase.isPro
? '${patterns.length} patterns'
: 'Patterns • PRO',
style: text.bodySmall?.copyWith(
color: purchase.isPro
? appColors.glow
: appColors.subtleText,
),
),
Text(
'${inv.dismissedCount} dismissed/explained',
style: text.bodySmall?.copyWith(
color: appColors.subtleText,
),
),
Text(
inv.hasBaseline
? 'Baseline ${inv.baselineLevel?.toStringAsFixed(1) ?? "—"}'
: 'No baseline recorded',
style: text.bodySmall?.copyWith(
color: appColors.subtleText,
),
),
],
),

// ----------------------------------------------------------
// PRO: PATTERN DETECTION + CONNECTIONS
// ----------------------------------------------------------

if (purchase.isPro && patterns.isNotEmpty) ...[
const SizedBox(height: AppTheme.spacingMd),

PatternCard(
patterns: patterns,
connections: connections,
onPatternTap: (p) => showOccurrencesSheet(
context,
pattern: p,
occurrences: provider.occurrencesFor(
context,
inv,
p,
),
),
),
],

if (!purchase.isPro) ...[
const SizedBox(height: AppTheme.spacingMd),

InkWell(
borderRadius: BorderRadius.circular(16),
onTap: () => _showProRequired(
'Pattern Detection and Connections',
),
child: Container(
padding: const EdgeInsets.all(
AppTheme.spacingMd,
),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: appColors.glow.withOpacity(0.35),
),
),
child: Row(
children: [
Icon(
Icons.lock_outline,
color: appColors.glow,
),
const SizedBox(width: AppTheme.spacingMd),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'PATTERN DETECTION',
style: text.labelLarge,
),
const SizedBox(height: 4),
Text(
'Repeated words, patterns and possible '
'connections are available with PRO.',
style: text.bodySmall?.copyWith(
color: appColors.subtleText,
),
),
],
),
),
Icon(
Icons.chevron_right,
color: appColors.subtleText,
),
],
),
),
),
],

const SizedBox(height: AppTheme.spacingLg),

Text(
'INVESTIGATION REPLAY',
style: text.labelLarge,
),

const SizedBox(height: AppTheme.spacingXs),

Text(
'Recorded audio and the app\'s interpretation of it, in order.',
style: text.labelSmall?.copyWith(
color: appColors.subtleText,
),
),

const SizedBox(height: AppTheme.spacingSm),

...List.generate(
inv.responses.length,
(i) {
final r = inv.responses[i];

final recurring = purchase.isPro &&
patterns.any(
(p) => p.responseIds.contains(r.id),
);

final environmentalChange =
purchase.isPro
? provider.isEnvironmentalChange(
context,
inv,
r,
)
: false;

return TimelineConnector(
hasResponse: r.hasResponse,
isFirst: i == 0,
isLast: i == inv.responses.length - 1,
child: ResponseCard(
response: r.copyWith(
revealed: true,
),
isRepeated: recurring,
expandDetails: true,
environmentalChange:
environmentalChange,
),
);
},
),

const SizedBox(height: AppTheme.spacingLg),

// ----------------------------------------------------------
// PRO INFORMATION
// ----------------------------------------------------------

if (!purchase.isPro) ...[
Container(
padding: const EdgeInsets.all(
AppTheme.spacingMd,
),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: appColors.glow.withOpacity(0.3),
),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(
Icons.lock_outline,
color: appColors.glow,
),
const SizedBox(width: 10),
Text(
'FULL ANALYSIS',
style: text.labelLarge,
),
],
),
const SizedBox(height: 10),
Text(
'SPIRIT TRACE PRO analyses your investigation '
'for repeated responses, patterns, connections, '
'repeatability and environmental changes.',
style: text.bodySmall?.copyWith(
color: appColors.subtleText,
),
),
const SizedBox(height: 14),
SizedBox(
width: double.infinity,
child: FilledButton(
onPressed: () => context.go('/settings'),
child: const Text('UNLOCK SPIRIT TRACE PRO'),
),
),
],
),
),
],
],
),
);
}
}

