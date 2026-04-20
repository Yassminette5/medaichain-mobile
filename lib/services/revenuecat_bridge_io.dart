import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'store_offer.dart';

/// Android / iOS / desktop : RevenueCat réel.
/// Si RevenueCat échoue (pas de Play Store, émulateur sans billing, etc.),
/// on retourne des offres de test pour ne pas bloquer le développement.
class RevenueCatBridge {
  static bool _configured = false;
  static bool _configFailed = false;

  static Future<void> configure(String apiKey, {String? userId}) async {
    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      debugPrint('🔑 [RevenueCat] Configuring with key: ${apiKey.substring(0, 10)}...');
      debugPrint('🔑 [RevenueCat] UserId: $userId');
      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = userId,
      );
      _configured = true;
      _configFailed = false;
      debugPrint('✅ [RevenueCat] Configuration done!');
    } catch (e) {
      debugPrint('❌ [RevenueCat] Configuration FAILED: $e');
      _configFailed = true;
    }
  }
  
  static Future<void> logIn(String userId) async {
    if (_configFailed) return;
    debugPrint('🔑 [RevenueCat] LogIn: $userId');
    await Purchases.logIn(userId);
  }

  static Future<void> logOut() async {
    if (_configFailed) return;
    await Purchases.logOut();
  }

  static Future<bool> isEntitlementActive(String entitlementId) async {
    if (_configFailed) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      debugPrint('📋 [RevenueCat] Active entitlements: ${info.entitlements.active.keys.toList()}');
      return info.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      debugPrint('❌ [RevenueCat] isEntitlementActive error: $e');
      return false;
    }
  }

  static Future<List<StoreOffer>> getStoreOffers() async {
    debugPrint('📦 [RevenueCat] Fetching offerings... (configured=$_configured, failed=$_configFailed)');
    
    // Si RevenueCat n'a pas pu se configurer, retourner des offres de test
    if (_configFailed) {
      debugPrint('⚠️ [RevenueCat] Config failed → returning mock offers for testing');
      return _getMockOffers();
    }
    
    try {
      final offerings = await Purchases.getOfferings();
      
      // Debug: lister toutes les offerings
      debugPrint('📦 [RevenueCat] All offerings: ${offerings.all.keys.toList()}');
      debugPrint('📦 [RevenueCat] Current offering: ${offerings.current?.identifier ?? "NULL"}');
      
      // Chercher l'offering current, sinon fallback par nom
      final offering = offerings.current 
          ?? offerings.all['offre'] 
          ?? offerings.all['default'];
      
      if (offering == null) {
        debugPrint('❌ [RevenueCat] Aucun offering trouvé → returning mock offers');
        return _getMockOffers();
      }
      
      final packages = offering.availablePackages;
      debugPrint('📦 [RevenueCat] Packages trouvés: ${packages.length}');
      
      if (packages.isEmpty) {
        debugPrint('⚠️ [RevenueCat] 0 packages → returning mock offers');
        return _getMockOffers();
      }
      
      for (final p in packages) {
        debugPrint('  📦 ${p.identifier} → ${p.storeProduct.title} (${p.storeProduct.priceString})');
      }
      
      return packages
          .map(
            (p) => StoreOffer(
              title: p.storeProduct.title,
              priceString: p.storeProduct.priceString,
              nativePackage: p,
            ),
          )
          .toList();
    } catch (e, stack) {
      debugPrint('❌ [RevenueCat] Erreur getStoreOffers: $e');
      debugPrint('❌ [RevenueCat] Stack: $stack');
      debugPrint('⚠️ [RevenueCat] Returning mock offers as fallback');
      return _getMockOffers();
    }
  }

  /// Offres de test utilisées quand RevenueCat ne fonctionne pas
  /// (émulateur sans Play Store, mode debug, etc.)
  static List<StoreOffer> _getMockOffers() {
    return [
      const StoreOffer(
        title: 'Premium Mensuel',
        priceString: '0,99 €/mois',
        nativePackage: null, // pas de package natif en mock
      ),
      const StoreOffer(
        title: 'Premium Annuel',
        priceString: '9,99 €/an',
        nativePackage: null,
      ),
    ];
  }

  static Future<bool> purchase(
    StoreOffer offer,
    String entitlementId,
  ) async {
    final native = offer.nativePackage;
    // En mode mock (nativePackage == null), simuler un achat réussi
    if (native == null) {
      debugPrint('🧪 [RevenueCat] Mock purchase — simulating success');
      return true;
    }
    if (native is! Package) return false;
    final result = await Purchases.purchasePackage(native);
    return result.entitlements.active.containsKey(entitlementId);
  }

  static Future<bool> restorePurchases(String entitlementId) async {
    if (_configFailed) {
      debugPrint('🧪 [RevenueCat] Mock restore — no purchases');
      return false;
    }
    final info = await Purchases.restorePurchases();
    return info.entitlements.active.containsKey(entitlementId);
  }

  static void addCustomerInfoListener(VoidCallback onUpdate) {
    if (_configFailed) return;
    Purchases.addCustomerInfoUpdateListener((_) => onUpdate());
  }
}
