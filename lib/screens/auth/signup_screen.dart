import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../patientnesrine/informations/informations_flow.dart';

/// Écran d'Inscription Ultra Moderne — 2 étapes (Patient only)
class SignupScreen extends StatefulWidget {
  final String? selectedRole;

  const SignupScreen({super.key, this.selectedRole});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0; // 0 = personal info, 1 = password + terms

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.darkGradient),
          child: Stack(
            children: [
              _buildBackgroundOrbs(),
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildStepIndicator(),
                              const SizedBox(height: 20),
                              _buildGlassCard(),
                              const SizedBox(height: 20),
                              _buildLoginLink(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(
            top: -100,
            left: -80,
            child: _buildOrb(280, AppColors.secondary.withValues(alpha: 0.2))),
        Positioned(
            bottom: 200,
            right: -100,
            child: _buildOrb(
                320, AppColors.primary.withValues(alpha: 0.15))),
        Positioned(
            top: 400,
            left: -60,
            child: _buildOrb(
                150, AppColors.prescription.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.neonGradient.createShader(bounds),
          child: const Text(
            'Créer un compte',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Rejoignez MEDAIChain et gérez\nvotre santé facilement',
          style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.3),
        ),
      ],
    );
  }

  // 2-step indicator
  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(2, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: isActive ? AppColors.neonGradient : null,
                    color: isActive
                        ? null
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.06)
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.25), width: 1.5),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      default:
        return _buildStep1();
    }
  }

  // Step 1 — Personal info (name, email, phone)
  Widget _buildStep1() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Informations personnelles', Icons.person_outline),
        const SizedBox(height: 16),
        _buildModernTextField(
            controller: _nameController,
            label: 'Nom complet',
            icon: Icons.badge_outlined,
            hint: 'Votre nom et prénom'),
        const SizedBox(height: 10),
        _buildModernTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.alternate_email,
            hint: 'exemple@email.com',
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _buildModernTextField(
            controller: _phoneController,
            label: 'Téléphone',
            icon: Icons.phone_outlined,
            hint: '+213 555 123 456',
            keyboardType: TextInputType.phone),
        const SizedBox(height: 20),
        _buildNextButton('Continuer'),
      ],
    );
  }

  // Step 2 — Password + Terms + Sign-up button (merged from old step 2 + 3)
  Widget _buildStep2() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Sécurité du compte', Icons.lock_outline),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _passwordController,
          label: 'Mot de passe',
          icon: Icons.lock_outline_rounded,
          hint: '••••••••',
          isPassword: true,
          obscure: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 10),
        _buildModernTextField(
          controller: _confirmPasswordController,
          label: 'Confirmer le mot de passe',
          icon: Icons.lock_outline_rounded,
          hint: '••••••••',
          isPassword: true,
          obscure: _obscureConfirmPassword,
          onToggleObscure: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        const SizedBox(height: 10),
        _buildPasswordStrength(),
        const SizedBox(height: 16),
        _buildTermsCheckbox(),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildBackButton()),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _buildSignupButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildStepTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppColors.neonGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool obscure = true,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
        ],
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscure,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.black, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: Colors.black.withValues(alpha: 0.4), fontSize: 13),
              prefixIcon: ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.neonGradient.createShader(bounds),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.black.withValues(alpha: 0.5),
                          size: 18),
                      onPressed: onToggleObscure,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    final colors = [
      AppColors.error,
      AppColors.warning,
      AppColors.warning,
      AppColors.success
    ];
    final labels = ['Faible', 'Moyen', 'Bon', 'Excellent'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
              4,
              (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index < strength
                            ? colors[strength - 1]
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
              labels[strength > 0 ? strength - 1 : 0],
              style: TextStyle(
                  color: strength > 0
                      ? colors[strength - 1]
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: _acceptTerms ? AppColors.neonGradient : null,
              color: _acceptTerms ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                  color: _acceptTerms
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.4),
                  width: 2),
            ),
            child: _acceptTerms
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                children: [
                  const TextSpan(text: "J'accepte les "),
                  TextSpan(
                      text: "conditions d'utilisation",
                      style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w500)),
                  const TextSpan(text: ' et la '),
                  TextSpan(
                      text: 'politique de confidentialité',
                      style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(String text) {
    return SizedBox(
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.neonGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: ElevatedButton(
          onPressed: () => setState(() => _currentStep++),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(text,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: () => setState(() => _currentStep--),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child:
            const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          gradient: _acceptTerms ? AppColors.neonGradient : null,
          color: _acceptTerms ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _acceptTerms
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: _acceptTerms && !_isLoading ? _handleSignup : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "S'inscrire",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _acceptTerms
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle_outline,
                        color: _acceptTerms
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Déjà un compte ?',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.neonGradient.createShader(bounds),
              child: const Text('Se connecter',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSignup() async {
    // Validation
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs obligatoires');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showErrorSnackBar('Veuillez entrer un mot de passe');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    if (_passwordController.text.length < 8) {
      _showErrorSnackBar(
          'Le mot de passe doit contenir au moins 8 caractères');
      return;
    }

    if (!_acceptTerms) {
      _showErrorSnackBar("Veuillez accepter les conditions d'utilisation");
      return;
    }

    setState(() => _isLoading = true);

    // All users register as patient — simple, no role confusion
    const UserRole role = UserRole.patient;

    final fullName = _nameController.text.trim();

    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      role: role,
      fullName: fullName,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Navigate to the patient informations flow,
        // which collects health data then goes to HomeScreen.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const InformationsFlow()),
          (route) => false,
        );
      } else {
        _showErrorSnackBar(
            authProvider.error ?? "Erreur d'inscription");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
