import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/subscription_service.dart';
import '../ai/premium_paywall_screen.dart';

/// Écran d'abonnement MEDAIChain — Choix entre Free / Premium.
/// Affiche le plan actuel et permet d'upgrader via RevenueCat.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subService = SubscriptionService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);
    await _subService.refreshBackendStatus();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _upgradeToPremium() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()),
    );
    if (result == true && mounted) {
      await _refreshStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _subService.isPremium;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPremium ? Icons.diamond_rounded : Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'MEDAIChain Pro',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPremium
                            ? 'Vous êtes abonné Premium ✨'
                            : 'Débloquez l\'intelligence artificielle',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Contenu ──
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Badge plan actuel
                        _buildCurrentPlanBadge(isPremium),
                        const SizedBox(height: 28),

                        // ── Plan Free ──
                        _buildPlanCard(
                          title: 'Gratuit',
                          subtitle: 'Fonctionnalités de base',
                          price: '0 DT / mois',
                          icon: Icons.person_rounded,
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade400, Colors.grey.shade600],
                          ),
                          features: const [
                            'Prendre des rendez-vous',
                            'Consulter vos résultats',
                            'Notifications en temps réel',
                            'Dossier médical digital',
                          ],
                          lockedFeatures: const [
                            'Assistant IA médical',
                            'Rendez-vous automatique d\'urgence',
                            'Analyse IA des résultats',
                            'Priorité IA',
                          ],
                          isActive: !isPremium,
                          onSubscribe: null,
                        ),

                        const SizedBox(height: 20),

                        // ── Plan Premium ──
                        _buildPlanCard(
                          title: 'Premium',
                          subtitle: 'Accès complet IA + Urgence',
                          price: '19.99 DT / mois',
                          icon: Icons.diamond_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                          ),
                          features: const [
                            'Tout du plan Gratuit',
                            '🤖 Assistant IA médical illimité',
                            '🚑 Rendez-vous automatique d\'urgence',
                            '🔬 Analyse IA des résultats d\'analyse',
                            '📄 OCR intelligent des documents',
                            '⚡ Réponses prioritaires',
                            '🛡️ Zéro publicité',
                          ],
                          lockedFeatures: const [],
                          isActive: isPremium,
                          isRecommended: true,
                          onSubscribe: isPremium ? null : _upgradeToPremium,
                        ),

                        const SizedBox(height: 28),

                        // Note informative
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Les fonctionnalités IA incluent le chat médical, '
                                  'l\'analyse automatique de vos résultats d\'analyse, '
                                  'et la prise de rendez-vous automatique en cas d\'urgence détectée.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildCurrentPlanBadge(bool isPremium) {
    final label = isPremium ? 'Premium' : 'Gratuit';
    final color = isPremium ? const Color(0xFFFFD700) : AppColors.textSecondary;
    final icon = isPremium ? Icons.diamond_rounded : Icons.verified_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            'Plan actuel : $label',
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required String price,
    required IconData icon,
    required Gradient gradient,
    required List<String> features,
    required List<String> lockedFeatures,
    required bool isActive,
    bool isRecommended = false,
    VoidCallback? onSubscribe,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: isActive
                ? Border.all(color: AppColors.primary, width: 2)
                : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.cardShadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Prix
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  price,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Features incluses
              for (final f in features) ...[
                _buildFeatureRow(f, included: true),
                const SizedBox(height: 8),
              ],

              // Features non incluses (verrouillées)
              for (final f in lockedFeatures) ...[
                _buildFeatureRow(f, included: false),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),

              // Bouton
              if (isActive)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '✅ Plan actif',
                      style: GoogleFonts.poppins(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              else if (onSubscribe != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.diamond_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Passer au Premium',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
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
        ),

        // Badge recommandé
        if (isRecommended)
          Positioned(
            top: -12,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '⭐ Recommandé',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureRow(String text, {required bool included}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          included ? Icons.check_circle_rounded : Icons.lock_rounded,
          color: included ? AppColors.success : AppColors.textLight,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: included ? AppColors.textPrimary : AppColors.textLight,
              fontWeight: included ? FontWeight.w500 : FontWeight.w400,
              decoration: included ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ],
    );
  }
}
