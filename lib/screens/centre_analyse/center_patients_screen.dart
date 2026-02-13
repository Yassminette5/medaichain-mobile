import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import 'patient_history_screen.dart';

/// Écran de liste des demandes de rendez-vous pour le centre d'analyse
class CenterPatientsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialAppointment;
  
  const CenterPatientsScreen({
    super.key,
    this.initialAppointment,
  });

  @override
  State<CenterPatientsScreen> createState() => _CenterPatientsScreenState();
}

class _CenterPatientsScreenState extends State<CenterPatientsScreen> {
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _filteredAppointments = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'Toutes'; // 'Toutes', 'En attente', 'Acceptées', 'Refusées'

  @override
  void initState() {
    super.initState();
    _filteredAppointments = [];
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appointments = await ApiService.getLabAppointments();
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String _getStatusLabel(String? status, String? appointmentId) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Accepté';
      case 'rejected':
        return 'Refusé';
      default:
        return 'En attente';
    }
  }

  Color _getStatusColor(String? status, String? appointmentId) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _getAnalysisTypeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'analyse_sanguin':
        return 'Analyse sanguine';
      case 'scanner':
        return 'Scanner';
      case 'radiologie':
        return 'Radiologie';
      case 'imagerie':
        return 'Imagerie';
      case 'biologie':
        return 'Biologie';
      default:
        return type ?? 'Autre';
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_appointments);

    // Filtrer par statut
    if (_selectedFilter == 'En attente') {
      filtered = filtered.where((apt) {
        final status = apt['status']?.toString().toLowerCase() ?? '';
        return status == 'pending';
      }).toList();
    } else if (_selectedFilter == 'Acceptées') {
      filtered = filtered.where((apt) {
        final status = apt['status']?.toString().toLowerCase() ?? '';
        return status == 'accepted';
      }).toList();
    } else if (_selectedFilter == 'Refusées') {
      filtered = filtered.where((apt) {
        final status = apt['status']?.toString().toLowerCase() ?? '';
        return status == 'rejected';
      }).toList();
    }
    // 'Toutes' ne filtre pas par statut mais inclut tout

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((apt) {
        final patientId = apt['patientId'];
        String patientName = '';
        
        if (patientId != null && patientId is Map) {
          final firstName = patientId['firstName']?.toString() ?? '';
          final lastName = patientId['lastName']?.toString() ?? '';
          patientName = '${firstName.trim()} ${lastName.trim()}'.trim();
          if (patientName.isEmpty) {
            patientName = patientId['name']?.toString() ?? patientId['email']?.toString() ?? '';
          }
        }
        
        final analysisType = _getAnalysisTypeLabel(apt['analysisType']?.toString());
        
        return patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               analysisType.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredAppointments = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Patients',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher un patient...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                // Filtres
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterButton('Toutes', _selectedFilter == 'Toutes'),
                      const SizedBox(width: 8),
                      _buildFilterButton('En attente', _selectedFilter == 'En attente'),
                      const SizedBox(width: 8),
                      _buildFilterButton('Acceptées', _selectedFilter == 'Acceptées'),
                      const SizedBox(width: 8),
                      _buildFilterButton('Refusées', _selectedFilter == 'Refusées'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Liste des rendez-vous
                Expanded(
                  child: _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAppointments,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : _filteredAppointments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: AppColors.textLight,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Aucun résultat trouvé'
                                        : 'Aucun patient trouvé',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadAppointments,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredAppointments.length,
                                itemBuilder: (context, index) {
                                  return _buildAppointmentCard(_filteredAppointments[index]);
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final appointmentDate = appointment['appointmentDate'] ?? '';
    final status = appointment['status'] ?? 'pending';
    final analysisType = appointment['analysisType'] ?? '';
    
    // Récupérer les informations du patient depuis patientId (populate)
    final patientId = appointment['patientId'];
    String patientName = 'Patient';
    String? patientEmail;
    String? patientPhone;
    
    if (patientId != null && patientId is Map) {
      final firstName = patientId['firstName'] ?? '';
      final lastName = patientId['lastName'] ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        patientName = '${firstName.trim()} ${lastName.trim()}'.trim();
        if (patientName.isEmpty) {
          patientName = patientId['name'] ?? patientId['email'] ?? 'Patient';
        }
      } else {
        patientName = patientId['name'] ?? patientId['email'] ?? 'Patient';
      }
      patientEmail = patientId['email'];
      patientPhone = patientId['phone'];
    } else {
      // Fallback pour les anciennes structures
      patientName = appointment['patientName'] ?? 'Patient';
    }
    
    final hasAllergies = appointment['hasAllergies'] ?? false;
    final allergies = appointment['allergiesDetails'] ?? [];
    final hasTreatment = appointment['hasCurrentTreatment'] ?? false;
    final treatmentDetails = appointment['currentTreatmentDetails'] ?? '';
    final notes = appointment['notes'] ?? '';

    // Extraire l'ID du patient
    String? patientIdString;
    if (patientId != null && patientId is Map) {
      patientIdString = patientId['_id']?.toString() ?? patientId['id']?.toString();
    }

    return InkWell(
      onTap: () {
        if (patientIdString != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientHistoryScreen(
                patientId: patientIdString!,
                patientName: patientName,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Informations du patient
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(appointmentDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status, appointment['_id']?.toString() ?? appointment['id']?.toString()).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(status, appointment['_id']?.toString() ?? appointment['id']?.toString()).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _getStatusLabel(status, appointment['_id']?.toString() ?? appointment['id']?.toString()),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status, appointment['_id']?.toString() ?? appointment['id']?.toString()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionDialog(BuildContext context, Map<String, dynamic> appointment, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'accepter' ? 'Accepter le rendez-vous' : 'Mettre en attente'),
        content: Text(
          action == 'accepter'
              ? 'Voulez-vous accepter ce rendez-vous ?'
              : 'Voulez-vous mettre ce rendez-vous en attente ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter l'action
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rendez-vous ${action == 'accepter' ? 'accepté' : 'mis en attente'}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Envoyer une notification'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Message',
            hintText: 'Ex: La date est occupée, veuillez choisir une autre date',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter l'envoi de notification
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification envoyée'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
