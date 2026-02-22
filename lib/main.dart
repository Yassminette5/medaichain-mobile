import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/dashboard_main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEDAIChain Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Since we deleted the mobile screens, we just point straight to the Web Dashboard.
      // Alternatively, we can use SplashScreen if it still exists and handles routing properly.
      home: const DashboardMainScreen(),
    );
  }
}
