import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

class PatientUploadAnalysisScreen extends StatefulWidget {
  const PatientUploadAnalysisScreen({super.key});

  @override
  State<PatientUploadAnalysisScreen> createState() =>
      _PatientUploadAnalysisScreenState();
}

class _PatientUploadAnalysisScreenState
    extends State<PatientUploadAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _centreNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _otherTypeController = TextEditingController();

  String _source = 'centre_analyse';
  String _analysisType = 'analyse_sanguin';
  DateTime _analysisDate = DateTime.now();
  PlatformFile? _pickedFile;
  bool _uploading = false;

  static const _analysisTypes = {
    'analyse_sanguin': 'Analyse sanguine',
    'scanner': 'Scanner',
    'radiologie': 'Radiologie',
    'imagerie': 'Imagerie',
    'biologie': 'Biologie',
    'autre': 'Autre',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _centreNameController.dispose();
    _notesController.dispose();
    _otherTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _analysisDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _analysisDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null || _pickedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fichier (Image ou PDF)')),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      await ApiService.uploadPatientAnalysis(
        title: _titleController.text.trim(),
        analysisType: _analysisType,
        analysisDate: _analysisDate,
        source: _source,
        fileBytes: _pickedFile!.bytes!,
        fileName: _pickedFile!.name,
        analysisTypeOther:
            _analysisType == 'autre' ? _otherTypeController.text.trim() : null,
        centreName: _source == 'centre_analyse'
            ? _centreNameController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analyse uploadée avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ajouter une analyse',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSourceSelector(),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _titleController,
                label: 'Titre de l\'analyse',
                hint: 'Ex: Bilan sanguin complet',
                icon: Icons.title_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
              ),
              const SizedBox(height: 16),
              _buildTypeSelector(),
              if (_analysisType == 'autre') ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _otherTypeController,
                  label: 'Préciser le type',
                  hint: 'Ex: Électrocardiogramme',
                  icon: Icons.edit_rounded,
                ),
              ],
              const SizedBox(height: 16),
              _buildDatePicker(),
              if (_source == 'centre_analyse') ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _centreNameController,
                  label: 'Nom du centre d\'analyse',
                  hint: 'Ex: Laboratoire Central',
                  icon: Icons.business_rounded,
                ),
              ],
              const SizedBox(height: 16),
              _buildTextField(
                controller: _notesController,
                label: 'Notes (optionnel)',
                hint: 'Remarques ou observations...',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildFilePicker(),
              const SizedBox(height: 28),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Source de l\'analyse',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSourceOption(
                  label: 'Centre d\'analyse',
                  value: 'centre_analyse',
                  icon: Icons.business_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSourceOption(
                  label: 'Personnel',
                  value: 'patient',
                  icon: Icons.person_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceOption({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final selected = _source == value;
    return GestureDetector(
      onTap: () => setState(() => _source = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 24),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _analysisType,
        decoration: InputDecoration(
          labelText: 'Type d\'analyse',
          prefixIcon:
              const Icon(Icons.science_rounded, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        items: _analysisTypes.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _analysisType = v);
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date de l\'analyse',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMMM yyyy', 'fr_FR').format(_analysisDate),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _pickedFile != null
              ? AppColors.success.withValues(alpha: 0.06)
              : AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pickedFile != null
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.15),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: _pickedFile != null
                    ? LinearGradient(colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.7)
                      ])
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _pickedFile != null
                    ? Icons.check_circle_rounded
                    : Icons.upload_file_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _pickedFile != null
                  ? _pickedFile!.name
                  : 'Sélectionner un fichier (Image ou PDF)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _pickedFile != null
                    ? AppColors.success
                    : AppColors.textPrimary,
              ),
            ),
            if (_pickedFile != null) ...[
              const SizedBox(height: 4),
              Text(
                '${(_pickedFile!.size / 1024).toStringAsFixed(1)} Ko',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Appuyez pour parcourir vos fichiers',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _uploading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _uploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_rounded, size: 22),
                  SizedBox(width: 10),
                  Text('Uploader l\'analyse',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}
