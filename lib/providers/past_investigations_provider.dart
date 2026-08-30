import 'package:flutter/foundation.dart';

import '../models/investigation.dart';
import '../services/investigation_service.dart';

class PastInvestigationsProvider extends ChangeNotifier {
  final InvestigationService _service;

  PastInvestigationsProvider({required InvestigationService service})
      : _service = service;

  List<Investigation> _investigations = [];
  List<Investigation> get investigations => _investigations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _investigations = await _service.getAllInvestigations();
    _isLoading = false;
    notifyListeners();
  }

  Future<Investigation?> getById(String id) => _service.getInvestigation(id);

  Future<void> deleteInvestigation(String id) async {
    await _service.deleteInvestigation(id);
    await load();
  }

  List<PatternResult> patternsFor(Investigation inv) =>
      _service.detectPatterns(inv);

  List<ConnectionResult> connectionsFor(Investigation inv) =>
      _service.detectConnections(patternsFor(inv));

  List<QuestionResponse> occurrencesFor(
    Investigation inv,
    PatternResult pattern,
  ) =>
      _service.occurrencesOf(inv, pattern);

  bool isEnvironmentalChange(Investigation inv, QuestionResponse r) =>
      _service.isEnvironmentalChange(inv, r);

  String caseFileFor(Investigation inv) => _service.buildCaseFile(inv);
}
