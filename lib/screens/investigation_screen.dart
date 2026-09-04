import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/investigation.dart';
import '../providers/investigation_provider.dart';
import '../providers/trace_field_provider.dart';
import '../services/audio_service.dart';
import '../services/investigation_service.dart';
import '../services/purchase_service.dart';
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
import '../widgets/investigation/waveform_painter.dart';

class InvestigationScreen extends StatefulWidget {
const InvestigationScreen({super.key});

@override
State<InvestigationScreen> createState() =>
_InvestigationScreenState();
}

class _InvestigationScreenState
extends State<InvestigationScreen> {
bool _baselineDismissed = false;

Future<void> _toggleBlind() async {
final provider =
context.read<InvestigationProvider>();

final turningOn = !provider.blindMode;

provider.toggleBlindMode();
HapticFeedback.selectionClick();

if (turningOn && !provider.blindIntroSeen) {
await showBlindModeInfo(context);
await provider.acknowledgeBlindIntro();
}
}

Future<void> _toggleSkeptic() async {
final provider =
context.read<InvestigationProvider>();

final turningOn = !provider.skepticMode;

provider.toggleSkepticMode();
HapticFeedback.selectionClick();

if (turningOn && !provider.skepticIntroSeen) {
await showSkepticModeInfo(context);
await provider.acknowledgeSkepticIntro();
}
}

Future<void> _ask({
String? prefill,
String? repeatOriginalId,
}) async {
final provider =
context.read<InvestigationProvider>();

final question = await showQuestionSheet(
context,
prefill: prefill,
title: repeatOriginalId != null
? 'REPEAT TEST'
: 'ASK A QUESTION',
);

if (question == null || !mounted) {
return;
}

await provider.askQuestion(
question,
repeatOriginalId: repeatOriginalId,
);
}

Future<void> _openPattern(
PatternResult pattern,
) async {
final provider =
context.read<InvestigationProvider>();

await showOccurrencesSheet(
context,
pattern: pattern,
occurrences: provider.occurrencesOf(pattern),
onPlay: (response) {
provider.playResponseAudio(response.id);
},
);
}

Future<void> _openTraceField() async {
final provider =
context.read<InvestigationProvider>();

final inv = provider.investigation;

if (inv == null) {
return;
}

final service =
context.read<InvestigationService>();

final audio =
context.read<AudioService>();

final purchase =
context.read<PurchaseService>();

HapticFeedback.mediumImpact();

await Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => MultiProvider(
providers: [
ChangeNotifierProvider<
InvestigationProvider>.value(
value: provider,
),
ChangeNotifierProvider(
create: (_) => TraceFieldProvider(
service: service,
audioService: audio,
investigation: inv,
purchaseService: purchase,
),
),
],
child: const TraceFieldScreen(),
),
),
);
}

Future<void> _stop() async {
await context
.read<InvestigationProvider>()
.stopInvestigation();

HapticFeedback.mediumImpact();
}

Future<void> _save() async {
final provider =
context.read<InvestigationProvider>();

final inv =
await provider.saveCurrentInvestigation();

if (!mounted || inv == null) {
return;
}

context.go(
'/investigation-summary/${inv.id}',
);
}

Future<void> _discard() async {
final provider =
context.read<InvestigationProvider>();

final confirmed = await showDialog<bool>(
context: context,
builder: (ctx) => AlertDialog(
title: const Text(
'DISCARD INVESTIGATION?',
),
content: const Text(
'This session will not be saved and cannot be recovered.',
),
actions: [
TextButton(
onPressed: () =>
Navigator.pop(ctx, false),
child: const Text('CANCEL'),
),
TextButton(
onPressed: () =>
Navigator.pop(ctx, true),
child: const Text('DISCARD'),
),
],
),
);

if (confirmed != true) {
return;
}

await provider.discardCurrentInvestigation();

if (mounted) {
context.go('/');
}
}

String _statusLabel(
InvestigationProvider provider,
) {
switch (provider.phase) {
case InvestigationPhase.baseline:
return 'BASELINE';
case InvestigationPhase.scanning:
return 'SCANNING';
case InvestigationPhase.detected:
return 'RESPONSE DETECTED';
case InvestigationPhase.idle:
return provider.isActive
? 'LISTENING'
: 'READY';
}
}

