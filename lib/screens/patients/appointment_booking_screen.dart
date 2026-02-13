import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Écran de prise de rendez-vous pour les patients
class AppointmentBookingScreen extends StatefulWidget {
  final String labId;
  final String centreName;

  const AppointmentBookingScreen({
    super.key,
    required this.labId,
    required this.centreName,
  });

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  // Contrôleurs
  final TextEditingController _treatmentController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();

  // État du formulaire
  String? _selectedAnalysisType;
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _hasCurrentTreatment = false;
  bool _hasAllergies = false;
  List<String> _allergies = [];
  bool _isLoading = false;
  bool _isLoadingLab = true;
  List<String> _availableCategories = [];

  // Créneaux horaires disponibles
  final List<String> _timeSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30',
  ];

  @override
  void initState() {
    super.initState();
    _loadLabCategories();
    // Allergies par défaut
    _allergies = ['Pénicilline', 'Latex'];
    _hasAllergies = true;
  }

  @override
  void dispose() {
    _treatmentController.dispose();
    _notesController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _loadLabCategories() async {
    try {
      final labData = await ApiService.getLabById(widget.labId);
      if (mounted) {
        setState(() {
          if (labData['categorie'] != null) {
            if (labData['categorie'] is List) {
              _availableCategories = List<String>.from(labData['categorie']);
            } else if (labData['categorie'] is String) {
              _availableCategories = [labData['categorie']];
            }
          }
          _isLoadingLab = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLab = false;
        });
      }
    }
  }

  Map<String, dynamic> _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('sang') || categoryLower.contains('sanguin')) {
      return {'icon': Icons.water_drop, 'value': 'analyse_sanguin'};
    } else if (categoryLower.contains('scanner')) {
      return {'icon': Icons.scanner, 'value': 'scanner'};
    } else if (categoryLower.contains('radio')) {
      return {'icon': Icons.radio_button_checked, 'value': 'radiologie'};
    } else if (categoryLower.contains('image')) {
      return {'icon': Icons.image, 'value': 'imagerie'};
    } else if (categoryLower.contains('bio')) {
      return {'icon': Icons.science, 'value': 'biologie'};
    } else {
      return {'icon': Icons.science, 'value': 'autre'};
    }
  }

  Future<void> _createAppointment() async {
    if (_selectedAnalysisType == null) {
      _showErrorSnackBar('Veuillez sélectionner un type d\'analyse');
      return;
    }

    if (_selectedDate == null) {
      _showErrorSnackBar('Veuillez sélectionner une date');
      return;
    }

    if (_selectedTime == null) {
      _showErrorSnackBar('Veuillez sélectionner une heure');
      return;
    }

    // Vérifier que la date n'est pas dans le passé
    final now = DateTime.now();
    final appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(_selectedTime!.split(':')[0]),
      int.parse(_selectedTime!.split(':')[1]),
    );

    if (appointmentDateTime.isBefore(now)) {
      _showErrorSnackBar('La date et l\'heure ne peuvent pas être dans le passé');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appointmentData = {
        'analysisType': _selectedAnalysisType,
        'appointmentDate': appointmentDateTime.toIso8601String(),
        'centreName': widget.centreName,
        'labId': widget.labId,
        'hasCurrentTreatment': _hasCurrentTreatment,
        'currentTreatmentDetails': _hasCurrentTreatment ? _treatmentController.text : null,
        'hasAllergies': _hasAllergies,
        'allergiesDetails': _hasAllergies && _allergies.isNotEmpty ? _allergies : null,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'status': 'pending',
      };

      await ApiService.createAppointment(appointmentData);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous créé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Retour avec succès
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _addAllergy() {
    if (_allergyController.text.trim().isNotEmpty) {
      setState(() {
        _allergies.add(_allergyController.text.trim());
        _allergyController.clear();
        _hasAllergies = true;
      });
    }
  }

  void _removeAllergy(String allergy) {
    setState(() {
      _allergies.remove(allergy);
      if (_allergies.isEmpty) {
        _hasAllergies = false;
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
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Prendre rendez-vous',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicateur de progression
            _buildProgressIndicator(),
            const SizedBox(height: 24),
            // Type d'analyse
            _buildAnalysisTypeSection(),
            const SizedBox(height: 24),
            // Date et Heure
            _buildDateTimeSection(),
            const SizedBox(height: 24),
            // Traitements
            _buildTreatmentSection(),
            const SizedBox(height: 24),
            // Allergies
            _buildAllergiesSection(),
            const SizedBox(height: 24),
            // Notes
            _buildNotesSection(),
            const SizedBox(height: 24),
            // Information banner
            _buildInfoBanner(),
            const SizedBox(height: 30),
            // Bouton de confirmation
            _buildConfirmButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuration du rendez-vous',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.66, // Étape 2 sur 3
                  backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Étape 2 sur 3',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildAnalysisTypeSection() {
  if (_isLoadingLab) {
    return const Center(child: CircularProgressIndicator());
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Type d'analyse",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 18),

      Wrap(
        spacing: 22,
        runSpacing: 22,
        children: _availableCategories.map((category) {
          final info = _getCategoryIcon(category);
          final isSelected = _selectedAnalysisType == info['value'];

          return _buildAnalysisTypeCard(
            category,
            info['icon'],
            info['value'],
            isSelected,
          );
        }).toList(),
      ),
    ],
  );
}


  List<Color> _getCategoryGradient(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('sang') || categoryLower.contains('sanguin')) {
      return [const Color(0xFFEC4899), const Color(0xFFF472B6)]; // Pink gradient
    } else if (categoryLower.contains('scanner')) {
      return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]; // Orange to Yellow gradient
    } else if (categoryLower.contains('radio')) {
      return [const Color(0xFF3B82F6), const Color(0xFF60A5FA)]; // Blue gradient
    } else if (categoryLower.contains('image')) {
      return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)]; // Purple gradient
    } else if (categoryLower.contains('bio')) {
      return [const Color(0xFF10B981), const Color(0xFF34D399)]; // Green gradient
    } else {
      return [const Color(0xFF6366F1), const Color(0xFF818CF8)]; // Indigo gradient
    }
  }

