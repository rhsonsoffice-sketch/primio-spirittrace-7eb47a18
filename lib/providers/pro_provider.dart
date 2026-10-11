import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/purchase_service.dart';

enum ProStatus { idle, loading, purchasing, pending, success, cancelled, error }

/// App-global Pro entitlement. Pro is granted only when StoreKit reports the
/// product as purchased or restored; a tap, a pending or a cancelled/failed
/// transaction never grants it.
class ProProvider extends ChangeNotifier {
  final PurchaseService _service;

  ProProvider({required PurchaseService service}) : _service = service;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _isPro = false;
  bool get isPro => _isPro;

  bool get storeSupported => _service.isSupported;

  ProductDetails? _product;
  ProductDetails? get product => _product;

  ProStatus _status = ProStatus.idle;
  ProStatus get status => _status;

  String? _errorKey;
  String? get errorKey => _errorKey;
  String? _errorDetail;
  String? get errorDetail => _errorDetail;

  String? _noticeKey;
  String? get noticeKey => _noticeKey;

  bool _restoring = false;
  bool get restoring => _restoring;

  bool get busy =>
      _status == ProStatus.purchasing || _status == ProStatus.pending;

  bool get canBuy =>
      storeSupported &&
      _product != null &&
      !_isPro &&
      !busy &&
      _status != ProStatus.loading;

  // Refresh (restorePurchases) bookkeeping.
  bool _refreshInFlight = false;
  bool _refreshBatchSeen = false;
  bool _refreshCallDone = false;
  bool _refreshFound = false;
  bool _userRestore = false;

  Future<void> init() async {
    _isPro = await _service.loadCachedEntitlement();
    notifyListeners();
    if (!storeSupported) return;
    _sub = _service.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) => _setError('proPurchaseFailed', '$e'),
    );
    await loadProduct();
    await _refresh(userInitiated: false);
  }

  Future<void> loadProduct() async {
    _status = ProStatus.loading;
    _errorKey = null;
    notifyListeners();
    try {
      if (!await _service.isAvailable()) {
        _setError('proStoreUnavailable');
        return;
      }
      final res = await _service.queryProduct();
      if (res.error != null) {
        _setError('proLoadFailed', res.error!.message);
        return;
      }
      if (res.productDetails.isEmpty) {
        _setError('proNotFound', PurchaseService.productId);
        return;
      }
      _product = res.productDetails.first;
      _status = ProStatus.idle;
      notifyListeners();
    } catch (e) {
      _setError('proLoadFailed', '$e');
    }
  }

  Future<void> buy() async {
    if (!canBuy) return;
    _status = ProStatus.purchasing;
    _errorKey = null;
    _noticeKey = null;
    notifyListeners();
    try {
      final started = await _service.buy(_product!);
      if (!started) _setError('proPurchaseFailed');
    } catch (e) {
      _setError('proPurchaseFailed', '$e');
    }
  }

  Future<void> restore() => _refresh(userInitiated: true);

  Future<void> _refresh({required bool userInitiated}) async {
    if (_refreshInFlight || !storeSupported) return;
    _refreshInFlight = true;
    _refreshBatchSeen = false;
    _refreshCallDone = false;
    _refreshFound = false;
    _userRestore = userInitiated;
    if (userInitiated) {
      _restoring = true;
      _noticeKey = null;
      _errorKey = null;
      if (_status == ProStatus.error || _status == ProStatus.cancelled) {
        _status = ProStatus.idle;
      }
      notifyListeners();
    }
    try {
      await _service.restore();
    } catch (e) {
      // Refresh failed: keep the cached entitlement, never revoke here.
      _refreshInFlight = false;
      _restoring = false;
      if (userInitiated) {
        _setError('proRestoreFailed', '$e');
      } else {
        notifyListeners();
      }
      return;
    }
    _refreshCallDone = true;
    _maybeFinishRefresh();
  }

  void _maybeFinishRefresh() {
    if (!_refreshInFlight || !_refreshCallDone || !_refreshBatchSeen) return;
    // Successful refresh that no longer contains the product → revoke
    // (refund / revoked). Covers a stale offline cache too.
    if (!_refreshFound && _isPro) {
      _isPro = false;
      unawaited(_service.saveEntitlement(false));
    }
    if (_userRestore) {
      _noticeKey = _refreshFound ? 'proRestored' : 'proRestoreNone';
    }
    _refreshInFlight = false;
    _restoring = false;
    notifyListeners();
  }

  Future<void> _onPurchases(List<PurchaseDetails> batch) async {
    final isRefreshBatch = _refreshInFlight &&
        batch.every((p) => p.status == PurchaseStatus.restored);
    for (final p in batch) {
      await _handle(p, inRefresh: isRefreshBatch);
    }
    if (isRefreshBatch) {
      _refreshBatchSeen = true;
      _maybeFinishRefresh();
    }
  }

  Future<void> _handle(PurchaseDetails p, {required bool inRefresh}) async {
    if (p.productID != PurchaseService.productId) {
      await _finish(p);
      return;
    }
    switch (p.status) {
      case PurchaseStatus.pending:
        _status = ProStatus.pending;
        notifyListeners();
        return; // never granted, never completed while pending
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        if (inRefresh) _refreshFound = true;
        // Grant durably first, then finish the transaction.
        _isPro = true;
        await _service.saveEntitlement(true);
        if (p.status == PurchaseStatus.purchased) _status = ProStatus.success;
        if (busy) _status = ProStatus.success;
        _errorKey = null;
        notifyListeners();
        await _finish(p);
        return;
      case PurchaseStatus.error:
        _setError('proPurchaseFailed', p.error?.message);
        await _finish(p);
        return;
      case PurchaseStatus.canceled:
        _status = ProStatus.cancelled;
        notifyListeners();
        await _finish(p);
        return;
    }
  }

  Future<void> _finish(PurchaseDetails p) async {
    if (!p.pendingCompletePurchase) return;
    try {
      await _service.complete(p);
    } catch (_) {
      // Grant is kept; StoreKit re-delivers the transaction on the next
      // refresh and completion is retried there.
    }
  }

  void _setError(String key, [String? detail]) {
    _status = ProStatus.error;
    _errorKey = key;
    _errorDetail = detail;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
