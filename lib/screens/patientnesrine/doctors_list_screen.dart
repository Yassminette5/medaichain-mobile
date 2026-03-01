import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import 'doctor_detail_sheet.dart';
import 'doctor.dart';

/// Écran liste des médecins (depuis l'API) avec option "Demander l'accès"
class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final list = await ApiService.searchDoctors();
      if (mounted) setState(() { _doctors = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _showRequestAccessSheet(BuildContext context, Map<String, dynamic> doctor) {
    final reasonCtrl = TextEditingController();
    String urgency = 'normal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Demander l\'accès',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'À ${doctor['fullName'] ?? 'ce médecin'}',
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Raison de la demande *',
                    hintText: 'Ex: Consultation de suivi, accès historique médical...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: urgency,
                  decoration: InputDecoration(
                    labelText: 'Priorité',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Basse')),
                    DropdownMenuItem(value: 'normal', child: Text('Normale')),
                    DropdownMenuItem(value: 'high', child: Text('Urgente')),
                  ],
                  onChanged: (v) => setModalState(() => urgency = v ?? 'normal'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final reason = reasonCtrl.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Veuillez indiquer la raison'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      final u = doctor['userId'];
                      final doctorId = u is Map ? u['_id']?.toString() : u?.toString();
                      if (doctorId == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Médecin invalide'), backgroundColor: Colors.red));
                        return;
                      }
                      try {
                        final urgencyApi = urgency == 'high' ? 'urgent' : (urgency == 'low' ? 'normal' : urgency);
                        await ApiService.createAccessRequest(
                          doctorId: doctorId.toString(),
                          reason: reason,
                          urgency: urgencyApi,
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Demande envoyée'), backgroundColor: AppColors.success),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Envoyer la demande', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Médecins', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text('Erreur', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppColors.textGrey, fontSize: 12)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadDoctors, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _doctors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services_outlined, size: 64, color: AppColors.textGrey.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('Aucun médecin trouvé', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDoctors,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final d = _doctors[index];
                          final name = d['fullName'] ?? 'Médecin';
                          final speciality = d['speciality'] ?? 'Médecine générale';
                          final hospital = d['hospital'] ?? '';
                          final city = d['city'] ?? d['wilaya'] ?? '';
                          final u = d['userId'];
                          final doctorId = u is Map ? u['_id']?.toString() : u?.toString();
                          final doctorForDetail = Doctor(
                            name: name,
                            specialty: speciality,
                            hospital: hospital,
                            rating: 4.5,
                            reviews: 0,
                            experience: (d['yearsOfExperience'] as num?)?.toInt() ?? 0,
                            about: '',
                            imagePath: '',
                          );
                          final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            shadowColor: Colors.black.withValues(alpha: 0.08),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                        child: Text(
                                          initials.isNotEmpty ? initials : '?',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: AppColors.textDark,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              speciality,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: AppColors.textGrey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (hospital.isNotEmpty || city.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                [hospital, city].where((s) => s.isNotEmpty).join(' • '),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: AppColors.textGrey.withValues(alpha: 0.9),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (ctx) => DoctorDetailSheet(doctor: doctorForDetail, doctorId: doctorId),
                                        ),
                                        child: Text('Voir', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primary)),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: doctorId != null ? () => _showRequestAccessSheet(context, d) : null,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: Text('Demander l\'accès', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
