import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../auth/signup_screen.dart';

/// Role Selection Screen - Second step in onboarding
/// Light themed with role cards for Patient, Médecin, Centre d'analyse, Pharmacie
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  final List<RoleOption> _roles = [
    RoleOption(
      id: 'patient',
      title: 'Patient',
      description: 'Gérez votre santé et vos ordonnances',
      icon: Icons.person_outline,
      color: const Color(0xFF3B82F6),
    ),
    RoleOption(
      id: 'medecin',
      title: 'Médecin',
      description: 'Consultez les dossiers et prescrivez',
      icon: Icons.medical_services_outlined,
      color: const Color(0xFF3B82F6),
    ),
    RoleOption(
      id: 'centre_analyse',
      title: "Centre d'analyse",
      description: "Transmettez les résultats d'analyses",
      icon: Icons.science_outlined,
      color: const Color(0xFF3B82F6),
    ),
    RoleOption(
      id: 'pharmacie',
      title: 'Pharmacie',
      description: 'Validez et délivrez les médicaments',
      icon: Icons.local_pharmacy_outlined,
      color: const Color(0xFF1E3A5F),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Set status bar style for light background
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildRobotIcon(),
                    const SizedBox(height: 24),
                    _buildTitle(),
                    const SizedBox(height: 32),
                    _buildRoleCards(),
                    const SizedBox(height: 32),
                    _buildContinueButton(),
                    const SizedBox(height: 16),
                    _buildFooterText(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: Colors.black87,
          ),
          const Expanded(
            child: Text(
              'Profil',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildRobotIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        size: 40,
        color: Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'Choisissez votre rôle',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Comment souhaitez-vous utiliser MEDAIChain ?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCards() {
    return Column(
      children: _roles.map((role) => _buildRoleCard(role)).toList(),
    );
  }

  Widget _buildRoleCard(RoleOption role) {
    final isSelected = _selectedRole == role.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: role.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                role.icon,
                color: role.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _selectedRole != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? _navigateToSignup : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
          foregroundColor: isEnabled ? Colors.white : Colors.grey,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Continuer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterText() {
    return Text(
      'En choisissant un rôle, vous acceptez d\'être\nvérifié selon les protocoles de sécurité de\nMEDAIChain.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[500],
        height: 1.5,
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

/// Role option data model
class RoleOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  RoleOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
