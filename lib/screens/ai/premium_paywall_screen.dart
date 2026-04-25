import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:math';
import '../../core/theme/app_colors.dart';
import '../../services/subscription_service.dart';
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
    setState(() => _isPurchasing = true);
    final success = await _subService.purchaseStoreOffer(offer);
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement Premium activé !'),
            backgroundColor: Colors.green,
          ),
        );
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
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final credits = _subService.adCredits;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
          children: [
            const SizedBox(height: 8),

            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.aiGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.colored(AppColors.secondary),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'IA Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accédez à l\'analyse IA pour diagnostics, ordonnances et conseils médicaux',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Crédits actuels
            if (credits > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.token, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous avez $credits crédit${credits > 1 ? 's' : ''} IA disponible${credits > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Option 1 : Regarder une pub
            _buildOptionCard(
              icon: Icons.play_circle_filled,
              iconColor: AppColors.info,
              title: 'Gratuit - Regarder une vidéo',
              subtitle:
                  'Regardez une courte vidéo publicitaire\npour gagner 1 crédit d\'analyse IA',
              buttonText: _isWatchingAd ? 'Chargement...' : 'Regarder la vidéo',
              buttonGradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
              ),
              onPressed: _isWatchingAd ? null : _watchAd,
              badge: 'GRATUIT',
              badgeColor: AppColors.info,
            ),

            const SizedBox(height: 16),

            // Option 2 : Abonnement Premium
            _buildOptionCard(
              icon: Icons.diamond,
              iconColor: AppColors.secondary,
              title: 'Premium - Analyses illimitées',
              subtitle:
                  'Accès illimité à l\'IA médicale\nSans publicités, priorité de traitement',
              buttonText: _isLoadingPackages
                  ? 'Chargement...'
                  : _isPurchasing
                      ? 'Achat en cours...'
                      : 'S\'abonner',
              buttonGradient: AppColors.aiGradient,
              onPressed: (_isLoadingPackages || _isPurchasing || _packages.isEmpty)
                  ? null
                  : () {
                      _purchase(_packages.first);
                    },
              badge: 'RECOMMANDÉ',
              badgeColor: AppColors.secondary,
              packages: _packages,
            ),

            const SizedBox(height: 16),

            // Avantages Premium
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Avantages Premium',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    Icons.all_inclusive,
                    'Analyses IA illimitées',
                  ),
                  _buildFeatureRow(Icons.speed, 'Priorité de traitement'),
                  _buildFeatureRow(Icons.block, 'Sans publicités'),
                  _buildFeatureRow(
                    Icons.medical_services,
                    'Suggestions d\'ordonnances',
                  ),
                  _buildFeatureRow(Icons.insights, 'Diagnostics avancés'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Restaurer
            if (!isWeb)
              TextButton(
                onPressed: _restore,
                child: const Text(
                  'Restaurer un achat existant',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),

            const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      }

          Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required LinearGradient buttonGradient,
    required VoidCallback? onPressed,
    required String badge,
    required Color badgeColor,
    List<StoreOffer>? packages,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.small,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (packages != null && packages.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...packages.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${p.title} - ${p.priceString}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: onPressed != null ? buttonGradient : null,
                color: onPressed == null ? Colors.grey[300] : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
/// Données d'une publicité simulée pour le web.
// ─────────────────────────────────────────────────────────────────────────────
class _AdData {
  final String appName;
  final String tagline;
  final String cta;
  final IconData icon;
  final Color bgColor;
  final Color accentColor;
  final List<Color> gradientColors;

  const _AdData({
    required this.appName,
    required this.tagline,
    required this.cta,
    required this.icon,
    required this.bgColor,
    required this.accentColor,
    required this.gradientColors,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
/// Simulation plein écran de pub — Web uniquement.
/// Affiche aléatoirement l'une des 8 publicités différentes à chaque ouverture.
/// Reproduit fidèlement l'expérience Google Ads Test Ad sur mobile.
// ─────────────────────────────────────────────────────────────────────────────
class _WebAdCountdownDialog extends StatefulWidget {
  const _WebAdCountdownDialog();

  @override
  State<_WebAdCountdownDialog> createState() => _WebAdCountdownDialogState();
}

class _WebAdCountdownDialogState extends State<_WebAdCountdownDialog>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 10;
  int _remaining = _totalSeconds;
  Timer? _timer;
  bool _rewardGranted = false;
  bool _canClose = false;
  late AnimationController _pulseController;
  late _AdData _currentAd;

  // ── Pool de 8 publicités variées ──────────────────────────────────────────
  static final List<_AdData> _adPool = [
    const _AdData(
      appName: 'Uber Eats',
      tagline: 'Commandez vos plats préférés\nlivrés en 30 min',
      cta: 'Commander',
      icon: Icons.delivery_dining,
      bgColor: Color(0xFF142328),
      accentColor: Color(0xFF06C167),
      gradientColors: [Color(0xFF142328), Color(0xFF1A3A2A)],
    ),
    const _AdData(
      appName: 'Spotify',
      tagline: 'Écoutez des millions de titres\n3 mois gratuits Premium',
      cta: 'Essayer gratuitement',
      icon: Icons.music_note_rounded,
      bgColor: Color(0xFF121212),
      accentColor: Color(0xFF1DB954),
      gradientColors: [Color(0xFF121212), Color(0xFF1A1A2E)],
    ),
    const _AdData(
      appName: 'Netflix',
      tagline: 'Films, séries et documentaires\nillimités dès 5,99€/mois',
      cta: 'S\'abonner',
      icon: Icons.movie_filter_rounded,
      bgColor: Color(0xFF141414),
      accentColor: Color(0xFFE50914),
      gradientColors: [Color(0xFF141414), Color(0xFF2D0A0A)],
    ),
    const _AdData(
      appName: 'Duolingo',
      tagline: 'Apprenez une langue gratuitement\n5 min par jour suffisent !',
      cta: 'Commencer',
      icon: Icons.school_rounded,
      bgColor: Color(0xFF235390),
      accentColor: Color(0xFF58CC02),
      gradientColors: [Color(0xFF235390), Color(0xFF1B3F6B)],
    ),
    const _AdData(
      appName: 'Nike Run Club',
      tagline: 'Votre coach running personnel\nGPS, plans d\'entraînement',
      cta: 'Télécharger',
      icon: Icons.directions_run_rounded,
      bgColor: Color(0xFF111111),
      accentColor: Color(0xFFFFFFFF),
      gradientColors: [Color(0xFF111111), Color(0xFF1A1A1A)],
    ),
    const _AdData(
      appName: 'Samsung Health',
      tagline: 'Suivez votre santé au quotidien\nSommeil, sport, alimentation',
      cta: 'Installer',
      icon: Icons.favorite_rounded,
      bgColor: Color(0xFF0A1F44),
      accentColor: Color(0xFF1A73E8),
      gradientColors: [Color(0xFF0A1F44), Color(0xFF0D2B5E)],
    ),
    const _AdData(
      appName: 'YouTube Premium',
      tagline: 'Vidéos sans pub, musique hors ligne\n1 mois offert',
      cta: 'Essayer',
      icon: Icons.play_circle_fill_rounded,
      bgColor: Color(0xFF1A1A1A),
      accentColor: Color(0xFFFF0000),
      gradientColors: [Color(0xFF1A1A1A), Color(0xFF2D0000)],
    ),
    const _AdData(
      appName: 'Starbucks',
      tagline: 'Commandez et gagnez des étoiles\nBoisson offerte à l\'inscription',
      cta: 'Rejoindre',
      icon: Icons.coffee_rounded,
      bgColor: Color(0xFF1E3932),
      accentColor: Color(0xFF00704A),
      gradientColors: [Color(0xFF1E3932), Color(0xFF0D2B22)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Choisir une pub aléatoire à chaque ouverture
    _currentAd = _adPool[Random().nextInt(_adPool.length)];
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
          Future.delayed(const Duration(milliseconds: 1500), () {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _currentAd;

    return Dialog.fullscreen(
      backgroundColor: ad.bgColor,
      child: Stack(
        children: [
          // ── Fond dégradé ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [...ad.gradientColors, ad.bgColor],
              ),
            ),
          ),

          // ── Contenu central ─────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo App
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.05);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: ad.accentColor.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        ad.icon,
                        size: 56,
                        color: ad.accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Nom de l'app
                Text(
                  ad.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Tagline
                Text(
                  ad.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton CTA
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                  decoration: BoxDecoration(
                    color: ad.accentColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: ad.accentColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    ad.cta,
                    style: TextStyle(
                      color: ad.accentColor.computeLuminance() > 0.5
                          ? Colors.black87
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ── Stars / Rating simulé ─────────────────────────
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(5, (i) => Icon(
                      i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                      color: const Color(0xFFFFC107),
                      size: 18,
                    )),
                    const SizedBox(width: 6),
                    Text(
                      '4.5',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '100M+',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // Progress bar
                if (!_rewardGranted) ...[
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_totalSeconds - _remaining) / _totalSeconds,
                            minHeight: 4,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ad.accentColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fermer dans $_remaining s',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Bannière "Test Ad" en haut ─────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black54,
              child: const Center(
                child: Text(
                  'Test Ad',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ── "Reward granted" notification ───────────────────────
          if (_rewardGranted)
            Positioned(
              top: 44,
              right: 16,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Reward granted',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _canClose ? () => Navigator.of(context).pop(true) : null,
                        child: const Icon(Icons.close, color: Colors.white54, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bouton X pour fermer ────────────────────────────────
          if (_canClose)
            Positioned(
              top: 44,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(true),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),

          // ── "Ad" badge en bas à gauche (comme Google) ───────────
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)],
                    ).createShader(bounds),
                    child: const Icon(Icons.ads_click, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Ad • Google',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
