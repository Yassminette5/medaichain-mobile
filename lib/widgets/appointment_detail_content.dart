import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';


/// Contenu des détails d'un rendez-vous (sans Scaffold) pour utilisation dans dialog
class AppointmentDetailContent extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailContent({
    super.key,
    required this.appointment,
  });

  DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  int? _computeAgeFromDob(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    if (age < 0 || age > 130) return null;
    return age;
  }

  String? _formatGender(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;

    final v = s.toLowerCase();
    if (v == 'm' || v == 'male' || v == 'homme' || v == 'man') return 'Homme';
    if (v == 'f' || v == 'female' || v == 'femme' || v == 'woman') return 'Femme';
    return s; // fallback: garder tel quel
  }

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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.accentOrange;
      default:
        return AppColors.warning;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      case 'pending':
        return 'En attente';
      default:
        return status ?? 'Inconnu';
    }
  }

  String _getStatusMessage(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return '✅ Demande acceptée automatiquement';
      case 'rejected':
        return '❌ Demande refusée';
      case 'pending':
      default:
        return '🕐 En attente de confirmation';
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
    final auth = context.read<AuthProvider>();
    final currentUser = auth.user;

    // Extraire les informations du patient
    final patientInfo = appointment['patientInfo'];
    final patientId = appointment['patientId'];
    String patientFirstName = 'Patient';
    String? patientEmail;
    String? patientPhone;
    int? patientAge;
    String? patientGender;
    List<String> patientAllergies = const [];
    
    // 1) Priorité: patientInfo (nouveau backend)
    if (patientInfo != null && patientInfo is Map) {
      final infoMap = Map<String, dynamic>.from(patientInfo);

      final fullName = infoMap['fullName']?.toString().trim();
      if (fullName != null && fullName.isNotEmpty) {
        patientFirstName = fullName;
      } else {
        final firstName = infoMap['firstName']?.toString() ?? '';
        final lastName = infoMap['lastName']?.toString() ?? '';
        final combined = '${firstName.trim()} ${lastName.trim()}'.trim();
        if (combined.isNotEmpty) patientFirstName = combined;
      }

      patientEmail = infoMap['email']?.toString();
      patientPhone = infoMap['phone']?.toString();
      patientGender = _formatGender(infoMap['gender'] ?? infoMap['sex']);

      final rawAge = infoMap['age'];
      if (rawAge is num) {
        patientAge = rawAge.toInt();
      } else {
        final dob = _tryParseDate(infoMap['dateOfBirth'] ?? infoMap['dob'] ?? infoMap['birthDate']);
        patientAge = _computeAgeFromDob(dob);
      }

      final rawAllergies = infoMap['allergies'];
      if (rawAllergies is List) {
        patientAllergies = rawAllergies.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    // 2) Fallback: patientId (compatibilité)
    if (patientId != null && patientId is Map) {
      final patientMap = Map<String, dynamic>.from(patientId);
      if (patientFirstName == 'Patient') {
        final firstName = patientMap['firstName']?.toString() ?? '';
        final lastName = patientMap['lastName']?.toString() ?? '';
        final fullName = patientMap['fullName']?.toString().trim();
        if (fullName != null && fullName.isNotEmpty) {
          patientFirstName = fullName;
        } else if (firstName.isNotEmpty || lastName.isNotEmpty) {
          patientFirstName = '${firstName.trim()} ${lastName.trim()}'.trim();
        } else {
          patientFirstName = patientMap['name']?.toString() ?? patientMap['email']?.toString() ?? 'Patient';
        }
      }

      // Contact: parfois directement sur patient, parfois dans userId
      final user = patientMap['userId'];
      if (user is Map) {
        final userMap = Map<String, dynamic>.from(user);
        patientEmail ??= (userMap['email'] ?? patientMap['email'])?.toString();
        patientPhone ??= (userMap['phone'] ?? patientMap['phone'])?.toString();
        patientGender ??= _formatGender(patientMap['gender'] ?? userMap['gender'] ?? patientMap['sex']);
        final dob = _tryParseDate(patientMap['dateOfBirth'] ?? userMap['dateOfBirth'] ?? patientMap['dob'] ?? patientMap['birthDate']);
        final computedAge = _computeAgeFromDob(dob);
        final rawAge = patientMap['age'] ?? userMap['age'];
        patientAge ??= rawAge is num ? rawAge.toInt() : computedAge;
      } else {
        patientEmail ??= patientMap['email']?.toString();
        patientPhone ??= patientMap['phone']?.toString();
        patientGender ??= _formatGender(patientMap['gender'] ?? patientMap['sex']);
        final dob = _tryParseDate(patientMap['dateOfBirth'] ?? patientMap['dob'] ?? patientMap['birthDate']);
        final computedAge = _computeAgeFromDob(dob);
        final rawAge = patientMap['age'];
        patientAge ??= rawAge is num ? rawAge.toInt() : computedAge;
      }

      if (patientAllergies.isEmpty) {
        final rawAllergies = patientMap['allergies'];
        if (rawAllergies is List) {
          patientAllergies = rawAllergies.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        } else {
          patientAllergies = const [];
        }
      }
    }

    // 3) Fallback patient connecté: certains backends renvoient patientId non-populé (string),
    // donc on utilise les infos du patient connecté plutôt que d'afficher "Patient".
    if (patientFirstName == 'Patient' && currentUser != null && currentUser.role == UserRole.patient) {
      final name = currentUser.fullName?.toString().trim();
      if (name != null && name.isNotEmpty) patientFirstName = name;
      patientEmail ??= currentUser.email;
      patientPhone ??= currentUser.phone;
      patientGender ??= _formatGender(currentUser.gender);
      patientAge ??= currentUser.age;
      final a = currentUser.allergies;
      if (patientAllergies.isEmpty && a != null && a.isNotEmpty) {
        patientAllergies = a.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
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
    final statusColor = _getStatusColor(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // En-tête du document
        _buildDocumentHeader(),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _getStatusMessage(status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // Informations Patient
        _buildSectionHeader('INFORMATIONS PATIENT'),
        const SizedBox(height: 16),
        _buildPatientInfo(
          patientFirstName,
          patientEmail,
          patientPhone,
          age: patientAge,
          gender: patientGender,
          allergies: patientAllergies,
        ),
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

  Widget _buildPatientInfo(
    String name,
    String? email,
    String? phone, {
    int? age,
    String? gender,
    List<String> allergies = const [],
  }) {
    final List<TableRow> rows = [_buildTableRow('Nom complet', name)];

    if (age != null) {
      rows.add(_buildTableRow('Âge', '$age ans'));
    }
    if (gender != null && gender.trim().isNotEmpty) {
      rows.add(_buildTableRow('Sexe', gender.trim()));
    }
    if (email != null && email.isNotEmpty) rows.add(_buildTableRow('Email', email));
    if (phone != null && phone.isNotEmpty) rows.add(_buildTableRow('Téléphone', phone));
    if (allergies.isNotEmpty) {
      rows.add(_buildTableRow('Allergies', allergies.join(', ')));
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
    final time = _formatTime(dateString);
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(5),
      },
      children: [
        _buildTableRow('Date', _formatDate(dateString)),
        if (time.isNotEmpty) _buildTableRow('Heure', time),
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
