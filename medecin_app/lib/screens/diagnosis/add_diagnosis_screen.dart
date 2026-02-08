import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/medical_text_field.dart';
import '../../widgets/medical_card.dart';

/// Écran Ajouter Diagnostic
class AddDiagnosisScreen extends StatefulWidget {
  const AddDiagnosisScreen({super.key});

  @override
  State<AddDiagnosisScreen> createState() => _AddDiagnosisScreenState();
}

class _AddDiagnosisScreenState extends State<AddDiagnosisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _treatmentController = TextEditingController();
  String _severity = 'Modéré';
  DateTime _diagnosisDate = DateTime.now();
  bool _isLoading = false;
  final List<String> _selectedQuickDiagnoses = [];

  final List<String> _quickDiagnoses = ['Diabète Type 2', 'Hypertension', 'Hyperlipidémie', 'Obésité', 'Anxiété', 'Dépression', 'Asthme', 'BPCO', 'Arthrite', 'Hypothyroïdie'];

  @override
  void dispose() {
    _diagnosisNameController.dispose();
    _notesController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter Diagnostic'), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
      body: Form(
        key: _formKey,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildPatientHeader(),
                const SizedBox(height: 24),
                Text('Sélection rapide', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickDiagnoses.map((diagnosis) {
                    final isSelected = _selectedQuickDiagnoses.contains(diagnosis);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) _selectedQuickDiagnoses.remove(diagnosis);
                          else {
                            _selectedQuickDiagnoses.add(diagnosis);
                            if (_diagnosisNameController.text.isEmpty) _diagnosisNameController.text = diagnosis;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? AppColors.primary : AppColors.border)),
                        child: Text(diagnosis, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                MedicalTextField(label: 'Nom du diagnostic *', hint: 'Entrez le nom du diagnostic', controller: _diagnosisNameController, prefixIcon: Icons.medical_information, validator: (value) => value == null || value.isEmpty ? 'Le nom du diagnostic est requis' : null),
                const SizedBox(height: 16),
                Text('Sévérité', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(children: ['Légère', 'Modérée', 'Sévère', 'Critique'].map((sev) => Expanded(child: GestureDetector(
                  onTap: () => setState(() => _severity = sev),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _severity == sev ? _getSeverityColor(sev).withValues(alpha: 0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _severity == sev ? _getSeverityColor(sev) : AppColors.border),
                    ),
                    child: Center(child: Text(sev, style: TextStyle(color: _severity == sev ? _getSeverityColor(sev) : AppColors.textSecondary, fontWeight: _severity == sev ? FontWeight.w600 : FontWeight.normal, fontSize: 12))),
                  ),
                ))).toList()),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: _diagnosisDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (date != null) setState(() => _diagnosisDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Row(children: [const Icon(Icons.calendar_today, color: AppColors.textSecondary), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Date du diagnostic', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)), const SizedBox(height: 4), Text('${_diagnosisDate.day}/${_diagnosisDate.month}/${_diagnosisDate.year}', style: const TextStyle(fontWeight: FontWeight.w500))])]),
                  ),
                ),
                const SizedBox(height: 16),
                MedicalTextField(label: 'Notes cliniques', hint: 'Ajoutez des notes cliniques...', controller: _notesController, maxLines: 3, prefixIcon: Icons.note),
                const SizedBox(height: 16),
                MedicalTextField(label: 'Plan de traitement', hint: 'Décrivez le plan de traitement...', controller: _treatmentController, maxLines: 3, prefixIcon: Icons.healing),
                const SizedBox(height: 24),
                _buildBlockchainNotice(),
              ]),
            ),
          ),
          _buildBottomBar(),
        ]),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return MedicalCard(
      margin: EdgeInsets.zero,
      backgroundColor: AppColors.diagnosisLight,
      child: Row(children: [
        CircleAvatar(radius: 24, backgroundColor: AppColors.diagnosis.withValues(alpha: 0.2), child: const Text('JD', style: TextStyle(color: AppColors.diagnosis, fontWeight: FontWeight.bold))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Jean Dupont', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), const SizedBox(height: 4), Text('45 ans • Homme', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))])),
      ]),
    );
  }

  Widget _buildBlockchainNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.blockchainLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blockchain.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.blockchain.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.verified_user, color: AppColors.blockchain, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Sécurisé par Blockchain', style: TextStyle(color: AppColors.blockchain, fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(height: 4), Text('Ce diagnostic sera signé numériquement et enregistré de manière immuable.', style: TextStyle(color: AppColors.blockchain.withValues(alpha: 0.8), fontSize: 12))])),
      ]),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(child: PrimaryButton(text: 'Enregistrer le diagnostic', icon: Icons.save, isLoading: _isLoading, onPressed: _handleSave)),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Légère': return AppColors.success;
      case 'Modérée': return AppColors.warning;
      case 'Sévère': return AppColors.error;
      case 'Critique': return const Color(0xFF9C27B0);
      default: return AppColors.warning;
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diagnostic enregistré avec succès'), backgroundColor: AppColors.success));
          Navigator.pop(context);
        }
      });
    }
  }
}
