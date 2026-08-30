import 'package:flutter/foundation.dart';

import '../services/investigation_service.dart';

/// Aggregate totals across every stored investigation.
class TraceMemoryStats {
  final int investigations;
  final int possibleResponses;
  final int repeatedResponses;
  final int patterns;

  const TraceMemoryStats({
    this.investigations = 0,
    this.possibleResponses = 0,
    this.repeatedResponses = 0,
    this.patterns = 0,
  });
}

class TraceMemoryProvider extends ChangeNotifier {
  final InvestigationService _service;

  TraceMemoryProvider({required InvestigationService service})
      : _service = service;

  TraceMemoryStats _stats = const TraceMemoryStats();
  TraceMemoryStats get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    final all = await _service.getAllInvestigations();
    var responses = 0;
    var repeated = 0;
    var patterns = 0;
    for (final inv in all) {
      responses += inv.responseCount;
      repeated += inv.repeatResponseCount;
      patterns += _service.detectPatterns(inv).length;
    }

    _stats = TraceMemoryStats(
      investigations: all.length,
      possibleResponses: responses,
      repeatedResponses: repeated,
      patterns: patterns,
    );
    _isLoading = false;
    notifyListeners();
  }
}
