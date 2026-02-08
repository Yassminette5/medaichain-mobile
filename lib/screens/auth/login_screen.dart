import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../dashboard/dashboard_screen.dart';
import 'signup_screen.dart';
import '../onboarding/role_selection_screen.dart';

/// Clean Login Screen with Dual Theme Support
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = ThemeProviderInherited.of(context);
    
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F7);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF1A1F3A);
    final textLight = isDark ? Colors.white60 : const Color(0xFF6B7280);
    const primaryColor = Color(0xFF00D4AA);
    final inputBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F7);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    _buildLogo(primaryColor),
                    const SizedBox(height: 40),
                    _buildWelcomeText(textDark, textLight),
                    const SizedBox(height: 36),
                    _buildLoginCard(isDark, cardColor, inputBgColor, textDark, textLight, primaryColor),
                    const SizedBox(height: 24),
                    _buildSignUpSection(primaryColor, textLight),
                    const SizedBox(height: 24),
                    _buildSecurityBadge(isDark, textDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              // Dark mode toggle button
              Positioned(
                top: 16,
                right: 16,
                child: _buildThemeToggle(themeProvider, isDark, cardColor, primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(themeProvider, bool isDark, Color cardColor, Color primaryColor) {
    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey(isDark),
            color: primaryColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Color primaryColor) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, const Color(0xFF00B894)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_hospital_rounded,
        color: Colors.white,
        size: 36,
      ),
    );
  }

  Widget _buildWelcomeText(Color textDark, Color textLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEDAIChain',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bienvenue, Docteur',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Connectez-vous pour accéder à vos patients',
          style: TextStyle(
            fontSize: 14,
            color: textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isDark, Color cardColor, Color inputBgColor, Color textDark, Color textLight, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'docteur@medaichain.com',
            icon: Icons.alternate_email,
            inputBgColor: inputBgColor,
            textDark: textDark,
            textLight: textLight,
            primaryColor: primaryColor,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            inputBgColor: inputBgColor,
            textDark: textDark,
            textLight: textLight,
            primaryColor: primaryColor,
            isDark: isDark,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: textLight,
                size: 22,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionsRow(textLight, primaryColor, isDark),
          const SizedBox(height: 24),
          _buildLoginButton(primaryColor),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color inputBgColor,
    required Color textDark,
    required Color textLight,
    required Color primaryColor,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: inputBgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(color: textDark, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textLight.withValues(alpha: 0.5)),
              prefixIcon: Icon(icon, color: primaryColor, size: 22),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsRow(Color textLight, Color primaryColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _rememberMe ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _rememberMe ? primaryColor : (isDark ? Colors.white24 : Colors.grey.shade300),
                    width: 2,
                  ),
                ),
                child: _rememberMe
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Se souvenir de moi',
              style: TextStyle(
                color: textLight,
                fontSize: 13,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _showForgotPassword,
          child: Text(
            'Mot de passe oublié ?',
            style: TextStyle(
              color: primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildSignUpSection(Color primaryColor, Color textLight) {
    return Column(
      children: [
        Text(
          'Nouveau sur MEDAIChain ?',
          style: TextStyle(color: textLight, fontSize: 14),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text(
              'Créer un compte',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge(bool isDark, Color textDark) {
    final badgeColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF1A1F3A).withValues(alpha: 0.08);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security_rounded, color: textDark, size: 18),
            const SizedBox(width: 8),
            Text(
              'Sécurisé par Blockchain',
              style: TextStyle(
                color: textDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPassword() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ForgotPasswordSheet(isDark: isDark),
    );
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }
}

/// Forgot Password Modal
class _ForgotPasswordSheet extends StatefulWidget {
  final bool isDark;
  const _ForgotPasswordSheet({required this.isDark});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  static const _primaryColor = Color(0xFF00D4AA);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = widget.isDark ? Colors.white : const Color(0xFF1A1F3A);
    final textLight = widget.isDark ? Colors.white60 : const Color(0xFF6B7280);
    final inputBgColor = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F7);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (!_emailSent) ...[
              Text(
                'Mot de passe oublié',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Entrez votre email pour recevoir un lien de réinitialisation.',
                style: TextStyle(color: textLight, fontSize: 14),
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                  ),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textDark, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'docteur@medaichain.com',
                    hintStyle: TextStyle(color: textLight.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.email_outlined, color: _primaryColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Envoyer le lien',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: _primaryColor, size: 48),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Email envoyé !',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vérifiez votre boîte mail',
                      style: TextStyle(color: textLight),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Retour', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _sendResetEmail() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    }
  }
}
