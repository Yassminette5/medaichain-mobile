import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/futuristic_theme.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';

/// Access History & Blockchain Audit Screen
class AccessHistoryScreen extends StatefulWidget {
  const AccessHistoryScreen({super.key});

  @override
  State<AccessHistoryScreen> createState() => _AccessHistoryScreenState();
}

class _AccessHistoryScreenState extends State<AccessHistoryScreen> {
  final List<Map<String, dynamic>> _history = [
    {
      'action': 'Consultation dossier',
      'patient': 'Jean Dupont',
      'time': '14:32',
      'date': 'Aujourd\'hui',
      'hash': '0x7a8f...3e2d',
      'verified': true,
    },
    {
      'action': 'Modification prescription',
      'patient': 'Marie Lambert',
      'time': '11:15',
      'date': 'Aujourd\'hui',
      'hash': '0x9b2c...5f1a',
      'verified': true,
    },
    {
      'action': 'Ajout diagnostic',
      'patient': 'Pierre Moreau',
      'time': '09:45',
      'date': 'Hier',
      'hash': '0x3d4e...8c7b',
      'verified': true,
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
                _buildBlockchainInfo(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _history.length,
                    itemBuilder: (context, index) => _buildHistoryEntry(_history[index]),
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
              shaderCallback: (bounds) => FuturisticColors.blockchainGradient.createShader(bounds),
              child: const Text(
                'Historique',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        showGlow: true,
        glowColor: FuturisticColors.neonGreen,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: FuturisticColors.blockchainGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: FuturisticTheme.neonGlow(FuturisticColors.neonGreen, intensity: 0.5),
              ),
              child: const Icon(Icons.link, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => FuturisticColors.blockchainGradient.createShader(bounds),
                    child: const Text(
                      'Blockchain Audit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Toutes les actions sont vérifiées',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.verified,
              color: FuturisticColors.neonGreen,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryEntry(Map<String, dynamic> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: FuturisticColors.cyberGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: FuturisticTheme.neonGlow(FuturisticColors.neonCyan, intensity: 0.3),
                  ),
                  child: const Icon(Icons.history, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry['action'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry['patient'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry['verified'] as bool)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: FuturisticColors.blockchainGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified, color: Colors.white, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FuturisticColors.glassWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: FuturisticColors.neonGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tag,
                    color: FuturisticColors.neonGreen.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hash: ${entry['hash']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: FuturisticColors.neonCyan.withValues(alpha: 0.7),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry['time']} • ${entry['date']}',
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
    );
  }
}
