import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService extends ChangeNotifier {
static const String proProductId = 'com.spirittrace.pro';

final InAppPurchase _inAppPurchase = InAppPurchase.instance;

ProductDetails? _proProduct;
bool _isAvailable = false;
bool _isPro = false;
bool _isLoading = false;

StreamSubscription<List<PurchaseDetails>>? _subscription;

ProductDetails? get proProduct => _proProduct;
bool get isAvailable => _isAvailable;
bool get isPro => _isPro;
bool get isLoading => _isLoading;

PurchaseService() {
_subscription = _inAppPurchase.purchaseStream.listen(
_handlePurchaseUpdates,
onDone: () => _subscription?.cancel(),
onError: (error) {
debugPrint('Purchase stream error: $error');
},
);

initialise();
}

Future<void> initialise() async {
if (_isLoading) return;

_isLoading = true;
notifyListeners();

try {
_isAvailable = await _inAppPurchase.isAvailable();

if (!_isAvailable) {
debugPrint('In-app purchases are not available.');
return;
}

final response = await _inAppPurchase.queryProductDetails(
{proProductId},
);

if (response.error != null) {
debugPrint(
'Product query error: ${response.error}',
);
return;
}

if (response.productDetails.isNotEmpty) {
_proProduct = response.productDetails.first;

debugPrint(
'Found Spirit Trace Pro: '
'${_proProduct!.id} '
'${_proProduct!.price}',
);
} else {
debugPrint('Spirit Trace Pro product was not found.');
}

/*
* Do NOT automatically call restorePurchases() here.
*
* Restore is deliberately user initiated from Settings.
*
* The purchase stream is still listened to continuously so that
* purchases/restores update entitlement while the app is running.
*/
} catch (e) {
debugPrint(
'Purchase initialisation error: $e',
);
} finally {
_isLoading = false;
notifyListeners();
}
}

Future<void> buyPro() async {
if (_isLoading) return;

if (_proProduct == null) {
await initialise();
}

if (_proProduct == null) {
debugPrint(
'Spirit Trace Pro product is unavailable.',
);
return;
}

final purchaseParam = PurchaseParam(
productDetails: _proProduct!,
);

await _inAppPurchase.buyNonConsumable(
purchaseParam: purchaseParam,
);
}

Future<void> restorePurchases() async {
if (_isLoading) return;

try {
_isLoading = true;
notifyListeners();

await _inAppPurchase.restorePurchases();
} catch (e) {
debugPrint(
'Restore purchases error: $e',
);
} finally {
_isLoading = false;
notifyListeners();
}
}

Future<void> _handlePurchaseUpdates(
List<PurchaseDetails> purchases,
) async {
for (final purchase in purchases) {
if (purchase.productID != proProductId) {
continue;
}

debugPrint(
'Spirit Trace Pro purchase status: '
'${purchase.status}',
);

switch (purchase.status) {
case PurchaseStatus.purchased:
_unlockPro();
break;

case PurchaseStatus.restored:
_unlockPro();
break;

case PurchaseStatus.pending:
debugPrint(
'Spirit Trace Pro purchase is pending.',
);
break;

case PurchaseStatus.error:
debugPrint(
'Spirit Trace Pro purchase error: '
'${purchase.error}',
);
break;

case PurchaseStatus.canceled:
debugPrint(
'Spirit Trace Pro purchase cancelled.',
);
break;
}

/*
* IMPORTANT:
*
* Unlock entitlement BEFORE completing the transaction.
*/
if (purchase.pendingCompletePurchase) {
await _inAppPurchase.completePurchase(
purchase,
);
}
}
}

void _unlockPro() {
if (_isPro) return;

_isPro = true;

debugPrint(
'SPIRIT TRACE PRO UNLOCKED',
);

notifyListeners();
}

@override
void dispose() {
_subscription?.cancel();
super.dispose();
}
}