Widget _buildAnalysisTypeCard(
    String label, IconData icon, String value, bool isSelected) {

  final gradient = _getCategoryGradient(label);

  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedAnalysisType = value;
      });
    },
    child: Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: isSelected
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}



  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date et Heure',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // Calendrier
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        if (_selectedDate != null) {
                          _selectedDate = DateTime(
                            _selectedDate!.year,
                            _selectedDate!.month - 1,
                          );
                        }
                      });
                    },
                  ),
                  Text(
                    _selectedDate != null
                        ? '${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}'
                        : '${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        if (_selectedDate != null) {
                          _selectedDate = DateTime(
                            _selectedDate!.year,
                            _selectedDate!.month + 1,
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCalendar(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Créneaux horaires
        const Text(
          'Sélectionner une heure',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeSlots.map((time) {
            final isSelected = _selectedTime == time;
            return _buildTimeSlot(time, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final displayMonth = _selectedDate ?? now;
    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final lastDay = DateTime(displayMonth.year, displayMonth.month + 1, 0);
    final firstDayWeekday = firstDay.weekday;

    final List<Widget> calendarDays = [];
    
    // Jours de la semaine
    final weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    for (final day in weekDays) {
      calendarDays.add(
        Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    // Espaces pour aligner le premier jour
    for (int i = 1; i < firstDayWeekday; i++) {
      calendarDays.add(const Expanded(child: SizedBox()));
    }

    // Jours du mois
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(displayMonth.year, displayMonth.month, day);
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

      calendarDays.add(
        Expanded(
          child: InkWell(
            onTap: isPast ? null : () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isPast
                        ? AppColors.textLight
                        : (isSelected ? Colors.white : AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: calendarDays.take(7).toList()),
        if (calendarDays.length > 7)
          ...List.generate(
            (calendarDays.length / 7).ceil() - 1,
            (week) => Row(
              children: calendarDays
                  .skip(7 * (week + 1))
                  .take(7)
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSlot(String time, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTime = time;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Préparation de l\'examen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: const Text(
                      'Traitements ou médicaments en cours',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: _hasCurrentTreatment,
                    onChanged: (value) {
                      setState(() {
                        _hasCurrentTreatment = value;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              if (_hasCurrentTreatment) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _treatmentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ex: Paracétamol, Insuline...',
                    hintStyle: TextStyle(color: AppColors.textLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
Widget _buildAllergiesSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Allergies connues',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 16),

      if (_allergies.isNotEmpty) ...[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allergies.map((allergy) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    allergy,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _removeAllergy(allergy),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],

      /// 🔵 Bouton Ajouter bleu (style capture)
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF3B82F6),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _showAddAllergyDialog,
            child: const Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '+ Ajouter',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}


  void _showAddAllergyDialog() {
    final TextEditingController dialogController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une allergie'),
        content: TextField(
          controller: dialogController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nom de l\'allergie',
            hintStyle: TextStyle(color: AppColors.textLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          onSubmitted: (_) {
            if (dialogController.text.trim().isNotEmpty) {
              setState(() {
                _allergies.add(dialogController.text.trim());
                _hasAllergies = true;
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (dialogController.text.trim().isNotEmpty) {
                setState(() {
                  _allergies.add(dialogController.text.trim());
                  _hasAllergies = true;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Ajouter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes supplémentaires',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ajouter des notes (optionnel)',
            hintStyle: TextStyle(color: AppColors.textLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.info,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pensez à apporter votre ordonnance originale et votre carte vitale le jour du rendez-vous.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Confirmer le rendez-vous',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }
}
