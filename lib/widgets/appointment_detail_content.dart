import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';


/// Contenu des détails d'un rendez-vous (sans Scaffold) pour utilisation dans dialog
class AppointmentDetailContent extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailContent({
    super.key,
    required this.appointment,
  });

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

  @override
  Widget build(BuildContext context) {
    // Extraire les informations du patient
    final patientId = appointment['patientId'];
    String patientFirstName = 'Patient';
    String? patientEmail;
    String? patientPhone;
    
    if (patientId != null && patientId is Map) {
      final patientMap = Map<String, dynamic>.from(patientId);
      final firstName = patientMap['firstName']?.toString() ?? '';
      final lastName = patientMap['lastName']?.toString() ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        patientFirstName = '${firstName.trim()} ${lastName.trim()}'.trim();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // En-tête du document
        _buildDocumentHeader(),
        const SizedBox(height: 40),
        // Informations Patient
        _buildSectionHeader('INFORMATIONS PATIENT'),
        const SizedBox(height: 16),
        _buildPatientInfo(patientFirstName, patientEmail, patientPhone),
        const SizedBox(height: 32),
        // Médecin Référent (si disponible)
        if (doctorId != null && doctorId is Map) ...[
          _buildSectionHeader('MÉDECIN RÉFÉRENT'),
          const SizedBox(height: 16),
          _buildDoctorInfo(Map<String, dynamic>.from(doctorId)),
          const SizedBox(height: 32),
        ],
        // Type d'analyse
        _buildSectionHeader('TYPE D\'ANALYSE'),
        const SizedBox(height: 16),
        _buildAnalysisInfo(analysisType),
        const SizedBox(height: 32),
        // Date et Heure
        _buildSectionHeader('DATE DE LA DEMANDE'),
        const SizedBox(height: 16),
        _buildDateTimeInfo(appointmentDate),
        const SizedBox(height: 32),
        // Notes & Allergies
        if (hasAllergies || hasTreatment || notes.isNotEmpty) ...[
          _buildSectionHeader('NOTES & ALLERGIES'),
          const SizedBox(height: 16),
          _buildNotesAllergiesInfo(hasAllergies, allergies, hasTreatment, treatmentDetails, notes),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildDocumentHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEMANDE D\'ANALYSE',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Document de prescription médicale',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            DateTime.now().toString().split(' ')[0],
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPatientInfo(String name, String? email, String? phone) {
    final List<TableRow> rows = [
      _buildTableRow('Nom complet', name),
    ];
    if (email != null && email.isNotEmpty) {
      rows.add(_buildTableRow('Email', email));
    }
    if (phone != null && phone.isNotEmpty) {
      rows.add(_buildTableRow('Téléphone', phone));
    }
    
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(5),
      },
      children: rows,
    );
  }

  Widget _buildDoctorInfo(Map<String, dynamic> doctor) {
    final doctorName = '${doctor['firstName'] ?? ''} ${doctor['lastName'] ?? ''}'.trim();
    final specialty = doctor['specialty'] ?? doctor['specialite'] ?? 'Non spécifié';

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(5),
      },
      children: [
        _buildTableRow('Nom', doctorName.isNotEmpty ? 'Dr. $doctorName' : 'Médecin'),
        _buildTableRow('Spécialité', specialty),
      ],
    );
  }

  Widget _buildAnalysisInfo(String type) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(5),
      },
      children: [
        _buildTableRow('Type d\'analyse', _getAnalysisTypeLabel(type)),
      ],
    );
  }

  Widget _buildDateTimeInfo(String dateString) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(5),
      },
      children: [
        _buildTableRow('Date', _formatDate(dateString)),
      ],
    );
  }

  Widget _buildNotesAllergiesInfo(
    bool hasAllergies,
    List<dynamic> allergies,
    bool hasTreatment,
    String treatmentDetails,
    String notes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAllergies && allergies.isNotEmpty) ...[
          _buildInfoLabel('Allergies connues'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergies.map((allergy) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  allergy.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (hasTreatment && treatmentDetails.isNotEmpty) ...[
          _buildInfoLabel('Traitements en cours'),
          const SizedBox(height: 8),
          _buildInfoValue(treatmentDetails),
          const SizedBox(height: 20),
        ],
        if (notes.isNotEmpty) ...[
          _buildInfoLabel('Notes supplémentaires'),
          const SizedBox(height: 8),
          _buildInfoValue(notes),
        ],
      ],
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 24),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildInfoValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }
}
