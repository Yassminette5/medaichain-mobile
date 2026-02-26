import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import 'patient_history_screen.dart';

/// Écran d'affichage des dossiers patients pour le centre d'analyse
class CenterPatientsScreen extends StatefulWidget {
  const CenterPatientsScreen({super.key});

  @override
  State<CenterPatientsScreen> createState() => _CenterPatientsScreenState();
}

class _CenterPatientsScreenState extends State<CenterPatientsScreen> {
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final appointments = await ApiService.getLabAppointments();
      
      // Extraire les patients uniques avec au moins un rendez-vous accepté
      final Map<String, Map<String, dynamic>> uniquePatients = {};
      
      for (var appointment in appointments) {
        final status = appointment['status']?.toString().toLowerCase();
        // On affiche les dossiers pour les patients acceptés
        if (status == 'accepted') {
          final patientData = appointment['patientId'];
          if (patientData != null && patientData is Map) {
            final patientMap = Map<String, dynamic>.from(patientData);
            final patientId = patientMap['_id']?.toString() ?? patientMap['id']?.toString() ?? '';
            
            if (patientId.isNotEmpty && !uniquePatients.containsKey(patientId)) {
              uniquePatients[patientId] = patientMap;
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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
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
        final lowerQuery = query.toLowerCase();
        _filteredPatients = _patients.where((patient) {
          final firstName = patient['firstName']?.toString().toLowerCase() ?? '';
          final lastName = patient['lastName']?.toString().toLowerCase() ?? '';
          final email = patient['email']?.toString().toLowerCase() ?? '';
          return firstName.contains(lowerQuery) || 
                 lastName.contains(lowerQuery) || 
                 email.contains(lowerQuery);
        }).toList();
      }
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
          'Dossiers Patients',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.8,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: _filterPatients,
              decoration: InputDecoration(
                hintText: 'Rechercher un patient...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredPatients.length,
                        itemBuilder: (context, index) {
                          return _buildPatientItem(_filteredPatients[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientItem(Map<String, dynamic> patient) {
    final firstName = patient['firstName'] ?? '';
    final lastName = patient['lastName'] ?? '';
    final name = '${firstName.trim()} ${lastName.trim()}'.trim();
    final displayName = name.isNotEmpty ? name : (patient['email']?.toString().split('@')[0] ?? 'Patient');
    final email = patient['email'] ?? '';
    final id = patient['_id']?.toString() ?? patient['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.folder_rounded, color: AppColors.primary),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        subtitle: Text(
          email,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
        onTap: () {
          if (id.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientHistoryScreen(
                  patientId: id,
                  patientName: displayName,
                  patientEmail: email,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Aucun patient trouvé' : 'Aucun résultat pour "$_searchQuery"',
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
