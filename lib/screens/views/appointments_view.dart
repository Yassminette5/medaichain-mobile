import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AppointmentsView extends StatefulWidget {
  const AppointmentsView({super.key});

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView> {
  late Future<List<dynamic>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = ApiService.getAppointments();
  }

  void _refresh() {
    setState(() {
      _appointmentsFuture = ApiService.getAppointments();
    });
  }

  // =========================================================
  //  DIALOG PROFESSIONNEL – Nouveau RDV
  // =========================================================
  void _showAddAppointmentDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String? selectedDoctorId;
    String? selectedDoctorName;
    DateTime? selectedDate;
    String? selectedTimeSlot;
    bool isLoading = false;

    Future<void> pickDate(BuildContext context, StateSetter setDialogState) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primaryMedical,
                onPrimary: Colors.white,
                onSurface: AppTheme.darkNavy,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) setDialogState(() => selectedDate = picked);
    }

    final timeSlots = [
      '08:00 - 08:30', '08:30 - 09:00', '09:00 - 09:30', '09:30 - 10:00',
      '10:00 - 10:30', '10:30 - 11:00', '11:00 - 11:30', '11:30 - 12:00',
      '14:00 - 14:30', '14:30 - 15:00', '15:00 - 15:30', '15:30 - 16:00',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryMedical.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, 12)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nouveau RDV', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text('Planifier un rendez-vous patient', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withOpacity(0.85))),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(dialogContext),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Patient', isRequired: true),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: nameCtrl,
                                decoration: _inputDecoration(hint: 'Nom Complet', icon: Icons.person_outline),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                              ),
                              const SizedBox(height: 18),
                              _buildLabel('Médecin', isRequired: true),
                              const SizedBox(height: 8),
                              FutureBuilder<List<dynamic>>(
                                future: ApiService.getDoctorsByClinic(),
                                builder: (ctx, snap) {
                                  if (snap.connectionState == ConnectionState.waiting) return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()));
                                  final doctors = snap.data ?? [];
                                  if (!doctors.any((d) => d['_id']?.toString() == selectedDoctorId) && selectedDoctorId != null) selectedDoctorId = null;

                                  return DropdownButtonFormField<String>(
                                    value: selectedDoctorId,
                                    decoration: _inputDecoration(hint: 'Sélectionner un médecin', icon: Icons.local_hospital_outlined),
                                    items: doctors.map((d) {
                                      final name = d['doctorId']?['fullName'] ?? d['fullName'] ?? 'Médecin';
                                      return DropdownMenuItem<String>(value: d['_id']?.toString(), child: Text('Dr. $name', style: GoogleFonts.plusJakartaSans(fontSize: 14)));
                                    }).toList(),
                                    onChanged: (v) {
                                      setDialogState(() {
                                        selectedDoctorId = v;
                                        final doc = doctors.firstWhere((d) => d['_id'].toString() == v);
                                        selectedDoctorName = doc['doctorId']?['fullName'] ?? doc['fullName'] ?? 'Médecin';
                                      });
                                    },
                                    validator: (v) => v == null ? 'Veuillez sélectionner un médecin' : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Date', isRequired: true),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () => pickDate(context, setDialogState),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: AppTheme.background,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: Colors.grey.withOpacity(0.15)),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_today_rounded, size: 20, color: AppTheme.primaryMedical.withOpacity(0.6)),
                                                const SizedBox(width: 12),
                                                Text(
                                                  selectedDate == null ? 'Sélectionner' : DateFormat('dd/MM/yyyy').format(selectedDate!),
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: selectedDate == null ? Colors.grey[400] : AppTheme.darkNavy),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Heure', isRequired: true),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<String>(
                                          value: selectedTimeSlot,
                                          decoration: _inputDecoration(hint: '00:00', icon: Icons.access_time_rounded),
                                          items: timeSlots.map((r) => DropdownMenuItem(value: r, child: Text(r, style: GoogleFonts.plusJakartaSans(fontSize: 14)))).toList(),
                                          onChanged: (v) => setDialogState(() => selectedTimeSlot = v),
                                          validator: (v) => v == null ? 'Requis' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _buildLabel('Motif'),
                              const SizedBox(height: 8),
                              TextFormField(controller: reasonCtrl, decoration: _inputDecoration(hint: 'Ex: Consultation Cardiologique', icon: Icons.medical_services_outlined)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: Text('Annuler', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : () async {
                                if (!formKey.currentState!.validate() || selectedDate == null) {
                                  if (selectedDate == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une date')));
                                  return;
                                }
                                setDialogState(() => isLoading = true);
                                try {
                                  await ApiService.createAppointment(
                                    doctorId: selectedDoctorId!,
                                    doctorName: selectedDoctorName,
                                    patientName: nameCtrl.text.trim(),
                                    date: DateFormat('yyyy-MM-dd').format(selectedDate!),
                                    timeSlot: selectedTimeSlot!,
                                    reason: reasonCtrl.text.trim(),
                                  );
                                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                                  _refresh();
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rendez-vous créé avec succès !'), backgroundColor: AppTheme.success));
                                } catch (e) {
                                  setDialogState(() => isLoading = false);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
                                }
                              },
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: AppTheme.primaryMedical, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                              child: isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment annuler/supprimer ce rendez-vous ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteAppointment(appointmentId);
        _refresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RDV supprimé.'), backgroundColor: AppTheme.success));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  void _showEditAppointmentDialog(Map<String, dynamic> appt) {
    String selectedStatus = appt['status'] ?? 'pending';
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
                      child: Text('Modifier RDV', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Statut'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: _inputDecoration(hint: 'Statut', icon: Icons.info_outline_rounded),
                            items: const [
                              DropdownMenuItem(value: 'pending', child: Text('En attente')),
                              DropdownMenuItem(value: 'confirmed', child: Text('Confirmé')),
                              DropdownMenuItem(value: 'in_progress', child: Text('En cours')),
                              DropdownMenuItem(value: 'completed', child: Text('Terminé')),
                              DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
                              DropdownMenuItem(value: 'no_show', child: Text('Non présenté')),
                            ],
                            onChanged: (v) => setDialogState(() => selectedStatus = v!),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                      child: Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: isLoading ? null : () => Navigator.pop(dialogContext), child: const Text('Annuler'))),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : () async {
                                setDialogState(() => isLoading = true);
                                try {
                                  await ApiService.updateAppointment(appointmentId: appt['_id'], status: selectedStatus);
                                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                                  _refresh();
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Succès!'), backgroundColor: AppTheme.success));
                                } catch (e) {
                                  setDialogState(() => isLoading = false);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMedical),
                              child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Valider', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Helper: Label de champ ──
  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkNavy.withOpacity(0.8))),
        if (isRequired) const Text(' *', style: TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryMedical.withOpacity(0.6)),
      filled: true,
      fillColor: AppTheme.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.withOpacity(0.15))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryMedical)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rendez-vous', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryMedical), onPressed: _refresh),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showAddAppointmentDialog,
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      label: Text('Planifier RDV', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMedical,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _appointmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryMedical));
                if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Aucun RDV trouvé.'));

                final appointments = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: appointments.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final appt = appointments[index];
                    final dateStr = appt['date'] != null ? appt['date'].toString().substring(0, 10) : '';
                    final timeStr = appt['timeSlot'] ?? '';
                    final isConfirmed = appt['status'] == 'confirmed';
                    final isCancelled = appt['status'] == 'cancelled';
                    
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(12)),
                        child: Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryMedical)),
                      ),
                      title: Text(appt['patientName'] ?? 'Patient inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('Avec Dr. ${appt['doctorName'] ?? 'Médecin non spécifié'} le $dateStr'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isConfirmed ? AppTheme.success.withOpacity(0.1) : (isCancelled ? AppTheme.error.withOpacity(0.1) : AppTheme.accentMedical.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              appt['status'] ?? 'pending',
                              style: TextStyle(
                                color: isConfirmed ? AppTheme.success : (isCancelled ? AppTheme.error : AppTheme.accentMedical),
                                fontWeight: FontWeight.bold, fontSize: 12
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditAppointmentDialog(appt);
                              } else if (value == 'delete') {
                                _deleteAppointment(appt['_id']);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18, color: AppTheme.primaryMedical), SizedBox(width: 8), Text('Modifier')])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.error), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: AppTheme.error))])),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
