import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/medical_card.dart';
import '../diagnosis/add_diagnosis_screen.dart';
import '../prescription/create_prescription_screen.dart';

/// Écran Dossier Médical Patient
class PatientMedicalRecordScreen extends StatefulWidget {
  const PatientMedicalRecordScreen({super.key});

  @override
  State<PatientMedicalRecordScreen> createState() => _PatientMedicalRecordScreenState();
}

class _PatientMedicalRecordScreenState extends State<PatientMedicalRecordScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _expandedIndex = -1;

  final List<Map<String, dynamic>> _timelineData = [
    {'date': '15 Jan 2026', 'title': 'Contrôle diabète', 'description': 'HbA1c: 7.2%, Glycémie à jeun: 1.32 g/L', 'type': 'checkup', 'doctor': 'Dr. Mitchell'},
    {'date': '3 Jan 2026', 'title': 'Renouvellement ordonnance', 'description': 'Metformine 500mg - Continuer 2x/jour', 'type': 'prescription', 'doctor': 'Dr. Mitchell'},
    {'date': '18 Déc 2025', 'title': 'Résultats labo', 'description': 'Bilan complet - Fonction rénale normale', 'type': 'lab', 'doctor': 'Labo Central'},
    {'date': '1 Déc 2025', 'title': 'Consultation cardiologie', 'description': 'ECG normal, Tension: 130/85', 'type': 'specialist', 'doctor': 'Dr. Cardinaux'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier Patient'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline),
            onSelected: (value) {
              if (value == 'diagnosis') Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDiagnosisScreen()));
              else if (value == 'prescription') Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePrescriptionScreen()));
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'diagnosis', child: Row(children: [Icon(Icons.medical_information, size: 20), SizedBox(width: 12), Text('Ajouter Diagnostic')])),
              const PopupMenuItem(value: 'prescription', child: Row(children: [Icon(Icons.medication, size: 20), SizedBox(width: 12), Text('Créer Ordonnance')])),
              const PopupMenuItem(value: 'note', child: Row(children: [Icon(Icons.note_add, size: 20), SizedBox(width: 12), Text('Ajouter Note')])),
            ],
          ),
        ],
      ),
      body: Column(children: [
        _buildPatientHeader(),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)]),
            tabs: const [Tab(text: 'Historique'), Tab(text: 'Diagnostics'), Tab(text: 'Labo'), Tab(text: 'Rx')],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: TabBarView(controller: _tabController, children: [_buildTimelineTab(), _buildDiagnosesTab(), _buildLabsTab(), _buildPrescriptionsTab()])),
      ]),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(children: [
          CircleAvatar(radius: 32, backgroundColor: Colors.white.withValues(alpha: 0.2), child: const Text('JD', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Jean Dupont', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('45 ans • Homme • Groupe O+', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.verified, color: Colors.white, size: 14), const SizedBox(width: 6), Text('Blockchain', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w500))]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _buildPatientStat('Dernière visite', '15 Jan 2026'),
          Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
          _buildPatientStat('Allergies', 'Pénicilline'),
          Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
          _buildPatientStat('Médecin', 'Dr. Mitchell'),
        ]),
      ]),
    );
  }

  Widget _buildPatientStat(String label, String value) {
    return Expanded(child: Column(children: [
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ]));
  }

  Widget _buildTimelineTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _timelineData.length,
      itemBuilder: (context, index) {
        final item = _timelineData[index];
        final isExpanded = _expandedIndex == index;
        IconData icon;
        Color color;
        switch (item['type']) {
          case 'prescription': icon = Icons.medication; color = AppColors.prescription; break;
          case 'lab': icon = Icons.science; color = AppColors.diagnosis; break;
          case 'specialist': icon = Icons.medical_services; color = AppColors.secondary; break;
          default: icon = Icons.check_circle; color = AppColors.primary;
        }
        return TimelineCard(
          title: item['title'],
          subtitle: item['description'],
          date: item['date'],
          icon: icon,
          iconColor: color,
          isExpanded: isExpanded,
          onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
          expandedContent: isExpanded ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.person, size: 14, color: AppColors.textSecondary), const SizedBox(width: 6), Text(item['doctor'], style: const TextStyle(fontSize: 13))]),
            const SizedBox(height: 8),
            Row(children: [OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 16), label: const Text('Télécharger')), const SizedBox(width: 12), ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.share, size: 16), label: const Text('Partager'))]),
          ]) : null,
        );
      },
    );
  }

  Widget _buildDiagnosesTab() {
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
      MedicalCard(title: 'Diabète Type 2', titleIcon: Icons.healing, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildDiagnosisInfo('Diagnostiqué', 'Mars 2022'),
        _buildDiagnosisInfo('Sévérité', 'Modéré'),
        _buildDiagnosisInfo('Statut', 'Actif - Sous traitement'),
      ])),
      MedicalCard(title: 'Hypertension', titleIcon: Icons.favorite, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildDiagnosisInfo('Diagnostiqué', 'Janvier 2023'),
        _buildDiagnosisInfo('Sévérité', 'Stade 1'),
        _buildDiagnosisInfo('Statut', 'Contrôlé'),
      ])),
    ]);
  }

  Widget _buildDiagnosisInfo(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)), Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))]));
  }

  Widget _buildLabsTab() {
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
      MedicalCard(title: 'HbA1c', titleIcon: Icons.science, child: Column(children: [
        Row(children: [const Text('7.2%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.warning)), const Spacer(), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text('Cible: < 7.0%', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)), const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(8)), child: const Text('Légèrement élevé', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w500)))])]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: 0.72, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning), minHeight: 8)),
      ])),
    ]);
  }

  Widget _buildPrescriptionsTab() {
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
      MedicalCard(title: 'Metformine 500mg', titleIcon: Icons.medication, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildDiagnosisInfo('Posologie', '2x par jour'),
        _buildDiagnosisInfo('Durée', 'Continue'),
        _buildDiagnosisInfo('Prescrit par', 'Dr. Mitchell'),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, color: AppColors.success, size: 14), SizedBox(width: 6), Text('Actif', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w500, fontSize: 12))])),
      ])),
      MedicalCard(title: 'Lisinopril 10mg', titleIcon: Icons.medication, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildDiagnosisInfo('Posologie', '1x par jour'),
        _buildDiagnosisInfo('Durée', 'Continue'),
        _buildDiagnosisInfo('Prescrit par', 'Dr. Cardinaux'),
      ])),
    ]);
  }
}
