import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medaichainmobile/clinique/theme/app_theme.dart';
import 'package:medaichainmobile/services/api_service.dart';
import 'dart:async';

class DashboardHomeView extends StatefulWidget {
  final Function(int)? onNavigate;
  final String clinicName;
  
  const DashboardHomeView({super.key, this.onNavigate, this.clinicName = 'Ma Clinique'});

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _dashboardStats;
  Timer? _refreshTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _floatController;
  late Animation<double> _floatAnim;
  late AnimationController _staggerController;
  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatAnim;
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _aiResults = [];
  bool _isLoadingAiResults = false;

  @override
  void initState() {
    super.initState();
    _dashboardStats = ApiService.getDashboardStats();
    _loadAiResults();
    
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _refresh();
    });
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _heartbeatAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _floatController.dispose();
    _staggerController.dispose();
    _heartbeatController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _dashboardStats = ApiService.getDashboardStats();
    });
    _loadAiResults();
  }

  Future<void> _loadAiResults() async {
    if (_isLoadingAiResults) return;
    setState(() => _isLoadingAiResults = true);
    try {
      final results = await ApiService.getClinicAiResults();
      
      // Le backend renvoie maintenant les résultats triés par Date et Heure
      // On conserve donc cet ordre chronologique ("b tandhim les date")
      // results.sort(...) a été retiré.

      if (mounted) setState(() => _aiResults = List<Map<String, dynamic>>.from(results));
    } catch (e) {
      debugPrint('[AI] Erreur chargement résultats: $e');

    } finally {
      if (mounted) setState(() => _isLoadingAiResults = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final stats = snapshot.data ?? {};
        final overview = stats['overview'] ?? {};
        final totalDoctors = overview['totalDoctors'] ?? 0;
        final totalAppointments = overview['totalAppointmentsToday'] ?? 0;
        final totalAdmissions = overview['totalAdmissionsToday'] ?? 0;
        final pendingAppointments = overview['pendingAppointments'] ?? 0;

        final finance = stats['finance'] ?? {};
        final rawRevenue = finance['totalRevenue'] ?? 0;
        final revenue = rawRevenue.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');

        final analytics = stats['analytics'] ?? {};
        final recentActivities = stats['recentActivities'] ?? [];
        final totalMonthlyAppointments = analytics['appointments']?['totalMonth'] ?? 0;
        final completedMonthlyAppointments = analytics['appointments']?['completedMonth'] ?? 0;
        double completionRate = 0;
        if (totalMonthlyAppointments > 0) {
          completionRate = (completedMonthlyAppointments / totalMonthlyAppointments) * 100;
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ======= WELCOME Banner =======
              _buildWelcomeBanner(revenue),
              const SizedBox(height: 28),

              // ======= KPI Row with stagger =======
              Row(
                children: [
                  Expanded(child: _buildStaggeredKpi(0, _buildKpiCard(
                    'Patients du jour',
                    totalAdmissions.toString(),
                    Icons.people_rounded,
                    AppTheme.primaryMedical,
                    AppTheme.primaryGradient,
                    '+12%',
                    true,
                  ))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStaggeredKpi(1, _buildKpiCard(
                    'RDV en attente',
                    pendingAppointments.toString(),
                    Icons.pending_actions_rounded,
                    AppTheme.indigo,
                    AppTheme.successGradient, // This is now indigo gradient in AppTheme
                    'Urgent',
                    false,
                  ))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStaggeredKpi(2, _buildKpiCard(
                    'RDV du jour',
                    totalAppointments.toString(),
                    Icons.event_available_rounded,
                    const Color(0xFF8B5CF6),
                    AppTheme.warningGradient, // This is now purple gradient in AppTheme
                    '+5%',
                    true,
                  ))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStaggeredKpi(3, _buildAiKpiCard(
                    'Patients à risque (IA)',
                    (overview['highRiskAdherencePatients'] ?? 0).toString(),
                    Icons.psychology_alt_rounded,
                    Colors.redAccent,
                  ))),
                ],
              ),
              const SizedBox(height: 28),

              // ======= Quick Actions =======
              Text(
                'Actions rapides',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkNavy,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildQuickAction(
                    'Nouvelle Admission',
                    'Enregistrer un patient',
                    Icons.person_add_alt_1_rounded,
                    AppTheme.primaryMedical,
                    2,
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: _buildQuickAction(
                    'Planifier RDV',
                    'Créer un rendez-vous',
                    Icons.calendar_today_rounded,
                    AppTheme.accentMedical,
                    3,
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: _buildQuickAction(
                    'Ajouter Médecin',
                    'Nouveau staff médical',
                    Icons.medical_services_rounded,
                    AppTheme.success,
                    1,
                  )),
                ],
              ),
              const SizedBox(height: 28),

              // ======= 🧠 VIGILANCE MÉDICALE =======
              _buildMedicalVigilanceSection(),
              const SizedBox(height: 28),

              // ======= Charts Row =======
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Efficiency Card
                  Expanded(
                    flex: 2,
                    child: _buildEfficiencyCard(completionRate, completedMonthlyAppointments, totalMonthlyAppointments),
                  ),
                  const SizedBox(width: 20),
                  // Right: Recent Activity
                  Expanded(
                    flex: 3,
                    child: _buildActivityCard(recentActivities),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ======= Bottom Row =======
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Revenue Chart
                  Expanded(
                    flex: 3,
                    child: _buildRevenueChart(rawRevenue.toDouble()),
                  ),
                  const SizedBox(width: 20),
                  // Top Doctors
                  Expanded(
                    flex: 2,
                    child: _buildTopDoctorsCard(),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // ======= WELCOME BANNER =======
  Widget _buildWelcomeBanner(String revenue) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetIcon;
    if (hour < 12) {
      greeting = 'Bonjour';
      greetIcon = Icons.wb_sunny_rounded;
    } else if (hour < 18) {
      greeting = 'Bon après-midi';
      greetIcon = Icons.wb_cloudy_rounded;
    } else {
      greeting = 'Bonsoir';
      greetIcon = Icons.nightlight_round;
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glowing orb top-right
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryMedical.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Glowing orb bottom-left
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentMedical.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Floating heartbeat icon
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, child) {
              return Positioned(
                right: 200,
                top: _floatAnim.value + 10,
                child: Opacity(
                  opacity: 0.1,
                  child: ScaleTransition(
                    scale: _heartbeatAnim,
                    child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 40),
                  ),
                ),
              );
            },
          ),
          // Floating DNA icon
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, child) {
              return Positioned(
                right: 120,
                bottom: -_floatAnim.value + 15,
                child: Opacity(
                  opacity: 0.08,
                  child: Transform.rotate(
                    angle: _floatAnim.value * 0.02,
                    child: const Icon(Icons.biotech_rounded, color: Colors.tealAccent, size: 35),
                  ),
                ),
              );
            },
          ),
          // Floating shield/health icon
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, child) {
              return Positioned(
                right: 40,
                top: _floatAnim.value * 0.5 + 30,
                child: Opacity(
                  opacity: 0.06,
                  child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 50),
                ),
              );
            },
          ),
          // Heartbeat line decoration
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: CustomPaint(
                size: const Size(double.infinity, 40),
                painter: _HeartbeatLinePainter(
                  progress: _pulseAnim.value,
                  color: AppTheme.primaryMedical.withOpacity(0.08),
                ),
              ),
            ),
          ),
          // Content
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(greetIcon, color: AppTheme.accentMedical, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                greeting,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Live pulse indicator
                        AnimatedBuilder(
                          animation: _heartbeatAnim,
                          builder: (ctx, child) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.indigo.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.indigo.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6 * _heartbeatAnim.value,
                                  height: 6 * _heartbeatAnim.value,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.indigo,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'En ligne',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.green[300],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.clinicName,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Voici le résumé de vos activités aujourd\'hui',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildBannerStat('Revenus du jour', '$revenue DA', Icons.trending_up_rounded),
                        const SizedBox(width: 24),
                        _buildBannerStat('Taux occupation', '78%', Icons.pie_chart_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              // Refresh Button
              Column(
                children: [
                  InkWell(
                    onTap: _refresh,
                    borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(Icons.sync_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rafraîchir',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
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

  Widget _buildBannerStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.chainAccent, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500)),
              Text(value, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  // ======= KPI CARD =======
  Widget _buildKpiCard(String title, String value, IconData icon, Color color, LinearGradient gradient, String badge, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppTheme.success : AppTheme.warning).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badge != 'Staff' && badge != 'Urgent')
                      Icon(
                        isPositive ? Icons.trending_up_rounded : Icons.priority_high_rounded,
                        size: 12,
                        color: isPositive ? AppTheme.success : AppTheme.warning,
                      ),
                    if (badge != 'Staff' && badge != 'Urgent')
                      const SizedBox(width: 2),
                    Text(
                      badge,
                      style: GoogleFonts.plusJakartaSans(
                        color: isPositive ? AppTheme.success : AppTheme.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return Text(
                animValue.toInt().toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkNavy,
                  height: 1,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAiKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              ElevatedButton(
                onPressed: _isAnalyzing ? null : () async {
                  setState(() => _isAnalyzing = true);
                  try {
                    final result = await ApiService.triggerClinicAdherenceAnalysis();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✅ ${result['analyzed']} patients analysés par le modèle IA !'), backgroundColor: AppTheme.primaryMedical)
                      );
                      _refresh();
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: Vérifiez l\'URL IA'), backgroundColor: Colors.red));
                  } finally {
                    if (mounted) setState(() => _isAnalyzing = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMedical,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _isAnalyzing 
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Lancer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.darkNavy,
              letterSpacing: -1,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ======= 🧠 AI ALERTS SECTION (PRO) =======
  Widget _buildMedicalVigilanceSection() {
    // _aiResults contains appointments from the backend
    final highCount = _aiResults.where((r) => r['diseaseColor'] == 'red').length;
    final medCount = _aiResults.where((r) => r['diseaseColor'] == 'orange').length;
    final lowCount = _aiResults.where((r) => r['diseaseColor'] == 'green').length;
    final total = _aiResults.length;
    final healthScore = total > 0 ? ((lowCount / total) * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // ═══════ HEADER ═══════
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFFEF4444), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vigilance Médicale du Jour',
                            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'L\'IA analyse tous les nouveaux RDV pour détecter les risques cachés en amont.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF22C55E), size: 14),
                          const SizedBox(width: 6),
                          Text('100% Auto', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF22C55E))),
                        ],
                      ),
                    ),
                  ],
                ),

                // ═══ Stats Summary Cards ═══
                if (_aiResults.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildHeaderStat('RDV Scannés', '$total', Icons.verified_user_rounded, const Color(0xFF64748B)),
                      const SizedBox(width: 12),
                      _buildHeaderStat('Risque Cardio', '$highCount', Icons.favorite_rounded, const Color(0xFFEF4444)),
                      const SizedBox(width: 12),
                      _buildHeaderStat('Risque Diabète', '$medCount', Icons.water_drop_rounded, const Color(0xFFF59E0B)),
                      const SizedBox(width: 12),
                      _buildHeaderStat('Taux Sains', '$healthScore%', Icons.shield_rounded, const Color(0xFF22C55E)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ═══════ PATIENT LIST ═══════
          if (_isLoadingAiResults)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator(color: Color(0xFFEF4444))),
            )
          else if (_aiResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, size: 48, color: Color(0xFFCBD5E1)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun patient à analyser aujourd\'hui',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkNavy),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text('PATIENT & HORAIRE', style: _tableHeaderStyle())),
                        Expanded(flex: 4, child: Text('PRÉ-DIAGNOSTIC IA (DÉTECTION PRÉCOCE)', style: _tableHeaderStyle())),
                        Expanded(flex: 2, child: Text('ACTION CLINIQUE', style: _tableHeaderStyle())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_aiResults.length, (i) => _buildVigilanceRow(_aiResults[i])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle() {
    return GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF94A3B8),
      letterSpacing: 1.0,
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.darkNavy)),
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVigilanceRow(Map<String, dynamic> r) {
    final name = r['patientName'] ?? 'Patient';
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

    // If NLP detected something, its color takes priority
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

    final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.substring(0, 1).toUpperCase();

    final dateStr = r['date']?.toString() ?? '';
    String displayDate = '';
    if (dateStr.isNotEmpty) {
      try {
        final d = DateTime.parse(dateStr);
        displayDate = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} • ';
      } catch(_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══ Patient Info ══
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: badgeColor,
                  foregroundColor: Colors.white,
                  radius: 18,
                  child: Text(initials, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.darkNavy)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('$displayDate$timeSlot', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // ══ AI PREDICTION & CLINICAL XAI ══
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. NLP SYMPTOM CHECKER
                if (hasNlp) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('NLP', style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w800, color: badgeColor)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '🩺 $nlpDiagnosis',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, 
                            fontWeight: FontWeight.w800, 
                            color: badgeColor
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.psychology_alt_rounded, size: 10, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text('${(r['nlpConfidence'] ?? 0).toStringAsFixed(0)}%', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Instructions Cliniques (Triage & Preparation)
                  if (r['nlpTriage'] != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.directions_walk_rounded, size: 12, color: badgeColor.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            r['nlpTriage'],
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor.withOpacity(0.9)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  if (r['nlpPreparation'] != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.medical_services_rounded, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            r['nlpPreparation'],
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  if (r['symptomsText'] != null)
                    Text(
                      '"${r['symptomsText']}"',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontStyle: FontStyle.italic, color: AppTheme.textSecondary.withOpacity(0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ] else ...[
                  // 2. DISEASE PREDICTOR (Fallback)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          diseaseLabel,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: badgeColor),
                        ),
                      ),
                      if (colorStr != 'green')
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 10, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text('${confidence.toStringAsFixed(0)}%', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (explanations.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: explanations.map((expl) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(colorStr == 'green' ? Icons.check_circle_outline : Icons.search_rounded, size: 10, color: badgeColor),
                            const SizedBox(width: 4),
                            Text(
                              expl.toString(),
                              style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w600, color: badgeColor.withOpacity(0.9)),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ],
            ),
          ),
          
          // ══ ACTION CLINIQUE ══
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: hasNlp && r['nlpActionButton'] != null
                  ? ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(badgeColor == const Color(0xFFEF4444) ? Icons.emergency_rounded : Icons.check_circle_outline_rounded, size: 14),
                      label: Text(r['nlpActionButton']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: badgeColor == const Color(0xFF22C55E) ? Colors.white : badgeColor,
                        foregroundColor: badgeColor == const Color(0xFF22C55E) ? const Color(0xFF22C55E) : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: badgeColor == const Color(0xFF22C55E) ? BorderSide(color: const Color(0xFF22C55E).withOpacity(0.3)) : BorderSide.none,
                        elevation: 0,
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    )
                  : badgeColor == const Color(0xFFEF4444)
                      ? ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.warning_rounded, size: 14),
                          label: const Text('Préparer dossier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                            textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        )
                      : badgeColor == const Color(0xFFF59E0B)
                          ? ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.visibility_rounded, size: 14),
                              label: const Text('Aviser médecin'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                                textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Text('RAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                            ),
            ),
          ),
        ],
      ),
    );
  }


  // ======= QUICK ACTION =======
  Widget _buildQuickAction(String title, String subtitle, IconData icon, Color color, int targetIndex) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (widget.onNavigate != null) {
            widget.onNavigate!(targetIndex);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======= EFFICIENCY CARD =======
  Widget _buildEfficiencyCard(double rate, int completed, int total) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMedical.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Efficacité Mensuelle',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ce mois',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Animated circular progress
              SizedBox(
                width: 100,
                height: 100,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: rate / 100),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '${(value * 100).toInt()}%',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RDV complétés',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$completed',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' / $total',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Mini progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: rate / 100),
                        duration: const Duration(milliseconds: 1500),
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======= ACTIVITY CARD =======
  Widget _buildActivityCard(List recentActivities) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.timeline_rounded, color: AppTheme.indigo, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Activité Récente',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text(
                  'Voir tout',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryMedical,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recentActivities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      "Aucune activité récente",
                      style: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(
              recentActivities.length > 4 ? 4 : recentActivities.length,
              (index) {
                final act = recentActivities[index];
                IconData actIcon = Icons.notifications_rounded;
                Color actColor = Colors.grey;
                if (act['type'] == 'appointment') {
                  actIcon = Icons.calendar_today_rounded;
                  actColor = AppTheme.primaryMedical;
                }
                if (act['type'] == 'admission') {
                  actIcon = Icons.person_add_alt_1_rounded;
                  actColor = AppTheme.warning;
                }
                if (act['type'] == 'invoice') {
                  actIcon = Icons.receipt_long_rounded;
                  actColor = AppTheme.success;
                }

                String timeText = '';
                if (act['date'] != null) {
                  final actDate = DateTime.parse(act['date']);
                  final diff = DateTime.now().difference(actDate);
                  if (diff.inMinutes < 60) {
                    timeText = 'Il y a ${diff.inMinutes} min';
                  } else if (diff.inHours < 24) {
                    timeText = 'Il y a ${diff.inHours}h';
                  } else {
                    timeText = 'Il y a ${diff.inDays}j';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: actColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(actIcon, size: 16, color: actColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act['title'] ?? 'Action',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkNavy,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              act['description'] ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          timeText,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ======= REVENUE CHART =======
  Widget _buildRevenueChart(double todayRevenue) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: AppTheme.success, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revenus de la Semaine',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkNavy,
                        ),
                      ),
                      Text(
                        'Évolution des encaissements (DA)',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 14, color: AppTheme.success),
                    const SizedBox(width: 4),
                    Text(
                      '+24%',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBarChartColumn('Lun', 2000, 10000),
                _buildBarChartColumn('Mar', 4500, 10000),
                _buildBarChartColumn('Mer', 3000, 10000),
                _buildBarChartColumn('Jeu', 8500, 10000),
                _buildBarChartColumn('Ven', todayRevenue, 10000, isToday: true),
                _buildBarChartColumn('Sam', 0, 10000),
                _buildBarChartColumn('Dim', 0, 10000),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======= TOP DOCTORS =======
  Widget _buildTopDoctorsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.emoji_events_rounded, color: Colors.amber[700], size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Top Médecins',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                ],
              ),
              Text(
                'Ce mois',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTopDoctorRow('Dr. Amine Benali', 'Cardiologie', '14', 1),
          const SizedBox(height: 14),
          _buildTopDoctorRow('Dr. Sara Mansouri', 'Pédiatrie', '9', 2),
          const SizedBox(height: 14),
          _buildTopDoctorRow('Dr. Karim Ziani', 'Généraliste', '5', 3),
        ],
      ),
    );
  }

  Widget _buildTopDoctorRow(String name, String spec, String rdvCount, int rank) {
    final colors = [Colors.amber[600]!, Colors.blueGrey[400]!, Colors.brown[300]!];
    final gradients = [
      const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFA000)]),
      const LinearGradient(colors: [Color(0xFF90A4AE), Color(0xFF607D8B)]),
      const LinearGradient(colors: [Color(0xFFBCAAA4), Color(0xFF8D6E63)]),
    ];
    final rankColor = colors[rank - 1];
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: rankColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rankColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: gradients[rank - 1],
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkNavy,
                    fontSize: 13,
                  ),
                ),
                Text(
                  spec,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryMedical.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$rdvCount RDV',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryMedical,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======= BAR CHART COLUMN =======
  Widget _buildBarChartColumn(String label, double value, double maxValue, {bool isToday = false}) {
    final double percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percentage),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, animVal, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (value > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${(value / 1000).toStringAsFixed(1)}k',
                  style: GoogleFonts.plusJakartaSans(
                    color: isToday ? AppTheme.darkNavy : AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            Container(
              width: isToday ? 38 : 28,
              height: 140 * animVal + 4,
              decoration: BoxDecoration(
                gradient: isToday
                    ? const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      )
                    : null,
                color: isToday ? null : AppTheme.primaryMedical.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isToday
                    ? [BoxShadow(color: AppTheme.primaryMedical.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isToday ? AppTheme.primaryMedical : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  // ======= LOADING SKELETON =======
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner skeleton
          _shimmerBox(height: 160, width: double.infinity, radius: 24),
          const SizedBox(height: 28),
          // KPI row skeleton
          Row(
            children: List.generate(4, (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i > 0 ? 16 : 0),
                child: _shimmerBox(height: 140, radius: 20),
              ),
            )),
          ),
          const SizedBox(height: 28),
          _shimmerBox(height: 16, width: 140, radius: 8),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i > 0 ? 14 : 0),
                child: _shimmerBox(height: 80, radius: 18),
              ),
            )),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(flex: 2, child: _shimmerBox(height: 200, radius: 22)),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: _shimmerBox(height: 200, radius: 20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({double? height, double? width, double radius = 12}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [
                AppTheme.dividerLight.withOpacity(value),
                AppTheme.dividerLight.withOpacity(value * 0.5),
                AppTheme.dividerLight.withOpacity(value),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  // ======= ERROR STATE =======
  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: AppTheme.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text('Réessayer', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMedical,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Staggered entry animation for KPI cards
  Widget _buildStaggeredKpi(int index, Widget child) {
    final start = index * 0.15;
    final end = start + 0.6;
    final anim = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - anim.value)),
          child: Opacity(
            opacity: anim.value,
            child: child,
          ),
        );
      },
    );
  }
}

// Heartbeat/ECG line CustomPainter
class _HeartbeatLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _HeartbeatLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final midY = h * 0.5;

    path.moveTo(0, midY);

    // Create ECG-like pattern
    final segmentWidth = w / 8;
    for (int i = 0; i < 8; i++) {
      final x = i * segmentWidth;
      final phase = (i + progress * 2) % 4;

      if (phase < 1) {
        // Flat line
        path.lineTo(x + segmentWidth * 0.3, midY);
        // Sharp peak
        path.lineTo(x + segmentWidth * 0.4, midY - h * 0.35);
        path.lineTo(x + segmentWidth * 0.5, midY + h * 0.15);
        path.lineTo(x + segmentWidth * 0.6, midY);
        path.lineTo(x + segmentWidth, midY);
      } else {
        // Flat line segment
        path.lineTo(x + segmentWidth, midY);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartbeatLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
