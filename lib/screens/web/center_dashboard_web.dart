import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/web/web_sidebar.dart';
import '../../widgets/web/web_header.dart';
import '../auth/login_web_screen.dart';
import '../centre_analyse/center_patients_screen.dart';
import 'center_notifications_screen.dart';
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
  int _rejectedCount = 0;
  int _todayCount = 0;
  int _totalPatients = 0;
  List<int> _weeklyAnalyses = [0, 0, 0, 0, 0, 0, 0]; // Lundi to Dimanche
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
        final now = DateTime.now();
        // Calculer les statistiques
        final pending = appointments.where((apt) {
          final status = apt['status']?.toString().toLowerCase() ?? '';
          return status == 'pending';
        }).length;

        final accepted = appointments.where((apt) {
          final status = apt['status']?.toString().toLowerCase() ?? '';
          return status == 'accepted';
        }).length;

        final rejected = appointments.where((apt) {
          final status = apt['status']?.toString().toLowerCase() ?? '';
          return status == 'rejected';
        }).length;

        final today = appointments.where((apt) {
          try {
            final date = DateTime.parse(apt['appointmentDate'] ?? '');
            return date.year == now.year && date.month == now.month && date.day == now.day;
          } catch (e) {
            return false;
          }
        }).length;

        // Calculer le nombre total de patients uniques (basé sur les RDV acceptés)
        final uniquePatients = appointments
            .where((apt) => apt['status']?.toString().toLowerCase() == 'accepted')
            .map((apt) => apt['patientId']?['_id'] ?? apt['patientId'])
            .where((id) => id != null)
            .toSet()
            .length;

        // Calculer les analyses hebdomadaires (Lundi au Dimanche)
        final List<int> weekly = [0, 0, 0, 0, 0, 0, 0];
        // Commencer par lundi de cette semaine
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));

        for (var apt in appointments) {
          try {
            final date = DateTime.parse(apt['appointmentDate'] ?? '');
            if (date.isAfter(monday.subtract(const Duration(seconds: 1))) &&
                date.isBefore(sunday.add(const Duration(days: 1)))) {
              final dayIndex = date.weekday - 1; // 0 for Monday, 6 for Sunday in Dart
              if (dayIndex >= 0 && dayIndex < 7) {
                weekly[dayIndex]++;
              }
            }
          } catch (e) {
            // Ignorer les formats de date invalides
          }
        }

        setState(() {
          _appointments = appointments;
          _pendingCount = pending;
          _acceptedCount = accepted;
          _rejectedCount = rejected;
          _todayCount = today;
          _totalPatients = uniquePatients;
          _weeklyAnalyses = weekly;
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
      _handleLogout();
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

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              // Retourner à l'écran de login web (sans changer l'URL -> évite 404 si l'app est servie derrière un backend sans rewrite)
              Navigator.of(this.context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginWebScreen()),
                (route) => false,
              );
            },
            child: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Réception demandes';
      case 2:
        return 'Prescriptions médecins';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome & Analytics
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildWorkStatCard(
                            'RDV AUJOURD\'HUI',
                            _todayCount.toString(),
                            'Programmes',
                            AppColors.primary,
                            Icons.calendar_today_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildWorkStatCard(
                            'TOTAL PATIENTS',
                            _totalPatients.toString(),
                            'Habituels',
                            AppColors.secondary,
                            Icons.people_alt_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildWorkStatCard(
                            'ATTENTE',
                            _pendingCount.toString(),
                            'Demandes',
                            AppColors.warning,
                            Icons.hourglass_empty_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildWeeklyAnalysesChart(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Profile & RDV Status
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    _buildRDVStatusChart(),
                  ],
                ),
              ),
            ],
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
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
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
                const SizedBox.shrink(),
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
                      color: AppColors.primary.withOpacity(0.3),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              Icon(icon, color: color.withOpacity(0.5), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            metric,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comparison,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRDVStatusChart() {
    final total = _pendingCount + _acceptedCount + _rejectedCount;
    final pendingPercent = total > 0 ? (_pendingCount / total * 100).toInt() : 0;
    final acceptedPercent = total > 0 ? (_acceptedCount / total * 100).toInt() : 0;
    final rejectedPercent = total > 0 ? (_rejectedCount / total * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STATISTIQUES RDV',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('Global', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.primary,
                        value: _acceptedCount.toDouble(),
                        title: '',
                        radius: 20,
                      ),
                      PieChartSectionData(
                        color: AppColors.primary.withOpacity(0.4),
                        value: _pendingCount.toDouble(),
                        title: '',
                        radius: 20,
                      ),
                      PieChartSectionData(
                        color: AppColors.primary.withOpacity(0.1),
                        value: _rejectedCount.toDouble(),
                        title: '',
                        radius: 20,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        total.toString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildLegendItem('Acceptés', '$acceptedPercent%', AppColors.primary),
          const SizedBox(height: 12),
          _buildLegendItem('En attente', '$pendingPercent%', AppColors.primary.withOpacity(0.4)),
          const SizedBox(height: 12),
          _buildLegendItem('Refusés', '$rejectedPercent%', AppColors.primary.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyAnalysesChart() {
    final days = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
    final maxVal = _weeklyAnalyses.isEmpty ? 1 : _weeklyAnalyses.reduce((a, b) => a > b ? a : b).toDouble();
    final yInterval = maxVal > 5 ? (maxVal / 5).ceil().toDouble() : 1.0;

    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ANALYSES RÉALISÉES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total semaine: ${_weeklyAnalyses.fold(0, (sum, item) => sum + item)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('Cette semaine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxVal == 0 ? 5 : maxVal) + ((maxVal == 0 ? 5 : maxVal) * 0.2),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${days[groupIndex]}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: rod.toY.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= days.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval == 0 ? 1 : yInterval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval == 0 ? 1 : yInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _weeklyAnalyses[index].toDouble(),
                        color: AppColors.primary,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: (maxVal == 0 ? 5 : maxVal) + ((maxVal == 0 ? 5 : maxVal) * 0.2),
                          color: AppColors.background,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

}