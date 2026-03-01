import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/medical_card.dart';

/// Écran Demandes d'Accès Patient (médecin)
class PatientAccessRequestScreen extends StatefulWidget {
  const PatientAccessRequestScreen({super.key});

  @override
  State<PatientAccessRequestScreen> createState() => _PatientAccessRequestScreenState();
}

class _PatientAccessRequestScreenState extends State<PatientAccessRequestScreen> {
  String _selectedDuration = '24 heures';
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final list = await ApiService.getAccessRequestsForDoctor();
      if (mounted) setState(() { _pendingRequests = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
      return 'il y a ${diff.inDays} jours';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Demandes d'accès"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadRequests, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
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
    final urgency = request['urgency']?.toString() ?? 'normal';
    final urgencyColor = urgency == 'high' ? AppColors.error : urgency == 'low' ? AppColors.success : AppColors.warning;
    final urgencyBgColor = urgency == 'high' ? AppColors.errorLight : urgency == 'low' ? AppColors.successLight : AppColors.warningLight;
    final urgencyLabel = urgency == 'high' ? 'URGENT' : urgency == 'low' ? 'BASSE' : 'NORMALE';
    final patient = request['patientId'] is Map ? request['patientId'] as Map<String, dynamic> : null;
    final name = patient?['fullName'] ?? 'Patient';
    final requestId = request['_id']?.toString() ?? '';

    return MedicalCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      showBorder: urgency == 'high',
      borderColor: AppColors.error.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
              child: Text(
                name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  Text('Demande d\'accès', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
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
              Expanded(child: Text(request['reason']?.toString() ?? '', style: Theme.of(context).textTheme.bodyMedium)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.access_time, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text('Demandé ${_timeAgo(request['createdAt']?.toString())}', style: Theme.of(context).textTheme.bodySmall),
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
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: SecondaryButton(
                    text: 'Refuser',
                    color: AppColors.error,
                    onPressed: () => _handleDecline(requestId, name),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: PrimaryButton(
                    text: 'Approuver',
                    icon: Icons.check,
                    onPressed: () => _handleApprove(requestId, name),
                  ),
                ),
              ),
            ],
          ),
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
          items: ['1 heure', '6 heures', '24 heures', '48 heures', '7 jours']
              .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedDuration = value);
          },
        ),
      ),
    );
  }

  Future<void> _handleApprove(String requestId, String name) async {
    try {
      await ApiService.acceptAccessRequest(requestId, duration: _selectedDuration);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accès accordé à $name pour $_selectedDuration'), backgroundColor: AppColors.success),
      );
      _loadRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _handleDecline(String requestId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Refuser l'accès ?"),
        content: Text("Êtes-vous sûr de vouloir refuser l'accès pour $name ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.refuseAccessRequest(requestId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Accès refusé pour $name'), backgroundColor: AppColors.error),
                );
                _loadRequests();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }
}

