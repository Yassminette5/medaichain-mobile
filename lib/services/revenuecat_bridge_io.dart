import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'store_offer.dart';

/// Android / iOS / desktop : RevenueCat réel.
/// Si RevenueCat échoue (pas de Play Store, émulateur sans billing, etc.),
/// on retourne des offres de test pour ne pas bloquer le développement.
class RevenueCatBridge {
  static bool _configured = false;
  static bool _configFailed = false;
  static String _apiKey = '';

  /// True si on utilise une clé test (pas de vrai store billing)
  static bool get isTestMode => _apiKey.startsWith('test_') || _configFailed;

  static Future<void> configure(String apiKey, {String? userId}) async {
    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      _apiKey = apiKey;
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
    String entitlementId, {
    bool skipNativeDialog = false,
  }) async {
    final native = offer.nativePackage;
    // En mode mock (nativePackage == null) ou skipNativeDialog, simuler un achat réussi
    if (native == null || skipNativeDialog) {
      debugPrint('🧪 [RevenueCat] Simulated purchase — skipping native dialog');
      return true;
    }
    if (native is! Package) return false;
    final result = await Purchases.purchasePackage(native);
    return result.customerInfo.entitlements.active.containsKey(entitlementId);
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

  /// Accorde un entitlement promotionnel via l'API REST de RevenueCat.
  /// Permet d'enregistrer l'achat dans le dashboard SANS le popup natif.
  /// Si l'API REST échoue, retourne false pour permettre un fallback.
  static Future<bool> grantTestEntitlement(String entitlementId) async {
    try {
      // Récupérer l'ID utilisateur RevenueCat
      final customerInfo = await Purchases.getCustomerInfo();
      final userId = customerInfo.originalAppUserId;
      final encodedUserId = Uri.encodeComponent(userId);
      final encodedEntitlement = Uri.encodeComponent(entitlementId);

      debugPrint('🎁 [RevenueCat] Granting promotional to $userId...');
      debugPrint('🎁 [RevenueCat] Entitlement: $entitlementId');

      final response = await http.post(
        Uri.parse(
          'https://api.revenuecat.com/v1/subscribers/$encodedUserId/entitlements/$encodedEntitlement/promotional',
        ),
        headers: {
          'Authorization': 'Bearer sk_lRylLBWppkQBdxzjmOCjKoKDcacBl',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'duration': 'monthly'}),
      ).timeout(const Duration(seconds: 10));

      debugPrint('🎁 [RevenueCat] Grant response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await Purchases.invalidateCustomerInfoCache();
        debugPrint('✅ [RevenueCat] Entitlement granted via REST API!');
        return true;
      } else {
        debugPrint('❌ [RevenueCat] Grant failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [RevenueCat] Grant promotional error: $e');
      return false;
    }
  }

  /// Achat via le SDK natif (affiche le popup natif RevenueCat)
  /// Utilisé en fallback quand l'API REST ne fonctionne pas.
  static Future<bool> purchaseNative(
    StoreOffer offer,
    String entitlementId,
  ) async {
    final native = offer.nativePackage;
    if (native == null || native is! Package) {
      debugPrint('🧪 [RevenueCat] No native package — simulating success');
      return true;
    }
    debugPrint('📱 [RevenueCat] Launching native purchase dialog...');
    final result = await Purchases.purchasePackage(native);
    return result.customerInfo.entitlements.active.containsKey(entitlementId);
  }
}
