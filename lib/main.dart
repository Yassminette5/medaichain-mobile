import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
// Clinique Imports
import 'theme/app_theme.dart' as clinique_theme;
import 'screens/clinique/web/dashboard_main_screen.dart';
import 'core/theme/app_theme.dart' as patient_theme;
import 'providers/auth_provider.dart';
import 'providers/medicines_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/patients_provider.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/login_web_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/patientnesrine/main_screen.dart';

// Admin Imports
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

// Web dashboards (routes compat *.html)
import 'screens/web/medecin_web_dashboard.dart';
import 'screens/web/center_dashboard_web.dart';
import 'screens/pharmacie/pharmacie_dashboard_screen.dart';
import 'screens/centre_analyse/home_centre_analyse.dart';
import 'medecin/screens/dashboard/dashboard_screen.dart';
import 'screens/clinique/mobile/home_admin_clinique_mobile.dart';
import 'models/user_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test sur téléphone réel (IP du Mac sur le même WiFi)
  ApiService.backendUrlOverride = 'http://172.20.10.4:3000';

  await initializeDateFormatting('fr_FR', null);

  // Éviter LocaleDataException (DateFormat avec 'fr_FR' dans l'agenda, etc.)
  await initializeDateFormatting('fr_FR', null);

  try {
    // Important en prod si l'app web est servie derrière un backend (ex: Nest/Express)
    // Sans "rewrite" côté serveur, la navigation en path (/xxx) peut afficher une 404.
    // Avec HashUrlStrategy, l'URL reste /#/xxx et évite ces 404.
    if (kIsWeb) {
      setUrlStrategy(const HashUrlStrategy());
    }

    // Respecter "remember me": si désactivé, purger la session persistée au démarrage.
    await ApiService.enforceRememberPolicyOnStartup();
  } catch (e, st) {
    // En web, SharedPreferences ou l'init peuvent échouer (ex: mode privé).
    // On affiche l'app quand même ; l'utilisateur pourra se connecter.
    if (kIsWeb) {
      debugPrint('[MEDAIChain] Startup init warning: $e');
    } else {
      rethrow;
    }
  }
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0E1A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  } catch (_) {
    // Ignoré sur plateformes où SystemChrome n'est pas supporté (ex: web)
  }

  // En mode debug web, afficher les erreurs de rendu au lieu d'un écran blanc
  if (kIsWeb) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Erreur d\'affichage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 12),
                SelectableText(details.exceptionAsString(), style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                if (details.stack != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(details.stack.toString(), style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                ],
              ],
            ),
          ),
        ),
      );
    };
  }

  runApp(const MEDAIChainApp());
}

class MEDAIChainApp extends StatelessWidget {
  const MEDAIChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => MedicinesProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => PatientsProvider()),
      ],
      child: MaterialApp(
        title: 'MEDAIChain',
        debugShowCheckedModeBanner: false,
        theme: clinique_theme.AppTheme.lightTheme,
        initialRoute: kIsWeb ? '/login' : '/',
        routes: {
          // Mobile: onboarding si pas de session mémorisée, sinon aller direct à l'app
          '/': (context) => kIsWeb ? const LoginWebScreen() : const AuthWrapper(),
          '/login': (context) => kIsWeb ? const LoginWebScreen() : const LoginScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/dashboard': (context) => const DashboardMainScreen(),
          '/patient_home': (context) => const AuthWrapper(),
          // '/pharmacie': (context) => const PharmacyWebDashboard(),
          '/centre_analyse': (context) => const CenterDashboardWeb(),
          '/admin': (context) => const AdminLoginScreen(),
          '/admin/dashboard': (context) => const AdminDashboardScreen(),
          '/signup.html': (context) => const SignupScreen(),
          '/signup': (context) => const SignupScreen(),

          // Compat: certains liens anciens pointent vers des pages *.html (éviter une navigation cassée)
          '/clinique_dashboard.html': (context) => const MedecinWebDashboard(),
          '/centre_dashboard.html': (context) => const CenterDashboardWeb(),
          '/centre_analyse_dashboard.html': (context) => const CenterDashboardWeb(),
          '/pharmacie_dashboard.html': (context) => const PharmacieDashboardScreen(),
          // Ancien écran de sélection (si besoin plus tard)
          '/launcher': (context) => const AppLauncherScreen(),
        },
      ),
    );
  }
}

class AppLauncherScreen extends StatelessWidget {
  const AppLauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety, size: 80, color: Color(0xFF0D47A1)),
            const SizedBox(height: 20),
            const Text(
              'Bienvenue sur MEDAIChain',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Text(
              'Sélectionnez votre espace',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 48),
            
            // Espace Clinique Button
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/dashboard');
              },
              child: Container(
                width: 300,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2E5BFF), Color(0xFF0030E5)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2E5BFF).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dashboard, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'ESPACE CLINIQUE',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Connexion Professionnelle (Pharmacie, Centre d'Analyse, Admin)
            _buildEspaceButton(
              context: context,
              route: '/login',
              label: 'ESPACE PROFESSIONNEL',
              subtitle: 'Pharmacie · Laboratoire · Admin',
              icon: Icons.local_hospital,
              colors: const [Color(0xFF2E5BFF), Color(0xFF0030E5)],

            ),
            const SizedBox(height: 24),
            
            // Espace Patient Button
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/patient_home');
              },
              child: Container(
                width: 300,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'ESPACE PATIENT',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEspaceButton({
    required BuildContext context,
    required String route,
    required String label,
    required IconData icon,
    required List<Color> colors,
    String? subtitle,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        width: 380,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.7), size: 18),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (!authProvider.isLoggedIn) {
      return const WelcomeScreen();
    }

    final user = authProvider.user;
    final userRole = user?.role ?? UserRole.patient;
    final userEmail = user?.email ?? '';
    
    // Theme selection based on role (optional but recommended)
    final themeData = (userRole == UserRole.patient) 
        ? patient_theme.AppTheme.lightTheme 
        : clinique_theme.AppTheme.lightTheme;

    return Theme(
      data: themeData,
      child: Builder(
        builder: (context) {
          // Rediriger vers le bon dashboard selon le rôle
          if (userEmail.toLowerCase() == 'admin@medaichain.com' || 
              userEmail.toLowerCase().contains('admin')) {
            return const AdminDashboardScreen();
          } else if (userRole == UserRole.centreAnalyse) {
            return kIsWeb ? const CenterDashboardWeb() : const HomeCentreAnalyse();
          } else if (userRole == UserRole.pharmacie) {
            return const PharmacieDashboardScreen();
          } else if (userRole == UserRole.medecin) {
            return const DashboardScreen();
          } else if (userRole == UserRole.clinique) {
            return kIsWeb ? const DashboardMainScreen() : const HomeAdminCliniqueMobile();
          } else {
            // Patient
            return const MainScreen();
          }
        }
      ),
    );
  }
}
