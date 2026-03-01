import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/medical_card.dart';

/// Écran Aide à la Décision IA
class AiDecisionSupportScreen extends StatefulWidget {
  const AiDecisionSupportScreen({super.key});

  @override
  State<AiDecisionSupportScreen> createState() => _AiDecisionSupportScreenState();
}

class _AiDecisionSupportScreenState extends State<AiDecisionSupportScreen> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _suggestedExams = [
    {'name': 'Test HbA1c', 'reason': 'Patient diabétique, dernier test il y a 3 mois', 'priority': 'high', 'patient': 'Jean Dupont'},
    {'name': 'Bilan lipidique', 'reason': 'Recommandé pour patients hypertendus', 'priority': 'medium', 'patient': 'Marie Martin'},
    {'name': 'Test fonction rénale', 'reason': 'Surveillance de routine pour patients sous metformine', 'priority': 'low', 'patient': 'Pierre Dubois'},
    {'name': 'ECG', 'reason': 'Patient a signalé inconfort thoracique', 'priority': 'high', 'patient': 'Sophie Laurent'},
  ];

  final List<Map<String, dynamic>> _riskAlerts = [
    {'title': 'Risque complications diabétiques', 'description': 'Jean Dupont présente un risque élevé de néphropathie diabétique selon les niveaux HbA1c récents.', 'severity': 'high', 'action': 'Envisager orientation vers néphrologue', 'timestamp': 'Il y a 2 heures'},
    {'title': "Alerte interaction médicamenteuse", 'description': "Interaction potentielle entre Lisinopril et suppléments de Potassium pour Pierre Dubois.", 'severity': 'medium', 'action': 'Réviser liste médicaments', 'timestamp': 'Il y a 4 heures'},
    {'title': 'Suivi manqué', 'description': 'Marie Martin a manqué le suivi cardiologie prévu depuis 2 semaines.', 'severity': 'low', 'action': 'Planifier nouveau rendez-vous', 'timestamp': 'Hier'},
  ];

  final List<Map<String, dynamic>> _recommendations = [
    {'title': 'Optimisation traitement', 'recommendation': 'Envisager ajout agoniste récepteur GLP-1 pour Jean Dupont selon les recommandations actuelles de gestion du diabète.', 'confidence': 0.89, 'sources': ['Guidelines ADA 2026', 'Recommandations EASD']},
    {'title': 'Soins préventifs', 'recommendation': 'Sophie Laurent doit recevoir le vaccin grippe annuel selon son historique médical.', 'confidence': 0.95, 'sources': ['Guidelines CDC', 'Historique patient']},
    {'title': 'Intervention mode de vie', 'recommendation': 'Orientation régime méditerranéen suggérée pour patients avec facteurs risque cardiovasculaire.', 'confidence': 0.82, 'sources': ['Guidelines ACC/AHA', 'Étude PREDIMED']},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          // Header avec style Health Drawer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Aide à la Décision IA', style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 4),
                  Text('Propulsé par MEDAIChain Intelligence', style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  )),
                ])),
              ]),
            ]),
          ),
          // Contenu principal avec coins arrondis
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: Column(children: [
                  const SizedBox(height: 20),
                  // Disclaimer IA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildAIDisclaimer(),
                  ),
                  const SizedBox(height: 16),
                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      _buildTab(0, 'Examens', Icons.science),
                      _buildTab(1, 'Alertes', Icons.warning_amber),
                      _buildTab(2, 'Conseils', Icons.lightbulb),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: IndexedStack(index: _selectedTab, children: [_buildExamsTab(), _buildAlertsTab(), _buildRecommendationsTab()])),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAIDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text("Les suggestions IA sont à titre informatif uniquement. Toujours appliquer le jugement clinique.", style: TextStyle(color: AppColors.warning.withValues(alpha: 0.9), fontSize: 12))),
      ]),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildExamsTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _suggestedExams.length,
      itemBuilder: (context, index) => _buildExamCard(_suggestedExams[index]),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final priorityColor = exam['priority'] == 'high' ? AppColors.error : exam['priority'] == 'medium' ? AppColors.warning : AppColors.success;
    final priorityBg = exam['priority'] == 'high' ? AppColors.errorLight : exam['priority'] == 'medium' ? AppColors.warningLight : AppColors.successLight;
    final priorityLabel = exam['priority'] == 'high' ? 'HAUTE' : exam['priority'] == 'medium' ? 'MOYENNE' : 'BASSE';

    return MedicalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.diagnosisLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.science, color: AppColors.diagnosis, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exam['name'], style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Pour: ${exam['patient']}', style: Theme.of(context).textTheme.bodySmall),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: priorityBg, borderRadius: BorderRadius.circular(12)), child: Text(priorityLabel, style: TextStyle(color: priorityColor, fontWeight: FontWeight.w600, fontSize: 10))),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [const Icon(Icons.auto_awesome, color: AppColors.prescription, size: 16), const SizedBox(width: 8), Expanded(child: Text(exam['reason'], style: const TextStyle(fontSize: 13)))]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Ignorer'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Commander'))),
        ]),
      ]),
    );
  }

  Widget _buildAlertsTab() {
    return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _riskAlerts.length, itemBuilder: (context, index) => _buildAlertCard(_riskAlerts[index]));
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severityColor = alert['severity'] == 'high' ? AppColors.error : alert['severity'] == 'medium' ? AppColors.warning : AppColors.info;
    final severityIcon = alert['severity'] == 'high' ? Icons.error : alert['severity'] == 'medium' ? Icons.warning : Icons.info;

    return MedicalCard(
      showBorder: alert['severity'] == 'high',
      borderColor: AppColors.error.withValues(alpha: 0.5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(severityIcon, color: severityColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(alert['title'], style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(alert['timestamp'], style: Theme.of(context).textTheme.labelSmall),
          ])),
        ]),
        const SizedBox(height: 12),
        Text(alert['description'], style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [Icon(Icons.arrow_forward, color: severityColor, size: 16), const SizedBox(width: 8), Expanded(child: Text('Suggéré: ${alert['action']}', style: TextStyle(color: severityColor, fontWeight: FontWeight.w500, fontSize: 13)))]),
        ),
      ]),
    );
  }

  Widget _buildRecommendationsTab() {
    return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _recommendations.length, itemBuilder: (context, index) => _buildRecommendationCard(_recommendations[index]));
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final confidence = (rec['confidence'] as double) * 100;

    return MedicalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: AppColors.aiGradient, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.lightbulb, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(rec['title'], style: Theme.of(context).textTheme.titleMedium)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)), child: Text('${confidence.toStringAsFixed(0)}% confiance', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w500, fontSize: 11))),
        ]),
        const SizedBox(height: 12),
        Text(rec['recommendation'], style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: rec['confidence'], backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success), minHeight: 6)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (rec['sources'] as List).map<Widget>((source) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.menu_book, size: 12, color: AppColors.textSecondary), const SizedBox(width: 4), Text(source, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]),
          )).toList(),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.thumb_down_outlined, size: 16), label: const Text('Pas utile'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check, size: 16), label: const Text('Appliquer'))),
        ]),
      ]),
    );
  }
}

