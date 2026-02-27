import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Clinique Imports
import 'theme/app_theme.dart' as clinique_theme;
import 'screens/dashboard_main_screen.dart';

// Patient Imports
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Respecter "remember me": si désactivé, purger la session persistée au démarrage.
  await ApiService.enforceRememberPolicyOnStartup();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
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
        initialRoute: '/',
        routes: {
          // Mobile: onboarding si pas de session mémorisée, sinon aller direct à l'app
          '/': (context) => kIsWeb ? const LoginWebScreen() : const AuthWrapper(),
          '/login': (context) => kIsWeb ? const LoginWebScreen() : const LoginScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/dashboard': (context) => const DashboardMainScreen(),
          '/patient_home': (context) => const AuthWrapper(),
          '/admin': (context) => const AdminLoginScreen(),
          '/admin/dashboard': (context) => const AdminDashboardScreen(),
          '/signup.html': (context) => const SignupScreen(),
          '/signup': (context) => const SignupScreen(),
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
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Override the theme to use the patient app theme temporarily for this widget tree
    return Theme(
      data: patient_theme.AppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final authProvider = Provider.of<AuthProvider>(context);
          if (authProvider.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (authProvider.isLoggedIn) return const MainScreen();
          return const WelcomeScreen();
        }
      ),
    );
  }
}
