import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../centre_analyse/patient_history_screen.dart';

/// Écran web pour afficher les patients acceptés sous forme de dossiers
class PatientsWebScreen extends StatefulWidget {
  const PatientsWebScreen({super.key});

  @override
  State<PatientsWebScreen> createState() => _PatientsWebScreenState();
}

class _PatientsWebScreenState extends State<PatientsWebScreen> {
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appointments = await ApiService.getLabAppointments();
      
      // Extraire les patients uniques avec statut "accepted"
      final Map<String, Map<String, dynamic>> uniquePatients = {};
      
      for (var appointment in appointments) {
        final status = appointment['status']?.toString().toLowerCase();
        if (status == 'accepted') {
          final patientId = appointment['patientId'];
          if (patientId != null && patientId is Map) {
            final patientMap = Map<String, dynamic>.from(patientId);
            final patientIdStr = patientMap['_id']?.toString() ?? 
                                 patientMap['id']?.toString() ?? 
                                 '';
            
            if (patientIdStr.isNotEmpty && !uniquePatients.containsKey(patientIdStr)) {
              // Compter le nombre de rendez-vous acceptés pour ce patient
              final appointmentCount = appointments.where((apt) {
                final aptStatus = apt['status']?.toString().toLowerCase();
                final aptPatientId = apt['patientId'];
                if (aptPatientId != null && aptPatientId is Map) {
                  final aptPatientMap = Map<String, dynamic>.from(aptPatientId);
                  final aptPatientIdStr = aptPatientMap['_id']?.toString() ?? 
                                         aptPatientMap['id']?.toString() ?? '';
                  return aptStatus == 'accepted' && aptPatientIdStr == patientIdStr;
                }
                return false;
              }).length;

              uniquePatients[patientIdStr] = {
                ...patientMap,
                'appointmentCount': appointmentCount,
              };
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _patients = uniquePatients.values.toList();
          _filteredPatients = _patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterPatients(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((patient) {
          final firstName = patient['firstName']?.toString().toLowerCase() ?? '';
          final lastName = patient['lastName']?.toString().toLowerCase() ?? '';
          final email = patient['email']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return firstName.contains(searchLower) ||
                 lastName.contains(searchLower) ||
                 email.contains(searchLower);
        }).toList();
      }
    });
  }

  String _getPatientName(Map<String, dynamic> patient) {
    final firstName = patient['firstName']?.toString() ?? '';
    final lastName = patient['lastName']?.toString() ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '${firstName.trim()} ${lastName.trim()}'.trim();
    }
    return patient['email']?.toString().split('@')[0] ?? 'Patient';
  }

  String _getPatientEmail(Map<String, dynamic> patient) {
    return patient['email']?.toString() ?? '';
  }

  void _openPatientHistory(Map<String, dynamic> patient) {
    final patientId = patient['_id']?.toString() ?? 
                     patient['id']?.toString() ?? '';
    final patientName = _getPatientName(patient);
    final patientEmail = _getPatientEmail(patient);
    
    if (patientId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientHistoryScreen(
            patientId: patientId,
            patientName: patientName,
            patientEmail: patientEmail, // Passer l'email directement
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche et filtre
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Barre de recherche
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: _filterPatients,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Bouton Filter
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter le filtre
                  },
                  icon: const Icon(Icons.filter_list_rounded, size: 20),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Grille de patients
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 64,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun patient accepté'
                                  : 'Aucun résultat trouvé',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = _filteredPatients[index];
                            final patientName = _getPatientName(patient);
                            final patientEmail = _getPatientEmail(patient);
                            final appointmentCount = patient['appointmentCount'] ?? 0;

                            return _buildPatientCard(
                              patientName,
                              patientEmail,
                              appointmentCount,
                              () => _openPatientHistory(patient),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(
    String name,
    String email,
    int appointmentCount,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Petit carré gris en haut à gauche
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Contenu principal
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image dossier violet
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Image.asset(
                        'assets/images/dossier_violet.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('❌ Erreur chargement image dossier_violet.jpg: $error');
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.folder_rounded,
                              color: AppColors.primary,
                              size: 60,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nom du patient
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Email
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Nombre de rendez-vous
                    Text(
                      '$appointmentCount ${appointmentCount > 1 ? 'rendez-vous' : 'rendez-vous'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
