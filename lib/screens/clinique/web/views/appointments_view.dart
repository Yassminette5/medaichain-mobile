import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medaichainmobile/clinique/theme/app_theme.dart';
import 'package:medaichainmobile/services/api_service.dart';

class AppointmentsView extends StatefulWidget {
  const AppointmentsView({super.key});

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView> {
  late Future<List<dynamic>> _appointmentsFuture;
  String _riskFilter = 'all'; // 'all', 'eleve', 'modere', 'faible'
  bool _sortByRisk = false;

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

  Color _getRiskColor(dynamic prob) {
    if (prob == null) return Colors.grey;
    final p = double.tryParse(prob.toString()) ?? 0;
    if (p < 20) return Colors.green;
    if (p < 50) return Colors.orange;
    return Colors.red;
  }

  String _getRiskLabel(dynamic prob) {
    if (prob == null) return 'N/A';
    final p = double.tryParse(prob.toString()) ?? 0;
    if (p < 20) return 'Risque Faible';
    if (p < 50) return 'Risque Modéré';
    return 'Risque Élevé';
  }

  // =========================================================
  //  DIALOG PREMIUM – Nouveau RDV (Multi-étapes)
  // =========================================================
  void _showAddAppointmentDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String? selectedDoctorId;
    String? selectedDoctorName;
    DateTime? selectedDate;
    String? selectedTimeSlot;
    String selectedType = 'Consultation';
    String selectedUrgency = 'Normal';
    String selectedGender = 'M';
    bool hasHipertension = false;
    bool hasDiabetes = false;
    bool hasAlcoholism = false;
    bool hasHandcap = false;
    bool smsReceived = true;
    int _currentStep = 0;
    bool isLoading = false;

    final consultationTypes = [
      {'icon': Icons.medical_services_rounded, 'label': 'Consultation', 'color': const Color(0xFF7C3AED)},
      {'icon': Icons.healing_rounded, 'label': 'Suivi', 'color': const Color(0xFF059669)},
      {'icon': Icons.vaccines_rounded, 'label': 'Vaccination', 'color': const Color(0xFF7C3AED)},
      {'icon': Icons.biotech_rounded, 'label': 'Analyse', 'color': const Color(0xFFDB2777)},
      {'icon': Icons.local_hospital_rounded, 'label': 'Urgence', 'color': const Color(0xFFDC2626)},
      {'icon': Icons.monitor_heart_rounded, 'label': 'Contrôle', 'color': const Color(0xFF0891B2)},
    ];

    final timeSlots = [
      '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
      '11:00', '11:30', '14:00', '14:30', '15:00', '15:30',
      '16:00', '16:30',
    ];

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
              colorScheme: const ColorScheme.light(primary: AppTheme.primaryMedical, onPrimary: Colors.white, onSurface: AppTheme.darkNavy),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) setDialogState(() => selectedDate = picked);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1E1B4B).withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 16)),
                    BoxShadow(color: AppTheme.primaryMedical.withOpacity(0.08), blurRadius: 80, offset: const Offset(0, 30)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── HEADER PREMIUM ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.08))),
                                child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Planifier un Rendez-vous', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                                    const SizedBox(height: 2),
                                    Text('Étape ${_currentStep + 1} sur 3', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(dialogContext),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Progress bar
                          Row(
                            children: List.generate(3, (i) {
                              return Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: i <= _currentStep ? Colors.white : Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    // ── FORM CONTENT ──
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
                        child: Form(
                          key: formKey,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _currentStep == 0
                                ? _buildStep1Patient(
                                    nameCtrl,
                                    phoneCtrl,
                                    ageCtrl,
                                    selectedGender,
                                    hasHipertension,
                                    hasDiabetes,
                                    hasAlcoholism,
                                    hasHandcap,
                                    smsReceived,
                                    selectedType,
                                    consultationTypes,
                                    setDialogState,
                                    (v) => setDialogState(() => selectedGender = v),
                                    (v) => setDialogState(() => hasHipertension = v),
                                    (v) => setDialogState(() => hasDiabetes = v),
                                    (v) => setDialogState(() => hasAlcoholism = v),
                                    (v) => setDialogState(() => hasHandcap = v),
                                    (v) => setDialogState(() => smsReceived = v),
                                    (v) => setDialogState(() => selectedType = v),
                                  )
                                : _currentStep == 1
                                    ? _buildStep2Doctor(selectedDoctorId, selectedDate, selectedTimeSlot, timeSlots, setDialogState, pickDate, dialogContext, (id, name) { selectedDoctorId = id; selectedDoctorName = name; }, (v) => selectedTimeSlot = v)
                                    : _buildStep3Summary(nameCtrl.text, phoneCtrl.text, selectedType, selectedDoctorName, selectedDate, selectedTimeSlot, reasonCtrl, notesCtrl, selectedUrgency, setDialogState, (v) => selectedUrgency = v),
                          ),
                        ),
                      ),
                    ),

                    // ── ACTION BUTTONS ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1)))),
                      child: Row(
                        children: [
                          if (_currentStep > 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => setDialogState(() => _currentStep--),
                                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                label: Text('Retour', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: Text('Annuler', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                              ),
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : () async {
                                if (_currentStep == 0) {
                                  if (nameCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le nom du patient est requis')));
                                    return;
                                  }
                                  setDialogState(() => _currentStep = 1);
                                } else if (_currentStep == 1) {
                                  if (selectedDate == null || selectedTimeSlot == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez la date et l\'heure')));
                                    return;
                                  }
                                  setDialogState(() => _currentStep = 2);
                                } else {
                                  setDialogState(() => isLoading = true);
                                  try {
                                    await ApiService.createAppointment(
                                      doctorId: selectedDoctorId ?? '',
                                      doctorName: selectedDoctorName,
                                      patientName: nameCtrl.text.trim(),
                                      date: DateFormat('yyyy-MM-dd').format(selectedDate!),
                                      timeSlot: selectedTimeSlot!,
                                      reason: '$selectedType${reasonCtrl.text.isNotEmpty ? ' - ${reasonCtrl.text}' : ''}',
                                      // IA Fields
                                      patientAge: int.tryParse(ageCtrl.text) ?? 30,
                                      patientGender: selectedGender,
                                      hipertension: hasHipertension ? 1 : 0,
                                      diabetes: hasDiabetes ? 1 : 0,
                                      alcoholism: hasAlcoholism ? 1 : 0,
                                      handcap: hasHandcap ? 1 : 0,
                                      smsReceived: smsReceived ? 1 : 0,
                                    );
                                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                                    _refresh();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20), const SizedBox(width: 10), const Text('Rendez-vous planifié !')]),
                                        backgroundColor: AppTheme.success,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        margin: const EdgeInsets.all(16),
                                      ));
                                    }
                                  } catch (e) {
                                    setDialogState(() => isLoading = false);
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
                                  }
                                }
                              },
                              icon: isLoading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Icon(_currentStep < 2 ? Icons.arrow_forward_rounded : Icons.check_rounded, size: 18),
                              label: Text(
                                _currentStep < 2 ? 'Continuer' : 'Confirmer le RDV',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: _currentStep < 2 ? AppTheme.primaryMedical : AppTheme.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
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

  // ── STEP 1: Patient & Type ──
  Widget _buildStep1Patient(
      TextEditingController nameCtrl,
      TextEditingController phoneCtrl,
      TextEditingController ageCtrl,
      String selectedGender,
      bool hasHipertension,
      bool hasDiabetes,
      bool hasAlcoholism,
      bool hasHandcap,
      bool smsReceived,
      String selectedType,
      List<Map<String, dynamic>> types,
      StateSetter ss,
      Function(String) onGenderChanged,
      Function(bool) onHiperChanged,
      Function(bool) onDiabChanged,
      Function(bool) onAlcoChanged,
      Function(bool) onHandiChanged,
      Function(bool) onSmsChanged,
      Function(String) onTypeChanged) {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.person_rounded, 'Informations Patient', 'Identifiez le patient pour ce rendez-vous'),
        const SizedBox(height: 16),
        _buildPremiumField('Nom complet du patient *', nameCtrl, Icons.person_outline_rounded, hint: 'Ex: Ahmed Benali'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPremiumField('Âge', ageCtrl, Icons.cake_rounded, hint: 'Ex: 45', inputType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Genre', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _genderOption('M', 'Homme', selectedGender == 'M', ss, () => onGenderChanged('M')),
                      const SizedBox(width: 8),
                      _genderOption('F', 'Femme', selectedGender == 'F', ss, () => onGenderChanged('F')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPremiumField('Téléphone', phoneCtrl, Icons.phone_rounded, hint: 'Ex: 0551234567', inputType: TextInputType.phone),
        const SizedBox(height: 20),
        _sectionHeader(Icons.health_and_safety_rounded, 'Antécédents & Facteurs (IA)', 'Ces infos aident l\'IA à prédire le risque d\'absence'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _simpleCheckbox('Hypertension', hasHipertension, (v) => ss(() => onHiperChanged(v!))),
            _simpleCheckbox('Diabète', hasDiabetes, (v) => ss(() => onDiabChanged(v!))),
            _simpleCheckbox('Alcoolisme', hasAlcoholism, (v) => ss(() => onAlcoChanged(v!))),
            _simpleCheckbox('Handicap', hasHandcap, (v) => ss(() => onHandiChanged(v!))),
            _simpleCheckbox('SMS Reçu', smsReceived, (v) => ss(() => onSmsChanged(v!))),
          ],
        ),
        const SizedBox(height: 24),
        _sectionHeader(Icons.category_rounded, 'Type de Consultation', 'Sélectionnez le motif du rendez-vous'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((t) {
            final isSelected = selectedType == t['label'];
            return InkWell(
              onTap: () => ss(() => onTypeChanged(t['label'] as String)),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? (t['color'] as Color).withOpacity(0.1) : AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? t['color'] as Color : Colors.grey.withOpacity(0.12), width: isSelected ? 2 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t['icon'] as IconData, size: 16, color: isSelected ? t['color'] as Color : AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(t['label'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? t['color'] as Color : AppTheme.textSecondary)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _genderOption(String value, String label, bool isSelected, StateSetter ss, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryMedical.withOpacity(0.1) : AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTheme.primaryMedical : Colors.grey.withOpacity(0.12), width: isSelected ? 2 : 1),
          ),
          child: Center(child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppTheme.primaryMedical : AppTheme.textSecondary))),
        ),
      ),
    );
  }

  Widget _simpleCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryMedical,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.darkNavy)),
      ],
    );
  }

  // ── STEP 2: Doctor & Schedule ──
  Widget _buildStep2Doctor(String? selectedDoctorId, DateTime? selectedDate, String? selectedTimeSlot, List<String> timeSlots, StateSetter ss, Future<void> Function(BuildContext, StateSetter) pickDate, BuildContext dialogContext, Function(String?, String?) onDoctorChanged, Function(String) onTimeChanged) {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.medical_services_rounded, 'Médecin Traitant', 'Assignez un médecin à ce rendez-vous'),
        const SizedBox(height: 16),
        FutureBuilder<List<dynamic>>(
          future: ApiService.getDoctorsByClinic(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return _loadingField();
            final doctors = snap.data ?? [];
            if (!doctors.any((d) => d['_id']?.toString() == selectedDoctorId) && selectedDoctorId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => ss(() => onDoctorChanged(null, null)));
            }
            return Column(
              children: doctors.map((d) {
                final name = d['doctorId']?['fullName'] ?? d['fullName'] ?? 'Médecin';
                final spec = d['speciality'] ?? 'Général';
                final isSelected = d['_id']?.toString() == selectedDoctorId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => ss(() => onDoctorChanged(d['_id']?.toString(), name)),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryMedical.withOpacity(0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? AppTheme.primaryMedical : Colors.grey.withOpacity(0.12), width: isSelected ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(gradient: isSelected ? AppTheme.primaryGradient : null, color: isSelected ? null : AppTheme.background, borderRadius: BorderRadius.circular(12)),
                            child: Center(child: Text('Dr', style: GoogleFonts.plusJakartaSans(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w800, fontSize: 14))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dr. $name', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                                Text(spec, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.primaryMedical, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        _sectionHeader(Icons.schedule_rounded, 'Date & Horaire', 'Choisissez le créneau souhaité'),
        const SizedBox(height: 14),
        // Date picker
        InkWell(
          onTap: () => pickDate(dialogContext, ss),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selectedDate != null ? AppTheme.primaryMedical.withOpacity(0.06) : AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selectedDate != null ? AppTheme.primaryMedical : Colors.grey.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryMedical),
                ),
                const SizedBox(width: 14),
                Text(
                  selectedDate == null ? 'Sélectionner une date' : DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(selectedDate),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.w500, color: selectedDate != null ? AppTheme.darkNavy : AppTheme.textSecondary),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Time slots grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeSlots.map((time) {
            final isSelected = selectedTimeSlot == time;
            final isMorning = int.parse(time.split(':')[0]) < 12;
            return InkWell(
              onTap: () => ss(() => onTimeChanged(time)),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryMedical : AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? AppTheme.primaryMedical : Colors.grey.withOpacity(0.12)),
                  boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryMedical.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))] : [],
                ),
                child: Column(
                  children: [
                    Icon(isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded, size: 12, color: isSelected ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary.withOpacity(0.4)),
                    const SizedBox(height: 2),
                    Text(time, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppTheme.darkNavy)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── STEP 3: Summary ──
  Widget _buildStep3Summary(String patientName, String phone, String type, String? doctorName, DateTime? date, String? time, TextEditingController reasonCtrl, TextEditingController notesCtrl, String urgency, StateSetter ss, Function(String) onUrgencyChanged) {
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.assignment_rounded, 'Récapitulatif', 'Vérifiez les informations avant confirmation'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primaryMedical.withOpacity(0.04), AppTheme.primaryMedical.withOpacity(0.01)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryMedical.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _summaryRow(Icons.person_rounded, 'Patient', patientName),
              if (phone.isNotEmpty) _summaryRow(Icons.phone_rounded, 'Téléphone', phone),
              _summaryRow(Icons.category_rounded, 'Type', type),
              _summaryRow(Icons.medical_services_rounded, 'Médecin', doctorName != null ? 'Dr. $doctorName' : 'Non assigné'),
              _summaryRow(Icons.calendar_today_rounded, 'Date', date != null ? DateFormat('dd/MM/yyyy').format(date) : '-'),
              _summaryRow(Icons.access_time_rounded, 'Heure', time ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Priority
        Text('Niveau d\'urgence', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
        const SizedBox(height: 8),
        Row(
          children: [
            _urgencyChip('Normal', const Color(0xFF059669), urgency, ss, onUrgencyChanged),
            const SizedBox(width: 8),
            _urgencyChip('Urgent', const Color(0xFFD97706), urgency, ss, onUrgencyChanged),
            const SizedBox(width: 8),
            _urgencyChip('Critique', const Color(0xFFDC2626), urgency, ss, onUrgencyChanged),
          ],
        ),
        const SizedBox(height: 14),
        _buildPremiumField('Notes (optionnel)', notesCtrl, Icons.notes_rounded, hint: 'Remarques, allergies...', maxLines: 2),
      ],
    );
  }

  Widget _urgencyChip(String label, Color color, String selected, StateSetter ss, Function(String) onChange) {
    final isSelected = selected == label;
    return Expanded(
      child: InkWell(
        onTap: () => ss(() => onChange(label)),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.12), width: isSelected ? 2 : 1),
          ),
          child: Center(child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? color : AppTheme.textSecondary))),
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: AppTheme.primaryMedical),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 80, child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary))),
          Expanded(child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkNavy))),
        ],
      ),
    );
  }

  // =========================================================
  //  ACTIONS – Delete & Edit
  // =========================================================
  void _deleteAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Supprimer le rendez-vous ?', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkNavy)),
              const SizedBox(height: 8),
              Text('Cette action est irréversible.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Annuler'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Supprimer'))),
                ],
              ),
            ],
          ),
        ),
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
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10))]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]), borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Modifier le statut', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                          InkWell(onTap: () => Navigator.pop(dialogContext), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.close_rounded, color: Colors.white, size: 18))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Patient info
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              children: [
                                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person_rounded, size: 16, color: AppTheme.primaryMedical)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(appt['patientName'] ?? 'Patient', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                                    Text('Dr. ${appt['doctorName'] ?? ''} • ${appt['date']?.toString().substring(0, 10) ?? ''}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Nouveau statut', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                          const SizedBox(height: 10),
                          ...['pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show'].map((status) {
                            final isSelected = selectedStatus == status;
                            final labels = {'pending': 'En attente', 'confirmed': 'Confirmé', 'in_progress': 'En cours', 'completed': 'Terminé', 'cancelled': 'Annulé', 'no_show': 'Absent'};
                            final colors = {'pending': AppTheme.warning, 'confirmed': AppTheme.success, 'in_progress': AppTheme.primaryMedical, 'completed': const Color(0xFF6366F1), 'cancelled': AppTheme.error, 'no_show': Colors.grey};
                            final icons = {'pending': Icons.hourglass_empty_rounded, 'confirmed': Icons.check_circle_outline_rounded, 'in_progress': Icons.play_circle_outline_rounded, 'completed': Icons.task_alt_rounded, 'cancelled': Icons.cancel_outlined, 'no_show': Icons.person_off_rounded};
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: InkWell(
                                onTap: () => setDialogState(() => selectedStatus = status),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? (colors[status] ?? AppTheme.primaryMedical).withOpacity(0.08) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSelected ? colors[status] ?? AppTheme.primaryMedical : Colors.grey.withOpacity(0.1), width: isSelected ? 2 : 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(icons[status], size: 18, color: isSelected ? colors[status] : AppTheme.textSecondary),
                                      const SizedBox(width: 12),
                                      Text(labels[status] ?? status, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? colors[status] : AppTheme.textSecondary)),
                                      const Spacer(),
                                      if (isSelected) Icon(Icons.check_rounded, size: 18, color: colors[status]),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                      child: Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: isLoading ? null : () => Navigator.pop(dialogContext), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Annuler'))),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : () async {
                                setDialogState(() => isLoading = true);
                                try {
                                  await ApiService.updateAppointment(appointmentId: appt['_id'], status: selectedStatus);
                                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                                  _refresh();
                                } catch (e) {
                                  setDialogState(() => isLoading = false);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
                                }
                              },
                              icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded, size: 18),
                              label: Text('Appliquer', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMedical, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  // ── Shared Helpers ──
  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: AppTheme.primaryMedical),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.darkNavy)),
            Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumField(String label, TextEditingController ctrl, IconData icon, {String hint = '', TextInputType? inputType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkNavy.withOpacity(0.7))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: inputType,
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[400]),
            prefixIcon: maxLines == 1 ? Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.06), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: AppTheme.primaryMedical.withOpacity(0.6))) : null,
            filled: true,
            fillColor: AppTheme.background,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.withOpacity(0.12))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryMedical, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _loadingField() {
    return Container(
      height: 56,
      decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(14)),
      child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryMedical))),
    );
  }

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

  // ── AI Detail Sheet ──
  void _showAiDetailSheet(BuildContext context, Map<String, dynamic> appt) {
    final prob = double.tryParse(appt['noShowProbability']?.toString() ?? '0') ?? 0;
    final riskColor = _getRiskColor(prob);
    final riskLabel = _getRiskLabel(prob);
    final recs = (appt['aiRecommendations'] as List<dynamic>?)?.cast<String>() ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.insights_rounded, color: riskColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Analyse IA - ${appt['patientName'] ?? 'Patient'}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkNavy)),
                            Text('Prediction basee sur le modele Kaggle (79% accuracy)',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Risk score bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: riskColor.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        // Score circle
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: riskColor, width: 3),
                          ),
                          child: Center(
                            child: Text('${prob.toInt()}%',
                              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: riskColor)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(riskLabel, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: riskColor)),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: prob / 100, minHeight: 8,
                                  backgroundColor: Colors.grey.withOpacity(0.12),
                                  valueColor: AlwaysStoppedAnimation(riskColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recommendations
                  Text('Recommandations cliniques', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                  const SizedBox(height: 8),
                  if (recs.isEmpty)
                    Text('Aucune recommandation disponible.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary))
                  else
                    ...recs.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 6, height: 6,
                            decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(r, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.darkNavy.withOpacity(0.8)))),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gestion des Rendez-vous', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                        Text('Planifiez et suivez tous vos RDV', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryMedical), onPressed: _refresh),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showAddAppointmentDialog,
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      label: Text('Planifier RDV', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
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
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.06), shape: BoxShape.circle), child: const Icon(Icons.event_busy_rounded, color: AppTheme.primaryMedical, size: 48)),
                        const SizedBox(height: 16),
                        Text('Aucun rendez-vous', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                        const SizedBox(height: 4),
                        Text('Planifiez votre premier rendez-vous', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }

                final appointments = snapshot.data!;

                // ── AI Stats Computation ──
                final aiAppointments = appointments.where((a) => a['noShowProbability'] != null).toList();
                final totalAi = aiAppointments.length;
                double avgRisk = 0;
                int highRisk = 0;
                int medRisk = 0;
                int lowRisk = 0;
                if (totalAi > 0) {
                  double sum = 0;
                  for (final a in aiAppointments) {
                    final p = double.tryParse(a['noShowProbability'].toString()) ?? 0;
                    sum += p;
                    if (p >= 50) highRisk++;
                    else if (p >= 20) medRisk++;
                    else lowRisk++;
                  }
                  avgRisk = sum / totalAi;
                }

                return Column(
                  children: [
                    // ── AI Analytics Banner ──
                    if (totalAi > 0) Container(
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF1E1B4B).withOpacity(0.97), const Color(0xFF312E81), const Color(0xFF7C3AED).withOpacity(0.85)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text('Intelligence Artificielle - Analyse', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text('$totalAi RDV analyses', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // ── Stats Row ──
                          Row(
                            children: [
                              // Average Risk Gauge
                              Expanded(child: _aiStatCard('Risque Moyen', '${avgRisk.toStringAsFixed(1)}%', Icons.speed_rounded, _getRiskColor(avgRisk))),
                              const SizedBox(width: 10),
                              Expanded(child: _aiStatCard('Risque Eleve', '$highRisk', Icons.warning_amber_rounded, Colors.redAccent)),
                              const SizedBox(width: 10),
                              Expanded(child: _aiStatCard('Risque Modere', '$medRisk', Icons.trending_flat_rounded, Colors.orangeAccent)),
                              const SizedBox(width: 10),
                              Expanded(child: _aiStatCard('Risque Faible', '$lowRisk', Icons.check_circle_outline_rounded, Colors.greenAccent)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // ── Smart Insight Bar ──
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_outline_rounded, color: Colors.amberAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    highRisk > 0
                                      ? '$highRisk patient${highRisk > 1 ? 's' : ''} a risque eleve detecte${highRisk > 1 ? 's' : ''} - envisagez un rappel telephonique.'
                                      : 'Tous les patients presentent un risque faible a modere. Situation favorable.',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white.withOpacity(0.85)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Appointments List ──
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: appointments.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final appt = appointments[index];
                    final dateStr = appt['date'] != null ? appt['date'].toString().substring(0, 10) : '';
                    final timeStr = appt['timeSlot'] ?? '';
                    final status = appt['status'] ?? 'pending';
                    final statusColors = {'pending': AppTheme.warning, 'confirmed': AppTheme.success, 'in_progress': AppTheme.primaryMedical, 'completed': const Color(0xFF6366F1), 'cancelled': AppTheme.error, 'no_show': Colors.grey};
                    final statusLabels = {'pending': 'En attente', 'confirmed': 'Confirmé', 'in_progress': 'En cours', 'completed': 'Terminé', 'cancelled': 'Annulé', 'no_show': 'Absent'};

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: appt['noShowProbability'] != null ? _getRiskColor(appt['noShowProbability']).withOpacity(0.2) : Colors.grey.withOpacity(0.1)),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    Text(timeStr.split(' - ').first, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryMedical)),
                                    Text(dateStr, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(appt['patientName'] ?? 'Patient', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.darkNavy)),
                                        const SizedBox(width: 8),
                                        if (appt['source'] == 'mobile') 
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                            child: Text('📱 Mobile', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.blue)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Dr. ${appt['doctorName'] ?? '-'} • ${appt['reason'] ?? ''}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
                                    
                                    // AI Insights Pro Integration
                                    if (appt['noShowProbability'] != null) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.auto_graph_rounded, size: 14, color: _getRiskColor(appt['noShowProbability'])),
                                          const SizedBox(width: 6),
                                          Text(
                                            'IA: ${_getRiskLabel(appt['noShowProbability'])} (${appt['noShowProbability']}%)',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: _getRiskColor(appt['noShowProbability'])),
                                          ),
                                          if ((appt['aiRecommendations'] as List<dynamic>?)?.isNotEmpty == true) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '• ${(appt['aiRecommendations'] as List)[0]}',
                                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: (statusColors[status] ?? AppTheme.warning).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text(statusLabels[status] ?? status, style: GoogleFonts.plusJakartaSans(color: statusColors[status] ?? AppTheme.warning, fontWeight: FontWeight.w700, fontSize: 11)),
                                  ),
                                  const SizedBox(height: 8),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey),
                                    onSelected: (value) {
                                      if (value == 'edit') _showEditAppointmentDialog(appt);
                                      else if (value == 'delete') _deleteAppointment(appt['_id']);
                                      else if (value == 'ai_details') _showAiDetailSheet(context, appt);
                                    },
                                    itemBuilder: (context) => [
                                      if (appt['noShowProbability'] != null)
                                        const PopupMenuItem(value: 'ai_details', child: Row(children: [Icon(Icons.insights_rounded, size: 18, color: Colors.purple), SizedBox(width: 8), Text('Détails IA')])),
                                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18, color: AppTheme.primaryMedical), SizedBox(width: 8), Text('Modifier')])),
                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.error), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: AppTheme.error))])),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Affichage des tags multiples si présents
                          if (appt['noShowProbability'] != null && (appt['aiRecommendations'] as List<dynamic>?) != null && (appt['aiRecommendations'] as List).length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: (appt['aiRecommendations'] as List<dynamic>).skip(1).take(3).map((rec) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _getRiskColor(appt['noShowProbability']).withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _getRiskColor(appt['noShowProbability']).withOpacity(0.15)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 10, color: _getRiskColor(appt['noShowProbability'])),
                                      const SizedBox(width: 4),
                                      Text(
                                        rec.toString(),
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: _getRiskColor(appt['noShowProbability'])),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ], // end Column children
          ); // end Column
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white60), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
