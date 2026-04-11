import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../dashboard/dashboard_screen.dart';
import '../web/center_dashboard_web.dart';
import '../pharmacie/pharmacie_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../patientnesrine/main_screen.dart';
import '../web/medecin_web_dashboard.dart';
import '../clinique/web/dashboard_main_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../clinique/mobile/home_admin_clinique_mobile.dart';
import 'signup_screen.dart';
import 'reset_password_screen.dart';

/// Écran de Connexion Web — Design Médical Élégant Bleu/Teal
class LoginWebScreen extends StatefulWidget {
  const LoginWebScreen({super.key});

  @override
  State<LoginWebScreen> createState() => _LoginWebScreenState();
}

class _LoginWebScreenState extends State<LoginWebScreen>
    with SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe       = false;
  bool _isLoading        = false;
  bool _obscurePassword  = true;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 800;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F7FF),
        body: isNarrow
            ? _buildMobileLayout()
            : _buildDesktopLayout(),
      ),
    );
  }

  // ── DESKTOP LAYOUT ─────────────────────────────────────────────────────────

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // ── Left Panel — Illustration ────────────────────────────────────────
        Expanded(
          flex: 5,
          child: _buildLeftPanel(),
        ),

        // ── Right Panel — Form ───────────────────────────────────────────────
        Expanded(
          flex: 4,
          child: _buildRightPanel(),
        ),
      ],
    );
  }

  // ── MOBILE LAYOUT ──────────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF0288D1)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildLogoWidget(),
                const SizedBox(height: 32),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── LEFT PANEL ─────────────────────────────────────────────────────────────

  Widget _buildLeftPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
            Color(0xFF0288D1),
            Color(0xFF00838F),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Animated background circles
          ..._buildDecoCircles(),

          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'MEDAIChain',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Central illustration
                Center(child: _buildMedicalIllustration()),

                const SizedBox(height: 48),

                // Headline
                Text(
                  'Votre plateforme\nde santé numérique',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gérez consultations, ordonnances et dossiers patients\nen toute sécurité grâce à la blockchain.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 40),

                // Feature chips
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _buildFeatureChip(Icons.shield_rounded,       'Sécurité Blockchain'),
                    _buildFeatureChip(Icons.psychology_rounded,   'IA Médicale'),
                    _buildFeatureChip(Icons.calendar_month_rounded,'Rendez-vous'),
                    _buildFeatureChip(Icons.science_rounded,      'Analyses Lab'),
                    _buildFeatureChip(Icons.videocam_rounded,     'Téléconsultation'),
                    _buildFeatureChip(Icons.local_pharmacy_rounded,'Pharmacie'),
                  ],
                ),

                const Spacer(),

                // Bottom tagline
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Santé connectée, soins optimisés',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDecoCircles() {
    return [
      Positioned(
        top: -80,
        right: -80,
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      Positioned(
        bottom: -60,
        left: -60,
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),
      Positioned(
        top: 200,
        left: -30,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      Positioned(
        bottom: 180,
        right: 40,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
      ),
    ];
  }

  Widget _buildMedicalIllustration() {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
          ),
          // Middle ring
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
          ),
          // Core circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
          // Orbiting icons
          ..._buildOrbitingIcons(),
        ],
      ),
    );
  }

  List<Widget> _buildOrbitingIcons() {
    final icons = [
      Icons.favorite_rounded,
      Icons.biotech_rounded,
      Icons.medication_rounded,
      Icons.person_rounded,
    ];
    final colors = [
      const Color(0xFFEF5350),
      const Color(0xFF42A5F5),
      const Color(0xFF4DB6AC),
      const Color(0xFFFB8C00),
    ];

    final List<Widget> result = [];
    for (int i = 0; i < icons.length; i++) {
      final angle = (i / icons.length) * 2 * math.pi - math.pi / 4;
      const radius = 115.0;
      final dx = radius * math.cos(angle);
      final dy = radius * math.sin(angle);

      result.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors[i].withValues(alpha: 0.25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icons[i], color: Colors.white, size: 20),
          ),
        ),
      );
    }
    return result;
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── RIGHT PANEL ────────────────────────────────────────────────────────────

  Widget _buildRightPanel() {
    return Container(
      color: Colors.white,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogoWidget(),
                    const SizedBox(height: 36),
                    _buildWelcomeText(),
                    const SizedBox(height: 36),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 16),
                    _buildRememberAndForgot(),
                    const SizedBox(height: 28),
                    _buildSignInButton(),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),
                    _buildSignUpRow(),
                    const SizedBox(height: 32),
                    _buildSecurityBadge(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeText(),
          const SizedBox(height: 24),
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 14),
          _buildRememberAndForgot(),
          const SizedBox(height: 24),
          _buildSignInButton(),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildSignUpRow(),
        ],
      ),
    );
  }

  // ── FORM COMPONENTS ────────────────────────────────────────────────────────

  Widget _buildLogoWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connexion',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Accédez à votre espace médical sécurisé',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adresse email',
          style: TextStyle(
            color: Color(0xFF0D1B3E),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight, width: 1.5),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              color: Color(0xFF0D1B3E),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'medecin@hopital.com',
              hintStyle: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.alternate_email_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mot de passe',
          style: TextStyle(
            color: Color(0xFF0D1B3E),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight, width: 1.5),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(
              color: Color(0xFF0D1B3E),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _rememberMe ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _rememberMe
                        ? AppColors.primary
                        : AppColors.textLight,
                    width: 1.5,
                  ),
                ),
                child: _rememberMe
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Se souvenir de moi',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Forgot password
        GestureDetector(
          onTap: _showForgotPasswordDialog,
          child: Text(
            'Mot de passe oublié ?',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Se connecter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.borderLight,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Nouveau sur MEDAIChain ?',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.borderLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpRow() {
    return OutlinedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignupScreen()),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Créer un compte patient',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.blockchainLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Connexion sécurisée — Données protégées par blockchain',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LOGIN LOGIC ────────────────────────────────────────────────────────────

  void _handleLogin() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(email: email, password: password);

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        final user     = authProvider.user;
        final userRole = user?.role ?? UserRole.patient;
        final userEmail = user?.email ?? '';

        Widget dashboard;

        if (userEmail.toLowerCase() == 'admin@medaichain.com' ||
            userEmail.toLowerCase().contains('admin')) {
          dashboard = const AdminDashboardScreen();
        } else if (userRole == UserRole.centreAnalyse) {
          dashboard = const CenterDashboardWeb();
        } else if (userRole == UserRole.pharmacie) {
          dashboard = const PharmacieDashboardScreen();
        } else if (userRole == UserRole.medecin) {
          dashboard = const MedecinWebDashboard();
        } else if (userRole == UserRole.clinique) {
          dashboard = kIsWeb
              ? const DashboardMainScreen()
              : const HomeAdminCliniqueMobile();
        } else {
          dashboard = const MainScreen();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => dashboard),
        );
      } else {
        _showErrorSnackBar(authProvider.error ?? 'Identifiants incorrects');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final authProvider    = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blockchainLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Réinitialiser le mot de passe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B3E),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textLight,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Entrez votre adresse email pour recevoir un lien de réinitialisation.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'votre@email.com',
                    hintStyle: TextStyle(color: AppColors.textLight),
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez entrer votre email'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(dialogContext);
                          final success =
                              await authProvider.forgotPassword(email);
                          if (mounted) {
                            if (success) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ResetPasswordScreen(email: email),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(authProvider.error ?? 'Erreur'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Envoyer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
