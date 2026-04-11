import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';



/// Écran d'abonnement MEDAIChain — Choix entre Free / Plus / Premium.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final plusPrice = '9.99 DT / mois';
    final premiumPrice = '19.99 DT / mois';

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
                        child: const Icon(Icons.workspace_premium_rounded,
                            color: Colors.white, size: 44),
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
                        'Débloquez l\'intelligence artificielle',
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Interface statique (Stripe sera branché plus tard)

                  // Badge plan actuel (statique)
                  _buildCurrentPlanBadge(),
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
                      'Notifications',
                    ],
                    lockedFeatures: const [
                      'Acceptation automatique IA',
                      'Analyse OCR des PDF',
                    ],
                    isActive: true,
                    onSubscribe: null,
                  ),

                  const SizedBox(height: 20),

                  // ── Plan Plus ──
                  _buildPlanCard(
                    title: 'Plus',
                    subtitle: 'Priorité IA',
                    price: plusPrice,
                    icon: Icons.bolt_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                    ),
                    features: const [
                      'Tout du plan Gratuit',
                      '✨ Modèle IA : acceptation automatique',
                      '📊 Rendez-vous prioritaires',
                      '🔬 Nombre limité d\'analyses OCR / mois',
                    ],
                    lockedFeatures: const [
                      'OCR illimité',
                      'Description complète des analyses',
                    ],
                    isActive: false,
                    isRecommended: true,
                    onSubscribe: null,
                  ),

                  const SizedBox(height: 20),

                  // ── Plan Premium ──
                  _buildPlanCard(
                    title: 'Premium',
                    subtitle: 'Accès complet IA + OCR',
                    price: premiumPrice,
                    icon: Icons.diamond_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                    ),
                    features: const [
                      'Tout du plan Plus',
                      '🧠 Modèle IA + OCR complet',
                      '📄 Analyse automatique des PDF',
                      '🔍 Plus de scans par mois',
                      '📝 Description complète des analyses',
                    ],
                    lockedFeatures: const [],
                    isActive: false,
                    onSubscribe: null,
                  ),

                  const SizedBox(height: 28),

                  // Boutons Stripe seront branchés ici plus tard

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // Overlay loading
      bottomSheet: _purchasing
          ? Container(
              color: Colors.black45,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildCurrentPlanBadge() {
    const label = 'Gratuit';
    final color = AppColors.textSecondary;

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
          Icon(Icons.verified_rounded, color: color, size: 20),
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

  // Stripe: actions de paiement seront ajoutées ici

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
                    onPressed: _purchasing ? null : onSubscribe,
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
                        child: Text(
                          'S\'abonner',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
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
