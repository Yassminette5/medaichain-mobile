import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medaichainmobile/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:medaichainmobile/providers/auth_provider.dart';
import 'package:medaichainmobile/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _aiResults = [];
  bool _isLoadingAiResults = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    
    _loadData();
    _loadAiResults();
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

  Future<void> _loadAiResults() async {
    if (_isLoadingAiResults) return;
    setState(() => _isLoadingAiResults = true);
    try {
      final results = await ApiService.getClinicAiResults();
      if (mounted) setState(() => _aiResults = List<Map<String, dynamic>>.from(results));
    } catch (e) {
      debugPrint('[AI] Erreur chargement résultats: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAiResults = false);
    }
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
          color: const Color(0xFF2563EB),
          onRefresh: () async {
            _loadData();
            _loadAiResults();
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
                      icon: const Icon(Icons.notifications_outlined, color: Color(0xFF2563EB)),
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
                            
                            // ======= 🧠 SECTION IA (MOBILE) =======
                            _buildMobileAiSection(),
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
                            
                            // ======= Actions rapides =======
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickAction(
                                    'Admission',
                                    Icons.person_add_alt_1_rounded,
                                    const Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickAction(
                                    'Planifier',
                                    Icons.calendar_today_rounded,
                                    const Color(0xFF4F46E5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickAction(
                                    'Médecin',
                                    Icons.medical_services_rounded,
                                    const Color(0xFF00ACC1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Text(
                              'Vue d\'ensemble',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
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
                                    const Color(0xFF3B82F6),
                                    [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'RDV du jour',
                                    totalAppointmentsToday.toString(),
                                    Icons.calendar_today_rounded,
                                    const Color(0xFF2563EB),
                                    [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
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
                                    const Color(0xFF2563EB),
                                    [const Color(0xFF2563EB), const Color(0xFF60A5FA)],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'RDV en attente',
                                    pendingAppointments.toString(),
                                    Icons.pending_actions_rounded,
                                    const Color(0xFF4F46E5),
                                    [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
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
                                    const Color(0xFF0284C7),
                                    [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'RDV du mois',
                                    totalMonth.toString(),
                                    Icons.date_range_rounded,
                                    const Color(0xFF1E3A8A),
                                    [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8)],
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
                                    const Color(0xFF0369A1),
                                    [const Color(0xFF0369A1), const Color(0xFF0EA5E9)],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildPremiumStatCard(
                                    'Factures en attente',
                                    pendingInvoices.toString(),
                                    Icons.receipt_long_rounded,
                                    const Color(0xFF312E81),
                                    [const Color(0xFF312E81), const Color(0xFF4338CA)],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            // ======= Activité Récente (Mock pour le "Pro" look) =======
                            Text(
                              'Activité récente',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRecentActivityCard(),
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
                            
                            const SizedBox(height: 24),
                            // ======= Activité Récente (Mock pour le "Pro" look) =======
                            Text(
                              'Activité récente',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRecentActivityCard(),

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
          colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
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
        const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
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

  // ======= SECTION IA VIGILANCE (MOBILE PRO) =======
  Widget _buildMobileAiSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ══ EN-TÊTE PREMIUM ══
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFFEF4444), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vigilance Médicale',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'L\'IA analyse tous les RDV en direct.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text('Auto', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF10B981))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // ══ LISTE DES PATIENTS (VIGILANCE ROWS) ══
          if (_isLoadingAiResults)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Color(0xFFEF4444))))
          else if (_aiResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.health_and_safety_rounded, size: 48, color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text('Aucun patient à risque.', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _aiResults.length > 5 ? 5 : _aiResults.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildMobileVigilanceRow(_aiResults[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ======= MOBILE VIGILANCE ROW (Adapted from Web) =======
  Widget _buildMobileVigilanceRow(Map<String, dynamic> r) {
    final patient = r['patient'] ?? {};
    final String name = r['patientName'] ?? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final timeSlot = r['timeSlot'] ?? '--:--';
    final diseaseLabel = r['diseaseLabel'] ?? 'Sain';
    final colorStr = r['diseaseColor'] ?? 'green';
    final confidence = (r['diseaseConfidence'] ?? 0).toDouble();
    final List<dynamic> explanations = r['explanations'] ?? [];
    
    Color badgeColor = const Color(0xFF22C55E);
    Color bg = const Color(0xFFF0FDF4);
    if (colorStr == 'red') {
      badgeColor = const Color(0xFFEF4444);
      bg = const Color(0xFFFEF2F2);
    } else if (colorStr == 'orange') {
      badgeColor = const Color(0xFFF59E0B);
      bg = const Color(0xFFFFFBEB);
    }

    // NLP Priority
    final nlpDiagnosis = r['nlpDiagnosis']?.toString();
    final hasNlp = nlpDiagnosis != null && nlpDiagnosis.isNotEmpty;
    if (hasNlp) {
      final nColor = r['nlpColor']?.toString() ?? 'green';
      if (nColor == 'red') {
        badgeColor = const Color(0xFFEF4444);
        bg = const Color(0xFFFEF2F2);
      } else if (nColor == 'orange') {
        badgeColor = const Color(0xFFF59E0B);
        bg = const Color(0xFFFFFBEB);
      } else {
        badgeColor = const Color(0xFF22C55E);
        bg = const Color(0xFFF0FDF4);
      }
    }

    final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : (name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P');

    final dateStr = r['date']?.toString() ?? '';
    String displayDate = '';
    if (dateStr.isNotEmpty) {
      try {
        final d = DateTime.parse(dateStr);
        displayDate = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} • ';
      } catch(_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Patient Info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: badgeColor,
                foregroundColor: Colors.white,
                radius: 20,
                child: Text(initials, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isNotEmpty ? name : 'Patient', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('$displayDate$timeSlot', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Button Top Right on Mobile
              if (hasNlp && r['nlpActionButton'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor == const Color(0xFF22C55E) ? Colors.white : badgeColor,
                    borderRadius: BorderRadius.circular(8),
                    border: badgeColor == const Color(0xFF22C55E) ? Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeColor == const Color(0xFFEF4444) ? Icons.emergency_rounded : Icons.check_circle_outline_rounded, size: 12, color: badgeColor == const Color(0xFF22C55E) ? const Color(0xFF22C55E) : Colors.white),
                      const SizedBox(width: 4),
                      Text(r['nlpActionButton'], style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor == const Color(0xFF22C55E) ? const Color(0xFF22C55E) : Colors.white)),
                    ],
                  ),
                )
              else if (badgeColor == const Color(0xFFEF4444) || badgeColor == const Color(0xFFF59E0B))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeColor == const Color(0xFFEF4444) ? Icons.warning_rounded : Icons.visibility_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(badgeColor == const Color(0xFFEF4444) ? 'Urgence' : 'Aviser', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Détails IA
          if (hasNlp) ...[
            // NLP Block
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('NLP', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: badgeColor)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🩺 $nlpDiagnosis',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: badgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (r['nlpTriage'] != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.directions_walk_rounded, size: 14, color: badgeColor.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r['nlpTriage'],
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: badgeColor.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            if (r['nlpPreparation'] != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_services_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r['nlpPreparation'],
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (r['symptomsText'] != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${r['symptomsText']}"',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                ),
              ),
          ] else ...[
            // Default Disease Block
            Row(
              children: [
                Expanded(
                  child: Text(
                    diseaseLabel,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: badgeColor),
                  ),
                ),
                Text('${confidence.toStringAsFixed(0)}% fiable', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
              ],
            ),
            if (explanations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: explanations.map((expl) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(colorStr == 'green' ? Icons.check_circle_outline : Icons.search_rounded, size: 14, color: badgeColor),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          expl.toString(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: badgeColor.withValues(alpha: 0.9), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ],
          
          // Emergency Actions (Appeler / SMS)
          if (badgeColor == const Color(0xFFEF4444) || badgeColor == const Color(0xFFF59E0B)) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: badgeColor.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final phone = patient['phone'] ?? '';
                      if (phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro de téléphone non disponible')));
                        return;
                      }
                      final url = 'tel:$phone';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de lancer l\'appel')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: badgeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                    label: const Text('Appeler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final phone = patient['phone'] ?? '';
                      if (phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro de téléphone non disponible')));
                        return;
                      }
                      final url = 'sms:$phone';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'envoyer le SMS')));
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: badgeColor,
                      side: BorderSide(color: badgeColor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.sms_rounded, size: 16),
                    label: const Text('SMS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action disponible sur la version Web.'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActivityItem('Nouveau patient admis', 'Il y a 10 min', Icons.person_add_rounded, const Color(0xFF3B82F6)),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildActivityItem('Rendez-vous planifié', 'Il y a 1h', Icons.calendar_today_rounded, const Color(0xFF4F46E5)),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildActivityItem('Facture réglée', 'Il y a 2h', Icons.check_circle_rounded, const Color(0xFF0284C7)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
