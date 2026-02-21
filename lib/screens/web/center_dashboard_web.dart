import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/web/web_sidebar.dart';
import '../../widgets/web/web_header.dart';
import '../centre_analyse/center_patients_screen.dart';
import '../centre_analyse/center_notifications_screen.dart';
import 'results_upload_screen.dart';
import 'results_history_screen.dart';
import 'digital_signature_screen.dart';
import 'prescriptions_web_screen.dart';
import 'center_profile_web_screen.dart';
import 'patients_web_screen.dart';

/// Dashboard web pour les centres d'analyse
class CenterDashboardWeb extends StatefulWidget {
  const CenterDashboardWeb({super.key});

  @override
  State<CenterDashboardWeb> createState() => _CenterDashboardWebState();
}

class _CenterDashboardWebState extends State<CenterDashboardWeb> {
  int _selectedIndex = 0;
  String? _labName;
  bool _isLoadingProfile = true;
  
  // Profil du centre
  Map<String, dynamic> _labProfile = {};
  
  // Statistiques
  int _pendingCount = 0;
  int _acceptedCount = 0;
  bool _isLoadingStats = true;
  List<Map<String, dynamic>> _appointments = [];
  
  // Calendrier
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLabProfile();
    _loadStatistics();
  }

  Future<void> _loadLabProfile() async {
    try {
      debugPrint('🔵 Dashboard Web: Chargement du profil lab...');
      final labProfile = await ApiService.getLabProfile();
      debugPrint('✅ Dashboard Web: Profil récupéré: $labProfile');
      
      if (mounted) {
        setState(() {
          _labProfile = labProfile;
          _labName = labProfile['name'] ?? 
                    labProfile['centreName'] ?? 
                    labProfile['centre_name'] ??
                    'Centre d\'Analyses';
          debugPrint('✅ Dashboard Web: Nom du centre: $_labName');
          debugPrint('✅ Dashboard Web: Email: ${labProfile['email']}');
          debugPrint('✅ Dashboard Web: Phone: ${labProfile['phone']}');
          debugPrint('✅ Dashboard Web: Localisation: ${labProfile['localisation']}');
          debugPrint('✅ Dashboard Web: Catégories: ${labProfile['categorie']}');
          final profilePhotoPath = labProfile['profilePhoto'] ?? 
                                   labProfile['photo'] ?? 
                                   labProfile['photoUrl'] ?? 
                                   labProfile['image'] ?? 
                                   labProfile['imageUrl'] ?? 
                                   labProfile['logo'] ?? 
                                   labProfile['logoUrl'] ?? 
                                   '';
          debugPrint('✅ Dashboard Web: ProfilePhotoPath: $profilePhotoPath');
          _isLoadingProfile = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Dashboard Web: Erreur lors du chargement du profil: $e');
      debugPrint('❌ Dashboard Web: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);

    try {
      final appointments = await ApiService.getLabAppointments();
      
      if (mounted) {
        // Calculer les statistiques
        final pending = appointments.where((apt) {
          final status = apt['status']?.toString().toLowerCase() ?? '';
          return status == 'pending';
        }).length;

        final accepted = appointments.where((apt) {
          final status = apt['status']?.toString().toLowerCase() ?? '';
          return status == 'accepted';
        }).length;

        // Compter les patients uniques
        final patientIds = <String>{};
        for (var apt in appointments) {
          final patientId = apt['patientId'];
          if (patientId != null) {
            final id = patientId is Map ? patientId['_id']?.toString() ?? patientId['id']?.toString() : patientId.toString();
            if (id != null) {
              patientIds.add(id);
            }
          }
        }

        setState(() {
          _appointments = appointments;
          _pendingCount = pending;
          _acceptedCount = accepted;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  void _onItemSelected(int index) {
    if (index == -1) {
      // Déconnexion gérée par le header
      return;
    }
    
    // Si on revient au dashboard, recharger le profil pour afficher les mises à jour
    if (index == 0 && _selectedIndex != 0) {
      _loadLabProfile();
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Réception demandes';
      case 2:
        return 'Prescriptions médecins';
      case 3:
        return 'Gestion RDV en ligne';
      case 5:
        return 'Upload résultats';
      case 6:
        return 'Signature numérique';
      case 7:
        return 'Historique';
      case 8:
        return 'Patients';
      case 9:
        return 'Notifications';
      case 10:
        return 'Paramètres';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return _buildReceptionDemandes();
      case 2:
        return _buildPrescriptions();
      case 3:
        return _buildGestionRDV();
      case 5:
        return const ResultsUploadScreen();
      case 6:
        return const DigitalSignatureScreen();
      case 7:
        return const ResultsHistoryScreen();
      case 8:
        return const PatientsWebScreen();
      case 9:
        return const CenterNotificationsScreen();
      case 10:
        return const CenterProfileWebScreen();
      default:
        return _buildDashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          // Sidebar
          WebSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
            labName: _labName,
          ),
          // Contenu principal
          Expanded(
            child: Column(
              children: [
                // Header
                WebHeader(title: _getPageTitle()),
                // Contenu
                Expanded(
                  child: _buildPageContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== PAGES DU DASHBOARD ==========

  Widget _buildDashboardHome() {
    if (_isLoadingStats || _isLoadingProfile) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de bienvenue
          Expanded(
            flex: 2,
            child: _buildWelcomeCard(),
          ),
          const SizedBox(width: 20),
          // Carte de profil
          Expanded(
            flex: 1,
            child: _buildProfileCard(),
          ),
        ],
      ),
    );
  }

  // ========== WIDGETS DU DASHBOARD ==========

  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final weekday = weekdays[now.weekday - 1];
    final formattedDate = '${months[now.month - 1]} ${now.day}, ${now.year}';
    final hour = now.hour;
    final period = hour < 12 ? 'am' : 'pm';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final formattedTime = '${displayHour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period';
    
    String greeting = 'Bonjour';
    if (hour < 12) {
      greeting = 'Bonjour';
    } else if (hour < 18) {
      greeting = 'Bon après-midi';
    } else {
      greeting = 'Bonsoir';
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 180, maxHeight: 180),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$formattedDate $formattedTime',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                '$greeting, ${_labName ?? 'Centre'}!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Passez une excellente $weekday!',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final localisation = _labProfile['localisation'] ?? 'Non spécifié';
    final email = _labProfile['email'] ?? '';
    final phone = _labProfile['phone'] ?? '';
    final categories = _labProfile['categorie'] ?? [];
    final categoryList = categories is List ? List<String>.from(categories) : (categories.toString().isNotEmpty ? [categories.toString()] : []);
    final mainCategory = categoryList.isNotEmpty ? categoryList.first.toUpperCase() : 'LABORATOIRE';
    // Le backend utilise 'profilePhoto' comme champ principal
    final profilePhotoPath = _labProfile['profilePhoto'] ?? 
                              _labProfile['photo'] ?? 
                              _labProfile['photoUrl'] ?? 
                              _labProfile['image'] ?? 
                              _labProfile['imageUrl'] ?? 
                              _labProfile['logo'] ?? 
                              _labProfile['logoUrl'] ?? 
                              '';
    
    // Construire l'URL complète si c'est un chemin relatif
    // Utiliser la route API qui gère mieux CORS
    String profileImage = '';
    if (profilePhotoPath.isNotEmpty) {
      if (profilePhotoPath.startsWith('http')) {
        profileImage = profilePhotoPath;
      } else {
        // Essayer d'abord la route API qui gère mieux CORS
        // Format: /lab/uploads/profiles/filename.png
        final filename = profilePhotoPath.split('/').last;
        profileImage = '${ApiService.baseUrl}/lab/uploads/profiles/$filename';
        debugPrint('🔵 Dashboard Web: URL image (route API): $profileImage');
      }
    }
    
    debugPrint('🔵 Dashboard Web: ProfilePhotoPath: $profilePhotoPath');
    debugPrint('🔵 Dashboard Web: ProfileImage URL finale: $profileImage');
    debugPrint('🔵 Dashboard Web: ProfileImage isNotEmpty: ${profileImage.isNotEmpty}');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header violet
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MON PROFIL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onItemSelected(10),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Corps blanc
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Photo de profil circulaire
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: profileImage.isNotEmpty
                        ? Image.network(
                            '$profileImage?t=${DateTime.now().millisecondsSinceEpoch}',
                            fit: BoxFit.cover,
                            cacheWidth: 200,
                            cacheHeight: 200,
                            headers: const {
                              'Accept': 'image/*',
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('❌ Dashboard Web: Erreur chargement image: $error');
                              debugPrint('❌ Dashboard Web: URL: $profileImage');
                              
                              // Fallback : essayer la route statique si la route API échoue
                              if (profileImage.contains('/lab/uploads/profiles/')) {
                                final filename = profileImage.split('/').last.split('?').first;
                                final alternativeUrl = '${ApiService.baseUrl}/uploads/lab-profiles/$filename';
                                debugPrint('🔄 Dashboard Web: Tentative route statique: $alternativeUrl');
                                return Image.network(
                                  '$alternativeUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                                  fit: BoxFit.cover,
                                  cacheWidth: 200,
                                  cacheHeight: 200,
                                  headers: const {
                                    'Accept': 'image/*',
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.local_hospital_rounded,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                );
                              }
                              
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.local_hospital_rounded,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Nom
                Text(
                  _labName ?? 'Centre d\'Analyses',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Localisation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        localisation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }



  Widget _buildWorkStatCard(String title, String metric, String comparison, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          // Graphique simple (barre ou ligne)
              Container(
            height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
                ),
            child: Center(
              child: Icon(icon, color: color, size: 32),
              ),
          ),
          const SizedBox(height: 16),
          Text(
            metric,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comparison,
            style: TextStyle(
              fontSize: 12,
              color: comparison.startsWith('+') ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    final now = DateTime.now();
    final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    final weekdays = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    
    // Obtenir le premier jour du mois et le nombre de jours
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7; // 0 = Dimanche
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MON CALENDRIER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              DropdownButton<String>(
                value: months[_selectedDate.month - 1],
                underline: Container(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
              fontSize: 14,
                ),
                dropdownColor: AppColors.primary,
                items: months.map((month) {
                  return DropdownMenuItem(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final monthIndex = months.indexOf(value);
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, monthIndex + 1, _selectedDate.day);
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // En-têtes des jours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Grille du calendrier
          ...List.generate(6, (weekIndex) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                final isCurrentMonth = dayNumber > 0 && dayNumber <= lastDay.day;
                final isToday = isCurrentMonth &&
                    dayNumber == now.day &&
                    _selectedDate.month == now.month &&
                    _selectedDate.year == now.year;
                final isSelected = isCurrentMonth &&
                    dayNumber == _selectedDate.day;
                
                if (!isCurrentMonth) {
                  return const Expanded(child: SizedBox());
                }
                
    return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
                      });
                    },
        child: Container(
                      margin: const EdgeInsets.all(2),
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScheduledEventsCard() {
    final todayAppointments = _appointments.where((apt) {
      try {
        final aptDate = DateTime.parse(apt['appointmentDate'] ?? '');
        return aptDate.year == _selectedDate.year &&
               aptDate.month == _selectedDate.month &&
               aptDate.day == _selectedDate.day;
      } catch (e) {
        return false;
      }
    }).toList();
    
    final totalEvents = todayAppointments.length;
    final consultations = todayAppointments.where((apt) {
      final type = apt['analysisType']?.toString().toLowerCase() ?? '';
      return type.contains('consultation') || type.isEmpty;
    }).length;
    final labAnalyses = todayAppointments.where((apt) {
      final type = apt['analysisType']?.toString().toLowerCase() ?? '';
      return !type.contains('consultation') && type.isNotEmpty;
    }).length;
    final meetings = 0; // TODO: Ajouter les meetings si disponibles
    
    final busyness = totalEvents > 0 ? ((totalEvents / 20) * 100).clamp(0, 100).toInt() : 0;

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MES ÉVÉNEMENTS PLANIFIÉS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              DropdownButton<String>(
                value: 'Aujourd\'hui',
                underline: Container(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                items: const [
                  DropdownMenuItem(value: 'Aujourd\'hui', child: Text('Aujourd\'hui')),
                  DropdownMenuItem(value: 'Cette semaine', child: Text('Cette semaine')),
                  DropdownMenuItem(value: 'Ce mois', child: Text('Ce mois')),
                ],
                onChanged: (value) {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Graphique circulaire de busyness
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: busyness / 100,
                      strokeWidth: 12,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.secondary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
              Text(
                        '$busyness%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'OCCUPÉ',
                style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                          letterSpacing: 1,
                ),
              ),
            ],
          ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Détails
          _buildEventDetail('$consultations Consultations', AppColors.primary),
          const SizedBox(height: 8),
          _buildEventDetail('$labAnalyses Analyses de laboratoire', AppColors.info),
          const SizedBox(height: 8),
          _buildEventDetail('$meetings Réunions', AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildEventDetail(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
              Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlansDoneCard() {
    final todayAppointments = _appointments.where((apt) {
      try {
        final aptDate = DateTime.parse(apt['appointmentDate'] ?? '');
        return aptDate.year == _selectedDate.year &&
               aptDate.month == _selectedDate.month &&
               aptDate.day == _selectedDate.day;
      } catch (e) {
        return false;
      }
    }).toList();
    
    final consultations = todayAppointments.where((apt) {
      final type = apt['analysisType']?.toString().toLowerCase() ?? '';
      return type.contains('consultation') || type.isEmpty;
    }).length;
    final analyses = todayAppointments.where((apt) {
      final type = apt['analysisType']?.toString().toLowerCase() ?? '';
      return !type.contains('consultation') && type.isNotEmpty;
    }).length;
    final meetings = 0;
    
    final consultationsPercent = consultations > 0 ? ((consultations / 10) * 100).clamp(0, 100).toInt() : 0;
    final analysesPercent = analyses > 0 ? ((analyses / 10) * 100).clamp(0, 100).toInt() : 0;
    final meetingsPercent = meetings > 0 ? ((meetings / 5) * 100).clamp(0, 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MES PLANS TERMINÉS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              DropdownButton<String>(
                value: 'Aujourd\'hui',
                underline: Container(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                items: const [
                  DropdownMenuItem(value: 'Aujourd\'hui', child: Text('Aujourd\'hui')),
                  DropdownMenuItem(value: 'Cette semaine', child: Text('Cette semaine')),
                  DropdownMenuItem(value: 'Ce mois', child: Text('Ce mois')),
                ],
                onChanged: (value) {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Barres de progression
          _buildProgressBar('Consultations', consultationsPercent, AppColors.primary),
          const SizedBox(height: 16),
          _buildProgressBar('Analyses', analysesPercent, AppColors.warning),
          const SizedBox(height: 16),
          _buildProgressBar('Réunions', meetingsPercent, AppColors.secondary),
          const SizedBox(height: 20),
          // Bouton ajouter plan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Ouvrir dialog pour ajouter un plan
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter un plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$percent%',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
          ),
          const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsListCard(List<Map<String, dynamic>> appointments) {
    final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    final monthName = months[_selectedDate.month - 1];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$monthName, ${_selectedDate.day}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...appointments.take(5).map<Widget>((appointment) {
            final aptDate = DateTime.tryParse(appointment['appointmentDate'] ?? '');
            final time = aptDate != null
                ? '${aptDate.hour.toString().padLeft(2, '0')}:${aptDate.minute.toString().padLeft(2, '0')}'
                : '';
            final patientId = appointment['patientId'];
            String patientName = 'Patient';
            if (patientId != null && patientId is Map) {
              final firstName = patientId['firstName']?.toString() ?? '';
              final lastName = patientId['lastName']?.toString() ?? '';
              if (firstName.isNotEmpty || lastName.isNotEmpty) {
                patientName = '${firstName.trim()} ${lastName.trim()}'.trim();
              } else {
                patientName = patientId['email']?.toString() ?? 'Patient';
              }
            }
            final analysisType = appointment['analysisType']?.toString() ?? '';
            final typeLabel = analysisType.isNotEmpty ? analysisType : 'Consultation';
            
            // Couleur selon le type
            Color dotColor = AppColors.primary;
            if (typeLabel.toLowerCase().contains('consultation')) {
              dotColor = AppColors.info;
            } else if (typeLabel.toLowerCase().contains('examen')) {
              dotColor = AppColors.secondary;
            } else {
              dotColor = AppColors.success;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$time $typeLabel avec $patientName',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReceptionDemandes() {
    // Afficher les demandes en attente avec un filtre
    return CenterPatientsScreen();
  }

  Widget _buildPrescriptions() {
    return const PrescriptionsWebScreen();
  }

  Widget _buildGestionRDV() {
    return const CenterPatientsScreen();
  }

}
