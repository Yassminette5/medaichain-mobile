import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AdService — Implémentation WEB
/// ─────────────────────────────────────────────────────────────────────────────
///
/// POURQUOI CE FICHIER EXISTE :
/// Google Mobile Ads (AdMob) est une SDK NATIVE Android/iOS uniquement.
/// Elle n'a aucun support Flutter Web officiel.
///
/// Sur web, la pub est gérée différemment :
///   → PremiumPaywallScreen détecte kIsWeb = true
///   → Affiche un dialog countdown de 10 secondes (_WebAdCountdownDialog)
///   → Après le countdown, appelle SubscriptionService().addAdCredit()
///   → Le crédit est accordé via le backend (même endpoint que mobile)
///
/// Ce fichier est donc un STUB — showRewardedAd() n'est jamais appelé
/// directement sur web (le paywall contourne via _watchAdWeb()).
///
/// Sélection automatique par Flutter :
///   ad_service.dart  →  export 'ad_service_web.dart'
///                   if (dart.library.io) 'ad_service_mobile.dart';
/// ─────────────────────────────────────────────────────────────────────────────
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  /// Toujours true sur web — le bouton "Regarder une pub" est toujours visible.
  /// Le vrai contrôle du flux se fait dans PremiumPaywallScreen._watchAdWeb().
  bool get isAdReady => true;

  /// Pas de chargement asynchrone nécessaire sur web.
  bool get isLoading => false;

  /// Aucune initialisation SDK nécessaire sur web.
  Future<void> initialize() async {
    debugPrint('[AdService Web] Mode web détecté — AdMob désactivé. '
        'La pub est simulée via dialog countdown dans PremiumPaywallScreen.');
  }

  /// Aucun pré-chargement nécessaire sur web.
  Future<void> loadRewardedAd() async {}

  /// Sur web, cette méthode ne doit PAS être appelée directement.
  /// PremiumPaywallScreen._watchAdWeb() gère le flux web complet.
  ///
  /// Si appelée par erreur, retourne false sans rien faire.
  Future<bool> showRewardedAd() async {
    debugPrint('[AdService Web] showRewardedAd() appelé directement sur web — '
        'ignoré. Utilisez PremiumPaywallScreen._watchAdWeb() à la place.');
    return false;
  }

  void dispose() {}
}
