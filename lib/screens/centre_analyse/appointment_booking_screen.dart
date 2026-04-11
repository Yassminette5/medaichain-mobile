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
  // Le controller du champ Autocomplete est fourni par Autocomplete via fieldViewBuilder.
  // On le garde pour lire la valeur réellement tapée/sélectionnée au moment de l'envoi.
  TextEditingController? _analysisFieldController;

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
    "Électrocardiogramme",
    "Test de dépistage",
    "Biopsie",
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _dateController.dispose();
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

  String _toBackendAnalysisType(String input) {
    final v = input.trim().toLowerCase();
    if (v.isEmpty) return 'autre';

    // Normalisation simple (sans dépendances): gérer les libellés UI et les valeurs backend
    switch (v) {
      case 'analyse sanguine':
      case 'analyse_sanguin':
      case 'analyse sanguin':
        return 'analyse_sanguin';
      case 'scanner':
        return 'scanner';
      case 'radiologie':
        return 'radiologie';
      case 'imagerie':
        return 'imagerie';
      case 'biologie':
        return 'biologie';
      case 'irm':
      case 'échographie':
      case 'echographie':
        // Le backend ne liste pas IRM/échographie séparément; on les regroupe sous imagerie
        return 'imagerie';
      default:
        return 'autre';
    }
  }

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedDate = _parseDate(_dateController.text.trim());
    if (parsedDate == null) {
      _showErrorSnackBar('Date invalide');
      return;
    }

    // Convention actuelle: heure fixe à 09:00 (locale), envoyée en UTC au backend.
    // Si la date choisie est "aujourd'hui" et que 09:00 est déjà passé, certains backends renvoient 400.
    final localAtNine = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, 9, 0);
    final appointmentDateTimeUtc = localAtNine.toUtc();
    final nowUtc = DateTime.now().toUtc();
    if (!appointmentDateTimeUtc.isAfter(nowUtc.add(const Duration(minutes: 1)))) {
      _showErrorSnackBar('Veuillez choisir une date future (au moins demain).');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rawAnalysis = _analysisFieldController?.text ?? '';
      final backendType = _toBackendAnalysisType(rawAnalysis);

      final appointmentData = {
        // Backend attend une valeur enum: analyse_sanguin | scanner | radiologie | imagerie | biologie | autre
        'analysisType': backendType,
        'appointmentDate': appointmentDateTimeUtc.toIso8601String(),
        'centreName': widget.centreName,
        'labId': widget.labId,
        // Champs optionnels: gardés à false par défaut (le backend gère l'automatisation).
        'hasCurrentTreatment': false,
        'hasAllergies': false,
        // Tier d'abonnement: en attendant Stripe, on envoie 'free' par défaut
        'subscriptionTier': 'free',
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      };

      final created = await ApiService.createLabAppointment(appointmentData);

      if (mounted) {
        setState(() => _isLoading = false);
        // SnackBar gérée au retour dans `CenterDetailScreen` (avec bouton "Voir" + détails).
        Navigator.pop(context, created);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(e.toString());
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: image seule (sans container autour)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/rendevu.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.primary,
                                size: 44,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Type d'analyse
                _buildSectionTitle('Type d\'analyse'),
                const SizedBox(height: 12),
                Autocomplete<String>(
                  optionsBuilder: (value) {
                    if (value.text.isEmpty) return _analysisTypes;
                    return _analysisTypes.where((e) =>
                        e.toLowerCase().contains(value.text.toLowerCase()));
                  },
                  onSelected: (value) {
                    _analysisFieldController?.text = value;
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                    // Garder une référence au controller réellement utilisé par Autocomplete.
                    _analysisFieldController = controller;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Champ requis" : null,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: "Choisir ou taper une analyse...",
                        hintStyle: TextStyle(color: AppColors.textLight),
                        prefixIcon: _buildInputPrefixIcon(
                          icon: Icons.science_rounded,
                          iconColor: AppColors.prescription,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index == 0
                                        ? AppColors.primary.withValues(alpha: 0.05)
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.science_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Date
                _buildSectionTitle('Date du rendez-vous'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              surface: AppColors.surface,
                              onSurface: AppColors.textPrimary,
                            ),
                            dialogBackgroundColor: AppColors.surface,
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null && mounted) {
                      setState(() {
                        _dateController.text =
                            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                      });
                    }
                  },
                  validator: (v) =>
                      v == null || v.isEmpty ? "Sélectionnez une date" : null,
                  decoration: InputDecoration(
                    hintText: "Choisir une date",
                    hintStyle: TextStyle(color: AppColors.textLight),
                    prefixIcon: _buildInputPrefixIcon(
                      icon: Icons.calendar_today_rounded,
                      iconColor: AppColors.info,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.error,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Notes
                _buildSectionTitle('Notes (optionnel)'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: "Ajouter des notes ou informations supplémentaires...",
                    hintStyle: TextStyle(color: AppColors.textLight),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: _buildInputPrefixIcon(
                        icon: Icons.edit_note_rounded,
                        iconColor: AppColors.secondary,
                        noMargin: true,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Bouton d'envoi
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Envoyer la demande",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.send_rounded, color: Colors.white, size: 22),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _softVioletIconGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.categoryPurple.withValues(alpha: 0.95),
        AppColors.categoryBlue.withValues(alpha: 0.65),
      ],
    );
  }

  Widget _buildInputPrefixIcon({
    required IconData icon,
    required Color iconColor,
    bool noMargin = false,
  }) {
    return Container(
      margin: noMargin ? EdgeInsets.zero : const EdgeInsets.all(12),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        gradient: _softVioletIconGradient(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
    );
  }
}
