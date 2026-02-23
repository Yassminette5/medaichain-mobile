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
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _analysisTypeController =
  TextEditingController();

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  /// Liste intelligente des analyses
  final List<String> _analysisTypes = [
    "Analyse sanguine",
    "Radiologie",
    "Scanner",
    "IRM",
    "Analyse hormonale",
    "Analyse urinaire",
    "Échographie",
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _dateController.dispose();
    _analysisTypeController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedDate = _parseDate(_dateController.text.trim());
    if (parsedDate == null) {
      _showErrorSnackBar('Date invalide');
      return;
    }

    final appointmentDateTime =
    DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day, 9, 0);

    setState(() => _isLoading = true);

    try {
      final appointmentData = {
        'analysisType': _analysisTypeController.text.trim(),
        'appointmentDate': appointmentDateTime.toIso8601String(),
        'centreName': widget.centreName,
        'labId': widget.labId,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
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
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(e.toString());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// HEADER GRADIENT VIOLET
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6A11CB),
                        Color(0xFF9C27B0),
                        Color(0xFFB721FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Prendre rendez-vous",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ),

                const SizedBox(height: 30),

                /// TYPE ANALYSE (AUTOCOMPLETE)
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Type d'analyse",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10),
                Autocomplete<String>(
                  optionsBuilder: (value) {
                    if (value.text.isEmpty) return _analysisTypes;
                    return _analysisTypes.where((e) =>
                        e.toLowerCase().contains(value.text.toLowerCase()));
                  },
                  onSelected: (value) {
                    _analysisTypeController.text = value;
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      validator: (v) =>
                      v == null || v.isEmpty ? "Champ requis" : null,
                      decoration: InputDecoration(
                        hintText: "Choisir ou taper une analyse...",
                        prefixIcon: const Icon(Icons.science,
                            color: Color(0xFF9C27B0)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                /// DATE PICKER MODERNE
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Date",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF9C27B0),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      _dateController.text =
                      "${picked.day}/${picked.month}/${picked.year}";
                    }
                  },
                  validator: (v) =>
                  v == null || v.isEmpty ? "Sélectionnez une date" : null,
                  decoration: InputDecoration(
                    hintText: "Choisir une date",
                    prefixIcon: const Icon(Icons.calendar_today,
                        color: Color(0xFF9C27B0)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 24),

                /// NOTES
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Notes (optionnel)",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Ajouter des notes...",
                    prefixIcon:
                    const Icon(Icons.note_alt, color: Color(0xFF9C27B0)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 40),

                /// BOUTON GRADIENT VIOLET
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6A11CB),
                        Color(0xFF9C27B0),
                        Color(0xFFB721FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Envoyer",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17)),
                        SizedBox(width: 10),
                        Icon(Icons.send, color: Colors.white)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}