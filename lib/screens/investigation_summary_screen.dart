import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/investigation.dart';
import '../providers/past_investigations_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/glowing_card.dart';
import '../widgets/investigation/investigation_sheets.dart';
import '../widgets/trace_field/field_sheets.dart';

class InvestigationSummaryScreen extends StatefulWidget {
final String investigationId;

const InvestigationSummaryScreen({
super.key,
required this.investigationId,
});

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

if (mounted) {
setState(() {
_investigation = inv;
});
}
});
}

Future<void> _showProRequired() async {
await showDialog<void>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('SPIRIT TRACE PRO'),
content: const Text(
'This analysis is available with SPIRIT TRACE PRO for £3.99.\n\n'
'PRO unlocks pattern detection, connections, full case files '
'and advanced investigation analysis.',
),
actions: [
TextButton(
onPressed: () {
Navigator.of(dialogContext).pop();
},
child: const Text('CLOSE'),
),
TextButton(
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
final colors = Theme.of(context).colorScheme;
final appColors =
Theme.of(context).extension<AppColorsExtension>()!;

if (_investigation == null) {
return const Scaffold(
body: Center(
child: CircularProgressIndicator(),
),
);
}

final inv = _investigation!;
final provider =
context.read<PastInvestigationsProvider>();

final patterns =
provider.patternsFor(context, inv);

final connections =
provider.connectionsFor(context, inv);

final caseFile =
provider.caseFileFor(context, inv);

final dur = inv.duration;

final durStr =
'${dur.inMinutes}m ${dur.inSeconds % 60}s';

return Scaffold(
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(
AppTheme.spacingLg,
),
child: Column(
children: [
const SizedBox(
height: AppTheme.spacingLg,
),

Container(
width: 72,
height: 72,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: colors.primary.withOpacity(
AppTheme.opacitySubtle,
),
border: Border.all(
color: colors.primary.withOpacity(
0.3,
),
),
boxShadow: [
BoxShadow(
color: colors.primary.withOpacity(
0.2,
),
blurRadius: 24,
),
],
),
child: Icon(
Icons.check,
size: AppTheme.iconLg,
color: colors.primary,
),
),

const SizedBox(
height: AppTheme.spacingLg,
),

Text(
'INVESTIGATION COMPLETE',
style: text.headlineSmall,
),

const SizedBox(
height: AppTheme.spacingXl,
),

// ----------------------------------------------------------------
// BASIC INVESTIGATION SUMMARY
// ----------------------------------------------------------------

GlowingCard(
child: Column(
children: [
_SummaryStat(
label: 'Duration',
value: durStr,
text: text,
color: colors.onSurface,
),

const SizedBox(
height: AppTheme.spacingSm,
),

_SummaryStat(
label: 'Questions Asked',
value: '${inv.questionCount}',
text: text,
color: colors.onSurface,
),

const SizedBox(
height: AppTheme.spacingSm,
),

_SummaryStat(
label: 'Possible Responses',
value: '${inv.responseCount}',
text: text,
color: appColors.glowSecondary,
),

const SizedBox(
height: AppTheme.spacingSm,
),

_SummaryStat(
label: 'Repeat Tests',
value: '${inv.repeatTestCount}',
text: text,
color: colors.secondary,
),

const SizedBox(
height: AppTheme.spacingSm,
),

_SummaryStat(
label: 'Repeated Responses',
value: '${inv.repeatResponseCount}',
text: text,
color: colors.secondary,
),

const SizedBox(
height: AppTheme.spacingSm,
),

// PRO analysis
if (provider.patternsFor(context, inv).isNotEmpty)
_SummaryStat(
label: 'Possible Patterns',
value: '${patterns.length}',
text: text,
color: appColors.glow,
)
else
_SummaryStat(
label: 'Possible Patterns',
value: provider
.patternsFor(context, inv)
.isEmpty
? 'PRO'
: '${patterns.length}',
text: text,
color: appColors.glow,
),

const SizedBox(
height: AppTheme.spacingSm,
),

if (provider.connectionsFor(context, inv)
.isNotEmpty)
_SummaryStat(
label: 'Possible Connections',
value: '${connections.length}',
text: text,
color: appColors.glow,
)
else
_SummaryStat(
label: 'Possible Connections',
value: 'PRO',
text: text,
color: appColors.glow,
),

const SizedBox(
height: AppTheme.spacingSm,
),

_SummaryStat(
label: 'Dismissed / Explained',
value: '${inv.dismissedCount}',
text: text,
color: appColors.subtleText,
),

const SizedBox(
height: AppTheme.spacingSm,
),

_SummaryStat(
label: 'Investigator Notes',
value: '${inv.noteCount}',
text: text,
color: appColors.subtleText,
),
],
),
),

// ----------------------------------------------------------------
// TRACE FIELD
// ----------------------------------------------------------------

if (inv.hasFieldData) ...[
const SizedBox(
height: AppTheme.spacingMd,
),

GlowingCard(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'TRACE FIELD',
style: text.labelMedium?.copyWith(
color: appColors.glowSecondary,
),
),

const SizedBox(
height: AppTheme.spacingSm,
),

_SummaryStat(
label: 'Field Disturbances',
value:
'${inv.fieldDisturbanceCount}',
text: text,
color: colors.onSurface,
),

const SizedBox(
height: AppTheme.spacingSm,
),

_SummaryStat(
label: 'Unclassified Events',
value:
'${inv.fieldUnclassifiedCount}',
text: text,
color: appColors.warning,
),

const SizedBox(
height: AppTheme.spacingSm,
),

_SummaryStat(
label: 'Possible Formations',
value:
'${inv.fieldFormationCount}',
text: text,
color: appColors.glow,
),

const SizedBox(
height: AppTheme.spacingSm,
),

_SummaryStat(
label: 'Marked Events',
value:
'${inv.fieldMarkedCount}',
text: text,
color: appColors.success,
),

const SizedBox(
height: AppTheme.spacingSm,
),

_SummaryStat(
label: 'Pulse Sessions',
value:
'${inv.fieldPulseCount}',
text: text,
color: appColors.subtleText,
),

const SizedBox(
height: AppTheme.spacingMd,
),

AppButton(
label: 'REVIEW TRACE',
icon: Icons.blur_on,
variant:
AppButtonVariant.secondary,
onPressed: () =>
showFieldTimeline(
context,
events: inv.fieldEvents
.reversed
.toList(),
blindActive: false,
skepticMode:
inv.skepticMode,
),
),
],
),
),
],

const SizedBox(
height: AppTheme.spacingXl,
),

// ----------------------------------------------------------------
// RESULTS
// ----------------------------------------------------------------

AppButton(
label: 'VIEW RESULTS',
icon: Icons.timeline,
onPressed: () => context.go(
'/investigation-detail/${inv.id}',
),
),

const SizedBox(
height: AppTheme.spacingMd,
),

// ----------------------------------------------------------------
// CASE FILE — PRO
// ----------------------------------------------------------------

AppButton(
label: 'EXPORT / SHARE CASE FILE',
icon: Icons.ios_share,
variant:
AppButtonVariant.secondary,
onPressed: caseFile != null
? () => showCaseFileSheet(
context,
caseFile,
)
: _showProRequired,
),

const SizedBox(
height: AppTheme.spacingMd,
),

AppButton(
label: 'START NEW INVESTIGATION',
icon: Icons.sensors,
variant:
AppButtonVariant.outline,
onPressed: () =>
context.go('/investigation'),
),

const SizedBox(
height: AppTheme.spacingMd,
),

TextButton(
onPressed: () => context.go('/'),
child: Text(
'Back to Home',
style: text.bodyMedium?.copyWith(
color: appColors.subtleText,
),
),
),

const SizedBox(
height: AppTheme.spacingMd,
),

Text(
'Results are not scientifically verified.',
style: text.labelSmall?.copyWith(
color: appColors.subtleText,
fontStyle: FontStyle.italic,
),
),

const SizedBox(
height: AppTheme.spacingLg,
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
final TextTheme text;
final Color color;

const _SummaryStat({
required this.label,
required this.value,
required this.text,
required this.color,
});

@override
Widget build(BuildContext context) {
return Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
Flexible(
child: Text(
label,
style: text.bodyMedium,
),
),
const SizedBox(width: 12),
Text(
value,
style: text.titleMedium?.copyWith(
color: color,
),
),
],
);
}
}

