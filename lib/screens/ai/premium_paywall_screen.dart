import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
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
/// Dialog de simulation pub — Web uniquement.
/// Affiche un compte à rebours de 10 secondes, puis débloque le bouton
/// "Obtenir mon crédit". L'utilisateur ne peut PAS fermer avant la fin.
// ─────────────────────────────────────────────────────────────────────────────
class _WebAdCountdownDialog extends StatefulWidget {
  const _WebAdCountdownDialog();

  @override
  State<_WebAdCountdownDialog> createState() => _WebAdCountdownDialogState();
}

class _WebAdCountdownDialogState extends State<_WebAdCountdownDialog> {
  static const int _totalSeconds = 10;
  int _remaining = _totalSeconds;
  Timer? _timer;
  bool _canClose = false;

  @override
  void initState() {
    super.initState();
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
          _canClose = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress => (_totalSeconds - _remaining) / _totalSeconds;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── En-tête ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.aiGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.play_circle_filled, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Publicité MEDAIChain',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Regardez pour gagner 1 crédit IA',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Zone pub simulée ─────────────────────────────────────────────
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF00838F)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MEDAIChain',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Votre santé, notre priorité',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Barre de progression ─────────────────────────────────────────
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _canClose
                          ? 'Publicité terminée !'
                          : 'Publicité en cours...',
                      style: TextStyle(
                        fontSize: 13,
                        color: _canClose
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _canClose
                            ? AppColors.successLight
                            : AppColors.blockchainLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _canClose ? '✓ Terminé' : '$_remaining s',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _canClose
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _canClose ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Boutons ──────────────────────────────────────────────────────
            Row(
              children: [
                // Fermer sans crédit
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Obtenir crédit (actif seulement après countdown)
                Expanded(
                  flex: 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: _canClose
                          ? const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade300,
                                Colors.grey.shade300,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _canClose
                          ? [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _canClose
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _canClose
                                ? Icons.check_circle_rounded
                                : Icons.hourglass_top_rounded,
                            color: _canClose ? Colors.white : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            _canClose
                                ? 'Obtenir mon crédit'
                                : 'Patientez $_remaining s',
                            style: TextStyle(
                              color: _canClose ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
