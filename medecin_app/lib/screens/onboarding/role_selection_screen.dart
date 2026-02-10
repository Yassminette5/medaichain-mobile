import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../auth/signup_screen.dart';

/// Role Selection Screen - Premium Design
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'patient',
      'title': 'Patient',
      'subtitle': 'Gérez votre santé et vos ordonnances en toute sécurité',
      'icon': Icons.person_rounded,
      'gradient': const [Color(0xFF667EEA), Color(0xFF764BA2)],
    },
    {
      'id': 'medecin',
      'title': 'Médecin',
      'subtitle': 'Consultez les dossiers et créez des prescriptions',
      'icon': Icons.medical_services_rounded,
      'gradient': const [Color(0xFF00D4AA), Color(0xFF00B894)],
    },
    {
      'id': 'centre_analyse',
      'title': "Centre d'analyse",
      'subtitle': "Transmettez les résultats d'analyses rapidement",
      'icon': Icons.biotech_rounded,
      'gradient': const [Color(0xFFF093FB), Color(0xFFF5576C)],
    },
    {
      'id': 'pharmacie',
      'title': 'Pharmacie',
      'subtitle': 'Validez et délivrez les médicaments en sécurité',
      'icon': Icons.local_pharmacy_rounded,
      'gradient': const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    },
    {
      'id': 'clinique',
      'title': 'Clinique',
      'subtitle': 'Gérez votre établissement et vos équipes efficacement',
      'icon': Icons.local_hospital_rounded,
      'gradient': const [Color(0xFFFF9966), Color(0xFFFF5E62)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0F172A),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 10), // Reduced from 24
                _buildTitle(),
                const SizedBox(height: 16), // Reduced from 32
                Expanded(child: _buildRoleList()),
                _buildContinueButton(),
                const SizedBox(height: 16), // Reduced from 24
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Étape 1/3',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Robot avatar - Reduced size
          Container(
            width: 60, // Reduced from 90
            height: 60, // Reduced from 90
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 30), // Reduced from 45
          ),
          const SizedBox(height: 16), // Reduced from 24
          ShaderMask(
            shaderCallback: (bounds) => AppColors.neonGradient.createShader(bounds),
            child: const Text(
              'Qui êtes-vous ?',
              style: TextStyle(
                fontSize: 24, // Reduced from 32
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4), // Reduced from 8
          Text(
            'Sélectionnez votre profil pour personnaliser\nvotre expérience', // Shortened text
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20), // Slightly reduced horizontal padding
      physics: const BouncingScrollPhysics(),
      itemCount: _roles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10), // Reduced from 16
      itemBuilder: (context, index) => _buildRoleCard(_roles[index], index),
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role, int index) {
    final isSelected = _selectedRole == role['id'];
    final gradientColors = role['gradient'] as List<Color>;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: 82, // Increased from 76
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
          borderRadius: BorderRadius.circular(20), // Slightly reduced radius
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
          child: Row(
            children: [
              // Icon
              Container(
                width: 42, // Reduced from 52
                height: 42, // Reduced from 52
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  role['icon'],
                  color: isSelected ? Colors.white : gradientColors[0],
                  size: 22, // Reduced size
                ),
              ),
              const SizedBox(width: 12),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      role['title'],
                      style: TextStyle(
                        fontSize: 15, // Reduced from 17
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role['subtitle'],
                      maxLines: 1, // Restricted to 1 line to save space
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11, // Reduced from 12
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Checkmark
              if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  width: 24, // Reduced from 28
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(Icons.check, color: gradientColors[0], size: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _selectedRole != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 54, // Increased from 50
        child: Container(
          decoration: BoxDecoration(
            gradient: isEnabled
                ? AppColors.primaryGradient
                : null,
            color: isEnabled ? null : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: isEnabled ? _navigateToSignup : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continuer',
                  style: TextStyle(
                    fontSize: 16, // Reduced from 17
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SignupScreen(selectedRole: _selectedRole!),
      ),
    );
  }
}
