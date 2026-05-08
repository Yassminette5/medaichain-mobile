import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medaichainmobile/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:medaichainmobile/providers/auth_provider.dart';
import 'package:medaichainmobile/services/api_service.dart';
import 'package:medaichainmobile/screens/auth/login_screen.dart';

class CliniqueSettingsTab extends StatefulWidget {
  const CliniqueSettingsTab({super.key});

  @override
  State<CliniqueSettingsTab> createState() => _CliniqueSettingsTabState();
}

class _CliniqueSettingsTabState extends State<CliniqueSettingsTab> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _profileFuture;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _profileFuture = ApiService.getClinicProfile();
    });
    _profileFuture.then((_) {
      if (mounted) _fadeController.forward(from: 0);
    }).catchError((_) {
      if (mounted) _fadeController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get user info from Provider as fallback
    final user = context.watch<AuthProvider>().user;
    
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            
            final clinicData = snapshot.data ?? {};
            final fallbackClinicName = user?.fullName ?? 'Ma Clinique';
            final fallbackEmail = user?.email ?? 'En attente...';
            final fallbackPhone = user?.phone ?? 'En attente...';
            
            final String clinicName = clinicData['name'] ?? fallbackClinicName;
            final String clinicAddress = clinicData['address'] ?? 'Adresse non renseignée';
            final String clinicEmail = clinicData['contactEmail'] ?? fallbackEmail;
            final String clinicPhone = clinicData['contactPhone'] ?? fallbackPhone;
            
            final joinDate = user != null 
                ? '${user.createdAt.day.toString().padLeft(2, '0')}/${user.createdAt.month.toString().padLeft(2, '0')}/${user.createdAt.year}'
                : '01/01/2024';

            if (isLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
            }

            return FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 280.0,
                    pinned: true,
                    backgroundColor: const Color(0xFF1E3A8A), // Premium dark blue
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                clinicName,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00ACC1).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF00ACC1).withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                'Compte Clinique Actif',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF80DEEA),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -20),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informations détaillées',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ces informations sont en lecture seule sur mobile.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildPremiumInfoTile('Email de contact', clinicEmail, Icons.email_rounded),
                                    Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
                                    _buildPremiumInfoTile('Téléphone principal', clinicPhone, Icons.phone_rounded),
                                    Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
                                    _buildPremiumInfoTile('Adresse de la clinique', clinicAddress, Icons.location_on_rounded),
                                    Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
                                    _buildPremiumInfoTile('Membre depuis', joinDate, Icons.calendar_today_rounded),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Section Paramètres
                              Text(
                                'Paramètres',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildActionCard(
                                context,
                                'Déconnexion',
                                Icons.logout_rounded,
                                const Color(0xFFE53935), // Red
                                () async {
                                  final auth = context.read<AuthProvider>();
                                  final shouldLogout = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Déconnexion'),
                                      content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text('Annuler', style: GoogleFonts.plusJakartaSans()),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text('Déconnexion', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFE53935))),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldLogout == true && context.mounted) {
                                    await auth.logout();
                                    if (context.mounted) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        (route) => false,
                                      );
                                    }
                                  }
                                },
                              ),
                              const SizedBox(height: 120), // Padding for bottom navbar
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumInfoTile(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
