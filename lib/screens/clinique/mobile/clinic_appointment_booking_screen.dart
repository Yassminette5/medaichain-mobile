import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart';
import '../../../../models/user_model.dart';
import '../../../../widgets/medical_animated_background.dart';

/// Écran de prise de rendez-vous dans une clinique pour les patients
/// Miroir du design 'Premium' du dashboard web
class ClinicAppointmentBookingScreen extends StatefulWidget {
  final String clinicId;
  final String clinicName;

  const ClinicAppointmentBookingScreen({
    super.key,
    required this.clinicId,
    required this.clinicName,
  });

  @override
  State<ClinicAppointmentBookingScreen> createState() =>
      _ClinicAppointmentBookingScreenState();
}

class _ClinicAppointmentBookingScreenState extends State<ClinicAppointmentBookingScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Form State
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Step 1: Type
  String _selectedType = 'Consultation';
  
  // Step 2: Date & Time
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  
  // Step 3: Notes
  final TextEditingController _notesController = TextEditingController();
  String _selectedUrgency = 'Normal';

  // Constants from Web View
  final consultationTypes = [
    {'icon': Icons.medical_services_rounded, 'label': 'Consultation', 'color': AppColors.primary},
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitAppointment() async {
    setState(() => _isLoading = true);

    try {
      final User? userProfile = await ApiService.getProfile();
      String patientName = userProfile?.fullName ?? 'Patient Mobile';

      final appointmentData = {
        'patientName': patientName,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'timeSlot': _selectedTimeSlot!,
        'reason': '$_selectedType [$_selectedUrgency]${_notesController.text.trim().isNotEmpty ? ' - ${_notesController.text.trim()}' : ''}',
      };

      await ApiService.bookClinicAppointmentMobile(widget.clinicId, appointmentData);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous planifié avec succès !'),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MedicalAnimatedBackground(
        child: Column(
          children: [
            // --- CUSTOM HEADER (Mirroring Web Header) ---
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.darkBackground, AppColors.darkSurface, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prendre un rendez-vous',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Étape ${_currentStep + 1} sur 3 • ${widget.clinicName}',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress Bar
                  Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _currentStep ? Colors.white : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // --- MAIN FORM CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentStep == 0
                      ? _buildStep1Type()
                      : _currentStep == 1
                          ? _buildStep2DateTime()
                          : _buildStep3Summary(),
                ),
              ),
            ),

            // --- NAVIGATION BUTTONS ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Retour', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Annuler', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.grey)),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        if (_currentStep == 0) {
                          setState(() => _currentStep = 1);
                        } else if (_currentStep == 1) {
                          if (_selectedDate == null || _selectedTimeSlot == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une date et un créneau')));
                            return;
                          }
                          setState(() => _currentStep = 2);
                        } else {
                          _submitAppointment();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStep == 2 ? const Color(0xFF059669) : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              _currentStep == 2 ? 'Confirmer le RDV' : 'Continuer',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
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
  }

  // --- STEPS UI ---

  Widget _buildStep1Type() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.category_rounded, 'Type de Consultation', 'Quel est le motif de votre visite ?'),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: consultationTypes.length,
          itemBuilder: (context, index) {
            final t = consultationTypes[index];
            final isSelected = _selectedType == t['label'];
            final color = t['color'] as Color;
            return InkWell(
              onTap: () => setState(() => _selectedType = t['label'] as String),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? color : Colors.grey.withValues(alpha: 0.15), width: isSelected ? 2 : 1),
                  boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))] : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t['icon'] as IconData, size: 32, color: isSelected ? color : Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      t['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? color : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep2DateTime() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.calendar_month_rounded, 'Date & Heure', 'Quand souhaiteriez-vous venir ?'),
        const SizedBox(height: 20),
        // Date Picker Widget
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _selectedDate != null ? const Color(0xFF7C3AED).withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _selectedDate != null ? const Color(0xFF7C3AED) : Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF7C3AED), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sélectionner la date', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
                      Text(
                        _selectedDate == null ? 'Cliquer pour choisir' : DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate!),
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('Créneaux horaires disponibles', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B))),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: timeSlots.map((time) {
            final isSelected = _selectedTimeSlot == time;
            return InkWell(
              onTap: () => setState(() => _selectedTimeSlot = time),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.withValues(alpha: 0.15)),
                  boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : [],
                ),
                child: Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF1E1B4B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3Summary() {
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.assignment_rounded, 'Récapitulatif', 'Veuillez confirmer vos choix'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              _summaryItem(Icons.category_rounded, 'Type', _selectedType, const Color(0xFF7C3AED)),
              const Divider(height: 24),
              _summaryItem(Icons.calendar_today_rounded, 'Date', _selectedDate != null ? DateFormat('d MMMM yyyy', 'fr_FR').format(_selectedDate!) : '-', const Color(0xFF059669)),
              const Divider(height: 24),
              _summaryItem(Icons.access_time_rounded, 'Heure', _selectedTimeSlot ?? '-', const Color(0xFFD97706)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Niveau d\'urgence', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B))),
        const SizedBox(height: 12),
        Row(
          children: [
            _urgencyButton('Normal', const Color(0xFF059669)),
            const SizedBox(width: 10),
            _urgencyButton('Urgent', const Color(0xFFD97706)),
            const SizedBox(width: 10),
            _urgencyButton('Critique', const Color(0xFFDC2626)),
          ],
        ),
        const SizedBox(height: 28),
        Text('Notes ou précisions (optionnel)', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B))),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 4,
          style: GoogleFonts.plusJakartaSans(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Symptômes, remarques particulieres...',
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  // --- UI COMPONENTS ---

  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E1B4B))),
              Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[500])),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B))),
          ],
        ),
      ],
    );
  }

  Widget _urgencyButton(String label, Color color) {
    final isSelected = _selectedUrgency == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedUrgency = label),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

