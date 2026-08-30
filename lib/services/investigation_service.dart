import 'package:intl/intl.dart';

import '../models/investigation.dart';
import '../repositories/investigation_repository.dart';

class InvestigationService {
  final InvestigationRepository _repository;

  InvestigationService({required InvestigationRepository repository})
      : _repository = repository;

  static const _stopWords = {
    'THE', 'AND', 'YOU', 'ARE', 'FOR', 'WAS', 'THAT', 'THIS', 'WITH', 'HAVE',
    'CAN', 'NOT', 'BUT', 'ALL', 'ANY', 'OUR', 'YOUR',
  };

  /// Levenshtein distance used for similarity clustering.
  int _distance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        final del = prev[j + 1] + 1;
        final ins = curr[j] + 1;
        final sub = prev[j] + cost;
        curr[j + 1] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[b.length];
  }

  /// 0.0 – 1.0 similarity between two words.
  double similarity(String a, String b) {
    final x = a.toUpperCase().trim();
    final y = b.toUpperCase().trim();
    if (x.isEmpty || y.isEmpty) return 0;
    final maxLen = x.length > y.length ? x.length : y.length;
    return 1 - (_distance(x, y) / maxLen);
  }

  bool _isSimilar(String a, String b) => similarity(a, b) >= 0.75;

  List<String> _wordsOf(QuestionResponse r) {
    final text = r.detectedResponse;
    if (text == null) return const [];
    return text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toList();
  }

  /// Responses that count towards analysis (dismissed/explained are excluded).
  List<QuestionResponse> analysableResponses(Investigation investigation) =>
      investigation.responses
          .where((r) => r.hasResponse && !r.isDismissed)
          .toList();

  /// Groups similar detected words into clusters. Similarity analysis only —
  /// it does not imply that the same source produced each occurrence.
  List<PatternResult> buildClusters(Investigation investigation) {
    final buckets = <List<String>>[];
    final bucketWords = <List<String>>[];

    for (final response in analysableResponses(investigation)) {
      for (final word in _wordsOf(response)) {
        var placed = false;
        for (var i = 0; i < buckets.length; i++) {
          if (_isSimilar(bucketWords[i].first, word)) {
            buckets[i].add(response.id);
            bucketWords[i].add(word);
            placed = true;
            break;
          }
        }
        if (!placed) {
          buckets.add([response.id]);
          bucketWords.add([word]);
        }
      }
    }

    final results = <PatternResult>[];
    for (var i = 0; i < buckets.length; i++) {
      final counts = <String, int>{};
      for (final w in bucketWords[i]) {
        counts[w] = (counts[w] ?? 0) + 1;
      }
      final canonical = counts.entries
          .reduce((a, b) => b.value > a.value ? b : a)
          .key;
      results.add(PatternResult(
        word: canonical,
        count: bucketWords[i].length,
        responseIds: buckets[i],
        variants: counts.keys.toList(),
      ));
    }
    results.sort((a, b) => b.count.compareTo(a.count));
    return results;
  }

  List<PatternResult> detectPatterns(Investigation investigation) =>
      buildClusters(investigation).where((c) => c.count > 1).toList();

  List<ConnectionResult> detectConnections(List<PatternResult> patterns) {
    final connections = <ConnectionResult>[];
    for (var i = 0; i < patterns.length; i++) {
      for (var j = i + 1; j < patterns.length; j++) {
        final a = patterns[i];
        final b = patterns[j];
        final shared = a.responseIds.toSet().intersection(b.responseIds.toSet());
        if (shared.isNotEmpty) {
          connections.add(ConnectionResult(
            word1: a.word,
            word2: b.word,
            reason: 'Appeared together in the same detected audio',
            responseIds: shared.toList(),
          ));
        } else {
          connections.add(ConnectionResult(
            word1: a.word,
            word2: b.word,
            reason: 'Both recurred separately during this investigation',
            responseIds: [...a.responseIds, ...b.responseIds],
          ));
        }
      }
    }
    return connections;
  }

  /// Responses referenced by a pattern, in chronological order.
  List<QuestionResponse> occurrencesOf(
    Investigation investigation,
    PatternResult pattern,
  ) {
    final ids = pattern.responseIds.toSet();
    return investigation.responses.where((r) => ids.contains(r.id)).toList();
  }

  RepeatComparison compareRepeatTest(
    QuestionResponse original,
    QuestionResponse repeat,
  ) {
    if (!original.hasResponse || !repeat.hasResponse) {
      return RepeatComparison.inconclusive;
    }
    final a = original.detectedResponse!.toUpperCase().trim();
    final b = repeat.detectedResponse!.toUpperCase().trim();
    final score = similarity(a, b);
    if (score >= 0.9) return RepeatComparison.repeated;
    if (score >= 0.6) return RepeatComparison.similar;

    final wordsA = _wordsOf(original).toSet();
    final wordsB = _wordsOf(repeat).toSet();
    if (wordsA.isNotEmpty && wordsA.intersection(wordsB).isNotEmpty) {
      return RepeatComparison.similar;
    }
    return RepeatComparison.different;
  }

  /// Suggested follow-up wording for a recurring detected word.
  String suggestFollowUpQuestionFor(String word) {
    final w = word.toUpperCase();
    const location = {'HERE', 'THERE', 'ROOM', 'INSIDE', 'OUTSIDE', 'UPSTAIRS'};
    if (location.contains(w)) return 'Can you tell us where you are?';
    if (w == 'NAME') return 'Can you tell us your name?';
    if (w == 'YES' || w == 'NO') return 'Can you answer that again for us?';
    if (w == 'HELP') return 'Can you tell us what you need help with?';
    if (w == 'LEAVE' || w == 'GO') return 'Do you want us to leave?';
    final pretty = w.length > 1
        ? '${w[0]}${w.substring(1).toLowerCase()}'
        : w;
    return 'Can you tell us who $pretty is?';
  }

  String suggestFollowUpQuestion(List<PatternResult> patterns) {
    if (patterns.isEmpty) return 'Is anyone here with us?';
    return suggestFollowUpQuestionFor(patterns.first.word);
  }

  /// True when the captured level differs meaningfully from the baseline.
  /// Describes the audio environment only — not paranormal activity.
  bool isEnvironmentalChange(Investigation investigation, QuestionResponse r) {
    final baseline = investigation.baselineLevel;
    final level = r.audioLevel;
    if (baseline == null || level == null) return false;
    return (level - baseline).abs() >= 2.5;
  }

  /// Plain-text case file for reading, copying or sharing.
  String buildCaseFile(Investigation inv) {
    final patterns = detectPatterns(inv);
    final connections = detectConnections(patterns);
    final dateFmt = DateFormat('MMM d, yyyy');
    final timeFmt = DateFormat('HH:mm:ss');
    final dur = inv.duration;

    final b = StringBuffer()
      ..writeln('SPIRIT TRACE — INVESTIGATION CASE FILE')
      ..writeln('=======================================')
      ..writeln('Name: ${inv.name}')
      ..writeln('Date: ${dateFmt.format(inv.startTime)}')
      ..writeln('Start: ${timeFmt.format(inv.startTime)}')
      ..writeln('End: ${inv.endTime != null ? timeFmt.format(inv.endTime!) : "—"}')
      ..writeln('Duration: ${dur.inMinutes}m ${dur.inSeconds % 60}s')
      ..writeln('Skeptic mode: ${inv.skepticMode ? "ON" : "OFF"}')
      ..writeln(
          'Environmental baseline: ${inv.hasBaseline ? inv.baselineLevel!.toStringAsFixed(2) : "not recorded"}')
      ..writeln('')
      ..writeln('SUMMARY')
      ..writeln('Questions asked: ${inv.questionCount}')
      ..writeln('Possible responses: ${inv.responseCount}')
      ..writeln('Repeat tests: ${inv.repeatTestCount}')
      ..writeln('Repeated responses: ${inv.repeatResponseCount}')
      ..writeln('Possible patterns: ${patterns.length}')
      ..writeln('Possible connections: ${connections.length}')
      ..writeln('Dismissed / explained events: ${inv.dismissedCount}')
      ..writeln('Investigator notes: ${inv.noteCount}')
      ..writeln('')
      ..writeln('TIMELINE');

    for (final r in inv.responses) {
      b
        ..writeln('---')
        ..writeln('[${timeFmt.format(r.timestamp)}] QUESTION: ${r.question}');
      if (r.hasResponse) {
        b.writeln('  ${r.classification.label}: ${r.detectedResponse!.toUpperCase()}');
      } else {
        b.writeln('  ${r.classification.label}');
      }
      final latency = r.latencyLabel;
      if (latency != null) b.writeln('  Timing: $latency');
      b.writeln(r.confidenceAvailable && r.confidence != null
          ? '  Confidence: ${(r.confidence! * 100).round()}% (CONFIDENCE AVAILABLE)'
          : '  CONFIDENCE UNAVAILABLE');
      if (r.audioLevel != null) {
        b.writeln('  Audio level: ${r.audioLevel!.toStringAsFixed(2)}');
      }
      if (r.audioDurationMs != null) {
        b.writeln('  Audio duration: ${(r.audioDurationMs! / 1000).toStringAsFixed(1)}s');
      }
      b.writeln('  Audio clip: ${r.audioPath != null ? "recorded" : "not available"}');
      b.writeln('  Blind mode: ${r.blindMode ? "ON" : "OFF"}');
      b.writeln('  Status: ${r.status.label}');
      if (r.isRepeatTest) b.writeln('  Repeat test of an earlier question');
      if ((r.note ?? '').isNotEmpty) b.writeln('  NOTE: ${r.note}');
    }

    if (patterns.isNotEmpty) {
      b
        ..writeln('')
        ..writeln('PATTERN ANALYSIS');
      for (final p in patterns) {
        b.writeln('  "${p.word}" — ${p.count} occurrences'
            '${p.hasVariants ? " (variants: ${p.variants.join(", ")})" : ""}');
      }
    }

    if (connections.isNotEmpty) {
      b
        ..writeln('')
        ..writeln('POSSIBLE CONNECTIONS');
      for (final c in connections) {
        b.writeln('  ${c.word1} -> ${c.word2} — ${c.reason}');
      }
    }

    b
      ..writeln('')
      ..writeln(
          'This report records audio captured by the device and the app\'s')
      ..writeln(
          'interpretation of it. Interpretations are not established fact and')
      ..writeln('results are not scientifically verified.');

    return b.toString();
  }

  Future<void> saveInvestigation(Investigation investigation) =>
      _repository.save(investigation);

  Future<List<Investigation>> getAllInvestigations() => _repository.getAll();

  Future<Investigation?> getInvestigation(String id) => _repository.getById(id);

  Future<void> deleteInvestigation(String id) => _repository.delete(id);

  Future<bool> getFlag(String key) => _repository.getFlag(key);

  Future<void> setFlag(String key, bool value) =>
      _repository.setFlag(key, value);
}
