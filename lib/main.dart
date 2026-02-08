import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MEDAIChainApp());
}

/// MEDAIChain Healthcare Application
/// Doctor Portal for managing patients, diagnoses, and prescriptions
class MEDAIChainApp extends StatefulWidget {
  const MEDAIChainApp({super.key});

  @override
  State<MEDAIChainApp> createState() => _MEDAIChainAppState();
}

class _MEDAIChainAppState extends State<MEDAIChainApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, child) {
        // Update system UI overlay style based on theme
        SystemChrome.setSystemUIOverlayStyle(
          _themeProvider.isDarkMode
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: const Color(0xFF0F172A),
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.white,
                ),
        );

        return ThemeProviderInherited(
          themeProvider: _themeProvider,
          child: MaterialApp(
            title: 'MEDAIChain',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeProvider.themeMode,
            home: const WelcomeScreen(),
          ),
        );
      },
    );
  }
}

/// InheritedWidget to provide ThemeProvider to the widget tree
class ThemeProviderInherited extends InheritedWidget {
  final ThemeProvider themeProvider;

  const ThemeProviderInherited({
    super.key,
    required this.themeProvider,
    required super.child,
  });

  static ThemeProvider of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<ThemeProviderInherited>();
    return widget!.themeProvider;
  }

  @override
  bool updateShouldNotify(ThemeProviderInherited oldWidget) {
    return themeProvider.themeMode != oldWidget.themeProvider.themeMode;
  }
}
