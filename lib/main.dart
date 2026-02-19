import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/centre_analyse/centre_analyse_dashboard_screen.dart';
import 'screens/pharmacie/pharmacie_dashboard_screen.dart';
import 'screens/patient/patient_dashboard_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
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

/// MEDAIChain Healthcare Application
/// Doctor Portal for managing patients, diagnoses, and prescriptions
class MEDAIChainApp extends StatelessWidget {
  const MEDAIChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
      ],
      child: MaterialApp(
        title: 'MEDAIChain Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Define routes for web navigation
        routes: {
          '/': (context) => kIsWeb ? const AdminLoginScreen() : const AuthWrapper(),
          '/admin': (context) => const AdminLoginScreen(),
          '/admin/dashboard': (context) => const AdminDashboardScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}

/// Wrapper qui gère la navigation selon l'état d'authentification
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Afficher un loader pendant l'initialisation
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si connecté, router vers le bon dashboard selon le rôle
    if (authProvider.isLoggedIn) {
      if (authProvider.user?.role == UserRole.centreAnalyse) {
        return const CentreAnalyseDashboardScreen();
      }
      if (authProvider.user?.role == UserRole.pharmacie) {
        return const PharmacieDashboardScreen();
      }
      if (authProvider.user?.role == UserRole.patient) {
        return const PatientDashboardScreen();
      }
      // Médecin ou Clinique → Dashboard médecin
      return const DashboardScreen();
    }

    // Sinon, afficher l'écran de bienvenue
    return const WelcomeScreen();
  }
}

