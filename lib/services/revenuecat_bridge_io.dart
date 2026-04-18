import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'store_offer.dart';

/// Android / iOS / desktop : RevenueCat réel.
class RevenueCatBridge {
  static Future<void> configure(String apiKey, {String? userId}) async {
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }
    await Purchases.configure(
      PurchasesConfiguration(apiKey)..appUserID = userId,
    );
  }
  
  static Future<void> logIn(String userId) async {
    await Purchases.logIn(userId);
  }

  static Future<void> logOut() async {
    await Purchases.logOut();
  }

  static Future<bool> isEntitlementActive(String entitlementId) async {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(entitlementId);
  }

  static Future<List<StoreOffer>> getStoreOffers() async {
    final offerings = await Purchases.getOfferings();
    final packages = offerings.current?.availablePackages ?? [];
    return packages
        .map(
          (p) => StoreOffer(
            title: p.storeProduct.title,
            priceString: p.storeProduct.priceString,
            nativePackage: p,
          ),
        )
        .toList();
  }

  static Future<bool> purchase(
    StoreOffer offer,
    String entitlementId,
  ) async {
    final native = offer.nativePackage;
    if (native is! Package) return false;
    final result = await Purchases.purchasePackage(native);
    return result.entitlements.active.containsKey(entitlementId);
  }

  static Future<bool> restorePurchases(String entitlementId) async {
    final info = await Purchases.restorePurchases();
    return info.entitlements.active.containsKey(entitlementId);
  }

  static void addCustomerInfoListener(VoidCallback onUpdate) {
    Purchases.addCustomerInfoUpdateListener((_) => onUpdate());
  }
}
