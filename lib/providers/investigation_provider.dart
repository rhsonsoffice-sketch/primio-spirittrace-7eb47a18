import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/investigation.dart';
import '../services/audio_service.dart';
import '../services/investigation_service.dart';
import '../services/purchase_service.dart';

enum InvestigationPhase {
idle,
baseline,
scanning,
detected,
}

enum SessionState {
ready,
active,
ended,
}

class InvestigationProvider extends ChangeNotifier {
final InvestigationService _service;
final AudioService _audioService;
final PurchaseService _purchaseService;

InvestigationProvider({
required InvestigationService service,
required AudioService audioService,
required PurchaseService purchaseService,
}) : _service = service,
_audioService = audioService,
_purchaseService = purchaseService;

static const int scanWindowSeconds = 15;
static const int baselineSeconds = 30;

static const String blindFlag = 'blind_intro_seen';
static const String skepticFlag = 'skeptic_intro_seen';

Investigation? _investigation;

Investigation? get investigation => _investigation;

SessionState _session = SessionState.ready;

SessionState get session => _session;

bool get isActive => _session == SessionState.active;

bool get isEnded => _session == SessionState.ended;

InvestigationPhase _phase = InvestigationPhase.idle;

InvestigationPhase get phase => _phase;

bool _blindMode = false;

bool get blindMode => _blindMode;

bool _skepticMode = false;

bool get skepticMode => _skepticMode;

bool _blindIntroSeen = false;

bool get blindIntroSeen => _blindIntroSeen;

bool _skepticIntroSeen = false;

bool get skepticIntroSeen => _skepticIntroSeen;

Duration _elapsed = Duration.zero;

Duration get elapsed => _elapsed;

String get elapsedLabel {
final minutes =
_elapsed.inMinutes.toString().padLeft(2, '0');

final seconds =
(_elapsed.inSeconds % 60).toString().padLeft(2, '0');

return '$minutes:$seconds';
}

int _scanTimeRemaining = 0;

int get scanTimeRemaining => _scanTimeRemaining;

int _baselineRemaining = 0;

int get baselineRemaining => _baselineRemaining;

double get baselineProgress {
if (_baselineRemaining <= 0) {
return 0;
}

return 1 -
(_baselineRemaining / baselineSeconds);
}

bool get hasBaseline =>
_investigation?.hasBaseline ?? false;

bool get showBaseline =>
_phase == InvestigationPhase.baseline;

String _liveText = '';

String get liveText => _liveText;

double _currentLevel = 0;

double get currentLevel => _currentLevel;

/// Used by the waveform on InvestigationScreen.
double get audioIntensity {
if (_currentLevel <= 0) {
return 0;
}

final value = _currentLevel / 10;

if (value > 1) {
return 1;
}

return value;
}

String? _error;

String? get error => _error;

bool _audioInitialized = false;

bool get audioInitialized => _audioInitialized;

bool get speechAvailable =>
_audioService.speechAvailable;

/// All responses from the current investigation.
List<QuestionResponse> get responses =>
_investigation?.responses ??
<QuestionResponse>[];

// ---------------------------------------------------------------------------
// PRO
// ---------------------------------------------------------------------------

bool get isPro => _purchaseService.isPro;

bool get patternAnalysisAvailable => isPro;

bool get connectionsAvailable => isPro;

bool get repeatabilityAnalysisAvailable => isPro;

bool get environmentalAnalysisAvailable => isPro;

bool get caseFileAvailable => isPro;

// ---------------------------------------------------------------------------
// TIMERS / CURRENT QUESTION
// ---------------------------------------------------------------------------

Timer? _scanTimer;
Timer? _baselineTimer;
Timer? _sessionTimer;

String? _currentAudioPath;
String? _currentQuestion;
String? _repeatOriginalId;

DateTime? _questionEndedAt;
DateTime? _firstEventAt;

double _peakLevel = 0;

final List<double> _levelSamples = [];

// ---------------------------------------------------------------------------
// PREMIUM ANALYSIS
// ---------------------------------------------------------------------------

List<PatternResult> get clusters {
if (!isPro || _investigation == null) {
return <PatternResult>[];
}

return _service.buildClusters(
_investigation!,
);
}

List<PatternResult> get patterns {
if (!isPro || _investigation == null) {
return <PatternResult>[];
}

return _service.detectPatterns(
_investigation!,
);
}

List<ConnectionResult> get connections {
if (!isPro) {
return <ConnectionResult>[];
}

return _service.detectConnections(
patterns,
);
}

String get suggestedQuestion {
if (!isPro) {
return 'Is anyone here with us?';
}

return _service.suggestFollowUpQuestion(
patterns,
);
}

String suggestedQuestionFor(String word) {
if (!isPro) {
return 'Can you tell us more?';
}

return _service.suggestFollowUpQuestionFor(
word,
);
}

List<QuestionResponse> occurrencesOf(
PatternResult pattern,
) {
if (!isPro || _investigation == null) {
return <QuestionResponse>[];
}

return _service.occurrencesOf(
_investigation!,
pattern,
);
}

bool isEnvironmentalChange(
QuestionResponse response,
) {
if (!isPro || _investigation == null) {
return false;
}

return _service.isEnvironmentalChange(
_investigation!,
response,
);
}

String get caseFileReport {
if (!isPro || _investigation == null) {
return '';
}

return _service.buildCaseFile(
_investigation!,
);
}

// ---------------------------------------------------------------------------
// AUDIO
// ---------------------------------------------------------------------------

Future<void> initAudio() async {
_blindIntroSeen =
await _service.getFlag(blindFlag);

_skepticIntroSeen =
await _service.getFlag(skepticFlag);

_audioInitialized =
await _audioService.initialize();

if (!_audioInitialized) {
_error =
'Microphone or speech recognition is unavailable on this device.';
}

notifyListeners();
}

// ---------------------------------------------------------------------------
// START / STOP
// ---------------------------------------------------------------------------

void startInvestigation() {
if (_session == SessionState.active) {
return;
}

_investigation = Investigation(
startTime: DateTime.now(),
skepticMode: _skepticMode,
);

_session = SessionState.active;
_phase = InvestigationPhase.idle;
_elapsed = Duration.zero;
_error = null;

_sessionTimer?.cancel();

_sessionTimer = Timer.periodic(
const Duration(seconds: 1),
(_) {
final inv = _investigation;

if (inv == null) {
return;
}

_elapsed =
DateTime.now().difference(inv.startTime);

notifyListeners();
},
);

notifyListeners();
}

Future<void> stopInvestigation() async {
if (_session != SessionState.active) {
return;
}

_scanTimer?.cancel();
_baselineTimer?.cancel();
_sessionTimer?.cancel();

_scanTimer = null;
_baselineTimer = null;
_sessionTimer = null;

await _audioService.stopListening();
await _audioService.stopRecording();

final inv = _investigation;

if (inv != null) {
inv.endTime ??= DateTime.now();
inv.skepticMode = _skepticMode;
_elapsed = inv.duration;
}

_phase = InvestigationPhase.idle;
_scanTimeRemaining = 0;
_baselineRemaining = 0;
_liveText = '';
_currentLevel = 0;

_session = SessionState.ended;

notifyListeners();
}

// ---------------------------------------------------------------------------
// SAVE
// ---------------------------------------------------------------------------

Future<Investigation?> saveCurrentInvestigation() async {
final inv = _investigation;

if (inv == null) {
return null;
}

// FREE USERS:
// One saved investigation maximum.
//
// PRO USERS:
// Unlimited saved investigations.
if (!isPro) {
try {
final saved =
await _service.getAllInvestigations();

if (saved.isNotEmpty) {
_error =
'Free users can save 1 investigation. Upgrade to SPIRIT TRACE PRO for unlimited saved investigations.';

notifyListeners();

return null;
}
} catch (e) {
_error =
'Unable to check saved investigations.';

debugPrint(
'SPIRIT TRACE save limit check error: $e',
);

notifyListeners();

return null;
}
}

inv.endTime ??= DateTime.now();

try {
await _service.saveInvestigation(inv);

_error = null;

notifyListeners();

return inv;
} catch (e) {
_error = 'Unable to save investigation.';

debugPrint(
'SPIRIT TRACE save error: $e',
);

notifyListeners();

return null;
}
}

Future<void> discardCurrentInvestigation() async {
final inv = _investigation;

if (inv != null) {
await _service.deleteInvestigation(
inv.id,
);
}

_investigation = null;

_session = SessionState.ready;
_phase = InvestigationPhase.idle;
_elapsed = Duration.zero;

notifyListeners();
}

void resetToReady() {
_investigation = null;

_session = SessionState.ready;
_phase = InvestigationPhase.idle;
_elapsed = Duration.zero;

notifyListeners();
}

// ---------------------------------------------------------------------------
// MODES
// ---------------------------------------------------------------------------

void toggleBlindMode() {
_blindMode = !_blindMode;

notifyListeners();
}

void toggleSkepticMode() {
_skepticMode = !_skepticMode;

_investigation?.skepticMode =
_skepticMode;

notifyListeners();
}

Future<void> acknowledgeBlindIntro() async {
_blindIntroSeen = true;

await _service.setFlag(
blindFlag,
true,
);

notifyListeners();
}

Future<void> acknowledgeSkepticIntro() async {
_skepticIntroSeen = true;

await _service.setFlag(
skepticFlag,
true,
);

notifyListeners();
}

void renameInvestigation(String name) {
final inv = _investigation;

if (inv == null ||
name.trim().isEmpty) {
return;
}

inv.name = name.trim();

notifyListeners();
}

// ---------------------------------------------------------------------------
// BASELINE
// ---------------------------------------------------------------------------

Future<void> startBaselineScan() async {
if (!isActive ||
_phase != InvestigationPhase.idle) {
return;
}

_phase = InvestigationPhase.baseline;

_baselineRemaining =
baselineSeconds;

_levelSamples.clear();

_currentLevel = 0;

notifyListeners();

await _audioService.startLevelScan(
duration: const Duration(
seconds: baselineSeconds,
),
onLevel: (level) {
_currentLevel = level;

_levelSamples.add(level);

notifyListeners();
},
);

_baselineTimer?.cancel();

_baselineTimer = Timer.periodic(
const Duration(seconds: 1),
(timer) {
_baselineRemaining--;

notifyListeners();

if (_baselineRemaining <= 0) {
timer.cancel();

_finishBaseline();
}
},
);
}

Future<void> _finishBaseline() async {
await _audioService.stopListening();

final inv = _investigation;

if (inv != null) {
inv.baselineLevel =
_levelSamples.isEmpty
? null
: _levelSamples.reduce(
(a, b) => a + b,
) /
_levelSamples.length;

inv.baselineCompletedAt =
DateTime.now();

inv.baselineDurationMs =
baselineSeconds * 1000;
}

_phase = InvestigationPhase.idle;

_baselineRemaining = 0;
_currentLevel = 0;

notifyListeners();
}

void cancelBaselineScan() {
_baselineTimer?.cancel();

_baselineTimer = null;

_audioService.stopListening();

_phase = InvestigationPhase.idle;

_baselineRemaining = 0;
_currentLevel = 0;

notifyListeners();
}

// ---------------------------------------------------------------------------
// QUESTIONS
// ---------------------------------------------------------------------------

Future<void> askQuestion(
String question, {
String? repeatOriginalId,
}) async {
if (!isActive ||
_investigation == null) {
return;
}

// Repeat testing is PRO.
if (repeatOriginalId != null &&
!isPro) {
_error =
'Repeat Test is available with SPIRIT TRACE PRO.';

notifyListeners();

return;
}

_currentQuestion = question;
_repeatOriginalId = repeatOriginalId;

_phase = InvestigationPhase.scanning;

_liveText = '';

_peakLevel = 0;

_firstEventAt = null;

_scanTimeRemaining =
scanWindowSeconds;

_questionEndedAt =
DateTime.now();

_error = null;

notifyListeners();

_currentAudioPath =
await _audioService.startRecording();

await _audioService.startListening(
listenFor: const Duration(
seconds: scanWindowSeconds,
),
onLevel: (level) {
_currentLevel = level;

if (level > _peakLevel) {
_peakLevel = level;
}

if (_firstEventAt == null &&
level > 1.0) {
_firstEventAt =
DateTime.now();
}

notifyListeners();
},
onResult:
(text, confidence, isFinal) {
if (text.isNotEmpty) {
_firstEventAt ??=
DateTime.now();
}

_liveText = text;

notifyListeners();

if (isFinal &&
text.isNotEmpty) {
_scanTimer?.cancel();

_completeWindow(
text,
confidence,
);
}
},
);

_scanTimer?.cancel();

_scanTimer = Timer.periodic(
const Duration(seconds: 1),
(timer) {
_scanTimeRemaining--;

notifyListeners();

if (_scanTimeRemaining <= 0) {
timer.cancel();

_completeWindow(
_liveText,
null,
);
}
},
);
}

AudioClassification _classify(
String text,
double? confidence,
) {
if (text.trim().isEmpty) {
final baseline =
_investigation?.baselineLevel;

final aboveBaseline =
baseline != null &&
(_peakLevel - baseline) >= 2.5;

if (aboveBaseline ||
_peakLevel > 5.0) {
return AudioClassification
.uncertainAudio;
}

return AudioClassification.none;
}

if (confidence == null ||
confidence <= 0) {
return AudioClassification
.possibleSpeech;
}

if (confidence >= 0.6) {
return AudioClassification
.possibleResponse;
}

if (confidence >= 0.35) {
return AudioClassification
.possibleSpeech;
}

return AudioClassification
.uncertainAudio;
}

Future<void> _completeWindow(
String text,
double? confidence,
) async {
await _audioService.stopListening();

final recorded =
await _audioService.stopRecording();

if (_session !=
SessionState.active) {
return;
}

final now = DateTime.now();

final trimmed = text.trim();

final hasText =
trimmed.isNotEmpty;

final confidenceAvailable =
confidence != null &&
confidence > 0;

final eventAt = _firstEventAt;

final latency =
eventAt != null &&
_questionEndedAt != null
? eventAt
.difference(
_questionEndedAt!,
)
.inMilliseconds
: null;

final windowMs =
_questionEndedAt != null
? now
.difference(
_questionEndedAt!,
)
.inMilliseconds
: null;

final response =
QuestionResponse(
question:
_currentQuestion ?? '',

timestamp: now,

questionEndedAt:
_questionEndedAt ?? now,

detectedResponse:
hasText ? trimmed : null,

confidence:
confidenceAvailable
? confidence
: null,

confidenceAvailable:
confidenceAvailable,

audioPath:
recorded ??
_currentAudioPath,

audioDurationMs:
windowMs,

audioLevel:
_peakLevel > 0
? _peakLevel
: null,

responseLatencyMs:
latency,

classification:
_classify(
trimmed,
confidence,
),

blindMode:
_blindMode,

skepticMode:
_skepticMode,

isRepeatTest:
_repeatOriginalId != null,

repeatTestOriginalId:
_repeatOriginalId,
);

_investigation?.responses
.add(response);

_phase = hasText
? InvestigationPhase.detected
: InvestigationPhase.idle;

_scanTimeRemaining = 0;

_liveText = '';

_currentLevel = 0;

_repeatOriginalId = null;

_currentAudioPath = null;

notifyListeners();
}

// ---------------------------------------------------------------------------
// RESPONSE REVIEW
// ---------------------------------------------------------------------------

QuestionResponse? responseById(
String id,
) {
for (final response in responses) {
if (response.id == id) {
return response;
}
}

return null;
}

void revealResponse(
String responseId,
) {
final response =
responseById(responseId);

if (response == null) {
return;
}

response.revealed = true;

notifyListeners();
}

void setStatus(
String responseId,
ResponseStatus status,
) {
final response =
responseById(responseId);

if (response == null) {
return;
}

response.status =
response.status == status
? ResponseStatus.unreviewed
: status;

notifyListeners();
}

void toggleSaveResponse(
String responseId,
) {
setStatus(
responseId,
ResponseStatus.saved,
);
}

void setNote(
String responseId,
String? note,
) {
final response =
responseById(responseId);

if (response == null) {
return;
}

final cleaned =
(note ?? '').trim();

response.note =
cleaned.isEmpty
? null
: cleaned;

notifyListeners();
}

void dismissDetection() {
_phase = InvestigationPhase.idle;

notifyListeners();
}

// ---------------------------------------------------------------------------
// PRO REPEATABILITY
// ---------------------------------------------------------------------------

RepeatComparison compareRepeat(
String originalId,
String repeatId,
) {
if (!isPro) {
return RepeatComparison
.inconclusive;
}

final original =
responseById(originalId);

final repeat =
responseById(repeatId);

if (original == null ||
repeat == null) {
return RepeatComparison
.inconclusive;
}

return _service.compareRepeatTest(
original,
repeat,
);
}

// ---------------------------------------------------------------------------
// AUDIO PLAYBACK
// ---------------------------------------------------------------------------

Future<void> playResponseAudio(
String responseId,
) async {
final response =
responseById(responseId);

if (response?.audioPath != null) {
await _audioService.playAudio(
response!.audioPath!,
);
}
}

// ---------------------------------------------------------------------------
// CLEANUP
// ---------------------------------------------------------------------------

@override
void dispose() {
_scanTimer?.cancel();
_baselineTimer?.cancel();
_sessionTimer?.cancel();

_audioService.dispose();

super.dispose();
}
}



