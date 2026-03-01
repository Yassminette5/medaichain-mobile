import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:medaichainmobile/providers/auth_provider.dart';
import 'package:medaichainmobile/services/api_service.dart';
import 'package:medaichainmobile/clinique/theme/app_theme.dart';
import 'package:medaichainmobile/widgets/medical_animated_background.dart';
import 'views/dashboard_home_view.dart';
import 'views/doctors_management_view.dart';
import 'views/reception_admissions_view.dart';
import 'views/appointments_view.dart';
import 'views/clinic_profile_view.dart';
import 'views/waiting_room_view.dart';
import 'views/appointments_calendar_view.dart';
import 'views/invoices_view.dart';

class DashboardMainScreen extends StatefulWidget {
  const DashboardMainScreen({super.key});

  @override
  State<DashboardMainScreen> createState() => _DashboardMainScreenState();
}

class _DashboardMainScreenState extends State<DashboardMainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  String _currentTime = '';
  String _currentDate = '';
  Timer? _clockTimer;
  bool _sidebarCollapsed = false;
  String _clinicName = 'Ma Clinique';
  String _clinicEmail = '';

  List<Widget> get _views => [
    DashboardHomeView(
      clinicName: _clinicName,
      onNavigate: (index) {
        if (mounted) {
          setState(() {
            _selectedIndex = index;
          });
          _animController.forward(from: 0);
        }
      },
    ),
    const DoctorsManagementView(),
    const ReceptionAdmissionsView(),
    const AppointmentsView(),
    const WaitingRoomView(),
    const AppointmentsCalendarView(),
    const InvoicesView(),
    ClinicProfileView(onProfileUpdated: _loadClinicProfile),
  ];


  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateClock());
    _loadClinicProfile();
  }

  Future<void> _loadClinicProfile() async {
    try {
      final profile = await ApiService.getClinicProfile();
      if (mounted) {
        setState(() {
          _clinicName = profile['name'] ?? 'Ma Clinique';
          _clinicEmail = profile['email'] ?? '';
        });
      }
    } catch (e) {
      // ignore – keep default name
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _currentDate = '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // ======= PREMIUM SIDEBAR =======
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: _sidebarCollapsed ? 80 : 270,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.sidebarGradient,
              ),
              child: Column(
                children: [
                  // Logo Area
                  Container(
                    height: 80,
                    padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 12 : 24),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryMedical.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.vaccines_rounded, color: Colors.white, size: 22),
                        ),
                        if (!_sidebarCollapsed) ...[
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MEDAIChain',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'Clinic Dashboard',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Divider
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 12 : 20),
                    child: Divider(color: Colors.white.withOpacity(0.06), height: 1),
                  ),
                  const SizedBox(height: 16),
                  // Section Title
                  if (!_sidebarCollapsed)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'MENU PRINCIPAL',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  // Navigation Items
                  _buildNavItem(0, 'Tableau de bord', Icons.dashboard_rounded),
                  _buildNavItem(1, 'Médecins', Icons.people_alt_rounded, badge: '5'),
                  _buildNavItem(2, 'Réception', Icons.how_to_reg_rounded),
                  _buildNavItem(3, 'Rendez-vous', Icons.calendar_month_rounded, badge: '3'),
                  _buildNavItem(4, 'Salle d\'attente', Icons.event_seat_rounded),
                  _buildNavItem(5, 'Calendrier RDV', Icons.calendar_view_week_rounded),
                  _buildNavItem(6, 'Facturation', Icons.receipt_long_rounded),
                  const SizedBox(height: 16),
                  if (!_sidebarCollapsed)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'PARAMÈTRES',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  _buildNavItem(7, 'Profil Clinique', Icons.settings_rounded),
                  const Spacer(),
                  // Collapse toggle
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 16 : 20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: _sidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                          children: [
                            Icon(
                              _sidebarCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            if (!_sidebarCollapsed) ...[
                              const SizedBox(width: 12),
                              Text(
                                'Réduire',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Divider above profile
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 12 : 20),
                    child: Divider(color: Colors.white.withOpacity(0.06), height: 1),
                  ),
                  // User Mini Profile
                  Padding(
                    padding: EdgeInsets.all(_sidebarCollapsed ? 12 : 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _showLogoutDialog(),
                      child: Container(
                        padding: EdgeInsets.all(_sidebarCollapsed ? 8 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  _clinicName.isNotEmpty ? _clinicName[0].toUpperCase() : 'C',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            if (!_sidebarCollapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _clinicName,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _clinicEmail.isNotEmpty ? _clinicEmail : 'Administrateur',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.logout_rounded, color: AppTheme.textSecondary.withOpacity(0.6), size: 18),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ======= MAIN CONTENT =======
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      // Page Title + Breadcrumb
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTitle(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkNavy,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'Dashboard',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_selectedIndex > 0) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.chevron_right_rounded, size: 14, color: AppTheme.textSecondary.withOpacity(0.5)),
                                ),
                                Text(
                                  _getTitle(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppTheme.primaryMedical,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Search bar
                      Container(
                        width: 280,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerLight.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Icon(Icons.search_rounded, color: AppTheme.textSecondary.withOpacity(0.6), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Recherche rapide...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textSecondary.withOpacity(0.5),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  filled: false,
                                ),
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.darkNavy),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.dividerLight),
                              ),
                              child: Text('⌘K', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Date/Time
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 16, color: AppTheme.primaryMedical.withOpacity(0.7)),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentTime,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.darkNavy,
                                  ),
                                ),
                                Text(
                                  _currentDate,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Notification bell
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.notifications_none_rounded, color: AppTheme.darkNavy, size: 22),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Page Content with animated medical background
                Expanded(
                  child: MedicalAnimatedBackground(
                    showIcons: true,
                    showParticles: true,
                    showWaves: true,
                    iconOpacity: 0.05,
                    particleOpacity: 0.06,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: _selectedIndex >= 0
                            ? _views[_selectedIndex]
                            : const Center(child: Text("Déconnexion...")),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, {String? badge}) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 12 : 14, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _selectedIndex = index);
            _animController.forward(from: 0);
          },
          hoverColor: AppTheme.sidebarHover,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 0 : 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppTheme.primaryMedical.withOpacity(0.2))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: _sidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                // Active indicator
                if (isSelected && !_sidebarCollapsed)
                  Container(
                    width: 3,
                    height: 20,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryMedical.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryMedical : AppTheme.textSecondary,
                  size: 20,
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMedical.withOpacity(isSelected ? 0.3 : 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.plusJakartaSans(
                          color: isSelected ? Colors.white : AppTheme.primaryMedical,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Déconnexion', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.darkNavy, fontSize: 18)),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter du tableau de bord ?',
          style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Annuler', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ApiService.clearClinicCache();
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Se déconnecter', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0: return 'Tableau de bord';
      case 1: return 'Gestion des Médecins';
      case 2: return 'Réception & Admissions';
      case 3: return 'Gestion des RDV';
      case 4: return 'Salle d\'attente';
      case 5: return 'Calendrier des RDV';
      case 6: return 'Facturation';
      case 7: return 'Profil Clinique';
      default: return '';
    }
  }
}
