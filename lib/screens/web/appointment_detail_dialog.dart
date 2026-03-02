import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Version dialog des détails de rendez-vous (sans Scaffold)
class AppointmentDetailDialog extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailDialog({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailDialog> createState() => _AppointmentDetailDialogState();
}

class _AppointmentDetailDialogState extends State<AppointmentDetailDialog> {
  bool _isProcessing = false;

  String _getAnalysisTypeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'analyse_sanguin':
        return 'Analyse sanguine';
      case 'scanner':
        return 'Scanner';
      case 'radiologie':
        return 'Radiologie';
      case 'imagerie':
        return 'Imagerie';
      case 'biologie':
        return 'Biologie';
      default:
        return type ?? 'Autre';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Future<void> _acceptAppointment() async {
    final appointmentId = widget.appointment['_id']?.toString() ?? widget.appointment['id']?.toString();
    if (appointmentId == null) return;

    setState(() => _isProcessing = true);

    try {
      await ApiService.acceptAppointment(appointmentId);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous accepté'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectAppointment() async {
    final appointmentId = widget.appointment['_id']?.toString() ?? widget.appointment['id']?.toString();
    if (appointmentId == null) return;

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser le rendez-vous'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du refus (optionnel)'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Raison du refus...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Refuser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);

      try {
        await ApiService.rejectAppointment(
          appointmentId,
          reason: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
        );
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rendez-vous refusé'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    
    // Extraire les informations du patient
    final patientId = appointment['patientId'];
    String patientFirstName = 'Patient';
    String? patientEmail;
    String? patientPhone;
    
    if (patientId != null && patientId is Map) {
      final patientMap = Map<String, dynamic>.from(patientId);
      final firstName = patientMap['firstName']?.toString() ?? '';
      if (firstName.isNotEmpty) {
        patientFirstName = firstName.trim();
      } else {
        patientFirstName = patientMap['name']?.toString() ?? patientMap['email']?.toString() ?? 'Patient';
      }
      patientEmail = patientMap['email']?.toString();
      patientPhone = patientMap['phone']?.toString();
    }

    final analysisType = appointment['analysisType']?.toString() ?? '';
    final appointmentDate = appointment['appointmentDate']?.toString() ?? '';
    final hasAllergies = appointment['hasAllergies'] == true;
    final allergies = appointment['allergiesDetails'] is List 
        ? List<dynamic>.from(appointment['allergiesDetails'] as List)
        : <dynamic>[];
    final hasTreatment = appointment['hasCurrentTreatment'] == true;
    final treatmentDetails = appointment['currentTreatmentDetails']?.toString() ?? '';
    final notes = appointment['notes']?.toString() ?? '';
    final doctorId = appointment['doctorId'];
    final status = appointment['status']?.toString() ?? 'pending';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte Patient
          _buildPatientCard(patientFirstName, patientEmail, patientPhone),
          const SizedBox(height: 24),
          // Médecin Référent (si disponible)
          if (doctorId != null && doctorId is Map) ...[
            _buildSectionTitle('MÉDECIN RÉFÉRENT'),
            const SizedBox(height: 12),
            _buildDoctorCard(Map<String, dynamic>.from(doctorId)),
            const SizedBox(height: 24),
          ],
          // Type d'analyse
          _buildSectionTitle('TYPE D\'ANALYSE'),
          const SizedBox(height: 12),
          _buildAnalysisCard(analysisType),
          const SizedBox(height: 24),
          // Date et Heure
          _buildSectionTitle('DATE ET HEURE'),
          const SizedBox(height: 12),
          _buildDateTimeCard(appointmentDate),
          const SizedBox(height: 24),
          // Allergies
          if (hasAllergies && allergies.isNotEmpty) ...[
            _buildSectionTitle('ALLERGIES CONNUES'),
            const SizedBox(height: 12),
            _buildAllergiesCard(allergies),
            const SizedBox(height: 24),
          ],
          // Traitements
          if (hasTreatment && treatmentDetails.isNotEmpty) ...[
            _buildSectionTitle('TRAITEMENTS EN COURS'),
            const SizedBox(height: 12),
            _buildTreatmentCard(treatmentDetails),
            const SizedBox(height: 24),
          ],
          // Notes
          if (notes.isNotEmpty) ...[
            _buildSectionTitle('NOTES'),
            const SizedBox(height: 12),
            _buildNotesCard(notes),
            const SizedBox(height: 24),
          ],
          // Actions
          if (status == 'pending') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _acceptAppointment,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Accepter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _rejectAppointment,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPatientCard(String name, String? email, String? phone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 30,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final name = doctor['firstName'] != null && doctor['lastName'] != null
        ? '${doctor['firstName']} ${doctor['lastName']}'
        : doctor['name']?.toString() ?? 'Médecin';
    final speciality = doctor['speciality']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (speciality.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    speciality,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(String type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.science_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            _getAnalysisTypeLabel(type),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard(String dateString) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(dateString),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(dateString),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesCard(List<dynamic> allergies) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: AppColors.warning, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Allergies connues',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergies.map((allergy) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  allergy.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(String treatment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medication_rounded, color: AppColors.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Traitements en cours',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  treatment,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note_rounded, color: AppColors.textSecondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notes,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
