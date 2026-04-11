import 'package:flutter/foundation.dart';
import 'store_offer.dart';

/// Web : pas de SDK RevenueCat dans le navigateur (même binaire).
class RevenueCatBridge {
  static Future<void> configure(String apiKey, {String? userId}) async {}

  static Future<void> logIn(String userId) async {}

  static Future<void> logOut() async {}

  static Future<bool> isEntitlementActive(String entitlementId) async => false;

  static Future<List<StoreOffer>> getStoreOffers() async => [];

  static Future<bool> purchase(
    StoreOffer offer,
    String entitlementId,
  ) async =>
      false;

  static Future<bool> restorePurchases(String entitlementId) async => false;

  static void addCustomerInfoListener(VoidCallback onUpdate) {}
}
