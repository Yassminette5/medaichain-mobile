import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'subscription_service.dart';

/// AdMob rewarded (Android / iOS / VM avec plugin natif).
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  static const String _rewardedAdUnitAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _rewardedAdUnitIos =
      'ca-app-pub-3940256099942544/1712485313';

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get isAdReady => _rewardedAd != null;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      await loadRewardedAd();
    } catch (e) {
      debugPrint('AdService init error: $e');
    }
  }

  Future<void> loadRewardedAd() async {
    if (_isLoading) return;
    _isLoading = true;

    final adUnitId = defaultTargetPlatform == TargetPlatform.iOS
        ? _rewardedAdUnitIos
        : _rewardedAdUnitAndroid;

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      debugPrint('Ad is null. Attempting to reload...');
      await loadRewardedAd();

      // Attente jusqu'à 3 secondes pour que la pub se charge
      for (int i = 0; i < 6; i++) {
        if (_rewardedAd != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (_rewardedAd == null) {
        debugPrint('La publicité n\'a pas pu être chargée après attente.');
        return false;
      }
    }

    final completer = Completer<bool>();
    bool hasEarnedReward = false;
    bool isCreditAdded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('Publicité affichée.'),
      onAdDismissedFullScreenContent: (ad) async {
        debugPrint('Publicité fermée.');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Précharger la suivante
        
        if (hasEarnedReward && !isCreditAdded) {
          // Si l'utilisateur a fermé très vite, on s'assure d'attendre l'ajout
          await Future.delayed(const Duration(milliseconds: 1500));
        }
        if (!completer.isCompleted) completer.complete(hasEarnedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Échec de l\'affichage de la publicité: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Précharger la suivante
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        debugPrint('Récompense obtenue: ${reward.amount} ${reward.type}');
        hasEarnedReward = true;
        try {
          await SubscriptionService().addAdCredit();
          isCreditAdded = true;
        } catch (e) {
          debugPrint('Erreur lors de l\'ajout du crédit : $e');
        }
      },
    );

    return completer.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
  }
}
