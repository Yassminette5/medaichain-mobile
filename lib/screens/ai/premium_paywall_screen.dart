import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';
import 'dart:async';

import '../../core/theme/app_colors.dart';
import '../../services/subscription_service.dart';
import '../../services/revenuecat_bridge.dart';
import '../../services/ad_service.dart';
import '../../services/store_offer.dart';

/// Écran paywall affiché quand le médecin n'a pas d'accès premium.
/// Deux options : regarder une pub vidéo (gratuit) ou s'abonner.
class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  final _subService = SubscriptionService();
  final _adService = AdService();
  List<StoreOffer> _packages = [];
  bool _isLoadingPackages = true;
  bool _isWatchingAd = false;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final packages = await _subService.getAvailableStoreOffers();
    if (mounted) {
      setState(() {
        _packages = packages;
        _isLoadingPackages = false;
      });
    }
  }

  Future<void> _watchAd() async {
    if (kIsWeb) {
      await _watchAdWeb();
    } else {
      await _watchAdMobile();
    }
  }

  /// Sur mobile : flux AdMob natif (Android / iOS)
  Future<void> _watchAdMobile() async {
    setState(() => _isWatchingAd = true);
    final success = await _adService.showRewardedAd();
    if (mounted) {
      setState(() => _isWatchingAd = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crédit IA gagné ! Vous pouvez lancer une analyse.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pub non disponible, réessayez dans un instant.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Sur web : simulation pub avec compte à rebours + crédit backend
  /// AdMob n'existe pas sur Flutter Web — on simule une pub de 10 secondes.
  Future<void> _watchAdWeb() async {
    setState(() => _isWatchingAd = true);

    final watched = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _WebAdCountdownDialog(),
    );

    if (!mounted) return;
    setState(() => _isWatchingAd = false);

    if (watched == true) {
      try {
        // Accorder le crédit via le backend (même chemin que mobile)
        await _subService.addAdCredit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text('Crédit IA gagné ! Vous pouvez lancer une analyse.'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'ajout du crédit : $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _purchase(StoreOffer offer) async {
    // Mode test : notre popup glassmorphism en premier
    if (RevenueCatBridge.isTestMode) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TestPurchaseDialog(offer: offer),
      );
      if (confirmed != true || !mounted) return;

      setState(() => _isPurchasing = true);
      
      // On lance le paiement natif RevenueCat juste après pour l'enregistrer dans le dashboard
      final successNative = await _subService.purchaseNative(offer);
      
      if (mounted) {
        setState(() => _isPurchasing = false);
        if (successNative) {
          Navigator.of(context).pop(true);
        }
      }
      return;
    }

    // Production : achat réel via le store natif (Google Play / App Store)
    setState(() => _isPurchasing = true);
    final success = await _subService.purchaseStoreOffer(offer);
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _restore() async {
    final success = await _subService.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Abonnement restauré !' : 'Aucun abonnement trouvé.',
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
      if (success) Navigator.of(context).pop(true);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final credits = _subService.adCredits;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          // Arrière-plan avec orbes lumineuses pour l'effet premium
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D9FF).withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 40,
                                    spreadRadius: -10,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Crown Icon
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 36),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  const Text(
                                    'MEDAIChain Pro',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  Text(
                                    "Accédez à la puissance illimitée de l'IA médicale sans interruption.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Crédits actuels
                                  if (credits > 0) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.bolt_rounded, color: Color(0xFF00D9FF), size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Vous avez $credits crédit${credits > 1 ? 's' : ''} IA',
                                            style: const TextStyle(
                                              color: Color(0xFF00D9FF),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  
                                  // Features
                                  _buildFeatureRow(Icons.check_circle_rounded, 'Analyses IA illimitées & rapides'),
                                  _buildFeatureRow(Icons.check_circle_rounded, 'Suggestions de diagnostics expertes'),
                                  _buildFeatureRow(Icons.check_circle_rounded, 'Zéro publicité, 100% focus'),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Abonnement
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF00D9FF), Color(0xFF007BFF)],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00D9FF).withValues(alpha: 0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: (_isLoadingPackages || _isPurchasing || _packages.isEmpty)
                                            ? null
                                            : () => _purchase(_packages.first),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                        child: Text(
                                          _isLoadingPackages
                                              ? 'Chargement...'
                                              : _isPurchasing
                                                  ? 'Activation...'
                                                  : 'Devenir Pro - ${_packages.isNotEmpty ? _packages.first.priceString : ""}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Regarder Pub
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: OutlinedButton(
                                      onPressed: _isWatchingAd ? null : _watchAd,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.play_circle_fill_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isWatchingAd ? 'Chargement...' : 'Regarder une pub (1 crédit)',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  if (!isWeb) ...[
                                    const SizedBox(height: 20),
                                    GestureDetector(
                                      onTap: _restore,
                                      child: Text(
                                        'Restaurer mes achats',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 13,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF00D9FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
/// Simulation premium — Web uniquement.
/// Affiche un écran glassmorphism avec compte à rebours avant d'accorder le crédit.
// ─────────────────────────────────────────────────────────────────────────────
class _WebAdCountdownDialog extends StatefulWidget {
  const _WebAdCountdownDialog();

  @override
  State<_WebAdCountdownDialog> createState() => _WebAdCountdownDialogState();
}

class _WebAdCountdownDialogState extends State<_WebAdCountdownDialog>
    with TickerProviderStateMixin {
  static const int _totalSeconds = 10;
  int _remaining = _totalSeconds;
  Timer? _timer;
  bool _rewardGranted = false;
  bool _canClose = false;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _remaining = 0;
          _rewardGranted = true;
          t.cancel();
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) setState(() => _canClose = true);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalSeconds - _remaining) / _totalSeconds;

    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF0A0E1A),
      child: Stack(
        children: [
          // ── Orbes lumineux animés ─────────────────────────────────
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateController.value * 2 * 3.14159,
                child: child,
              );
            },
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00D9FF).withValues(alpha: 0.2),
                          const Color(0xFF00D9FF).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.4,
                  left: MediaQuery.of(context).size.width * 0.5 - 100,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFD700).withValues(alpha: 0.1),
                          const Color(0xFFFFD700).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Contenu principal ──────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Icône animée ──────────────────────────────
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + (_pulseController.value * 0.08);
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: _rewardGranted
                                ? const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00C853)])
                                : const LinearGradient(colors: [Color(0xFF00D9FF), Color(0xFF007BFF)]),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_rewardGranted ? const Color(0xFF00E676) : const Color(0xFF00D9FF))
                                    .withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _rewardGranted ? Icons.check_rounded : Icons.bolt_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Titre ──────────────────────────────────────
                      Text(
                        _rewardGranted ? 'Crédit Obtenu !' : 'Obtenir un Crédit IA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        _rewardGranted
                            ? 'Votre crédit IA a été ajouté avec succès.'
                            : 'Patientez quelques secondes pour\nobtenir votre crédit gratuit.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Carte glassmorphism ────────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                // ── Circular progress ───────────────
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 6,
                                          strokeCap: StrokeCap.round,
                                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _rewardGranted
                                                ? const Color(0xFF00E676)
                                                : const Color(0xFF00D9FF),
                                          ),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _rewardGranted ? '✓' : '$_remaining',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: _rewardGranted ? 36 : 40,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          if (!_rewardGranted)
                                            Text(
                                              'secondes',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.5),
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── Features ─────────────────────────
                                _buildMiniFeature(Icons.smart_toy_rounded, 'Analyse IA médicale'),
                                const SizedBox(height: 10),
                                _buildMiniFeature(Icons.speed_rounded, 'Résultat instantané'),
                                const SizedBox(height: 10),
                                _buildMiniFeature(Icons.shield_rounded, 'Données sécurisées'),

                                const SizedBox(height: 24),

                                // ── Bouton ────────────────────────────
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: _canClose
                                      ? SizedBox(
                                          key: const ValueKey('btn_ready'),
                                          width: double.infinity,
                                          height: 54,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF00E676), Color(0xFF00C853)],
                                              ),
                                              borderRadius: BorderRadius.circular(18),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF00E676).withValues(alpha: 0.4),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton.icon(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                                              label: const Text(
                                                'Utiliser mon crédit',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(18),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : SizedBox(
                                          key: const ValueKey('btn_wait'),
                                          width: double.infinity,
                                          height: 54,
                                          child: OutlinedButton(
                                            onPressed: null,
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(18),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white.withValues(alpha: 0.4),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'Préparation du crédit...',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.5),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Annuler ────────────────────────────────────
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00D9FF), size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Test Purchase Dialog — Glassmorphism style
/// Simulates a RevenueCat purchase confirmation (sandbox/test mode).
// ─────────────────────────────────────────────────────────────────────────────
class _TestPurchaseDialog extends StatefulWidget {
  final StoreOffer offer;
  const _TestPurchaseDialog({required this.offer});

  @override
  State<_TestPurchaseDialog> createState() => _TestPurchaseDialogState();
}

class _TestPurchaseDialogState extends State<_TestPurchaseDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmPurchase() async {
    setState(() => _isProcessing = true);
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A1F3A).withValues(alpha: 0.95),
                            const Color(0xFF0F1329).withValues(alpha: 0.98),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D9FF).withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge "Test Mode"
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.science_rounded,
                                    color: Colors.amber, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'SANDBOX TEST',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Crown icon
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.diamond_rounded,
                                color: Colors.white, size: 32),
                          ),

                          const SizedBox(height: 20),

                          // Title
                          const Text(
                            'Confirmer l\'abonnement',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            widget.offer.title,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Price card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00D9FF).withValues(alpha: 0.1),
                                  const Color(0xFF007BFF).withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF00D9FF)
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  widget.offer.priceString,
                                  style: const TextStyle(
                                    color: Color(0xFF00D9FF),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Renouvellement automatique',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Features
                          _buildCheckItem('Analyses IA illimitées'),
                          const SizedBox(height: 8),
                          _buildCheckItem('Aucune publicité'),
                          const SizedBox(height: 8),
                          _buildCheckItem('Support prioritaire'),
                          const SizedBox(height: 8),
                          _buildCheckItem('Annulable à tout moment'),

                          const SizedBox(height: 28),

                          // Confirm button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00D9FF), Color(0xFF007BFF)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D9FF)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    _isProcessing ? null : _confirmPurchase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isProcessing
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Traitement en cours...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Confirmer l\'achat',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Cancel
                          TextButton(
                            onPressed: _isProcessing
                                ? null
                                : () => Navigator.of(context).pop(false),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded,
            color: Color(0xFF00D9FF), size: 18),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
