import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class DoctorsManagementView extends StatefulWidget {
  const DoctorsManagementView({super.key});

  @override
  State<DoctorsManagementView> createState() => _DoctorsManagementViewState();
}

class _DoctorsManagementViewState extends State<DoctorsManagementView> {
  late Future<List<dynamic>> _futureDoctors;

  @override
  void initState() {
    super.initState();
    _futureDoctors = ApiService.getDoctorsByClinic();
  }

  void _refreshDoctors() {
    setState(() {
      _futureDoctors = ApiService.getDoctorsByClinic();
    });
  }

  void _showAddDoctorDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddDoctorDialog(
        onDoctorAdded: _refreshDoctors,
      ),
    );
  }

  void _showEditDoctorDialog(dynamic clinicDoctor) {
    showDialog(
      context: context,
      builder: (context) => _EditDoctorDialog(
        clinicDoctor: clinicDoctor,
        onDoctorUpdated: _refreshDoctors,
      ),
    );
  }

  void _deleteDoctor(String clinicDoctorId) async {
    try {
      await ApiService.removeDoctor(clinicDoctorId);
      _refreshDoctors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Médecin retiré.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Staff Médical',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNavy,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.primaryMedical),
                  onPressed: _refreshDoctors,
                ),
                ElevatedButton.icon(
                  onPressed: _showAddDoctorDialog,
                  icon: const Icon(Icons.add, size: 20, color: Colors.white),
                  label: const Text('Ajouter un médecin', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMedical,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FutureBuilder<List<dynamic>>(
              future: _futureDoctors,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryMedical));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun médecin trouvé pour cette clinique.'));
                }

                final doctors = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: doctors.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.grey.withOpacity(0.2)),
                  itemBuilder: (context, index) {
                    final doc = doctors[index];
                    final bool isActive = doc['status'] == 'active';
                    final String safeName = doc['fullName'] ?? 'Inconnu';
                    final String safeSpeciality = doc['speciality'] ?? 'Non spécifiée';
                    final String safeEmail = doc['email'] ?? 'Sans email';
                    final String initial = safeName.length > 4 ? safeName.substring(4, 5) : 'X';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryMedical.withOpacity(0.1),
                        child: Text(
                          initial.toUpperCase(),
                          style: const TextStyle(color: AppTheme.primaryMedical, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        safeName,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                      ),
                      subtitle: Text('$safeSpeciality • $safeEmail'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'Actif' : 'Inactif',
                              style: TextStyle(
                                color: isActive ? AppTheme.success : AppTheme.error,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => _showEditDoctorDialog(doc)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDoctor(doc['_id'])),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AddDoctorDialog extends StatefulWidget {
  final VoidCallback onDoctorAdded;
  const _AddDoctorDialog({required this.onDoctorAdded});

  @override
  State<_AddDoctorDialog> createState() => _AddDoctorDialogState();
}

class _AddDoctorDialogState extends State<_AddDoctorDialog> {
  bool _isLoading = true;
  List<dynamic> _availableDoctors = [];
  String? _selectedDoctorId;
  String? _selectedSpeciality;

  final List<String> _specialities = [
    'Cardiologie', 'Dermatologie', 'Gynécologie', 'Pédiatrie', 
    'Neurologie', 'Ophtalmologie', 'Orthopédie', 'Médecine Générale',
    'Psychiatrie', 'Radiologie', 'Urologie', 'ORL'
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final docs = await ApiService.getAvailableDoctors();
      if (mounted) {
        setState(() {
          _availableDoctors = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Ajouter un médecin', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      content: _isLoading 
        ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppTheme.primaryMedical)))
        : SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sélectionnez un médecin inscrit sur la plateforme.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Médecin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  value: _selectedDoctorId,
                  items: _availableDoctors.map((doc) {
                    final email = doc['email'] ?? 'Sans email';
                    return DropdownMenuItem<String>(
                      value: doc['_id'],
                      child: Text(email),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDoctorId = val),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Spécialité',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.medical_services),
                  ),
                  value: _selectedSpeciality,
                  items: _specialities.map((spec) => DropdownMenuItem<String>(value: spec, child: Text(spec))).toList(),
                  onChanged: (val) => setState(() => _selectedSpeciality = val),
                ),
              ],
            ),
          ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryMedical,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _selectedDoctorId == null || _selectedSpeciality == null ? null : () async {
            try {
              final selectedDoc = _availableDoctors.firstWhere((d) => d['_id'] == _selectedDoctorId);
              // Provide a fallback name if fullName isn't returned from search endpoint
              final name = selectedDoc['fullName'] ?? selectedDoc['email'];
              
              await ApiService.addDoctor(_selectedDoctorId!, name, selectedDoc['email'] ?? '', _selectedSpeciality!);
              if (context.mounted) Navigator.pop(context);
              widget.onDoctorAdded();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            }
          },
          child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _EditDoctorDialog extends StatefulWidget {
  final dynamic clinicDoctor;
  final VoidCallback onDoctorUpdated;

  const _EditDoctorDialog({required this.clinicDoctor, required this.onDoctorUpdated});

  @override
  State<_EditDoctorDialog> createState() => _EditDoctorDialogState();
}

class _EditDoctorDialogState extends State<_EditDoctorDialog> {
  String _selectedStatus = 'active';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.clinicDoctor['status'] == 'inactive' ? 'inactive' : 'active';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Modifier le médecin', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Statut au sein de la clinique',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            value: _selectedStatus,
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Actif (Reçoit des patients)')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactif (En congé / Absent)')),
            ],
            onChanged: (val) => setState(() => _selectedStatus = val!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryMedical,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            try {
              await ApiService.changeDoctorStatus(widget.clinicDoctor['_id'], _selectedStatus);
              if (context.mounted) Navigator.pop(context);
              widget.onDoctorUpdated();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            }
          },
          child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

