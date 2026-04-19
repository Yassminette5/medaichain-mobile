import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/medical_card.dart';
import '../../widgets/ai_assistant_chat.dart';
import '../auth/login_screen.dart';

/// Tableau de Bord Patient - Espace Santé Personnel
class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _PatientHomeView(),
          _PatientHealthView(),
          _PatientProfileView(),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AiAssistantChat(userId: authProvider.user?.id),
          );
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.aiGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 30),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
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
              _buildNavItem(0, Icons.home_rounded, 'Accueil'),
              _buildNavItem(1, Icons.favorite_rounded, 'Ma Santé'),
              _buildNavItem(2, Icons.person_rounded, 'Profil'),
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

// ========== HOME VIEW ==========
class _PatientHomeView extends StatelessWidget {
  const _PatientHomeView();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?.email.split('@').first ?? 'Patient';

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
              _buildHeader(userName, context),
              const SizedBox(height: 20),
              _buildAiAssistantCard(context),
              const SizedBox(height: 24),
              _buildHealthSummary(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildUpcomingAppointments(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiAssistantCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AiAssistantChat(userId: authProvider.user?.id),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.aiGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Besoin d\'aide ?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Parlez à notre assistant IA dès maintenant.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour 👋', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AiAssistantChat(userId: authProvider.user?.id),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.notifications_outlined, size: 24, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mon état de santé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHealthCard('Prochain RDV', '15 Mars', Icons.calendar_today_rounded, AppColors.primary),
              const SizedBox(width: 12),
              _buildHealthCard('Ordonnances', '3 actives', Icons.description_rounded, AppColors.prescription),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHealthCard('Analyses', '2 en cours', Icons.science_rounded, AppColors.secondary),
              const SizedBox(width: 12),
              _buildHealthCard('Documents', '12 fichiers', Icons.folder_rounded, AppColors.ai),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(Icons.calendar_month_rounded, 'Prendre\nRDV', AppColors.primary),
              const SizedBox(width: 12),
              _buildActionButton(Icons.description_rounded, 'Mes\nOrdonnances', AppColors.prescription),
              const SizedBox(width: 12),
              _buildActionButton(Icons.science_rounded, 'Mes\nAnalyses', AppColors.secondary),
              const SizedBox(width: 12),
              _buildActionButton(Icons.chat_bubble_outline, 'Contacter\nMédecin', AppColors.diagnosis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.event_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Prochains rendez-vous', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            ],
          ),
          const SizedBox(height: 16),
          _buildAppointmentItem('Dr. Benali', 'Médecin généraliste', '15 Mars', '09:00', AppColors.primary),
          const SizedBox(height: 10),
          _buildAppointmentItem('Dr. Hadj', 'Cardiologue', '22 Mars', '14:30', AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(String doctor, String speciality, String date, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(doctor[0] + doctor.split(' ').last[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(speciality, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
              const SizedBox(height: 2),
              Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Activité récente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem('Ordonnance reçue', 'Dr. Benali • Médecin généraliste', Icons.description_rounded, AppColors.prescription),
          const SizedBox(height: 10),
          _buildActivityItem('Résultat d\'analyses', 'Laboratoire Central', Icons.science_rounded, AppColors.secondary),
          const SizedBox(height: 10),
          _buildActivityItem('Consultation terminée', 'Dr. Hadj • Cardiologue', Icons.check_circle_rounded, AppColors.success),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

// ========== HEALTH VIEW ==========
class _PatientHealthView extends StatelessWidget {
  const _PatientHealthView();

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
              const Text('Ma Santé', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Gérez vos documents et votre dossier médical', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              _buildMedicalCard('Dossier médical', 'Consultez votre historique médical complet', Icons.medical_information_rounded, AppColors.primary),
              const SizedBox(height: 12),
              _buildMedicalCard('Ordonnances', 'Vos ordonnances et prescriptions actives', Icons.description_rounded, AppColors.prescription),
              const SizedBox(height: 12),
              _buildMedicalCard('Résultats d\'analyses', 'Consultez vos résultats de laboratoire', Icons.science_rounded, AppColors.secondary),
              const SizedBox(height: 12),
              _buildMedicalCard('Vaccinations', 'Votre carnet de vaccination', Icons.vaccines_rounded, AppColors.success),
              const SizedBox(height: 12),
              _buildMedicalCard('Allergies & Antécédents', 'Vos informations médicales importantes', Icons.warning_amber_rounded, AppColors.warning),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

// ========== RÉSULTATS D'ANALYSE (profil patient) ==========
class _PatientAnalysisResultsSection extends StatefulWidget {
  const _PatientAnalysisResultsSection({required this.userId});
  final String userId;

  @override
  State<_PatientAnalysisResultsSection> createState() => _PatientAnalysisResultsSectionState();
}

class _PatientAnalysisResultsSectionState extends State<_PatientAnalysisResultsSection> {
  List<dynamic> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getPatientAnalysisResults(widget.userId);
      if (mounted) setState(() { _results = list is List ? list : []; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _results = []; _loading = false; });
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted && !ok) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le PDF')));
        }
      }
    } catch (e) {
      if (mounted) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      title: 'Résultats d\'analyse',
      titleIcon: Icons.science_rounded,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          : _results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aucun résultat d\'analyse pour le moment.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _results.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _buildResultItem(_results[i]),
                    ],
                  ],
                ),
    );
  }

  Widget _buildResultItem(dynamic a) {
    final m = a is Map<String, dynamic> ? a : <String, dynamic>{};
    final type = m['analysisType'] ?? m['analysisTypeOther'] ?? 'Analyse';
    final typeStr = type.toString().replaceAll('_', ' ').toLowerCase();
    final date = m['analysisDate'];
    String dateStr = '—';
    if (date != null) {
      try {
        dateStr = DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(date.toString()));
      } catch (_) {}
    }
    final lab = m['labId'];
    String labName = '';
    if (lab is Map<String, dynamic>) {
      labName = lab['centreName'] ?? lab['name'] ?? '';
    }
    final resultFile = m['resultFile']?.toString() ?? '';
    final filename = resultFile.contains('/') ? resultFile.split('/').last : resultFile;
    final pdfUrl = filename.isNotEmpty ? '${ApiService.baseUrl}/lab/uploads/results/$filename' : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.biotech_rounded, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeStr.isNotEmpty ? typeStr : 'Résultat', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (labName.isNotEmpty) Text(labName, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(dateStr, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (pdfUrl != null && pdfUrl.isNotEmpty)
            IconButton(
              onPressed: () => _openPdf(pdfUrl),
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 28),
              tooltip: 'Ouvrir le PDF',
              style: IconButton.styleFrom(backgroundColor: AppColors.error.withValues(alpha: 0.1)),
            )
          else
            Icon(Icons.description_outlined, color: AppColors.textLight, size: 24),
        ],
      ),
    );
  }
}

// ========== PROFILE VIEW ==========
class _PatientProfileView extends StatelessWidget {
  const _PatientProfileView();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

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
            children: [
              const SizedBox(height: 20),
              // Profile avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? user?.email ?? '',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              if (user?.id != null) _PatientAnalysisResultsSection(userId: user!.id),
              const SizedBox(height: 24),
              _buildProfileOption(Icons.person_outline, 'Informations personnelles', null),
              _buildProfileOption(Icons.lock_outline, 'Sécurité', null),
              _buildProfileOption(Icons.notifications_outlined, 'Notifications', null),
              _buildProfileOption(Icons.help_outline, 'Aide & Support', null),
              _buildProfileOption(Icons.info_outline, 'À propos', null),
              const SizedBox(height: 20),
              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    authProvider.logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text('Se déconnecter', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String label, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.textPrimary)),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
