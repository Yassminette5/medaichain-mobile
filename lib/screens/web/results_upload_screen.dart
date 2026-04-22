import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Écran d'upload de résultats numériques pour le web
class ResultsUploadScreen extends StatefulWidget {
  const ResultsUploadScreen({super.key});

  @override
  State<ResultsUploadScreen> createState() => _ResultsUploadScreenState();
}

class _ResultsUploadScreenState extends State<ResultsUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientEmailController = TextEditingController();
  final _analysisTypeOtherController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedAnalysisType;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _isDragging = false;

  // Liste des patients acceptés pour l'autocomplétion
  List<Map<String, dynamic>> _acceptedPatients = [];
  bool _isLoadingPatients = false;

  // Mapping des types d'analyse selon l'enum du backend
  final Map<String, String> _analysisTypes = {
    'Analyse sanguine': 'analyse_sanguin',
    'Scanner': 'scanner',
    'Radiologie': 'radiologie',
    'Imagerie': 'imagerie',
    'Biologie': 'biologie',
    'Autre': 'autre',
  };

  final List<String> _analysisTypeLabels = [
    'Analyse sanguine',
    'Scanner',
    'Radiologie',
    'Imagerie',
    'Biologie',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadAcceptedPatients();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientEmailController.dispose();
    _analysisTypeOtherController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAcceptedPatients() async {
    setState(() => _isLoadingPatients = true);

    try {
      final appointments = await ApiService.getLabAppointments();

      // Extraire les patients uniques avec statut "accepted"
      final Map<String, Map<String, dynamic>> uniquePatients = {};

      for (var appointment in appointments) {
        final status = appointment['status']?.toString().toLowerCase();
        if (status == 'accepted') {
          final patientId = appointment['patientId'];
          if (patientId != null && patientId is Map) {
            final patientMap = Map<String, dynamic>.from(patientId);
            final patientIdStr = patientMap['_id']?.toString() ??
                patientMap['id']?.toString() ??
                '';

            if (patientIdStr.isNotEmpty && !uniquePatients.containsKey(patientIdStr)) {
              uniquePatients[patientIdStr] = patientMap;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _acceptedPatients = uniquePatients.values.toList();
          _isLoadingPatients = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Results Upload: Erreur chargement patients: $e');
      if (mounted) {
        setState(() => _isLoadingPatients = false);
      }
    }
  }

  String _getPatientName(Map<String, dynamic> patient) {
    final firstName = patient['firstName']?.toString() ?? '';
    final lastName = patient['lastName']?.toString() ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '${firstName.trim()} ${lastName.trim()}'.trim();
    }
    return patient['email']?.toString().split('@')[0] ?? 'Patient';
  }

  String _getPatientEmail(Map<String, dynamic> patient) {
    return patient['email']?.toString() ?? '';
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        // Backend: PDF et Images
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final picked = result.files.single;
        final name = picked.name.toLowerCase();
        final ext = name.contains('.') ? name.split('.').last : '';
        if (!['pdf', 'png', 'jpg', 'jpeg'].contains(ext)) {
          _showErrorDialog(
            title: 'Format non autorisé',
            message: 'Seuls les formats PDF, JPG, JPEG et PNG sont acceptés.',
          );
          return;
        }
        setState(() {
          _selectedFile = picked;
        });
      }
    } catch (e) {
      _showErrorDialog(
        title: 'Erreur',
        message: 'Erreur lors de la sélection du fichier: $e',
      );
    }
  }

  Future<void> _uploadResult() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null || _selectedFile!.bytes == null) {
      _showErrorDialog(title: 'Fichier manquant', message: 'Veuillez sélectionner un fichier (PDF ou Image).');
      return;
    }

    // Double sécurité côté front
    final fileName = _selectedFile!.name.toLowerCase();
    final ext = fileName.contains('.') ? fileName.split('.').last : '';
    if (!['pdf', 'png', 'jpg', 'jpeg'].contains(ext)) {
      _showErrorDialog(
        title: 'Format non autorisé',
        message: 'Seuls les formats PDF, JPG, JPEG et PNG sont acceptés.',
      );
      return;
    }

    if (_selectedAnalysisType == null) {
      _showErrorDialog(title: 'Champ requis', message: 'Veuillez sélectionner un type d\'analyse.');
      return;
    }

    if (_selectedStartDate == null) {
      _showErrorDialog(title: 'Champ requis', message: 'Veuillez sélectionner une date d\'analyse.');
      return;
    }

    // Si "Autre" est sélectionné, vérifier que le champ personnalisé est rempli
    if (_selectedAnalysisType == 'autre' &&
        (_analysisTypeOtherController.text.isEmpty)) {
      _showErrorDialog(
        title: 'Champ requis',
        message: 'Veuillez spécifier le type d\'analyse personnalisé.',
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final analysisTypeValue = _analysisTypes[_selectedAnalysisType]!;

      await ApiService.uploadAnalysisResult(
        patientName: _patientNameController.text.trim(),
        patientEmail: _patientEmailController.text.trim(),
        analysisType: analysisTypeValue,
        analysisDate: _selectedStartDate!,
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        analysisTypeOther: _selectedAnalysisType == 'autre'
            ? _analysisTypeOtherController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        _showSuccessSnackBar('Résultat uploadé avec succès');
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(title: 'Upload échoué', message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _resetForm() {
    _patientNameController.clear();
    _patientEmailController.clear();
    _analysisTypeOtherController.clear();
    _notesController.clear();
    setState(() {
      _selectedAnalysisType = null;
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedFile = null;
    });
  }

  Future<void> _showErrorDialog({required String title, required String message}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec icône et titre
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upload Résultat d\'Analyse',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Téléversez les résultats d\'analyses pour les patients',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Formulaire en deux colonnes
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colonne gauche
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Nom du patient'),
                          const SizedBox(height: 8),
                          _buildPatientNameAutocomplete(),
                          const SizedBox(height: 24),
                          _buildLabel('Type d\'analyse'),
                          const SizedBox(height: 8),
                          _buildDropdown(
                            value: _selectedAnalysisType,
                            items: _analysisTypeLabels,
                            hint: 'Sélectionner un type',
                            icon: Icons.science_rounded,
                            onChanged: (value) {
                              setState(() {
                                _selectedAnalysisType = value;
                                if (value != 'Autre') {
                                  _analysisTypeOtherController.clear();
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner un type';
                              }
                              return null;
                            },
                          ),
                          if (_selectedAnalysisType == 'Autre') ...[
                            const SizedBox(height: 24),
                            _buildLabel('Type personnalisé'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _analysisTypeOtherController,
                              hintText: 'Spécifier le type d\'analyse',
                              icon: Icons.edit_rounded,
                              validator: (value) {
                                if (_selectedAnalysisType == 'Autre' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Veuillez spécifier le type';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 24),
                          _buildLabel('Date d\'analyse'),
                          const SizedBox(height: 8),
                          _buildDateField(
                            date: _selectedStartDate,
                            label: 'Sélectionner une date',
                            icon: Icons.calendar_today_rounded,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedStartDate = date;
                                });
                              }
                            },
                            validator: () {
                              if (_selectedStartDate == null) {
                                return 'Veuillez sélectionner une date';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Colonne droite
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Email du patient'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _patientEmailController,
                            hintText: 'patient@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer l\'email';
                              }
                              if (!value.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Section Upload Document
                _buildLabel('Upload Document'),
                const SizedBox(height: 8),
                Text(
                  'Glissez-déposez le document pour uploader votre résultat d\'analyse',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildUploadZone(),

                if (_selectedFile != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFile!.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_selectedFile!.bytes!.length / 1024).toStringAsFixed(2)} KB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedFile = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Section Description/Notes
                _buildLabel('Description'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _notesController,
                  hintText: 'Descript your experience here!',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                ),

                const SizedBox(height: 40),

                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isUploading ? null : () {
                        // Save as Draft - TODO: Implémenter
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer comme brouillon',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _isUploading ? null : _resetForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Réinitialiser',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isUploading ? null : _uploadResult,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Enregistrer le résultat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDateField({
    required DateTime? date,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    String? Function()? validator,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Text(
          date != null ? _formatDate(date) : label,
          style: TextStyle(
            color: date != null ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientNameAutocomplete() {
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Map<String, dynamic>>.empty();
        }

        final query = textEditingValue.text.toLowerCase();
        return _acceptedPatients.where((patient) {
          final name = _getPatientName(patient).toLowerCase();
          final email = _getPatientEmail(patient).toLowerCase();
          return name.contains(query) || email.contains(query);
        });
      },
      displayStringForOption: (Map<String, dynamic> patient) {
        return _getPatientName(patient);
      },
      fieldViewBuilder: (
          BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted,
          ) {
        // Synchroniser avec le controller principal
        if (textEditingController.text != _patientNameController.text) {
          textEditingController.text = _patientNameController.text;
        }

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Nom complet du patient',
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: _isLoadingPatients
                ? const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le nom du patient';
            }
            return null;
          },
          onChanged: (value) {
            _patientNameController.text = value;
          },
        );
      },
      onSelected: (Map<String, dynamic> patient) {
        final patientName = _getPatientName(patient);
        final patientEmail = _getPatientEmail(patient);

        setState(() {
          _patientNameController.text = patientName;
          _patientEmailController.text = patientEmail;
        });
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final patient = options.elementAt(index);
                  final name = _getPatientName(patient);
                  final email = _getPatientEmail(patient);

                  return InkWell(
                    onTap: () => onSelected(patient),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a file or drag & drop it here.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
                  'PDF ou Images (PNG, JPG) jusqu’à 50MB',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Browse files'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}