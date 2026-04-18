import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../patientnesrine/notifications_screen.dart';
import '../patientnesrine/doctor_detail_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../patientnesrine/doctor.dart';
import '../patientnesrine/profile_screen.dart';
import '../patientnesrine/doctors_list_screen.dart';
import '../patientnesrine/document_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _unreadNotificationCount = 0;
  List<Map<String, dynamic>> _topDoctors = [];
  bool _topDoctorsLoading = true;
  List<Map<String, dynamic>> _prescriptions = [];
  bool _prescriptionsLoading = true;
  int _selectedSpecialty = 0;

  late AnimationController _headerAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  final List<Map<String, dynamic>> _specialties = [
    {
      'icon': Icons.psychology_rounded,
      'label': 'Neurologie',
      'color': const Color(0xFF1E88E5),
    },
    {
      'icon': Icons.favorite_rounded,
      'label': 'Cardiologie',
      'color': const Color(0xFF00897B),
    },
    {
      'icon': Icons.accessibility_new_rounded,
      'label': 'Orthopédie',
      'color': const Color(0xFFFB8C00),
    },
    {
      'icon': Icons.air_rounded,
      'label': 'Pneumologie',
      'color': const Color(0xFF0097A7),
    },
    {
      'icon': Icons.remove_red_eye_rounded,
      'label': 'Ophtalmologie',
      'color': const Color(0xFF7E57C2),
    },
    {
      'icon': Icons.child_care_rounded,
      'label': 'Pédiatrie',
      'color': const Color(0xFFEC407A),
    },
    {
      'icon': Icons.face_rounded,
      'label': 'Dermatologie',
      'color': const Color(0xFF43A047),
    },
  ];

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic),
    );
    _headerAnimController.forward();

    _loadUnreadCount();
    _loadTopDoctors();
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _prescriptionsLoading = true);
    try {
      final list = await ApiService.getMyPrescriptions();
      if (mounted) {
        setState(() {
          _prescriptions = list;
          _prescriptionsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _prescriptions = [];
          _prescriptionsLoading = false;
        });
      }
    }
  }

  Future<void> _loadTopDoctors() async {
    setState(() => _topDoctorsLoading = true);
    try {
      final list = await ApiService.searchDoctors();
      if (mounted) {
        setState(() {
          _topDoctors = list;
          _topDoctorsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _topDoctors = [];
          _topDoctorsLoading = false;
        });
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final data = await ApiService.getUnreadNotificationsCount();
      final count =
          data['unreadCount'] is int ? data['unreadCount'] as int : 0;
      if (mounted) setState(() => _unreadNotificationCount = count);
    } catch (_) {
      if (mounted) setState(() => _unreadNotificationCount = 0);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadPrescriptions(),
      _loadUnreadCount(),
      _loadTopDoctors(),
    ]);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour 🌤️';
    if (hour < 17) return 'Bon après-midi ☀️';
    return 'Bonsoir 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        displacement: 60,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Curved Header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: _buildHeader(dateStr),
                ),
              ),
            ),

            // ── Body Content ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Search bar
                  _buildSearchBar(),
                  const SizedBox(height: 28),

                  // Services rapides
                  _buildSectionTitle('Mes Services'),
                  const SizedBox(height: 14),
                  _buildQuickServices(),
                  const SizedBox(height: 28),

                  // Spécialités scroll
                  _buildSectionTitle('Spécialités'),
                  const SizedBox(height: 14),
                  _buildSpecialtiesScroll(),
                  const SizedBox(height: 28),

                  // Prochain rendez-vous
                  _buildSectionTitle(
                    'Prochain rendez-vous',
                    actionLabel: 'Voir tout',
                    onTap: () {},
                  ),
                  const SizedBox(height: 14),
                  _buildAppointmentCard(),
                  const SizedBox(height: 28),

                  // Mes ordonnances
                  _buildSectionTitle('Mes ordonnances'),
                  const SizedBox(height: 14),
                  _buildPrescriptionsSection(),
                  const SizedBox(height: 28),

                  // Top Médecins
                  _buildSectionTitle(
                    'Top Médecins',
                    actionLabel: 'Voir tout',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorsListScreen(),
                        ),
                      );
                      _loadTopDoctors();
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildTopDoctors(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader(String dateStr) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final name = auth.user?.fullName ?? 'Patient';
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D47A1),
                Color(0xFF1565C0),
                Color(0xFF0288D1),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                right: 80,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 14, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: logo + actions
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          // Logo
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.medical_services_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'MEDAIChain',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          // Notification + Avatar
                          Row(
                            children: [
                              _buildNotificationButton(context),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ProfileScreen(),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: Color(0xFF1565C0),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Greeting + Name
                      Text(
                        _getGreeting(),
                        style: GoogleFonts.poppins(
                          color:
                              Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white54,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: GoogleFonts.poppins(
                              color: Colors.white
                                  .withValues(alpha: 0.60),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Health stats
                      Row(
                        children: [
                          _buildHealthStat(
                            Icons.favorite_rounded,
                            '72 bpm',
                            'Pouls',
                            const Color(0xFFEF5350),
                          ),
                          const SizedBox(width: 10),
                          _buildHealthStat(
                            Icons.thermostat_rounded,
                            '37.0°C',
                            'Température',
                            const Color(0xFFFB8C00),
                          ),
                          const SizedBox(width: 10),
                          _buildHealthStat(
                            Icons.water_drop_rounded,
                            '98%',
                            'SpO2',
                            const Color(0xFF42A5F5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthStat(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 13),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher médecins, spécialités...',
          hintStyle: GoogleFonts.poppins(
            color: AppColors.textLight,
            fontSize: 13,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blockchainLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ── SECTION TITLE ─────────────────────────────────────────────────────────

  Widget _buildSectionTitle(
    String title, {
    VoidCallback? onTap,
    String actionLabel = 'Voir tout',
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.blockchainLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── QUICK SERVICES ────────────────────────────────────────────────────────

  Widget _buildQuickServices() {
    final services = [
      {
        'icon': Icons.calendar_month_rounded,
        'label': 'Rendez-\nvous',
        'gradient': const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'shadow': const Color(0xFF1565C0),
      },
      {
        'icon': Icons.description_rounded,
        'label': 'Ordon-\nnances',
        'gradient': const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'shadow': const Color(0xFF00897B),
      },
      {
        'icon': Icons.science_rounded,
        'label': 'Analyses',
        'gradient': const LinearGradient(
          colors: [Color(0xFF00838F), Color(0xFF00ACC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'shadow': const Color(0xFF00ACC1),
      },
      {
        'icon': Icons.emergency_rounded,
        'label': 'Urgences',
        'gradient': const LinearGradient(
          colors: [Color(0xFFC62828), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'shadow': const Color(0xFFEF5350),
      },
    ];

    return Row(
      children: services.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 9),
            padding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              gradient: s['gradient'] as LinearGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color:
                      (s['shadow'] as Color).withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    s['icon'] as IconData,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s['label'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── SPECIALTIES SCROLL ────────────────────────────────────────────────────

  Widget _buildSpecialtiesScroll() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _specialties.length,
        itemBuilder: (context, i) {
          final s = _specialties[i];
          final selected = _selectedSpecialty == i;
          final color = s['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _selectedSpecialty = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected ? color : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.38),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                border: selected
                    ? null
                    : Border.all(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    s['icon'] as IconData,
                    color: selected
                        ? Colors.white
                        : color,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    s['label'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── APPOINTMENT CARD ──────────────────────────────────────────────────────

  Widget _buildAppointmentCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00695C),
            Color(0xFF00897B),
            Color(0xFF26A69A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00897B).withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -25,
            right: -25,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -35,
            left: -25,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Doctor info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person_rounded,
                          color: Color(0xFF00897B),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. Jennifer Smith',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Consultation Orthopédique',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Confirmé ✓',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Date & time
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white70,
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mer, 7 Sep 2024',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 22,
                        color: Colors.white30,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Colors.white70,
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '10:30 AM',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Rejoindre',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF00695C),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Reprogrammer',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PRESCRIPTIONS SECTION ─────────────────────────────────────────────────

  Widget _buildPrescriptionsSection() {
    if (_prescriptionsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_prescriptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.prescriptionLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.prescription,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aucune ordonnance',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vos ordonnances apparaîtront ici',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _prescriptions
          .take(5)
          .map((p) => _buildPrescriptionCard(p))
          .toList(),
    );
  }

  // ── TOP DOCTORS ───────────────────────────────────────────────────────────

  Widget _buildTopDoctors() {
    return SizedBox(
      height: 200,
      child: _topDoctorsLoading
          ? const Center(child: CircularProgressIndicator())
          : _topDoctors.isEmpty
              ? Center(
                  child: Text(
                    'Aucun médecin disponible',
                    style: GoogleFonts.poppins(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _topDoctors.length,
                  itemBuilder: (context, index) {
                    final d = _topDoctors[index];
                    final u = d['userId'];
                    final doctorId = u is Map
                        ? u['_id']?.toString()
                        : u?.toString();
                    final doctor = Doctor(
                      name: d['fullName'] ?? 'Médecin',
                      specialty:
                          d['speciality'] ?? 'Médecine générale',
                      hospital: d['hospital'] ?? '',
                      rating: 4.5,
                      reviews: 0,
                      experience:
                          (d['yearsOfExperience'] as num?)?.toInt() ??
                              0,
                      about: '',
                      imagePath: '',
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _buildDoctorCard(
                        context,
                        doctor,
                        doctorId: doctorId,
                      ),
                    );
                  },
                ),
    );
  }

  // ── PRESCRIPTION CARD ─────────────────────────────────────────────────────

  Widget _buildPrescriptionCard(Map<String, dynamic> p) {
    final doctorId = p['doctorId'];
    String doctorName = 'Médecin';
    if (doctorId is Map) {
      doctorName =
          doctorId['fullName'] ?? doctorId['email'] ?? 'Médecin';
    }
    final meds = p['medications'] as List? ?? [];
    final firstMed = meds.isNotEmpty && meds[0] is Map
        ? '${(meds[0] as Map)['name']} ${(meds[0] as Map)['dosage']}'
        : null;
    final status = p['status'] as String? ?? 'active';
    final date = p['prescriptionDate'] != null
        ? DateFormat('dd MMM yyyy', 'fr').format(
            DateTime.parse(p['prescriptionDate'].toString()),
          )
        : (p['createdAt'] != null
            ? DateFormat('dd MMM yyyy', 'fr').format(
                DateTime.parse(p['createdAt'].toString()),
              )
            : '--');
    final statusLabel = status == 'active'
        ? 'Active'
        : status == 'completed'
            ? 'Complétée'
            : 'Annulée';
    final statusColor = status == 'active'
        ? AppColors.secondary
        : status == 'completed'
            ? AppColors.success
            : AppColors.textGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.aiLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (firstMed != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      firstMed,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textLight,
          ),
        ],
      ),
    );
  }

  // ── NOTIFICATION BUTTON ───────────────────────────────────────────────────

  Widget _buildNotificationButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NotificationsScreen(),
          ),
        );
        _loadUnreadCount();
        _loadPrescriptions();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (_unreadNotificationCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _unreadNotificationCount > 99
                      ? '99+'
                      : '$_unreadNotificationCount',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── DOCTOR CARD ───────────────────────────────────────────────────────────

  Widget _buildDoctorCard(
    BuildContext context,
    Doctor doctor, {
    String? doctorId,
  }) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DoctorDetailSheet(
            doctor: doctor,
            doctorId: doctorId,
          ),
        );
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.blockchainLight,
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              doctor.name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              doctor.specialty,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFB8C00),
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  '${doctor.rating}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── LEGACY WIDGETS (kept for compatibility) ───────────────────────────────

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
  }) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.medium,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.medium,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
