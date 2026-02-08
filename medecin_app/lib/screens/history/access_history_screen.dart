import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/medical_card.dart';

/// Écran Historique des Accès
class AccessHistoryScreen extends StatefulWidget {
  const AccessHistoryScreen({super.key});

  @override
  State<AccessHistoryScreen> createState() => _AccessHistoryScreenState();
}

class _AccessHistoryScreenState extends State<AccessHistoryScreen> {
  String _selectedFilter = 'Tous';

  final List<Map<String, dynamic>> _accessLogs = [
    {'patient': 'Jean Dupont', 'action': 'Dossier consulté', 'timestamp': 'Aujourd\'hui, 14:32', 'type': 'view', 'verified': true, 'txHash': '0x7f2e...3a91'},
    {'patient': 'Marie Martin', 'action': 'Ordonnance créée', 'timestamp': 'Aujourd\'hui, 11:15', 'type': 'prescription', 'verified': true, 'txHash': '0x8d3f...4b82'},
    {'patient': 'Pierre Dubois', 'action': 'Diagnostic ajouté', 'timestamp': 'Hier, 16:45', 'type': 'diagnosis', 'verified': true, 'txHash': '0x9e4g...5c73'},
    {'patient': 'Sophie Laurent', 'action': 'Dossier consulté', 'timestamp': 'Hier, 09:20', 'type': 'view', 'verified': true, 'txHash': '0xaf5h...6d64'},
    {'patient': 'Jean Dupont', 'action': 'Labo commandé', 'timestamp': '12 Jan, 14:00', 'type': 'lab', 'verified': true, 'txHash': '0xbg6i...7e55'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des accès'), actions: [IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog)]),
      body: Column(children: [
        _buildStatsHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: ['Tous', 'Consultations', 'Ordonnances', 'Diagnostics'].map((filter) => Expanded(child: GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: _selectedFilter == filter ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(filter, style: TextStyle(color: _selectedFilter == filter ? Colors.white : AppColors.textSecondary, fontWeight: _selectedFilter == filter ? FontWeight.w600 : FontWeight.normal, fontSize: 12))),
            ),
          ))).toList()),
        ),
        const SizedBox(height: 16),
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _accessLogs.length, itemBuilder: (context, index) => _buildLogCard(_accessLogs[index]))),
      ]),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(child: Column(children: [const Text('156', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), Text('Total accès', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12))])),
        Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
        Expanded(child: Column(children: [const Text('100%', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), Text('Vérifiés', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12))])),
        Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
        Expanded(child: Column(children: [const Text('24', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), Text('Ce mois', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12))])),
      ]),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    IconData icon;
    Color color;
    switch (log['type']) {
      case 'prescription': icon = Icons.medication; color = AppColors.prescription; break;
      case 'diagnosis': icon = Icons.medical_information; color = AppColors.diagnosis; break;
      case 'lab': icon = Icons.science; color = AppColors.secondary; break;
      default: icon = Icons.visibility; color = AppColors.primary;
    }

    return MedicalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(log['patient'], style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 4), Text(log['action'], style: Theme.of(context).textTheme.bodySmall)])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(log['timestamp'], style: Theme.of(context).textTheme.labelSmall), const SizedBox(height: 4), if (log['verified']) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.blockchainLight, borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified, color: AppColors.blockchain, size: 12), SizedBox(width: 4), Text('Vérifié', style: TextStyle(color: AppColors.blockchain, fontSize: 10, fontWeight: FontWeight.w500))]))]),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [const Icon(Icons.link, color: AppColors.textSecondary, size: 14), const SizedBox(width: 8), Text('TX: ${log['txHash']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace')), const Spacer(), GestureDetector(onTap: () {}, child: const Icon(Icons.open_in_new, color: AppColors.primary, size: 16))]),
        ),
      ]),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Filtrer par période', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...['Aujourd\'hui', 'Cette semaine', 'Ce mois', '3 derniers mois', 'Tout'].map((period) => ListTile(title: Text(period), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.pop(context))),
        ]),
      ),
    );
  }
}
