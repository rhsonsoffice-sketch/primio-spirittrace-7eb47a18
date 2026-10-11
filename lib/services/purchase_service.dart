import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../repositories/investigation_repository.dart';

/// Thin wrapper around Apple's StoreKit (via `in_app_purchase`) for the single
/// non-consumable lifetime Pro unlock. All entitlement decisions live in
/// ProProvider; this class only talks to the store and the local cache.
class PurchaseService {
  /// Must match App Store Connect exactly (Non-Consumable).
  static const String productId = 'com.spirittrace.pro';
  static const String _cacheFlag = 'pro_entitlement_cache';

  final InvestigationRepository _repository;

  PurchaseService({required InvestigationRepository repository})
      : _repository = repository;

  /// The store is only wired for iOS. The web preview has no store, and the
  /// Android billing version available on the current Flutter pin is no
  /// longer accepted by Google Play.
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  InAppPurchase get _iap => InAppPurchase.instance;

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetailsResponse> queryProduct() =>
      _iap.queryProductDetails({productId});

  Future<bool> buy(ProductDetails product) => _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );

  /// On StoreKit 2 this reads the Apple ID's current verified entitlements
  /// and emits exactly one batch on [purchaseStream].
  Future<void> restore() => _iap.restorePurchases();

  Future<void> complete(PurchaseDetails details) =>
      _iap.completePurchase(details);

  /// Offline cache only — refreshed against StoreKit on every launch.
  Future<bool> loadCachedEntitlement() => _repository.getFlag(_cacheFlag);

  Future<void> saveEntitlement(bool value) =>
      _repository.setFlag(_cacheFlag, value);
}
