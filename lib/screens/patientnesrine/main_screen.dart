import 'package:flutter/material.dart';
import '../patientnesrine/health_drawer_screen.dart';
import '../patientnesrine/homeScreen.dart';
import '../patientnesrine/profile_screen.dart';
import '../patientnesrine/records_screen.dart';
import '../../core/theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RecordsScreen(),
    const HealthDrawerScreen(),
    const ProfileScreen(),
  ];

  static const _navItems = [
    _NavItem(
      icon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Accueil',
    ),
    _NavItem(
      icon: Icons.favorite_rounded,
      inactiveIcon: Icons.favorite_border_rounded,
      label: 'Santé',
    ),
    _NavItem(
      icon: Icons.medical_services_rounded,
      inactiveIcon: Icons.medical_services_outlined,
      label: 'Services',
    ),
    _NavItem(
      icon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                (i) => _buildNavItem(i),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Blue dot indicator above icon ──────────────────────────────
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 5),

            // ── Icon pill with animated fill ───────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.neonGradient : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isSelected ? item.icon : item.inactiveIcon,
                color: isSelected ? Colors.white : Colors.grey.shade400,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),

            // ── Label — always reserves height, fades in/out ───────────────
            SizedBox(
              height: 13,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                opacity: isSelected ? 1.0 : 0.0,
                child: Text(
                  item.label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Internal nav-item data class ─────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData inactiveIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.inactiveIcon,
    required this.label,
  });
}

// ─── ContainerWidget — kept unchanged ─────────────────────────────────────────
class ContainerWidget extends StatelessWidget {
  final IconData icon;
  const ContainerWidget({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