@override
Widget build(BuildContext context) {
final provider =
context.watch<InvestigationProvider>();

final appColors =
Theme.of(context)
.extension<AppColorsExtension>()!;

final micUnavailable =
!provider.speechAvailable &&
provider.audioInitialized;

final topBar = InvestigationTopBar(
blindMode: provider.blindMode,
skepticMode: provider.skepticMode,
micUnavailable: micUnavailable,
sessionActive: provider.isActive,
onToggleBlind: _toggleBlind,
onToggleSkeptic: _toggleSkeptic,
onBlindInfo: () =>
showBlindModeInfo(context),
onSkepticInfo: () =>
showSkepticModeInfo(context),
onStop: _stop,
onExit: provider.isActive
? null
: () => context.go('/'),
);

Widget body;

// ----------------------------------------
// READY
// ----------------------------------------
if (provider.session ==
SessionState.ready) {
body = Column(
children: [
topBar,
const WaveformDisplay(
isActive: false,
intensity: 0.25,
),
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
}

// ----------------------------------------
// ENDED
// ----------------------------------------
else if (provider.session ==
SessionState.ended) {
final inv = provider.investigation;

body = Column(
children: [
topBar,
Expanded(
child: inv == null
? const SizedBox.shrink()
: SessionEndedView(
investigation: inv,
patternCount:
provider.patterns.length,
blindMode:
provider.blindMode,
skepticMode:
provider.skepticMode,
onSave: _save,
onDiscard: _discard,
),
),
],
);
}

// ----------------------------------------
// ACTIVE INVESTIGATION
// ----------------------------------------
else {
body = Column(
children: [
topBar,

WaveformDisplay(
isActive: provider.isActive,
intensity: provider.audioIntensity,
),

if (provider.showBaseline &&
!_baselineDismissed)
BaselinePanel(
running:
provider.phase ==
InvestigationPhase.baseline,
secondsRemaining:
provider.baselineRemaining,
progress:
provider.baselineProgress,
onStart: () {
provider.startBaselineScan();
},
onSkip: () {
setState(() {
_baselineDismissed = true;
});
},
onCancel: () {
provider.cancelBaselineScan();

setState(() {
_baselineDismissed = true;
});
},
),

InvestigationStatusBar(
status: _statusLabel(provider),
active: provider.isActive,
liveText: provider.liveText,
level: provider.currentLevel,
listening:
provider.audioInitialized &&
provider.speechAvailable,
timerLabel: provider.elapsedLabel,
),

Expanded(
child: ListView(
padding:
const EdgeInsets.fromLTRB(
16,
8,
16,
24,
),
children: [

// --------------------------------
// PRO PATTERN ANALYSIS
// --------------------------------
if (provider.patterns.isNotEmpty)
PatternCard(
patterns: provider.patterns,
connections:
provider.connections,
onPatternTap:
_openPattern,
onInvestigate:
(pattern) {
_ask(
prefill:
provider
.suggestedQuestionFor(
pattern.word,
),
);
},
),

// --------------------------------
// RESPONSE TIMELINE
// --------------------------------
...provider.responses.map(
(response) => Padding(
padding:
const EdgeInsets.only(
bottom: 12,
),
child: ResponseCard(
response: response,
onPlay: () {
provider
.playResponseAudio(
response.id,
);
},
isRepeated:
response.isRepeatTest,
environmentalChange:
provider
.isEnvironmentalChange(
response,
),
skepticMode:
provider.skepticMode,
blindActive:
provider.blindMode,
),
),
),

const SizedBox(height: 16),

// --------------------------------
// ASK QUESTION
// --------------------------------
AppButton(
label: 'ASK A QUESTION',
onPressed:
provider.isActive
? () => _ask()
: null,
),

const SizedBox(height: 10),

// --------------------------------
// TRACE FIELD
// --------------------------------
AppButton(
label: 'TRACE FIELD',
onPressed:
provider.isActive
? _openTraceField
: null,
),

const SizedBox(height: 10),

// --------------------------------
// STOP
// --------------------------------
if (provider.isActive)
AppButton(
label:
'STOP INVESTIGATION',
onPressed: _stop,
),
],
),
),
],
);
}

return Scaffold(
backgroundColor:
appColors.deepBackground,
body: SafeArea(
child: body,
),
);
}
}


