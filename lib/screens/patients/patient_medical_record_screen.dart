import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/medical_card.dart';

/// Écran du dossier médical patient
class PatientMedicalRecordScreen extends StatelessWidget {
  const PatientMedicalRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.background],
            stops: const [0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientInfo(),
                      const SizedBox(height: 24),
                      _buildVitalSigns(),
                      const SizedBox(height: 24),
                      _buildMedicalHistory(),
                      const SizedBox(height: 24),
                      _buildCurrentMedications(),
                      const SizedBox(height: 24),
                      _buildRecentConsultations(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Dossier Médical',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
            ),
            child: const Icon(Icons.more_vert, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text('JD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jean Dupont',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '52 ans • Masculin',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ID: PAT-2024-1234',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSigns() {
    return MedicalCard(
      title: 'Signes Vitaux',
      titleIcon: Icons.favorite_rounded,
      child: Row(
        children: [
          _buildVitalItem('❤️', '72', 'bpm', 'Rythme'),
          _buildVitalItem('🩺', '120/80', 'mmHg', 'Tension'),
          _buildVitalItem('🌡️', '36.8', '°C', 'Temp.'),
          _buildVitalItem('🫁', '16', '/min', 'Resp.'),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String emoji, String value, String unit, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMedicalHistory() {
    return MedicalCard(
      title: 'Antécédents',
      titleIcon: Icons.history_rounded,
      child: Column(
        children: [
          _buildHistoryItem('Diabète Type 2', '2018', AppColors.warning),
          const SizedBox(height: 12),
          _buildHistoryItem('Hypertension', '2020', AppColors.error),
          const SizedBox(height: 12),
          _buildHistoryItem('Chirurgie appendice', '2010', AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String condition, String year, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(condition, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(year, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCurrentMedications() {
    return MedicalCard(
      title: 'Médicaments Actuels',
      titleIcon: Icons.medication_rounded,
      child: Column(
        children: [
          _buildMedicationItem('Metformine', '500mg', '2x/jour', AppColors.primary),
          const SizedBox(height: 12),
          _buildMedicationItem('Amlodipine', '5mg', '1x/jour', AppColors.secondary),
          const SizedBox(height: 12),
          _buildMedicationItem('Aspirine', '100mg', '1x/jour', AppColors.prescription),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(String name, String dose, String frequency, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(dose, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(frequency, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentConsultations() {
    return MedicalCard(
      title: 'Consultations Récentes',
      titleIcon: Icons.calendar_today_rounded,
      child: Column(
        children: [
          _buildConsultationItem('Dr. Sarah Mitchell', '15 Jan 2024', 'Suivi diabète'),
          const SizedBox(height: 12),
          _buildConsultationItem('Dr. Marc Laurent', '02 Jan 2024', 'Bilan cardiologique'),
          const SizedBox(height: 12),
          _buildConsultationItem('Dr. Sarah Mitchell', '18 Déc 2023', 'Contrôle tension'),
        ],
      ),
    );
  }

  Widget _buildConsultationItem(String doctor, String date, String reason) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.person, color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(reason, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Text(date, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}


