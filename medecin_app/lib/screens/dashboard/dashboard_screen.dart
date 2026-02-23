import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/medical_card.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../patients/patient_access_request_screen.dart';
import '../patients/patient_medical_record_screen.dart';
import '../patients/patient_medication_request_screen.dart';
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
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.4), blurRadius: 16)],
          ),
          child: const Center(child: Text('SM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour 👋', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Dr. Sarah Mitchell', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
          ),
          child: Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 24),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: AppColors.aiGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: '24',
                label: "Patients du jour",
                icon: Icons.people_alt_rounded,
                iconColor: AppColors.primary,
                gradient: AppColors.primaryGradient,
                hasGlow: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                value: '8',
                label: 'En attente',
                icon: Icons.pending_actions_rounded,
                iconColor: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: '3',
                label: 'Alertes critiques',
                icon: Icons.warning_rounded,
                iconColor: AppColors.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                value: '12',
                label: 'Suggestions IA',
                icon: Icons.auto_awesome,
                iconColor: AppColors.ai,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? UserRole.patient;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        userRole == UserRole.patient
            ? Row(
                children: [
                  _buildActionButton(
                    context,
                    Icons.medical_services_outlined,
                    'Demander\nMédicament',
                    AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientMedicationRequestScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(context, Icons.document_scanner_outlined, 'Scanner\nDocument', AppColors.secondary),
                  const SizedBox(width: 12),
                  _buildActionButton(context, Icons.video_call_outlined, 'Appel\nVidéo', AppColors.diagnosis),
                  const SizedBox(width: 12),
                  _buildActionButton(context, Icons.calendar_today_outlined, 'Planifier', AppColors.prescription),
                ],
              )
            : Row(
                children: [
                  _buildActionButton(context, Icons.add_circle_outline, 'Nouvelle\nConsult.', AppColors.primary),
                  const SizedBox(width: 12),
                  _buildActionButton(context, Icons.document_scanner_outlined, 'Scanner\nDocument', AppColors.secondary),
                  const SizedBox(width: 12),
                  _buildActionButton(context, Icons.video_call_outlined, 'Appel\nVidéo', AppColors.diagnosis),
                  const SizedBox(width: 12),
                  _buildActionButton(context, Icons.calendar_today_outlined, 'Planifier', AppColors.prescription),
                ],
              ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 15)],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequests(BuildContext context) {
    return MedicalCard(
      title: "Demandes d'accès",
      titleIcon: Icons.key_rounded,
      trailing: TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientAccessRequestScreen())),
        child: const Text('Voir tout'),
      ),
      child: Column(
        children: [
          _buildRequestItem('Jean Dupont', 'Accès urgence', AppColors.error, 'URGENT'),
          const SizedBox(height: 12),
          _buildRequestItem('Marie Martin', 'Historique médical', AppColors.warning, 'HAUTE'),
        ],
      ),
    );
  }

  Widget _buildRequestItem(String name, String type, Color priorityColor, String priority) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: priorityColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: priorityColor.withValues(alpha: 0.1),
            radius: 22,
            child: Text(name[0], style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(type, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [priorityColor, priorityColor.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(priority, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayConsultations(BuildContext context) {
    return MedicalCard(
      title: "Consultations du jour",
      titleIcon: Icons.calendar_today_rounded,
      child: Column(
        children: [
          _buildConsultationItem(context, 'Pierre Dubois', '09:00', 'Suivi diabète', AppColors.primary, true),
          const SizedBox(height: 12),
          _buildConsultationItem(context, 'Sophie Laurent', '10:30', 'Bilan général', AppColors.secondary, false),
          const SizedBox(height: 12),
          _buildConsultationItem(context, 'Marc Petit', '14:00', 'Contrôle cardiaque', AppColors.error, false),
        ],
      ),
    );
  }

  Widget _buildConsultationItem(BuildContext context, String name, String time, String type, Color color, bool isNow) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientMedicalRecordScreen())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isNow ? color.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: isNow ? Border.all(color: color.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: isNow ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)]) : null,
                color: isNow ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(time, style: TextStyle(fontWeight: FontWeight.bold, color: isNow ? Colors.white : color, fontSize: 13))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(type, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            if (isNow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('EN COURS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
