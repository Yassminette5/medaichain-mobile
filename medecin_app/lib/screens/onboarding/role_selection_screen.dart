import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildTitle(),
                const SizedBox(height: 32),
                Expanded(child: _buildRoleGrid()),
                _buildContinueButton(),
                const SizedBox(height: 24),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00D4AA),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Étape 1/3',
                  style: TextStyle(
                    color: Color(0xFF00D4AA),
                    fontSize: 13,
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
          // Robot avatar
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 45),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF00E5CC)],
            ).createShader(bounds),
            child: const Text(
              'Qui êtes-vous ?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez votre profil pour personnaliser\nvotre expérience MEDAIChain',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: _roles.length,
        itemBuilder: (context, index) => _buildRoleCard(_roles[index], index),
      ),
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
          borderRadius: BorderRadius.circular(24),
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
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      role['icon'],
                      color: isSelected ? Colors.white : gradientColors[0],
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    role['title'],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Subtitle
                  Text(
                    role['subtitle'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.5),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(Icons.check, color: gradientColors[0], size: 18),
                ),
              ),
          ],
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
        height: 58,
        child: Container(
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
                  )
                : null,
            color: isEnabled ? null : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D4AA).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continuer',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  size: 22,
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
