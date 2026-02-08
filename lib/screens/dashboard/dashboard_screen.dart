import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../main.dart';
import '../../core/theme/futuristic_theme.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../patients/patient_access_request_screen.dart';
import '../patients/patient_medical_record_screen.dart';
import '../ai/ai_decision_support_screen.dart';
import '../history/access_history_screen.dart';
import '../operations/operation_presets_screen.dart';
import '../profile/doctor_profile_screen.dart';

/// Futuristic Doctor Dashboard
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _cardController;
  late List<Animation<Offset>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _cardAnimations = List.generate(
      4,
      (index) => Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _cardController,
          curve: Interval(
            index * 0.1,
            0.6 + (index * 0.1),
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );
    
    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedBackground(
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildAIInsights()),
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(child: _buildStats()),
                SliverToBoxAdapter(child: _buildRecentPatients()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHeader() {
    final themeProvider = ThemeProviderInherited.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (bounds) => FuturisticColors.cyberGradient.createShader(bounds),
                  child: const Text(
                    'Dr. Sophie Martin',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Dark mode toggle
          GestureDetector(
            onTap: () => themeProvider.toggleTheme(),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: FuturisticColors.cardDark,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    color: FuturisticColors.neonCyan,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          // Profile button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorProfileScreen()),
            ),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: FuturisticColors.aiGradient,
                boxShadow: FuturisticTheme.neonGlow(FuturisticColors.neonPurple),
              ),
              child: const Center(
                child: Text(
                  'SM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: SlideTransition(
        position: _cardAnimations[0],
        child: FadeTransition(
          opacity: _cardController,
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            showGlow: true,
            glowColor: FuturisticColors.neonPurple,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: FuturisticColors.aiGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: FuturisticTheme.neonGlow(FuturisticColors.neonPurple, intensity: 0.4),
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => FuturisticColors.aiGradient.createShader(bounds),
                            child: const Text(
                              'IA Assistant',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: FuturisticColors.aiGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ACTIF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '3 suggestions de diagnostic disponibles',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: FuturisticColors.neonPurple.withValues(alpha: 0.7),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.people_alt_outlined, 'label': 'Demandes', 'color': FuturisticColors.neonCyan, 'route': const PatientAccessRequestScreen()},
      {'icon': Icons.auto_awesome, 'label': 'IA Aide', 'color': FuturisticColors.neonPurple, 'route': const AIDecisionSupportScreen()},
      {'icon': Icons.history_rounded, 'label': 'Historique', 'color': FuturisticColors.neonYellow, 'route': const AccessHistoryScreen()},
      {'icon': Icons.description_outlined, 'label': 'Modèles', 'color': FuturisticColors.neonGreen, 'route': const OperationPresetsScreen()},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: List.generate(
          actions.length,
          (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < 3 ? 12 : 0),
              child: SlideTransition(
                position: _cardAnimations[1],
                child: FadeTransition(
                  opacity: _cardController,
                  child: _buildActionCard(
                    icon: actions[index]['icon'] as IconData,
                    label: actions[index]['label'] as String,
                    color: actions[index]['color'] as Color,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => actions[index]['route'] as Widget),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: FuturisticTheme.neonGlow(color, intensity: 0.3),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final stats = [
      {'value': '1,248', 'label': 'Patients', 'color': FuturisticColors.neonCyan},
      {'value': '856', 'label': 'Consultations', 'color': FuturisticColors.neonPurple},
      {'value': '4.9', 'label': 'Note', 'color': FuturisticColors.neonYellow},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: SlideTransition(
        position: _cardAnimations[2],
        child: FadeTransition(
          opacity: _cardController,
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: List.generate(
                stats.length,
                (index) => Expanded(
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [stats[index]['color'] as Color, (stats[index]['color'] as Color).withValues(alpha: 0.6)],
                        ).createShader(bounds),
                        child: Text(
                          stats[index]['value'] as String,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stats[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPatients() {
    final patients = [
      {'name': 'Jean Dupont', 'info': '45 ans • Diabète', 'urgent': true},
      {'name': 'Marie Lambert', 'info': '32 ans • Hypertension', 'urgent': false},
      {'name': 'Pierre Moreau', 'info': '58 ans • Contrôle', 'urgent': false},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Patients Récents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => FuturisticColors.cyberGradient.createShader(bounds),
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Voir tous',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...patients.asMap().entries.map((entry) {
            return SlideTransition(
              position: _cardAnimations[3],
              child: FadeTransition(
                opacity: _cardController,
                child: _buildPatientCard(entry.value),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final isUrgent = patient['urgent'] as bool;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PatientMedicalRecordScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: GlassCard(
          padding: const EdgeInsets.all(18),
          showGlow: isUrgent,
          glowColor: isUrgent ? const Color(0xFFEF4444) : null,
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: isUrgent
                      ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF87171)])
                      : FuturisticColors.cyberGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isUrgent
                      ? FuturisticTheme.neonGlow(const Color(0xFFEF4444), intensity: 0.4)
                      : null,
                ),
                child: Center(
                  child: Text(
                    (patient['name'] as String).split(' ').map((n) => n[0]).take(2).join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          patient['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        if (isUrgent) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      patient['info'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.3),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                FuturisticColors.primaryDark.withValues(alpha: 0.95),
                FuturisticColors.primaryDark,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FuturisticColors.glassWhite,
                      FuturisticColors.glassWhite.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: FuturisticColors.glassBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Accueil'),
                    _buildNavItem(1, Icons.people_outline, Icons.people, 'Patients'),
                    _buildNavItem(2, Icons.calendar_today_outlined, Icons.calendar_today, 'RDV'),
                    _buildNavItem(3, Icons.person_outline, Icons.person, 'Profil'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isActive ? 20 : 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? FuturisticColors.cyberGradient : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? FuturisticTheme.neonGlow(FuturisticColors.neonCyan, intensity: 0.4)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: Colors.white,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
