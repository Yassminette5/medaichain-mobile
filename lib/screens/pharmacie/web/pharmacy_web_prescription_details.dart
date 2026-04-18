import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/pharmacy_dashboard.dart';
import '../../../services/api_service.dart';
import '../../../services/pharmacy_service.dart';
import '../../../widgets/pharmacie/web/pharmacy_web_notifications_bell.dart';

/// Web-optimized Pharmacy Prescription Details Screen
class PharmacyWebPrescriptionDetails extends StatefulWidget {
  final MedicationRequest request;

  const PharmacyWebPrescriptionDetails({
    super.key,
    required this.request,
  });

  @override
  State<PharmacyWebPrescriptionDetails> createState() =>
      _PharmacyWebPrescriptionDetailsState();
}

class _PharmacyWebPrescriptionDetailsState
    extends State<PharmacyWebPrescriptionDetails> {
  late RequestStatus _currentStatus;

  bool _showingIncomingAlert = false;
  final Set<String> _handledIncomingNotificationIds = <String>{};
  static const Duration _pollInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.request.status;
    _startIncomingRequestsPolling();
  }

  void _startIncomingRequestsPolling() {
    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      while (mounted) {
        await _pollUnreadNotificationsOnce();
        await Future<void>.delayed(_pollInterval);
      }
    });
  }

  Future<void> _pollUnreadNotificationsOnce() async {
    if (_showingIncomingAlert) return;
    try {
      final unread = await ApiService.getUnreadNotifications();
      if (!mounted) return;

      Map<String, dynamic>? candidate;
      for (final n in unread) {
        final data = (n['data'] is Map) ? (n['data'] as Map).cast<String, dynamic>() : <String, dynamic>{};
        if (data['type']?.toString() != 'pharmacy_request_created') continue;
        final id = (n['id'] ?? n['_id'] ?? '').toString();
        if (id.isEmpty) continue;
        if (_handledIncomingNotificationIds.contains(id)) continue;
        candidate = n;
        break;
      }

      if (candidate == null) return;

      final notificationId = (candidate['id'] ?? candidate['_id'] ?? '').toString();
      final data = (candidate['data'] is Map) ? (candidate['data'] as Map).cast<String, dynamic>() : <String, dynamic>{};
      final requestId = (data['requestId'] ?? candidate['relatedId'] ?? '').toString();
      if (requestId.isEmpty) return;

      _handledIncomingNotificationIds.add(notificationId);
      _showingIncomingAlert = true;

      MedicationRequest? request;
      try {
        request = await PharmacyService.getMyRequestById(requestId);
      } catch (_) {
        request = null;
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          final title = (candidate?['title'] ?? 'Nouvelle demande').toString();
          final message = (candidate?['message'] ?? '').toString();

          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.isNotEmpty) Text(message),
                    const SizedBox(height: 12),
                    if (request != null) ...[
                      Text('Patient: ${request.patient.name}'),
                      if (request.patient.phoneNumber != null && request.patient.phoneNumber!.isNotEmpty)
                        Text('Téléphone: ${request.patient.phoneNumber}'),
                      const SizedBox(height: 12),
                      const Text('Médicaments:', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      ...request.medications.map((m) {
                        final dosage = m.dosage.isNotEmpty ? ' — ${m.dosage}' : '';
                        final qty = '${m.quantity} ${m.unit}'.trim();
                        return Text('- ${m.name}$dosage ($qty)');
                      }),
                      const SizedBox(height: 12),
                      if (request.requestsDelivery) const Text('Livraison: demandée'),
                      if (request.isUrgent) const Text('Urgence: oui'),
                    ] else ...[
                      const Text('Détails indisponibles (échec du chargement).'),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (notificationId.isNotEmpty) {
        try {
          await ApiService.markNotificationAsRead(notificationId);
        } catch (_) {}
      }
    } catch (_) {
      // Ignore polling errors
    } finally {
      _showingIncomingAlert = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Détails de l\'ordonnance #${widget.request.id}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [
          PharmacyWebNotificationsBell(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isLargeScreen ? 40 : 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientCard(),
                  const SizedBox(height: 24),
                  _buildMedicationsCard(),
                ],
              ),
            ),
            if (isLargeScreen) const SizedBox(width: 24),
            if (isLargeScreen)
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    _buildActionsCard(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du Patient',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF4FACFE),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.patient.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.request.patient.phoneNumber != null)
                      Text(
                        widget.request.patient.phoneNumber!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Médicaments Demandés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.request.medications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final medication = widget.request.medications[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            medication.displayQuantity,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;

    switch (_currentStatus) {
      case RequestStatus.urgent:
        statusColor = Colors.red;
        statusIcon = Icons.priority_high_rounded;
        break;
      case RequestStatus.enAttente:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      case RequestStatus.valide:
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        break;
      case RequestStatus.nonValide:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      case RequestStatus.termine:
        statusColor = const Color(0xFF8B5CF6);
        statusIcon = Icons.done_all_rounded;
        break;
      default:
        statusColor = const Color(0xFF4FACFE);
        statusIcon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statut',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentStatus.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Date de demande',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.request.requestDate.day}/${widget.request.requestDate.month}/${widget.request.requestDate.year}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            label: 'Valider',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            onTap: _currentStatus != RequestStatus.valide
                ? () => _updateStatus(RequestStatus.valide)
                : null,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Rejeter',
            icon: Icons.cancel_rounded,
            color: Colors.red,
            onTap: _currentStatus != RequestStatus.nonValide
                ? () => _updateStatus(RequestStatus.nonValide)
                : null,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Marquer comme terminée',
            icon: Icons.done_all_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: _currentStatus != RequestStatus.termine
                ? () => _updateStatus(RequestStatus.termine)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(RequestStatus newStatus) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _currentStatus = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${newStatus.displayName}'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


