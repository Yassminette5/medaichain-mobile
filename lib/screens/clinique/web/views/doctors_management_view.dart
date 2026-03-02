import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medaichainmobile/clinique/theme/app_theme.dart';
import 'package:medaichainmobile/services/api_service.dart';

class DoctorsManagementView extends StatefulWidget {
  const DoctorsManagementView({super.key});

  @override
  State<DoctorsManagementView> createState() => _DoctorsManagementViewState();
}

class _DoctorsManagementViewState extends State<DoctorsManagementView> {
  late Future<List<dynamic>> _futureDoctors;
  String _searchQuery = '';

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
      barrierDismissible: false,
      builder: (context) => _AddDoctorDialog(onDoctorAdded: _refreshDoctors),
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

  void _confirmDeleteDoctor(String clinicDoctorId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Retirer le médecin', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.darkNavy)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[600]),
            children: [
              const TextSpan(text: 'Êtes-vous sûr de vouloir retirer '),
              TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
              const TextSpan(text: ' de votre clinique ?'),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.removeDoctor(clinicDoctorId);
                _refreshDoctors();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name a été retiré de la clinique'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: Text('Retirer', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======= HEADER =======
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMedical.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: AppTheme.primaryMedical, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Staff Médical', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.darkNavy)),
                    Text('Gérez les médecins de votre clinique', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                // Search
                Container(
                  width: 220,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerLight),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.textSecondary.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _refreshDoctors,
                  icon: const Icon(Icons.sync_rounded, color: AppTheme.primaryMedical),
                  tooltip: 'Rafraîchir',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAddDoctorDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text('Ajouter un médecin', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMedical,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ======= DOCTORS LIST =======
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _futureDoctors,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryMedical));
              } else if (snapshot.hasError) {
                return _buildEmptyState('Erreur de chargement', 'Vérifiez votre connexion et réessayez', Icons.error_outline_rounded);
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState('Aucun médecin', 'Ajoutez votre premier médecin à la clinique', Icons.people_outline_rounded);
              }

              List<dynamic> doctors = snapshot.data!;
              if (_searchQuery.isNotEmpty) {
                doctors = doctors.where((d) {
                  final name = (d['fullName'] ?? '').toString().toLowerCase();
                  final spec = (d['speciality'] ?? '').toString().toLowerCase();
                  final email = (d['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || spec.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: doctors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildDoctorCard(doctors[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(dynamic doc) {
    final bool isActive = doc['status'] == 'active';
    final String safeName = doc['fullName'] ?? 'Dr. Inconnu';
    final String safeSpeciality = doc['speciality'] ?? 'Non spécifiée';
    final String safeEmail = doc['email'] ?? 'Sans email';
    final String safePhone = doc['phone'] ?? '';
    final String initial = safeName.isNotEmpty ? safeName[0].toUpperCase() : 'D';

    // Color based on speciality
    final specColors = {
      'Cardiologie': const Color(0xFFE53935),
      'Dermatologie': const Color(0xFFFF7043),
      'Gynécologie': const Color(0xFFEC407A),
      'Pédiatrie': const Color(0xFF42A5F5),
      'Neurologie': const Color(0xFF7E57C2),
      'Ophtalmologie': const Color(0xFF26A69A),
      'Orthopédie': const Color(0xFF8D6E63),
      'Médecine Générale': AppTheme.primaryMedical,
      'Psychiatrie': const Color(0xFFAB47BC),
      'Radiologie': const Color(0xFF78909C),
      'Urologie': const Color(0xFF5C6BC0),
      'ORL': const Color(0xFF29B6F6),
      'Chirurgie': const Color(0xFFEF5350),
      'Anesthésie': const Color(0xFF66BB6A),
    };
    final specColor = specColors[safeSpeciality] ?? AppTheme.primaryMedical;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? AppTheme.dividerLight.withOpacity(0.5) : AppTheme.error.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [specColor.withOpacity(0.8), specColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: specColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Center(
              child: Text(initial, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Dr. $safeName',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkNavy),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: specColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        safeSpeciality,
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: specColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 13, color: AppTheme.textSecondary.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(safeEmail, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                    if (safePhone.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.phone_outlined, size: 13, color: AppTheme.textSecondary.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(safePhone, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isActive ? AppTheme.success : AppTheme.error).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (isActive ? AppTheme.success : AppTheme.error).withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.success : AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'Actif' : 'Inactif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: isActive ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Actions
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.darkNavy),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'edit') _showEditDoctorDialog(doc);
              if (val == 'delete') _confirmDeleteDoctor(doc['_id'], safeName);
            },
            itemBuilder: (_) => [
              _popupItem('edit', 'Modifier le statut', Icons.edit_rounded, AppTheme.primaryMedical),
              _popupItem('delete', 'Retirer de la clinique', Icons.person_remove_rounded, AppTheme.error),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String value, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.primaryMedical.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppTheme.primaryMedical.withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
          const SizedBox(height: 8),
          Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDoctorDialog,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: Text('Ajouter un médecin', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMedical,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  ADD DOCTOR DIALOG — Professional Clinic Form
// ============================================================
class _AddDoctorDialog extends StatefulWidget {
  final VoidCallback onDoctorAdded;
  const _AddDoctorDialog({required this.onDoctorAdded});

  @override
  State<_AddDoctorDialog> createState() => _AddDoctorDialogState();
}

class _AddDoctorDialogState extends State<_AddDoctorDialog> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _availableDoctors = [];
  String? _selectedDoctorId;
  String? _selectedSpeciality;
  int _currentStep = 0;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // Working days selection
  final Map<String, bool> _workingDays = {
    'Samedi': true,
    'Dimanche': true,
    'Lundi': true,
    'Mardi': true,
    'Mercredi': true,
    'Jeudi': true,
    'Vendredi': false,
  };

  String _startTime = '08:00';
  String _endTime = '17:00';

  final List<String> _specialities = [
    'Médecine Générale', 'Cardiologie', 'Dermatologie', 'Gynécologie',
    'Pédiatrie', 'Neurologie', 'Ophtalmologie', 'Orthopédie',
    'Psychiatrie', 'Radiologie', 'Urologie', 'ORL',
    'Chirurgie Générale', 'Anesthésie-Réanimation', 'Gastro-entérologie',
    'Pneumologie', 'Endocrinologie', 'Rhumatologie', 'Néphrologie',
    'Médecine Interne', 'Oncologie', 'Hématologie',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    try {
      final docs = await ApiService.getAvailableDoctors();
      if (mounted) {
        setState(() { _availableDoctors = docs; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDoctorSelected(String? doctorId) {
    if (doctorId == null) return;
    final doc = _availableDoctors.firstWhere((d) => d['_id'] == doctorId, orElse: () => null);
    if (doc != null) {
      setState(() {
        _selectedDoctorId = doctorId;
        _nameCtrl.text = doc['fullName'] ?? '';
        _emailCtrl.text = doc['email'] ?? '';
        _phoneCtrl.text = doc['phone'] ?? '';
      });
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _selectedSpeciality == null) return;
    setState(() => _isSaving = true);
    try {
      final doctorId = _selectedDoctorId ?? ApiService.generateObjectId();
      await ApiService.addDoctor(doctorId, _nameCtrl.text, _emailCtrl.text, _selectedSpeciality!);
      if (mounted && context.mounted) Navigator.pop(context);
      widget.onDoctorAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 160, vertical: 40),
      child: _isLoading
          ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: AppTheme.primaryMedical)))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ======= HEADER =======
                Container(
                  padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ajouter un médecin', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('Associez un médecin à votre clinique', style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      ),
                    ],
                  ),
                ),

                // ======= STEP INDICATOR =======
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: AppTheme.background,
                  child: Row(
                    children: [
                      _buildStepDot(0, 'Médecin'),
                      _buildStepLine(0),
                      _buildStepDot(1, 'Spécialité'),
                      _buildStepLine(1),
                      _buildStepDot(2, 'Planning'),
                    ],
                  ),
                ),

                // ======= FORM CONTENT =======
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentStep == 0
                          ? _buildStep1()
                          : _currentStep == 1
                              ? _buildStep2()
                              : _buildStep3(),
                    ),
                  ),
                ),

                // ======= ACTIONS =======
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.dividerLight.withOpacity(0.5))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        TextButton.icon(
                          onPressed: () => setState(() => _currentStep--),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: Text('Précédent', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                        )
                      else
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Annuler', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        ),
                      if (_currentStep < 2)
                        ElevatedButton.icon(
                          onPressed: _canGoNext() ? () => setState(() => _currentStep++) : null,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: Text('Suivant', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryMedical,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.primaryMedical.withOpacity(0.3),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _submit,
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(_isSaving ? 'Ajout...' : 'Ajouter le médecin', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  bool _canGoNext() {
    if (_currentStep == 0) return _nameCtrl.text.isNotEmpty;
    if (_currentStep == 1) return _selectedSpeciality != null;
    return true;
  }

  // ======= STEP 1: SELECT DOCTOR =======
  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Select from platform
        if (_availableDoctors.isNotEmpty) ...[
          _buildSectionTitle('Sélectionner depuis la plateforme', Icons.cloud_rounded),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.dividerLight),
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Choisir un médecin inscrit...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary.withOpacity(0.5)),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.person_search_rounded, size: 16, color: AppTheme.primaryMedical),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              value: _selectedDoctorId,
              isExpanded: true,
              items: _availableDoctors.map((doc) {
                final email = doc['email'] ?? '';
                final name = doc['fullName'] ?? email;
                return DropdownMenuItem<String>(
                  value: doc['_id'],
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primaryMedical.withOpacity(0.1),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryMedical)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(email, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _onDoctorSelected,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: AppTheme.dividerLight.withOpacity(0.5))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OU saisissez manuellement', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              ),
              Expanded(child: Divider(color: AppTheme.dividerLight.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 20),
        ],

        _buildSectionTitle('Informations du médecin', Icons.badge_rounded),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildFormField('Nom complet *', _nameCtrl, Icons.person_rounded, 'Dr. Ahmed Benmoussa')),
            const SizedBox(width: 14),
            Expanded(child: _buildFormField('Email', _emailCtrl, Icons.email_rounded, 'ahmed@example.com')),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildFormField('Téléphone', _phoneCtrl, Icons.phone_rounded, '+213 5XX XXX XXX')),
            const SizedBox(width: 14),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  // ======= STEP 2: SPECIALITY =======
  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Spécialité médicale', Icons.medical_services_rounded),
        const SizedBox(height: 6),
        Text('Sélectionnez la spécialité du médecin dans votre clinique', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _specialities.map((spec) {
            final isSelected = _selectedSpeciality == spec;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedSpeciality = spec),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryMedical : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryMedical : AppTheme.dividerLight,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppTheme.primaryMedical.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      spec,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.darkNavy,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Notes additionnelles', Icons.note_alt_rounded),
        const SizedBox(height: 12),
        _buildFormField('Notes (optionnel)', _noteCtrl, Icons.notes_rounded, 'Ex: Consultations le matin uniquement...', maxLines: 3),
      ],
    );
  }

  // ======= STEP 3: PLANNING =======
  Widget _buildStep3() {
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Jours de travail', Icons.calendar_today_rounded),
        const SizedBox(height: 6),
        Text('Définissez les jours de présence du médecin', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _workingDays.entries.map((entry) {
            final isActive = entry.value;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _workingDays[entry.key] = !entry.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.success.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isActive ? AppTheme.success : AppTheme.dividerLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: isActive ? AppTheme.success : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? AppTheme.success : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('Horaires de consultation', Icons.schedule_rounded),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTimePicker('Début', _startTime, (v) => setState(() => _startTime = v))),
            const SizedBox(width: 14),
            Expanded(child: _buildTimePicker('Fin', _endTime, (v) => setState(() => _endTime = v))),
          ],
        ),
        const SizedBox(height: 24),

        // Summary card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryMedical.withOpacity(0.05), AppTheme.primaryMedical.withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryMedical.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Récapitulatif', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.darkNavy)),
              const SizedBox(height: 12),
              _buildSummaryRow(Icons.person_rounded, 'Médecin', 'Dr. ${_nameCtrl.text}'),
              _buildSummaryRow(Icons.medical_services_rounded, 'Spécialité', _selectedSpeciality ?? '-'),
              _buildSummaryRow(Icons.email_rounded, 'Email', _emailCtrl.text.isNotEmpty ? _emailCtrl.text : '-'),
              _buildSummaryRow(Icons.schedule_rounded, 'Horaires', '$_startTime — $_endTime'),
              _buildSummaryRow(Icons.calendar_today_rounded, 'Jours', _workingDays.entries.where((e) => e.value).map((e) => e.key.substring(0, 3)).join(', ')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.primaryMedical.withOpacity(0.6)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkNavy))),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, String value, ValueChanged<String> onChanged) {
    final times = List.generate(24, (h) => ['${'$h'.padLeft(2, '0')}:00', '${'$h'.padLeft(2, '0')}:30']).expand((e) => e).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerLight),
          ),
          child: DropdownButtonFormField<String>(
            value: times.contains(value) ? value : null,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.primaryMedical),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: times.map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.plusJakartaSans(fontSize: 13)))).toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryMedical : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? AppTheme.primaryMedical : AppTheme.dividerLight, width: isCurrent ? 2 : 1),
              boxShadow: isCurrent ? [BoxShadow(color: AppTheme.primaryMedical.withOpacity(0.3), blurRadius: 8)] : null,
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : Text('${step + 1}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: isActive ? Colors.white : AppTheme.textSecondary)),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500, color: isCurrent ? AppTheme.primaryMedical : AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryMedical : AppTheme.dividerLight,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryMedical),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
      ],
    );
  }

  Widget _buildFormField(String label, TextEditingController ctrl, IconData icon, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.darkNavy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary.withOpacity(0.4)),
            prefixIcon: maxLines == 1
                ? Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 16, color: AppTheme.primaryMedical),
                  )
                : null,
            filled: true,
            fillColor: AppTheme.background,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.dividerLight.withOpacity(0.5))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.dividerLight.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryMedical, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ============================================================
//  EDIT DOCTOR DIALOG
// ============================================================
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
    final name = widget.clinicDoctor['fullName'] ?? 'Médecin';
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.edit_rounded, color: AppTheme.primaryMedical, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Modifier le statut', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.darkNavy)),
              Text('Dr. $name', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('active', 'Actif', 'Reçoit des patients normalement', Icons.check_circle_rounded, AppTheme.success),
            const SizedBox(height: 10),
            _buildStatusOption('inactive', 'Inactif', 'En congé ou temporairement absent', Icons.pause_circle_rounded, AppTheme.warning),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              await ApiService.changeDoctorStatus(widget.clinicDoctor['_id'], _selectedStatus);
              if (context.mounted) Navigator.pop(context);
              widget.onDoctorUpdated();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
              }
            }
          },
          icon: const Icon(Icons.save_rounded, size: 16),
          label: Text('Enregistrer', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryMedical,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusOption(String value, String title, String desc, IconData icon, Color color) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selectedStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : AppTheme.dividerLight, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.darkNavy)),
                  Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
