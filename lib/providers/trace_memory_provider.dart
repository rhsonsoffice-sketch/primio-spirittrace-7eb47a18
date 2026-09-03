import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';

import '../services/investigation_service.dart';
import '../services/purchase_service.dart';

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

TraceMemoryProvider({
required InvestigationService service,
}) : _service = service;

TraceMemoryStats _stats = const TraceMemoryStats();

TraceMemoryStats get stats => _stats;

bool _isLoading = false;

bool get isLoading => _isLoading;

bool _isLocked = true;

/// True when Trace Memory is unavailable because PRO is not unlocked.
bool get isLocked => _isLocked;

/// Loads Trace Memory.
///
/// Trace Memory is a SPIRIT TRACE PRO feature.
/// FREE users are deliberately prevented from running the
/// historical pattern analysis.
Future<void> load(BuildContext context) async {
final purchase = context.read<PurchaseService>();

// ------------------------------------------------------------
// FREE USER
// ------------------------------------------------------------

if (!purchase.isPro) {
_isLocked = true;

_stats = const TraceMemoryStats();

notifyListeners();

return;
}

// ------------------------------------------------------------
// PRO USER
// ------------------------------------------------------------

_isLocked = false;
_isLoading = true;

notifyListeners();

try {
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
} catch (e) {
debugPrint(
'SPIRIT TRACE Trace Memory error: $e',
);

_stats = const TraceMemoryStats();
} finally {
_isLoading = false;

notifyListeners();
}
}
}

