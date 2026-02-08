import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../core/theme/futuristic_theme.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';

/// Patient Medical Record with Timeline
class PatientMedicalRecordScreen extends StatefulWidget {
  const PatientMedicalRecordScreen({super.key});

  @override
  State<PatientMedicalRecordScreen> createState() => _PatientMedicalRecordScreenState();
}

class _PatientMedicalRecordScreenState extends State<PatientMedicalRecordScreen> {
  final List<Map<String, dynamic>> _timeline = [
    {
      'date': '15 Jan 2026',
      'type': 'Consultation',
      'title': 'Suivi diabète',
      'doctor': 'Dr. Martin',
      'details': 'Glycémie stable, traitement maintenu',
    },
    {
      'date': '10 Jan 2026',
      'type': 'Analyse',
      'title': 'Bilan sanguin',
      'doctor': 'Laboratoire',
      'details': 'HbA1c: 6.5%, Cholestérol normal',
    },
    {
      'date': '05 Jan 2026',
      'type': 'Prescription',
      'title': 'Renouvellement',
      'doctor': 'Dr. Martin',
      'details': 'Metformine 850mg x2/jour',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildPatientInfo(),
                        const SizedBox(height: 24),
                        _buildSecurityInfo(),
                        const SizedBox(height: 24),
                        _buildTimeline(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FuturisticColors.glassWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FuturisticColors.glassBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => FuturisticColors.cyberGradient.createShader(bounds),
              child: const Text(
                'Dossier Médical',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Icon(
            Icons.lock_outline,
            color: FuturisticColors.neonGreen,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      showGlow: true,
      glowColor: FuturisticColors.neonCyan,
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: FuturisticColors.cyberGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: FuturisticTheme.neonGlow(FuturisticColors.neonCyan, intensity: 0.4),
            ),
            child: const Center(
              child: Text(
                'JD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jean Dupont',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '45 ans • Diabète Type 2',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: FuturisticColors.blockchainGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'VÉRIFIÉ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: FuturisticColors.blockchainGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: FuturisticTheme.neonGlow(FuturisticColors.neonGreen, intensity: 0.3),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => FuturisticColors.blockchainGradient.createShader(bounds),
                  child: const Text(
                    'Accès Sécurisé',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hash: 0x7a8f...3e2d',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: FuturisticColors.neonGreen,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique Médical',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        ..._timeline.map((entry) => _buildTimelineEntry(entry)),
      ],
    );
  }

  Widget _buildTimelineEntry(Map<String, dynamic> entry) {
    Color typeColor;
    IconData typeIcon;
    
    switch (entry['type']) {
      case 'Consultation':
        typeColor = FuturisticColors.neonCyan;
        typeIcon = Icons.medical_services_outlined;
        break;
      case 'Analyse':
        typeColor = FuturisticColors.neonPurple;
        typeIcon = Icons.science_outlined;
        break;
      case 'Prescription':
        typeColor = FuturisticColors.neonGreen;
        typeIcon = Icons.medication_outlined;
        break;
      default:
        typeColor = FuturisticColors.neonCyan;
        typeIcon = Icons.circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [typeColor, typeColor.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: FuturisticTheme.neonGlow(typeColor, intensity: 0.3),
                ),
                child: Icon(typeIcon, color: Colors.white, size: 20),
              ),
              if (_timeline.last != entry)
                Container(
                  width: 2,
                  height: 60,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        typeColor.withValues(alpha: 0.5),
                        typeColor.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [typeColor, typeColor.withValues(alpha: 0.7)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry['type'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry['details'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: typeColor.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry['doctor'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time,
                        color: typeColor.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry['date'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
