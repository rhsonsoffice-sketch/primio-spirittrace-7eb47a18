import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/investigation.dart';
import '../services/audio_service.dart';
import '../services/investigation_service.dart';
import '../services/motion_service.dart';
import '../services/purchase_service.dart';
import '../services/trace_field_engine.dart';

enum FieldState {
idle,
calibrating,
ready,
monitoring,
stopped,
}

class TraceFieldProvider extends ChangeNotifier {
TraceFieldProvider({
required InvestigationService service,
required AudioService audioService,
required Investigation investigation,
required PurchaseService purchaseService,
MotionService? motionService,
}) : _service = service,
_audio = audioService,
_investigation = investigation,
_purchaseService = purchaseService,
_motion = motionService ?? MotionService();

static const String introFlag = 'trace_field_intro_seen';
static const int calibrationSeconds = 8;
static const int pulseSeconds = 30;

final InvestigationService _service;
final AudioService _audio;
final MotionService _motion;
final Investigation _investigation;
final PurchaseService _purchaseService;

final TraceFieldEngine engine = TraceFieldEngine();

/// Frame counter the painter repaints from, so the Field animates without
/// rebuilding the widget tree.
final ValueNotifier<int> frame = ValueNotifier<int>(0);

// -------------------------------------------------------------
// PRO ACCESS
// -------------------------------------------------------------

bool get isPro => _purchaseService.isPro;

/// Basic Trace Field monitoring remains available to everyone.
bool get basicFieldAvailable => true;

/// Trace Pulse is a PRO feature.
bool get tracePulseAvailable => isPro;

/// Advanced/full Trace Field analysis is a PRO feature.
bool get advancedFieldAvailable => isPro;

/// Replay of captured formation frames is part of the advanced Field
/// analysis and therefore requires PRO.
bool get replayAvailable => isPro;

FieldState _state = FieldState.idle;
FieldState get state => _state;

bool _introSeen = false;
bool get introSeen => _introSeen;

bool get audioAvailable => _audio.speechAvailable;
bool get motionAvailable => _motion.available;

int _calibrationRemaining = calibrationSeconds;
int get calibrationRemaining => _calibrationRemaining;

double get calibrationProgress =>
1 - (_calibrationRemaining / calibrationSeconds);

int _pulseRemaining = 0;
int get pulseRemaining => _pulseRemaining;

bool get pulseActive => _pulseRemaining > 0;

String _statusTitle = 'FIELD';
String get statusTitle => _statusTitle;

String _statusDetail = '';
String get statusDetail => _statusDetail;

String? _prompt;
String? get prompt => _prompt;

FieldEvent? _latestEvent;
FieldEvent? get latestEvent => _latestEvent;

bool _formationVisible = false;
bool get formationVisible => _formationVisible;

List<FieldEvent> get events =>
_investigation.fieldEvents;

Investigation get investigation =>
_investigation;

double get drive =>
engine.drive;

double get coherence =>
engine.coherence;

/// Replay frames captured for formation events.
///
/// Replay is an advanced PRO feature. Free users receive no replay data.
List<List<Offset>>? replayFor(
String eventId,
) {
if (!isPro) {
return null;
}

return _replays[eventId];
}

final Map<String, List<List<Offset>>> _replays = {};

// -------------------------------------------------------------
// BASELINE MEASUREMENTS
// -------------------------------------------------------------

final List<double> _calAudio = [];
final List<double> _calMotion = [];

double _audioMean = 0;
double _audioStd = 1;

double _motionMean = 0;
double _motionStd = 1;

double _audioLevel = 0;

Timer? _ticker;
Timer? _audioRestart;
Timer? _countdown;

double _aboveThreshold = 0;
double _cooldown = 0;
double _coherentFor = 0;
double _formationCooldown = 0;

FieldEvent? _openFormation;
DateTime? _formationStart;

double _promptTimer = 20;

final List<List<Offset>> _buffer = [];
int _bufferSkip = 0;

int _pulseDisturbances = 0;
int _pulseUnclassified = 0;
int _pulseFormations = 0;

DateTime? _pulseStart;

bool _blindMode = false;
bool _skepticMode = false;

// -------------------------------------------------------------
// MODES
// -------------------------------------------------------------

void applyModes({
required bool blind,
required bool skeptic,
}) {
_blindMode = blind;
_skepticMode = skeptic;
}

bool _revealed = false;

bool get revealed =>
_revealed || !_blindMode;

void revealTrace() {
_revealed = true;
notifyListeners();
}

// -------------------------------------------------------------
// INTRO
// -------------------------------------------------------------

Future<void> init() async {
_introSeen =
await _service.getFlag(
introFlag,
);

notifyListeners();
}

Future<void> acknowledgeIntro() async {
_introSeen = true;

await _service.setFlag(
introFlag,
true,
);

notifyListeners();
}

// -------------------------------------------------------------
// CALIBRATION
// -------------------------------------------------------------

Future<void> startCalibration() async {
if (_state == FieldState.calibrating ||
_state == FieldState.monitoring) {
return;
}

_state = FieldState.calibrating;

_statusTitle = 'CALIBRATING';
_statusDetail =
'Establishing environmental baseline...';

_calibrationRemaining =
calibrationSeconds;

_calAudio.clear();
_calMotion.clear();

notifyListeners();

await _motion.start();

await _startAudioScan();

_startTicker();

_countdown?.cancel();

_countdown = Timer.periodic(
const Duration(seconds: 1),
(t) {
_calibrationRemaining--;

if (_calibrationRemaining <= 0) {
t.cancel();
_finishCalibration();
}

notifyListeners();
},
);
}

double _mean(List<double> v) =>
v.isEmpty
? 0
: v.reduce(
(a, b) => a + b,
) /
v.length;

double _std(
List<double> v,
double mean,
) {
if (v.length < 2) {
return 1;
}

final sum = v.fold<double>(
0,
(a, b) =>
a +
pow(
b - mean,
2,
).toDouble(),
);

return max(
sqrt(sum / v.length),
0.35,
);
}

void _finishCalibration() {
_audioMean =
_mean(_calAudio);

_audioStd =
_std(
_calAudio,
_audioMean,
);

_motionMean =
_mean(_calMotion);

_motionStd =
_std(
_calMotion,
_motionMean,
);

_state = FieldState.ready;

_statusTitle =
'FIELD READY';

_statusDetail =
'Baseline established.';

notifyListeners();

Timer(
const Duration(
milliseconds: 1400,
),
() {
if (_state != FieldState.ready) {
return;
}

_state =
FieldState.monitoring;

_statusTitle =
'MONITORING';

_statusDetail =
'Ask. Observe. Investigate.';

notifyListeners();
},
);
}

Future<void> _startAudioScan() async {
await _audio.startLevelScan(
duration:
const Duration(seconds: 20),
onLevel: (l) =>
_audioLevel = l,
);

_audioRestart?.cancel();

_audioRestart = Timer.periodic(
const Duration(seconds: 19),
(_) async {
await _audio.stopListening();

await _audio.startLevelScan(
duration:
const Duration(seconds: 20),
onLevel: (l) =>
_audioLevel = l,
);
},
);
}

// -------------------------------------------------------------
// FIELD ENGINE
// -------------------------------------------------------------

void _startTicker() {
_ticker?.cancel();

_ticker = Timer.periodic(
const Duration(milliseconds: 33),
(_) => _tick(),
);
}

void _tick() {
const dt = 0.033;

final zAudio = audioAvailable
? ((_audioLevel - _audioMean).abs() /
_audioStd)
: null;

final zMotion = motionAvailable
? ((_motion.magnitude -
_motionMean)
.abs() /
_motionStd)
: null;

if (_state ==
FieldState.calibrating) {
if (audioAvailable) {
_calAudio.add(
_audioLevel,
);
}

if (motionAvailable) {
_calMotion.add(
_motion.magnitude,
);
}

engine.tick(
dt,
0.18,
);

frame.value++;

return;
}

final z = max(
zAudio ?? 0,
zMotion ?? 0,
);

engine.tick(
dt,
(z / 4.5)
.clamp(0.05, 1.0),
);

frame.value++;

_cooldown =
max(0, _cooldown - dt);

_formationCooldown =
max(
0,
_formationCooldown - dt,
);

_bufferSkip++;

if (_bufferSkip >= 3) {
_bufferSkip = 0;

_buffer.add(
engine.snapshot(),
);

if (_buffer.length > 70) {
_buffer.removeAt(0);
}
}

if (_state !=
FieldState.monitoring) {
return;
}

// -----------------------------------------------------------
// BASIC DISTURBANCE DETECTION
// -----------------------------------------------------------

if (z > 2.5) {
_aboveThreshold += dt;
} else {
_aboveThreshold = 0;
}

if (_aboveThreshold > 0.4 &&
_cooldown <= 0) {
_aboveThreshold = 0;
_cooldown = 6;

_emitDisturbance(
zAudio,
zMotion,
);
}

// -----------------------------------------------------------
// BASIC FORMATION DETECTION
// -----------------------------------------------------------

if (engine.coherence > 0.82) {
_coherentFor += dt;
} else {
_coherentFor = 0;

if (_openFormation != null &&
engine.coherence < 0.60) {
_closeFormation();
}
}

if (_coherentFor > 0.7 &&
_openFormation == null &&
_formationCooldown <= 0) {
_openFormationEvent();
}

// -----------------------------------------------------------
// PROMPTS
// -----------------------------------------------------------

_promptTimer -= dt;

if (_promptTimer <= 0) {
_promptTimer =
55 +
Random()
.nextInt(50)
.toDouble();

_prompt =
_prompts[
Random().nextInt(
_prompts.length,
)];

notifyListeners();
}
}

static const List<String> _prompts = [
'Ask a clear question.',
'Remain silent and watch the Field.',
'If you believe someone is present, ask them to interact with the Field.',
'Try repeating the same question.',
];

void dismissPrompt() {
_prompt = null;
notifyListeners();
}

// -------------------------------------------------------------
// ENVIRONMENTAL EVENTS
// -------------------------------------------------------------

String? _causeFor(
double? zAudio,
double? zMotion,
) {
final a = zAudio ?? 0;
final m = zMotion ?? 0;

if (m > 3.0 &&
m > a * 1.4) {
return 'Movement detected';
}

if (m > 2.5 &&
_motion.orientationDelta >
1.5) {
return 'Device orientation changed';
}

if (a > 3.0 &&
a > m * 1.4) {
return 'Audio change detected';
}

if (a > 2.5 ||
m > 2.5) {
return 'Environmental change detected';
}

return null;
}

void _emitDisturbance(
double? zAudio,
double? zMotion,
) {
final cause =
_causeFor(
zAudio,
zMotion,
);

final event = FieldEvent(
type: cause == null
? FieldEventType.unclassified
: FieldEventType.disturbance,
timestamp: DateTime.now(),
durationMs: 400,
audioDeviation: zAudio,
motionDeviation: zMotion,
likelyCause: cause,
blindMode: _blindMode,
skepticMode: _skepticMode,
);

_investigation.fieldEvents
.add(event);

_latestEvent = event;

if (pulseActive) {
if (event.type ==
FieldEventType.unclassified) {
_pulseUnclassified++;
} else {
_pulseDisturbances++;
}
}

_statusTitle =
event.type.label;

_statusDetail =
'Change detected';

notifyListeners();

Timer(
const Duration(seconds: 4),
() {
if (_state ==
FieldState.monitoring &&
!_formationVisible) {
_statusTitle =
'FIELD STABLE';

_statusDetail =
'Monitoring...';

notifyListeners();
}
},
);
}

// -------------------------------------------------------------
// FORMATIONS
// -------------------------------------------------------------

void _openFormationEvent() {
_formationStart =
DateTime.now();

_formationVisible = true;

_openFormation = FieldEvent(
type:
FieldEventType.formation,
timestamp:
_formationStart!,
coherence:
engine.coherence,
resemblance:
engine.resemblance,
blindMode:
_blindMode,
skepticMode:
_skepticMode,
);

_statusTitle =
'POSSIBLE FORMATION';

_statusDetail =
'Observe';

notifyListeners();
}

void _closeFormation() {
final event =
_openFormation;

if (event == null) {
return;
}

event.durationMs =
DateTime.now()
.difference(
_formationStart ??
DateTime.now(),
)
.inMilliseconds;

_investigation.fieldEvents
.add(event);

// Replay is advanced Trace Field functionality
// and is therefore retained only for PRO.
if (isPro) {
_replays[event.id] =
List<List<Offset>>.from(
_buffer,
);
}

if (pulseActive) {
_pulseFormations++;
}

_latestEvent = event;

_openFormation = null;

_formationVisible = false;

_formationCooldown = 45;

_statusTitle =
'FORMATION RECORDED';

_statusDetail =
event.timeLabel;

notifyListeners();

Timer(
const Duration(seconds: 6),
() {
if (_state ==
FieldState.monitoring &&
!_formationVisible) {
_statusTitle =
'FIELD STABLE';

_statusDetail =
'Monitoring...';

notifyListeners();
}
},
);
}

// -------------------------------------------------------------
// TRACE PULSE — PRO ONLY
// -------------------------------------------------------------

void startPulse() {
if (!isPro) {
_statusTitle =
'TRACE PULSE — PRO';

_statusDetail =
'Upgrade to SPIRIT TRACE PRO to unlock Trace Pulse.';

notifyListeners();

return;
}

if (_state !=
FieldState.monitoring ||
pulseActive) {
return;
}

_pulseRemaining =
pulseSeconds;

_pulseDisturbances = 0;
_pulseUnclassified = 0;
_pulseFormations = 0;

_pulseStart =
DateTime.now();

_statusTitle =
'TRACE PULSE';

_statusDetail =
'Remain still. Ask your question. Watch the Field.';

notifyListeners();

_countdown?.cancel();

_countdown = Timer.periodic(
const Duration(seconds: 1),
(t) {
_pulseRemaining--;

if (_pulseRemaining <= 0) {
t.cancel();
_finishPulse();
}

notifyListeners();
},
);
}

void _finishPulse() {
// Safety check in case entitlement
// changed while the pulse was running.
if (!isPro) {
_pulseRemaining = 0;
return;
}

final event = FieldEvent(
type:
FieldEventType.pulse,
timestamp:
_pulseStart ??
DateTime.now(),
durationMs:
pulseSeconds * 1000,
blindMode:
_blindMode,
skepticMode:
_skepticMode,
pulseDisturbances:
_pulseDisturbances,
pulseUnclassified:
_pulseUnclassified,
pulseFormations:
_pulseFormations,
);

_investigation.fieldEvents
.add(event);

_latestEvent = event;

_statusTitle =
'PULSE COMPLETE';

_statusDetail =
'${_pulseDisturbances} disturbances · '
'${_pulseUnclassified} unclassified · '
'${_pulseFormations} formations';

notifyListeners();
}

// -------------------------------------------------------------
// REVIEW
// -------------------------------------------------------------

void setStatus(
String eventId,
FieldEventStatus status,
) {
for (final e
in _investigation.fieldEvents) {
if (e.id == eventId) {
e.status =
e.status == status
? FieldEventStatus.unreviewed
: status;
break;
}
}

notifyListeners();
}

void markEvent(String id) =>
setStatus(
id,
FieldEventStatus.marked,
);

void dismissEvent(String id) =>
setStatus(
id,
FieldEventStatus.dismissed,
);

void clearLatest() {
_latestEvent = null;
notifyListeners();
}

// -------------------------------------------------------------
// STOP
// -------------------------------------------------------------

Future<void> stopField() async {
_ticker?.cancel();
_countdown?.cancel();
_audioRestart?.cancel();

_ticker = null;
_countdown = null;
_audioRestart = null;

_pulseRemaining = 0;

await _audio.stopListening();
await _motion.stop();

_state =
FieldState.stopped;

notifyListeners();
}

// -------------------------------------------------------------
// CLEANUP
// -------------------------------------------------------------

@override
void dispose() {
_ticker?.cancel();
_countdown?.cancel();
_audioRestart?.cancel();

_audio.stopListening();
_motion.dispose();

frame.dispose();

super.dispose();
}
}

