import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/centre_analyse/home_centre_analyse.dart';
import 'screens/pharmacie/pharmacie_dashboard_screen.dart';
import 'screens/patients/centers_list_screen.dart';

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
        title: 'MEDAIChain',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper qui gère la navigation selon l'état d'authentification
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser Consumer pour écouter les changements d'AuthProvider
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
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
          final role = authProvider.user?.role;
          
          // Debug: afficher le rôle pour diagnostiquer
          debugPrint('🔍 Rôle utilisateur détecté: $role');
          debugPrint('🔍 User complet: ${authProvider.user?.email} - ${authProvider.user?.role}');
          debugPrint('🔍 User ID: ${authProvider.user?.id}');
          
          if (role == UserRole.patient) {
            debugPrint('✅ Redirection vers CentersListScreen pour patient');
            return const CentersListScreen();
          }
          if (role == UserRole.centreAnalyse) {
            debugPrint('✅ Redirection vers HomeCentreAnalyse pour centre d\'analyse');
            return const HomeCentreAnalyse();
          }
          if (role == UserRole.pharmacie) {
            debugPrint('✅ Redirection vers PharmacieDashboardScreen pour pharmacie');
            return const PharmacieDashboardScreen();
          }
          if (role == UserRole.medecin) {
            debugPrint('✅ Redirection vers HomeCentreAnalyse pour médecin');
            return const HomeCentreAnalyse();
          }
          // Pour les autres rôles ou si le rôle n'est pas défini
          debugPrint('⚠️ Rôle non reconnu ou null: $role');
          return const WelcomeScreen();
        }

        // Sinon, afficher l'écran de bienvenue
        debugPrint('ℹ️ Utilisateur non connecté, affichage de WelcomeScreen');
        return const WelcomeScreen();
      },
    );
  }
}
