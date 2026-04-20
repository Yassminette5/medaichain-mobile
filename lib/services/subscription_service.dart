import 'package:flutter/foundation.dart';
import 'revenuecat_bridge.dart';
import 'store_offer.dart';
import 'api_service.dart';

/// Gère l'abonnement premium via RevenueCat et les crédits IA backend.
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  // Test Store key (medaichain-v2) pour le développement / debug
  static const String _revenueCatApiKeyAndroid =
      'test_mThrMrvmkejjQOaswkPPTrxmuLA';
  // TODO: Remplacer par la vraie clé Play Store pour la production
  static const String _revenueCatApiKeyIos = 'test_mThrMrvmkejjQOaswkPPTrxmuLA';

  static const String _premiumEntitlement = 'Create a project called medaichain-v2 Pro';

  bool _isPremium = false;
  bool _isInitialized = false;
  int _adCredits = 0;
  String? _plan = 'free';

  bool get isPremium => _isPremium;
  bool get isInitialized => _isInitialized;
  int get adCredits => _adCredits;
  String? get plan => _plan;

  bool get hasAiAccess => _isPremium || _adCredits > 0;

  Future<void> initialize({String? userId}) async {
    try {
      if (kIsWeb) {
        await refreshBackendStatus();
        _isInitialized = true;
        notifyListeners();
        return;
      }

      final apiKey = defaultTargetPlatform == TargetPlatform.iOS
          ? _revenueCatApiKeyIos
          : _revenueCatApiKeyAndroid;

      if (!_isInitialized) {
        // Première configuration
        await RevenueCatBridge.configure(apiKey, userId: userId);
        RevenueCatBridge.addCustomerInfoListener(_checkPremiumStatus);
        _isInitialized = true;
      } else if (userId != null) {
        // Déjà configuré : on identifie l'utilisateur actuel
        await RevenueCatBridge.logIn(userId);
      }

      await _checkPremiumStatus();
      await refreshBackendStatus();
      notifyListeners();
    } catch (e) {
      debugPrint('SubscriptionService init error: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      if (!kIsWeb) {
        await RevenueCatBridge.logOut();
      }
      _isPremium = false;
      _adCredits = 0;
      _plan = 'free';
      notifyListeners();
    } catch (e) {
      debugPrint('SubscriptionService logout error: $e');
    }
  }

  Future<void> refreshBackendStatus() async {
    try {
      final status = await ApiService.getMySubscriptionStatus();
      _adCredits = status['aiCredits'] ?? 0;
      _plan = status['plan'] ?? 'free';
      // Mettre à jour isPremium basé sur le backend si on veut
      // Mais RevenueCatBridge est plus précis pour le statut local
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching backend subscription status: $e');
    }
  }

  Future<void> _checkPremiumStatus() async {
    try {
      _isPremium = await RevenueCatBridge.isEntitlementActive(
        _premiumEntitlement,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Check premium error: $e');
    }
  }

  Future<List<StoreOffer>> getAvailableStoreOffers() async {
    try {
      return await RevenueCatBridge.getStoreOffers();
    } catch (e) {
      debugPrint('Get offerings error: $e');
      return [];
    }
  }

  Future<bool> purchaseStoreOffer(StoreOffer offer) async {
    try {
      _isPremium = await RevenueCatBridge.purchase(offer, _premiumEntitlement);
      await refreshBackendStatus();
      notifyListeners();
      return _isPremium;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      _isPremium = await RevenueCatBridge.restorePurchases(_premiumEntitlement);
      await refreshBackendStatus();
      notifyListeners();
      return _isPremium;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  Future<void> addAdCredit() async {
    // Optimistic UI update: on donne immédiatement le crédit local
    // pour ne pas bloquer l'utilisateur s'il a vu la vidéo ("hasEarnedReward" = true)
    _adCredits += 1;
    notifyListeners();

    try {
      final backendCredits = await ApiService.addAdCredit();
      _adCredits = backendCredits; // Remplacer par la vraie valeur DB
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding ad credit to backend: $e');
      // On garde _adCredits incrémenté localement pour cet usage précis
      // car Google AdMob a déjà acté que la vidéo a été vue jusqu'au bout.
    }
  }

  Future<bool> useAdCredit() async {
    if (_isPremium) return true;
    if (_adCredits <= 0) return false;

    // On ne déduit plus le crédit ici car le backend le déduit
    // dans le SubscriptionGuard ou lors de l'appel AI.
    // On fait juste une mise à jour locale en attendant le rafraîchissement complet.
    _adCredits--;
    notifyListeners();
    return true;
  }
}
