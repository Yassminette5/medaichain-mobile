import 'package:flutter/material.dart';
import 'package:medaichainmobile/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tabs/clinique_doctors_tab.dart';
import 'tabs/clinique_dashboard_tab.dart';
import 'tabs/clinique_settings_tab.dart';
import 'tabs/clinique_finance_tab.dart';

class HomeAdminCliniqueMobile extends StatefulWidget {
  const HomeAdminCliniqueMobile({super.key});

  @override
  State<HomeAdminCliniqueMobile> createState() => _HomeAdminCliniqueMobileState();
}

class _HomeAdminCliniqueMobileState extends State<HomeAdminCliniqueMobile> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              CliniqueDashboardTab(),
              CliniqueFinanceTab(),
              CliniqueDoctorsTab(),
              CliniqueSettingsTab(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFloatingBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomBar() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'Accueil'),
              _buildNavItem(1, Icons.request_quote_rounded, 'Finance'),
              _buildNavItem(2, Icons.medical_services_rounded, 'Médecins'),
              _buildNavItem(3, Icons.health_and_safety_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    // Premium Blue for Clinical look
    final Color selectedColor = const Color(0xFF1E88E5);
    final Color unselectedColor = const Color(0xFF90A4AE);

    return GestureDetector(
      onTap: () {
        if (_currentIndex == index) return;
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selectedColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
