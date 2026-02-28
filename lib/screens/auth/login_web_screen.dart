import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../dashboard/dashboard_screen.dart';
import '../web/center_dashboard_web.dart';
import '../pharmacie/pharmacie_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../patientnesrine/main_screen.dart';
import '../web/medecin_web_dashboard.dart';
import '../dashboard_main_screen.dart';
import 'signup_screen.dart';
import 'reset_password_screen.dart';

/// Écran de Connexion Web avec Design Moderne
class LoginWebScreen extends StatefulWidget {
  const LoginWebScreen({super.key});

  @override
  State<LoginWebScreen> createState() => _LoginWebScreenState();
}

class _LoginWebScreenState extends State<LoginWebScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0B2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: Row(
          children: [
            // Left Section - Welcome Message with Background
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Fond abstrait avec dégradé
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2D1B4E),
                          Color(0xFF1A0B2E),
                          Color(0xFF0F0A1E),
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _AbstractBackgroundPainter(),
                      size: Size.infinite,
                    ),
                  ),
                  // Overlay avec gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                  // Message de bienvenue
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Welcome',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Have a great journey ahead...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Right Section - Login Form
            Expanded(
              flex: 2,
              child: Container(
                color: const Color(0xFF1A1F2E).withValues(alpha: 0.95),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),
                          _buildLogo(),
                          const SizedBox(height: 40),
                          _buildInputField(
                            label: 'Username',
                            controller: _emailController,
                            hint: 'John Doe',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 24),
                          _buildInputField(
                            label: 'Password',
                            controller: _passwordController,
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 16),
                          _buildRememberMe(),
                          const SizedBox(height: 32),
                          _buildSignInButton(),
                          const SizedBox(height: 24),
                          _buildSignUpLink(),
                          const SizedBox(height: 16),
                          _buildForgotPasswordLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    // Créer un fond abstrait avec des formes colorées
    return CustomPaint(
      painter: _AbstractBackgroundPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.health_and_safety,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF60A5FA),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscureText,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.black.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(icon, color: Colors.black.withValues(alpha: 0.7)),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
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

  Widget _buildRememberMe() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _rememberMe
                  ? const Color(0xFF7C3AED)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _rememberMe
                    ? const Color(0xFF7C3AED)
                    : Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: _rememberMe
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Remember me',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'SIGN IN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              );
            },
            child: const Text(
              'Sign Up',
              style: TextStyle(
                color: Color(0xFFA78BFA),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Center(
      child: GestureDetector(
        onTap: _showForgotPasswordDialog,
        child: Text(
          'Forgot Password',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
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
        final user = authProvider.user;
        final userRole = user?.role ?? UserRole.patient;
        final userEmail = user?.email ?? '';

        Widget dashboard;

        // Rediriger vers le bon dashboard selon le rôle
        if (userEmail.toLowerCase() == 'admin@medaichain.com' ||
            userEmail.toLowerCase().contains('admin')) {
          dashboard = const AdminDashboardScreen();
        } else if (userRole == UserRole.centreAnalyse) {
          // Use web dashboard for center analysis on web platform
          dashboard = const CenterDashboardWeb();
        } else if (userRole == UserRole.pharmacie) {
          dashboard = const PharmacieDashboardScreen();
        } else if (userRole == UserRole.medecin) {
          dashboard = const MedecinWebDashboard();
        } else if (userRole == UserRole.clinique) {
          // Dashboard clinique (module clinique)
          dashboard = const DashboardMainScreen();
        } else {
          dashboard = const MainScreen();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => dashboard),
        );
      } else {
        _showErrorSnackBar(authProvider.error ?? 'Erreur de connexion');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Mot de passe oublié',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrez votre email pour recevoir un lien de réinitialisation',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'votre@email.com',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
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

              final success = await authProvider.forgotPassword(email);

              if (mounted) {
                if (success) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResetPasswordScreen(email: email),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.error ?? 'Erreur'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text(
              'Envoyer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter pour le fond abstrait
class _AbstractBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Formes abstraites - cercles lumineux
    paint.color = const Color(0xFF7C3AED).withValues(alpha: 0.15);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      size.width * 0.3,
      paint,
    );

    paint.color = const Color(0xFFA78BFA).withValues(alpha: 0.1);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.6),
      size.width * 0.25,
      paint,
    );

    paint.color = const Color(0xFFEC4899).withValues(alpha: 0.08);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.8),
      size.width * 0.2,
      paint,
    );

    // Formes de rochers abstraits
    paint.color = const Color(0xFF4C1D95).withValues(alpha: 0.2);
    final rockPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..lineTo(size.width * 0.3, size.height * 0.5)
      ..lineTo(size.width * 0.35, size.height * 0.6)
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..close();
    canvas.drawPath(rockPath, paint);

    paint.color = const Color(0xFF5B21B6).withValues(alpha: 0.15);
    final rockPath2 = Path()
      ..moveTo(size.width * 0.6, size.height * 0.9)
      ..lineTo(size.width * 0.8, size.height * 0.7)
      ..lineTo(size.width * 0.85, size.height * 0.8)
      ..lineTo(size.width * 0.7, size.height)
      ..close();
    canvas.drawPath(rockPath2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
