import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';

import '../models/investigation.dart';
import '../services/investigation_service.dart';
import '../services/purchase_service.dart';

class PastInvestigationsProvider extends ChangeNotifier {
final InvestigationService _service;

PastInvestigationsProvider({
required InvestigationService service,
}) : _service = service;

List<Investigation> _investigations = [];

List<Investigation> get investigations => _investigations;

bool _isLoading = false;

bool get isLoading => _isLoading;

// ------------------------------------------------------------
// LOAD INVESTIGATIONS
// ------------------------------------------------------------

Future<void> load() async {
_isLoading = true;
notifyListeners();

try {
_investigations =
await _service.getAllInvestigations();
} catch (e) {
debugPrint(
'SPIRIT TRACE: Error loading investigations: $e',
);
} finally {
_isLoading = false;
notifyListeners();
}
}

// ------------------------------------------------------------
// GET ONE INVESTIGATION
// ------------------------------------------------------------

Future<Investigation?> getById(String id) {
return _service.getInvestigation(id);
}

// ------------------------------------------------------------
// DELETE
// ------------------------------------------------------------

Future<void> deleteInvestigation(String id) async {
await _service.deleteInvestigation(id);
await load();
}

// ------------------------------------------------------------
// PATTERN DETECTION — PRO
// ------------------------------------------------------------

List<PatternResult> patternsFor(
BuildContext context,
Investigation inv,
) {
final purchase =
context.read<PurchaseService>();

if (!purchase.isPro) {
return <PatternResult>[];
}

return _service.detectPatterns(inv);
}

// ------------------------------------------------------------
// CONNECTIONS — PRO
// ------------------------------------------------------------

List<ConnectionResult> connectionsFor(
BuildContext context,
Investigation inv,
) {
final purchase =
context.read<PurchaseService>();

if (!purchase.isPro) {
return <ConnectionResult>[];
}

final patterns = _service.detectPatterns(inv);

return _service.detectConnections(patterns);
}

// ------------------------------------------------------------
// RESPONSE OCCURRENCES — PRO
// ------------------------------------------------------------

List<QuestionResponse> occurrencesFor(
BuildContext context,
Investigation inv,
PatternResult pattern,
) {
final purchase =
context.read<PurchaseService>();

if (!purchase.isPro) {
return <QuestionResponse>[];
}

return _service.occurrencesOf(
inv,
pattern,
);
}

// ------------------------------------------------------------
// ENVIRONMENTAL CHANGE — PRO
// ------------------------------------------------------------

bool isEnvironmentalChange(
BuildContext context,
Investigation inv,
QuestionResponse response,
) {
final purchase =
context.read<PurchaseService>();

if (!purchase.isPro) {
return false;
}

return _service.isEnvironmentalChange(
inv,
response,
);
}

// ------------------------------------------------------------
// FULL CASE FILE — PRO
// ------------------------------------------------------------

String? caseFileFor(
BuildContext context,
Investigation inv,
) {
final purchase =
context.read<PurchaseService>();

if (!purchase.isPro) {
return null;
}

return _service.buildCaseFile(inv);
}
}

