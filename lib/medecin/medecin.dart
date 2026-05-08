/// Package Médecin — point d'entrée (exports)
///
/// Objectif: structurer les écrans médecin dans `lib/medecin/` sans casser
/// les anciens imports (les anciens chemins dans `lib/screens/...` exportent
/// vers ces fichiers).
library;

export 'screens/web/medecin_web_dashboard.dart';
export 'screens/dashboard/dashboard_screen.dart';
export 'screens/profile/doctor_profile_screen.dart';
export 'screens/agenda/agenda_screen.dart';
export 'screens/agenda/add_consultation_dialog.dart';
export 'screens/prescription/create_prescription_screen.dart';

