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

StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

ProductDetails? get proProduct => _proProduct;

bool get isAvailable => _isAvailable;

bool get isPro => _isPro;

bool get isLoading => _isLoading;

PurchaseService() {
_listenForPurchases();
initialise();
}

// ------------------------------------------------------------
// PURCHASE LISTENER
// ------------------------------------------------------------

void _listenForPurchases() {
_purchaseSubscription = _inAppPurchase.purchaseStream.listen(
_handlePurchaseUpdates,
onError: (Object error) {
debugPrint('SPIRIT TRACE purchase stream error: $error');
},
onDone: () {
_purchaseSubscription?.cancel();
},
);
}

// ------------------------------------------------------------
// INITIALISE
// ------------------------------------------------------------

Future<void> initialise() async {
if (_isLoading) {
return;
}

_isLoading = true;
notifyListeners();

try {
_isAvailable = await _inAppPurchase.isAvailable();

if (!_isAvailable) {
debugPrint(
'SPIRIT TRACE: In-app purchases are unavailable.',
);
return;
}

final ProductDetailsResponse response =
await _inAppPurchase.queryProductDetails(
<String>{proProductId},
);

if (response.error != null) {
debugPrint(
'SPIRIT TRACE product query error: '
'${response.error}',
);
return;
}

if (response.productDetails.isEmpty) {
debugPrint(
'SPIRIT TRACE PRO product was not found.',
);
return;
}

for (final ProductDetails product in response.productDetails) {
if (product.id == proProductId) {
_proProduct = product;

debugPrint(
'SPIRIT TRACE PRO found: '
'${product.id} '
'${product.price}',
);

break;
}
}
} catch (e) {
debugPrint(
'SPIRIT TRACE purchase initialisation error: $e',
);
} finally {
_isLoading = false;
notifyListeners();
}
}

// ------------------------------------------------------------
// BUY PRO
// ------------------------------------------------------------

Future<void> buyPro() async {
if (_isLoading) {
return;
}

if (!_isAvailable) {
await initialise();
}

if (_proProduct == null) {
debugPrint(
'SPIRIT TRACE PRO product is unavailable.',
);
return;
}

try {
final PurchaseParam purchaseParam = PurchaseParam(
productDetails: _proProduct!,
);

debugPrint(
'SPIRIT TRACE: Starting PRO purchase.',
);

await _inAppPurchase.buyNonConsumable(
purchaseParam: purchaseParam,
);
} catch (e) {
debugPrint(
'SPIRIT TRACE PRO purchase error: $e',
);
}
}

// ------------------------------------------------------------
// RESTORE PURCHASE
// ------------------------------------------------------------

Future<void> restorePurchases() async {
if (_isLoading) {
return;
}

try {
_isLoading = true;
notifyListeners();

debugPrint(
'SPIRIT TRACE: Restoring purchases.',
);

await _inAppPurchase.restorePurchases();
} catch (e) {
debugPrint(
'SPIRIT TRACE restore error: $e',
);
} finally {
_isLoading = false;
notifyListeners();
}
}

// ------------------------------------------------------------
// HANDLE PURCHASE UPDATES
// ------------------------------------------------------------

Future<void> _handlePurchaseUpdates(
List<PurchaseDetails> purchases,
) async {
for (final PurchaseDetails purchase in purchases) {
if (purchase.productID != proProductId) {
continue;
}

debugPrint(
'SPIRIT TRACE PRO purchase status: '
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
'SPIRIT TRACE PRO purchase is pending.',
);
break;

case PurchaseStatus.error:
debugPrint(
'SPIRIT TRACE PRO purchase error: '
'${purchase.error}',
);
break;

case PurchaseStatus.canceled:
debugPrint(
'SPIRIT TRACE PRO purchase was cancelled.',
);
break;
}

/*
* IMPORTANT:
*
* PRO is unlocked BEFORE the transaction is completed.
*/
if (purchase.pendingCompletePurchase) {
await _inAppPurchase.completePurchase(
purchase,
);
}
}
}

// ------------------------------------------------------------
// UNLOCK PRO
// ------------------------------------------------------------

void _unlockPro() {
if (_isPro) {
return;
}

_isPro = true;

debugPrint(
'SPIRIT TRACE PRO UNLOCKED',
);

notifyListeners();
}

// ------------------------------------------------------------
// MANUAL ENTITLEMENT RESET
// ------------------------------------------------------------
//
// This is deliberately private.
// The app should never allow a normal user action to turn PRO off.
//

void _lockPro() {
if (!_isPro) {
return;
}

_isPro = false;
notifyListeners();
}

// ------------------------------------------------------------
// CLEAN UP
// ------------------------------------------------------------

@override
void dispose() {
_purchaseSubscription?.cancel();
super.dispose();
}
}


