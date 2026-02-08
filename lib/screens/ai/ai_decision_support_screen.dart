import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../core/theme/futuristic_theme.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';

/// AI Decision Support Screen
class AIDecisionSupportScreen extends StatefulWidget {
  const AIDecisionSupportScreen({super.key});

  @override
  State<AIDecisionSupportScreen> createState() => _AIDecisionSupportScreenState();
}

class _AIDecisionSupportScreenState extends State<AIDecisionSupportScreen>
    with SingleTickerProviderStateMixin {
  final _symptomsController = TextEditingController();
  bool _isAnalyzing = false;
  bool _showResults = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

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
                        _buildAIHeader(),
                        const SizedBox(height: 24),
                        _buildInputSection(),
                        if (_showResults) ...[
                          const SizedBox(height: 24),
                          _buildResults(),
                        ],
                        const SizedBox(height: 24),
                        _buildDisclaimer(),
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
              shaderCallback: (bounds) => FuturisticColors.aiGradient.createShader(bounds),
              child: const Text(
                'IA Assistant',
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

  Widget _buildAIHeader() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      showGlow: true,
      glowColor: FuturisticColors.neonPurple,
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: FuturisticColors.aiGradient,
                shape: BoxShape.circle,
                boxShadow: FuturisticTheme.neonGlow(FuturisticColors.neonPurple, intensity: 0.6),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => FuturisticColors.aiGradient.createShader(bounds),
                  child: const Text(
                    'Assistant IA Médical',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Analyse intelligente des symptômes',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: FuturisticColors.aiGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ACTIF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Symptômes du Patient',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: FuturisticColors.neonCyan.withValues(alpha: 0.2),
                  blurRadius: 15,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: FuturisticColors.glassWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: FuturisticColors.neonCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _symptomsController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Décrivez les symptômes observés...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          NeonButton(
            text: _isAnalyzing ? 'ANALYSE EN COURS...' : 'ANALYSER',
            icon: Icons.auto_awesome,
            onPressed: _handleAnalyze,
            isLoading: _isAnalyzing,
            gradient: FuturisticColors.aiGradient,
            glowColor: FuturisticColors.neonPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        _buildSuggestionCard(
          title: 'Diagnostic Probable',
          content: 'Infection respiratoire haute',
          riskLevel: 'Moyen',
          riskColor: FuturisticColors.neonYellow,
          icon: Icons.medical_information_outlined,
        ),
        const SizedBox(height: 14),
        _buildSuggestionCard(
          title: 'Examens Recommandés',
          content: 'Radiographie thoracique, Test sanguin complet',
          riskLevel: 'Standard',
          riskColor: FuturisticColors.neonCyan,
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: 14),
        _buildSuggestionCard(
          title: 'Traitement Suggéré',
          content: 'Antibiotiques, Repos, Hydratation',
          riskLevel: 'Faible',
          riskColor: FuturisticColors.neonGreen,
          icon: Icons.medication_outlined,
        ),
      ],
    );
  }

  Widget _buildSuggestionCard({
    required String title,
    required String content,
    required String riskLevel,
    required Color riskColor,
    required IconData icon,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      showGlow: true,
      glowColor: riskColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [riskColor, riskColor.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: FuturisticTheme.neonGlow(riskColor, intensity: 0.3),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [riskColor, riskColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  riskLevel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: FuturisticColors.neonYellow.withValues(alpha: 0.8),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Les suggestions de l\'IA sont des aides au diagnostic. La décision finale revient au médecin.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAnalyze() async {
    setState(() {
      _isAnalyzing = true;
      _showResults = false;
    });
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _showResults = true;
      });
    }
  }
}
