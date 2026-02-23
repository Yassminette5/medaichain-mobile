import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/medical_card.dart';

/// Écran Demandes d'Accès Patient
class PatientAccessRequestScreen extends StatefulWidget {
  const PatientAccessRequestScreen({super.key});

  @override
  State<PatientAccessRequestScreen> createState() => _PatientAccessRequestScreenState();
}

class _PatientAccessRequestScreenState extends State<PatientAccessRequestScreen> {
  String _selectedDuration = '24 heures';

  final List<Map<String, dynamic>> _pendingRequests = [
    {'name': 'Jean Dupont', 'age': 45, 'gender': 'Homme', 'requestTime': 'il y a 10 min', 'reason': 'Consultation de suivi pour la gestion du diabète', 'urgency': 'normal'},
    {'name': 'Sophie Martin', 'age': 32, 'gender': 'Femme', 'requestTime': 'il y a 25 min', 'reason': 'Consultation urgence - douleur thoracique', 'urgency': 'high'},
    {'name': 'Robert Petit', 'age': 58, 'gender': 'Homme', 'requestTime': 'il y a 1 heure', 'reason': 'Renouvellement ordonnance', 'urgency': 'low'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Demandes d'accès"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 24),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(20)),
                child: Text('${_pendingRequests.length} En attente', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 16),
            ..._pendingRequests.map((request) => _buildRequestCard(context, request)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.info_outline, color: AppColors.info, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Text("Examinez et approuvez les demandes d'accès. L'accès temporaire est enregistré sur la blockchain.", style: TextStyle(color: AppColors.info, fontSize: 13))),
      ]),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request) {
    final urgencyColor = request['urgency'] == 'high' ? AppColors.error : request['urgency'] == 'low' ? AppColors.success : AppColors.warning;
    final urgencyBgColor = request['urgency'] == 'high' ? AppColors.errorLight : request['urgency'] == 'low' ? AppColors.successLight : AppColors.warningLight;
    final urgencyLabel = request['urgency'] == 'high' ? 'URGENT' : request['urgency'] == 'low' ? 'BASSE' : 'NORMALE';

    return MedicalCard(
      margin: const EdgeInsets.only(bottom: 16),
      showBorder: request['urgency'] == 'high',
      borderColor: AppColors.error.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
              child: Text(request['name'].split(' ').map((n) => n[0]).join(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(request['name'], style: Theme.of(context).textTheme.titleMedium),
              Text('${request['age']} ans • ${request['gender']}', style: Theme.of(context).textTheme.bodySmall),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: urgencyBgColor, borderRadius: BorderRadius.circular(12)),
              child: Text(urgencyLabel, style: TextStyle(color: urgencyColor, fontWeight: FontWeight.w600, fontSize: 10)),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.medical_information, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(request['reason'], style: Theme.of(context).textTheme.bodyMedium)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.access_time, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text('Demandé ${request['requestTime']}', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            _buildDurationDropdown(),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.blockchainLight, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer_outlined, color: AppColors.blockchain, size: 16),
              const SizedBox(width: 8),
              Text('Accès temporaire: $_selectedDuration', style: const TextStyle(color: AppColors.blockchain, fontWeight: FontWeight.w500, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: SecondaryButton(text: 'Refuser', color: AppColors.error, onPressed: () => _handleDecline(request['name']))),
            const SizedBox(width: 12),
            Expanded(child: PrimaryButton(text: 'Approuver', icon: Icons.check, onPressed: () => _handleApprove(request['name']))),
          ]),
        ],
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDuration,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: ['1 heure', '6 heures', '24 heures', '48 heures', '7 jours'].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (value) { if (value != null) setState(() => _selectedDuration = value); },
        ),
      ),
    );
  }

  void _handleApprove(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accès accordé à $name pour $_selectedDuration'), backgroundColor: AppColors.success));
    Navigator.pop(context);
  }

  void _handleDecline(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Refuser l'accès ?"),
        content: Text("Êtes-vous sûr de vouloir refuser l'accès pour $name ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accès refusé pour $name'), backgroundColor: AppColors.error));
            },
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }
}
