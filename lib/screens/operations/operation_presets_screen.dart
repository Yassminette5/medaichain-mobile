import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/futuristic_theme.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';

/// Operation Presets Screen
class OperationPresetsScreen extends StatefulWidget {
  const OperationPresetsScreen({super.key});

  @override
  State<OperationPresetsScreen> createState() => _OperationPresetsScreenState();
}

class _OperationPresetsScreenState extends State<OperationPresetsScreen> {
  final List<Map<String, dynamic>> _presets = [
    {'name': 'Consultation Standard', 'category': 'Général', 'color': FuturisticColors.neonCyan, 'uses': 245},
    {'name': 'Suivi Diabète', 'category': 'Chronique', 'color': FuturisticColors.neonPurple, 'uses': 128},
    {'name': 'Contrôle Tension', 'category': 'Cardiovasculaire', 'color': FuturisticColors.neonPink, 'uses': 156},
    {'name': 'Bilan Annuel', 'category': 'Préventif', 'color': FuturisticColors.neonGreen, 'uses': 89},
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
                  child: GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _presets.length,
                    itemBuilder: (context, index) => _buildPresetCard(_presets[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFAB(),
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
                'Modèles',
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

  Widget _buildPresetCard(Map<String, dynamic> preset) {
    final color = preset['color'] as Color;
    
    return GestureDetector(
      onTap: () => _usePreset(preset['name'] as String),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        showGlow: true,
        glowColor: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: FuturisticTheme.neonGlow(color, intensity: 0.4),
              ),
              child: const Icon(Icons.description_outlined, color: Colors.white, size: 28),
            ),
            const Spacer(),
            Text(
              preset['name'] as String,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                preset['category'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.check_circle, color: color.withValues(alpha: 0.7), size: 14),
                const SizedBox(width: 6),
                Text(
                  '${preset['uses']} utilisations',
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: FuturisticColors.cyberGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: FuturisticTheme.neonGlow(FuturisticColors.neonCyan, intensity: 0.6),
      ),
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _usePreset(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modèle "$name" appliqué'),
        backgroundColor: FuturisticColors.neonCyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
