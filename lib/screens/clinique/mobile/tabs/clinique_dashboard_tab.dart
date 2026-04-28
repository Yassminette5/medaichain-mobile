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
      results.sort((a, b) {
        final double scoreA = (a['riskScore'] ?? 0).toDouble();
        final double scoreB = (b['riskScore'] ?? 0).toDouble();
        return scoreA.compareTo(scoreB);
      });
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
          color: const Color(0xFF7C3AED),
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
                                    const Color(0xFF7C3AED),
                                    [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
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

  // ======= SECTION IA (MOBILE) =======
  Widget _buildMobileAiSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // En-tête Gradient IA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Intelligence Artificielle',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Text(
                        'Prédiction d\'adhérence au traitement',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadAiResults,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Statistiques rapides IA
          if (!_isLoadingAiResults && _aiResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildAiMiniStat('Analysés', _aiResults.length.toString(), Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildAiMiniStat('À Risque', _aiResults.where((r) => r['riskLevel'] == 'élevé').length.toString(), Colors.redAccent)),
                ],
              ),
            ),

          // Liste des patients
          if (_isLoadingAiResults)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: Color(0xFF1E1B4B))))
          else if (_aiResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Aucune donnée d\'adhérence disponible.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _aiResults.length > 5 ? 5 : _aiResults.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final result = _aiResults[index];
                final patient = result['patient'] ?? {};
                final riskLevel = result['riskLevel'] ?? 'faible';
                final score = (result['riskScore'] ?? 0).toDouble();
                final String name = '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
                final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : (name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P');
                
                final isHigh = riskLevel == 'élevé';
                final isMed = riskLevel == 'modéré';

                final badgeColor = isHigh ? const Color(0xFFEF4444) : isMed ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
                final badgeBg = isHigh ? const Color(0xFFFEF2F2) : isMed ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5);
                final badgeLabel = isHigh ? 'Risque Élevé' : isMed ? 'Risque Modéré' : 'Risque Faible';
                final levelIcon = isHigh ? Icons.warning_rounded : isMed ? Icons.error_outline_rounded : Icons.check_circle_rounded;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isHigh ? const Color(0xFFFFF5F5) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isHigh ? const Color(0xFFFECACA) : isMed ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                      width: isHigh ? 1.5 : 1,
                    ),
                    boxShadow: isHigh ? [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))] : [],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isHigh
                                    ? [const Color(0xFFEF4444), const Color(0xFFF97316)]
                                    : isMed
                                        ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
                                        : [const Color(0xFF10B981), const Color(0xFF34D399)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: badgeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Center(
                              child: Text(initials, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name.isNotEmpty ? name : 'Patient Inconnu', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(levelIcon, size: 14, color: badgeColor),
                                    const SizedBox(width: 4),
                                    Text(badgeLabel, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: badgeColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${score.toStringAsFixed(1)}%',
                                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: badgeColor),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: score / 100,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    color: badgeColor,
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isHigh || isMed) ...[
                        const SizedBox(height: 14),
                        Divider(height: 1, color: isHigh ? const Color(0xFFFECACA) : const Color(0xFFFDE68A)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(isHigh ? Icons.phone_in_talk_rounded : Icons.sms_rounded, size: 14, color: badgeColor),
                                const SizedBox(width: 6),
                                Text(isHigh ? 'Action requise immédiate' : 'Suivi recommandé', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final phone = patient['phone'] ?? '';
                                if (phone.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro de téléphone non disponible')));
                                  return;
                                }
                                final url = isHigh ? 'tel:$phone' : 'sms:$phone';
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de lancer l\'application')));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: badgeColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: Icon(isHigh ? Icons.phone_rounded : Icons.sms_rounded, size: 14),
                              label: Text(isHigh ? 'Appeler' : 'SMS', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            
          // Bouton Lancer Analyse
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : () async {
                  setState(() => _isAnalyzing = true);
                  try {
                    final result = await ApiService.triggerClinicAdherenceAnalysis();
                    await _loadAiResults();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${result['analyzed']} patients analysés !'), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Erreur IA'), backgroundColor: Colors.red));
                  } finally {
                    if (mounted) setState(() => _isAnalyzing = false);
                  }
                },
                icon: _isAnalyzing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded),
                label: Text(_isAnalyzing ? 'Analyse en cours...' : 'Lancer l\'analyse IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1B4B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
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
