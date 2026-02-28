import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../views/dashboard_home_view.dart';
import '../views/doctors_management_view.dart';
import '../views/reception_admissions_view.dart';
import '../views/appointments_view.dart';
import '../views/clinic_profile_view.dart';

class DashboardMainScreen extends StatefulWidget {
  const DashboardMainScreen({super.key});

  @override
  State<DashboardMainScreen> createState() => _DashboardMainScreenState();
}

class _DashboardMainScreenState extends State<DashboardMainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _views = [
    DashboardHomeView(onNavigate: (index) {
      if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
      }
    }),
    const DoctorsManagementView(),
    const ReceptionAdmissionsView(),
    const AppointmentsView(),
    const ClinicProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                // Logo Area
                Container(
                  height: 100,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.vaccines, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'MEDAIChain',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Menu Items
                _buildNavItem(0, 'Tableau de bord', Icons.dashboard_rounded),
                _buildNavItem(1, 'Gestion des Médecins', Icons.people_alt_rounded),
                _buildNavItem(2, 'Réception/Admissions', Icons.how_to_reg_rounded),
                _buildNavItem(3, 'Gestion des RDV', Icons.calendar_month_rounded),
                _buildNavItem(4, 'Profil Clinique', Icons.settings_rounded),
                const Spacer(),
                // Logout
                _buildNavItem(-1, 'Déconnexion', Icons.logout_rounded, isLogout: true),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top AppBar (Web style)
                Container(
                  height: 80,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTitle(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkNavy,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.background,
                            ),
                            child: const Icon(Icons.notifications_none_rounded, color: AppTheme.darkNavy),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Clinique Centrale',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.darkNavy,
                                      ),
                                    ),
                                    Text(
                                      'Admin',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.grey,
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
                ),
                // View Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    child: _selectedIndex >= 0 ? _views[_selectedIndex] : const Center(child: Text("Déconnexion...")),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, {bool isLogout = false}) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        if (isLogout) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Déconnexion', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
              content: Text('Voulez-vous vraiment vous déconnecter du tableau de bord ?', style: GoogleFonts.plusJakartaSans(color: Colors.grey[700])),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Annuler', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ApiService.logout();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Se déconnecter', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryMedical.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? AppTheme.error : (isSelected ? AppTheme.primaryMedical : Colors.grey[600]),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: isLogout ? AppTheme.error : (isSelected ? AppTheme.primaryMedical : Colors.grey[700]),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Gestion des Médecins';
      case 2:
        return 'Réception & Admissions';
      case 3:
        return 'Gestion des RDV';
      case 4:
        return 'Profil Clinique';
      default:
        return '';
    }
  }
}

