import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../patients/patient_access_request_screen.dart';
import '../patients/patient_medical_record_screen.dart';
import '../ai/ai_decision_support_screen.dart';
import '../profile/doctor_profile_screen.dart';

/// Tableau de Bord Moderne avec Navigation
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeView(),
    const _PatientsView(),
    const AiDecisionSupportScreen(),
    const DoctorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'Accueil'),
              _buildNavItem(1, Icons.people_rounded, 'Patients'),
              _buildNavItem(2, Icons.auto_awesome, 'IA'),
              _buildNavItem(3, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.textLight, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.background],
          stops: const [0, 0.3],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 28),
              _buildStatsGrid(context),
              const SizedBox(height: 28),
              _buildQuickActions(context),
              const SizedBox(height: 28),
              _buildPendingRequests(context),
              const SizedBox(height: 28),
              _buildTodayConsultations(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final doctorProfile = authProvider.doctorProfile;
    final doctorName = doctorProfile?.fullName ?? 'Dr. Docteur';
    final initials = doctorProfile?.initials ?? 'DR';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour 👋',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctorName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 24, color: Colors.white),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
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

  Widget _buildStatsGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Aujourd\'hui',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  '24',
                  'Patients du jour',
                  Icons.people_alt_rounded,
                  AppColors.primary,
                  AppColors.primaryGradient,
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernStatCard(
                  '8',
                  'En attente',
                  Icons.pending_actions_rounded,
                  AppColors.warning,
                  LinearGradient(
                    colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
                  ),
                  false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  '3',
                  'Alertes critiques',
                  Icons.warning_rounded,
                  AppColors.error,
                  LinearGradient(
                    colors: [AppColors.error, AppColors.error.withValues(alpha: 0.7)],
                  ),
                  false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernStatCard(
                  '12',
                  'Suggestions IA',
                  Icons.auto_awesome,
                  AppColors.ai,
                  AppColors.aiGradient,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(String value, String label, IconData icon, Color color, Gradient gradient, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isHighlighted ? gradient : null,
        color: isHighlighted ? null : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted ? null : Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isHighlighted ? Colors.white : color,
                  size: 20,
                ),
              ),
              if (isHighlighted)
                Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isHighlighted ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isHighlighted ? Colors.white.withValues(alpha: 0.9) : color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildModernActionButton(
                context,
                Icons.add_circle_outline,
                'Nouvelle\nConsult.',
                AppColors.primary,
                AppColors.primaryGradient,
              ),
              const SizedBox(width: 12),
              _buildModernActionButton(
                context,
                Icons.document_scanner_outlined,
                'Scanner\nDocument',
                AppColors.secondary,
                LinearGradient(colors: [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.7)]),
              ),
              const SizedBox(width: 12),
              _buildModernActionButton(
                context,
                Icons.video_call_outlined,
                'Appel\nVidéo',
                AppColors.diagnosis,
                LinearGradient(colors: [AppColors.diagnosis, AppColors.diagnosis.withValues(alpha: 0.7)]),
              ),
              const SizedBox(width: 12),
              _buildModernActionButton(
                context,
                Icons.calendar_today_outlined,
                'Planifier',
                AppColors.prescription,
                LinearGradient(colors: [AppColors.prescription, AppColors.prescription.withValues(alpha: 0.7)]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(BuildContext context, IconData icon, String label, Color color, Gradient gradient) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequests(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.key_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Demandes d'accès",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientAccessRequestScreen())),
                child: const Text(
                  'Voir tout',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildModernRequestItem('Jean Dupont', 'Accès urgence', AppColors.error, 'URGENT'),
          const SizedBox(height: 12),
          _buildModernRequestItem('Marie Martin', 'Historique médical', AppColors.warning, 'HAUTE'),
        ],
      ),
    );
  }

  Widget _buildModernRequestItem(String name, String type, Color priorityColor, String priority) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [priorityColor.withValues(alpha: 0.1), priorityColor.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [priorityColor, priorityColor.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: priorityColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [priorityColor, priorityColor.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: priorityColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              priority,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayConsultations(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "Consultations du jour",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildModernConsultationItem(context, 'Pierre Dubois', '09:00', 'Suivi diabète', AppColors.primary, true),
          const SizedBox(height: 12),
          _buildModernConsultationItem(context, 'Sophie Laurent', '10:30', 'Bilan général', AppColors.secondary, false),
          const SizedBox(height: 12),
          _buildModernConsultationItem(context, 'Marc Petit', '14:00', 'Contrôle cardiaque', AppColors.error, false),
        ],
      ),
    );
  }

  Widget _buildModernConsultationItem(BuildContext context, String name, String time, String type, Color color, bool isNow) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientMedicalRecordScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isNow
              ? LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)])
              : LinearGradient(colors: [AppColors.background, AppColors.surface]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNow ? color.withValues(alpha: 0.3) : AppColors.textLight.withValues(alpha: 0.1),
          ),
          boxShadow: isNow
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isNow
                    ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
                    : null,
                color: isNow ? null : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: isNow ? null : Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time.split(':')[0],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isNow ? Colors.white : color,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    time.split(':')[1],
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isNow ? Colors.white.withValues(alpha: 0.9) : color.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isNow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'EN COURS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _PatientsView extends StatelessWidget {
  const _PatientsView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Patients', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 15)],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un patient...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textLight),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildPatientCard(context, 'Jean Dupont', 'Diabète Type 2', AppColors.warning),
                  _buildPatientCard(context, 'Marie Martin', 'Hypertension', AppColors.error),
                  _buildPatientCard(context, 'Pierre Dubois', 'Soins généraux', AppColors.success),
                  _buildPatientCard(context, 'Sophie Laurent', 'Cardiologie', AppColors.prescription),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, String name, String condition, Color color) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientMedicalRecordScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 15)],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(condition, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_right, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
