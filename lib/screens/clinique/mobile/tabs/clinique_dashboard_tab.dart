import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medaichainmobile/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:medaichainmobile/providers/auth_provider.dart';
import 'package:medaichainmobile/services/api_service.dart';

class CliniqueDashboardTab extends StatefulWidget {
  const CliniqueDashboardTab({super.key});

  @override
  State<CliniqueDashboardTab> createState() => _CliniqueDashboardTabState();
}

class _CliniqueDashboardTabState extends State<CliniqueDashboardTab> with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _dataFuture;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    
    _loadData();
    // Auto refresh every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _loadData());
  }

  void _loadData() {
    setState(() {
      _dataFuture = Future.wait([
        ApiService.getDashboardStats(),
        ApiService.getClinicProfile(),
      ]);
    });
    _dataFuture.then((_) {
      if (mounted) _fadeController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final fallbackClinicName = user?.fullName ?? 'Ma Clinique';

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: const Color(0xFF7C3AED),
          onRefresh: () async {
            _loadData();
            await _dataFuture;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Premium AppBar
              SliverAppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                pinned: true,
                title: Text(
                  'Tableau de bord',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
                centerTitle: false,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Color(0xFF7C3AED)),
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: FutureBuilder<List<dynamic>>(
                    future: _dataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState(fallbackClinicName);
                      }
                      
                      if (snapshot.hasError) {
                        return _buildErrorState(fallbackClinicName);
                      }

                      final stats = snapshot.data![0] as Map<String, dynamic>;
                      final clinicProfile = snapshot.data![1] as Map<String, dynamic>;
                      
                      final realClinicName = clinicProfile['name'] ?? fallbackClinicName;

                      final overview = stats['overview'] ?? {};
                      final finance = stats['finance'] ?? {};
                      final admissionsToday = stats['admissionsToday'] ?? {};
                      final monthly = stats['monthly'] ?? {};
                      final monthlyAppointments = monthly['appointments'] ?? {};
                      
                      final totalDoctors = overview['totalDoctors'] ?? 0;
                      final totalAppointmentsToday = overview['totalAppointmentsToday'] ?? 0;
                      final totalAdmissionsToday = overview['totalAdmissionsToday'] ?? 0;
                      final pendingAppointments = overview['pendingAppointments'] ?? 0;
                      final waitingRoomCount = admissionsToday['waiting'] ?? 0;
                      
                      final rawRevenue = finance['totalRevenue'] ?? 0;
                      final revenue = rawRevenue.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
                      final pendingInvoices = finance['pendingInvoices'] ?? 0;
                      
                      final totalMonth = monthlyAppointments['total'] ?? 0;
                      final completedMonth = monthlyAppointments['completed'] ?? 0;
                      double completionRate = monthlyAppointments['completionRate']?.toDouble() ?? 0.0;

                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPremiumBanner(realClinicName, revenue),
                            const SizedBox(height: 24),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Statistiques clinique',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'En ligne',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Ligne 1: Médecins, RDV du jour
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'Médecins',
                                    totalDoctors.toString(),
                                    Icons.medical_services_rounded,
                                    const Color(0xFF7C3AED),
                                    [const Color(0xFF7C3AED), const Color(0xFF00ACC1)],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'RDV du jour',
                                    totalAppointmentsToday.toString(),
                                    Icons.calendar_today_rounded,
                                    const Color(0xFF43A047),
                                    [const Color(0xFF43A047), const Color(0xFF66BB6A)],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Ligne 2: Patients admis, RDV en attente
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'Patients admis',
                                    totalAdmissionsToday.toString(),
                                    Icons.people_alt_rounded,
                                    const Color(0xFF7E57C2),
                                    [const Color(0xFF7E57C2), const Color(0xFFAB47BC)],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'RDV en attente',
                                    pendingAppointments.toString(),
                                    Icons.pending_actions_rounded,
                                    const Color(0xFFF57C00),
                                    [const Color(0xFFF57C00), const Color(0xFFFFB74D)],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Ligne 3: Salle d'attente, RDV du mois
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'Salle d\'attente',
                                    waitingRoomCount.toString(),
                                    Icons.event_seat_rounded,
                                    const Color(0xFF00ACC1),
                                    [const Color(0xFF00ACC1), const Color(0xFF26C6DA)],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'RDV du mois',
                                    totalMonth.toString(),
                                    Icons.date_range_rounded,
                                    const Color(0xFF6366F1),
                                    [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Ligne 4: Taux complétion, Factures en attente
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'Taux complétion',
                                    '${completionRate.toStringAsFixed(0)}%',
                                    Icons.trending_up_rounded,
                                    const Color(0xFF059669),
                                    [const Color(0xFF059669), const Color(0xFF10B981)],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'Factures en attente',
                                    pendingInvoices.toString(),
                                    Icons.receipt_long_rounded,
                                    const Color(0xFFDC2626),
                                    [const Color(0xFFDC2626), const Color(0xFFEF4444)],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            // Informative box for read-only constraint
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFB74D).withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF57C00).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Cette interface est en lecture seule. Pour ajouter un médecin ou gérer les plannings, utilisez la version Web sur ordinateur.',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFE65100),
                                        fontSize: 12,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 100), // Padding for Floating Bottom Bar
                          ],
                        ),
                      );
                    }
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBanner(String clinicName, String revenue) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12 ? 'Bonjour,' : (hour < 18 ? 'Bon après-midi,' : 'Bonsoir,');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF132E57), Color(0xFF1A4B8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                clinicName,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.amber, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Revenus du jour',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$revenue DA',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatCard(String title, String value, IconData icon, Color primaryColor, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              // Little decoration dot
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(String clinicName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPremiumBanner(clinicName, '...'),
        const SizedBox(height: 24),
        const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
      ],
    );
  }

  Widget _buildErrorState(String clinicName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPremiumBanner(clinicName, '0'),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(
                'Erreur de chargement',
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
