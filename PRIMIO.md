# spirit trace

## Overview
A paranormal investigation tool that uses real microphone input and speech recognition to detect possible audio responses during investigations. Its core differentiator is the combination of Blind Mode (hide responses until deliberately revealed), persistent investigation memory, repeat-test comparison, and cross-response pattern detection — making it feel like a serious investigation instrument rather than a random word generator.

## Tech Stack & Key Decisions
- speech_to_text for real-time speech recognition during response windows — this is the core detection mechanism, not simulated
- record package for audio file capture alongside speech recognition — may conflict with speech_to_text on some platforms; gracefully degrades
- just_audio for playback of recorded investigation audio clips
- SharedPreferences with JSON serialization for investigation persistence — lightweight, no schema migrations needed
- ChangeNotifier providers route-scoped — InvestigationProvider is the heaviest, managing active scanning state with Timer-based countdown
- Portrait-locked via SystemChrome — optimized for iPhone handheld investigation use

## Architecture
- Audio flow: InvestigationProvider → AudioService → speech_to_text (recognition) + record (file capture) simultaneously; if recording fails due to mic conflict, recognition still works
- Pattern detection is pure Dart string analysis in InvestigationService — splits responses into words, counts occurrences, finds co-occurring words across different responses
- Session lifecycle is explicit: READY (nothing running) → ACTIVE (timer + audio) → ENDED (everything stopped). Opening the investigation route never starts anything
- Investigations live in memory only during a session and are written to SharedPreferences solely when the investigator chooses SAVE; DISCARD deletes any trace, so no session is ever persisted implicitly
- Blind Mode and Skeptic Mode are session-level toggles that genuinely change presentation (blind hides wording, live transcript, baseline, comparisons and the whole pattern panel; skeptic adds data-derived alternative explanations and expands fingerprints) and are stored on the investigation record
- First-use explanations for both modes are gated by boolean flags in SharedPreferences via the repository's getFlag/setFlag
- Response window is 15 seconds with Timer.periodic countdown; speech_to_text auto-stops via its own listenFor parameter
- Blind mode is a per-investigation toggle stored with each QuestionResponse — responses created during blind mode start with revealed=false

## Conventions
- All providers are route-scoped: InvestigationProvider created fresh per /investigation route, PastInvestigationsProvider per /past-investigations and detail routes
- QuestionResponse.id (UUID) is used as the key for reveal/save/repeat-test operations
- Pattern detection runs on-demand via getter (not cached) since investigation response lists are small
- Audio files stored in app documents directory with timestamp-based names (st_<epoch>.m4a)
- The "REPEAT TEST" flow reuses the question sheet with prefilled text and a repeatOriginalId link back to the original response

## Analysis Engine
- Every captured event stores a full fingerprint: timing relative to question end, peak audio level, window duration, confidence (with an explicit availability flag), classification and review status — all derived from the audio pipeline, never invented
- Confidence is only shown when the recogniser actually supplies it; otherwise the UI states CONFIDENCE UNAVAILABLE rather than manufacturing a percentage
- Word clustering uses Levenshtein similarity (≥0.75) so JOHN/JON group together; the canonical label is the most frequent variant
- Environmental baseline is a ~30s level scan before questioning; later events are compared against its average to flag audio-environment changes only
- Dismissed / explained / background-noise events stay in the record but are excluded from pattern analysis

## Trace Field
- An additive second investigation surface opened from an ACTIVE session; it shares the same InvestigationProvider so its events are appended to the live Investigation and saved/discarded with it
- Inputs are genuine only: microphone level (via the existing AudioService level scan, restarted periodically because speech_to_text auto-stops) and accelerometer via sensors_plus; if a sensor is missing the UI says so instead of substituting values
- Calibration measures mean/std of each available input; disturbances are z-score deviations above threshold sustained ~0.4s with a cooldown to prevent event spam
- Formations are read out of the particle engine's measured convergence (coherence), never from a timer or an overlaid image; attractor geometry is re-rolled while the Field is quiet so shapes are not a fixed gallery, and a long cooldown keeps them rare
- The Field animates from a Timer-driven engine tick that increments a ValueNotifier the painter repaints from — the widget tree is not rebuilt per frame
- Formation replay frames are session-only (in-memory rolling buffer); persisted field events keep metadata only

## Localization
- Hand-written Dart dictionaries only — no ARB files, no build_runner, no code generation
- Adding a language requires exactly two edits: an entry in `lib/l10n/app_locales.dart` and a matching map in `lib/l10n/app_strings.dart`; every other file resolves keys dynamically
- Missing keys silently fall back to English, so a partially translated dictionary can never produce blank UI
- LocaleProvider is app-global (created in main.dart): a null selection means "follow the device", which lets Flutter resolve the system locale against the supported list and fall back to English
- Language choice is presentation only — it never touches investigation state, audio, analysis or persistence
- Translated labels must stay wrap-safe: statistic labels, status pills and buttons use Flexible/softWrap because several languages are far longer than English

## Key Patterns & Gotchas
- speech_to_text.initialize() must be called before listen() — handled in AudioService.initialize() called from provider's initAudio()
- On web, speech_to_text uses browser Web Speech API which has inconsistent support; the app gracefully shows "MIC UNAVAILABLE" when speech is not available
- record and speech_to_text may fight over the microphone on Android — recording is best-effort; the recognized text is always the primary result
- The investigation provider uses a Timer that calls notifyListeners every second during scanning — ensure the widget tree doesn't do expensive rebuilds (timeline uses reverse ListView for efficiency)

## Design System
- Premium dark paranormal aesthetic: near-black backgrounds (#060610 deep, #0C0C18 surface) with electric purple (#6C5CE7) and cyan (#00D2FF) accents — serious instrument feel, not horror/Halloween
- Inter font throughout with generous letter-spacing on labels and headings for a technical/instrument appearance
- Animated particle background on home screen and sine-wave waveform on investigation screen provide atmosphere without distracting from content
- All glow effects use box-shadow with the accent colors at low opacity — consistent visual language for "active/detected" states
- Cards use subtle border glow that intensifies when content is significant (response detected, pattern found)
- The home hero is an ambient Trace Scanner (radar sweep, rings, wave ring, particles) — it is decorative instrument atmosphere and deliberately never reflects microphone state; the home audio trace is labelled IDLE / MIC NOT ACTIVE because no mic is opened outside an investigation
- Ambient visuals run on repeating AnimationControllers with CustomPaint; all gradients declare explicit stops so they compile under mobile Skia
