import 'package:flutter/material.dart';

class AppImages {
  // Updated mapping based on user's specific files
  static const String welcomeBg = 'assets/images/hopital2.jpg'; // "premier page"
  static const String checkin = 'assets/images/chek in.jpg';    // "Check in"
  static const String triage = 'assets/images/salle d\'attente.jpg'; // "salle d'attente en triage IA"
  static const String hero = 'assets/images/hopital3.jpg';      // "hopital3 en analyse ia" (Assuming Hero/Analyse IA section)
  static const String analyse = 'assets/images/analyse.jpg';    // "analyse.jpg" for Analyses & Labo
  static const String doctor = 'assets/images/medecin.jpg';     // "medecin.jpg" for Planning
  static const String pharma = 'assets/images/pharma.jpg';
  static const String dashboard = 'assets/images/dashbord.jpg';
  static const String logo = 'assets/images/med.png';           // MedIaChain logo

  // Network Fallbacks (Unsplash) - Kept for safety
  static const String welcomeBgUrl = 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?q=80&w=2070&auto=format&fit=crop';
  static const String checkinUrl = 'https://images.unsplash.com/photo-1550989460-0adf9ea622e2?q=80&w=687&auto=format&fit=crop';
  static const String triageUrl = 'https://images.unsplash.com/photo-1516574187841-693083f69454?q=80&w=2070&auto=format&fit=crop';
  static const String doctorUrl = 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=1964&auto=format&fit=crop';
  static const String pharmaUrl = 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?q=80&w=2069&auto=format&fit=crop';
  static const String dashboardUrl = 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?q=80&w=2070&auto=format&fit=crop';
  static const String heroUrl = 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?q=80&w=2070&auto=format&fit=crop';

  static ImageProvider provider(String assetPath, String networkUrl) {
    // SWITCHED TO ASSET IMAGE as requested
    return AssetImage(assetPath);
  }
}
