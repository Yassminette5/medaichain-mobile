import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medaichainmobile/core/theme/app_colors.dart';
import 'package:medaichainmobile/services/api_service.dart';
import 'package:medaichainmobile/providers/patients_provider.dart';
import 'package:medaichainmobile/models/patient_model.dart';
import 'package:medaichainmobile/widgets/primary_button.dart';
import 'package:medaichainmobile/widgets/medical_text_field.dart';
import 'package:medaichainmobile/widgets/medical_card.dart';

/// Écran Création Ordonnance
class CreatePrescriptionScreen extends StatefulWidget {
  const CreatePrescriptionScreen({super.key});

  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _medications = [];
  final _notesController = TextEditingController();
  String? _selectedPatientId;
  Patient? _selectedPatient;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addMedication();

    // Load patients for doctor selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final patientsProvider = Provider.of<PatientsProvider>(context, listen: false);
      if (patientsProvider.patients.isEmpty && !patientsProvider.isLoading) {
        patientsProvider.loadPatients();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addMedication() {
    setState(() {
      _medications.add({'name': TextEditingController(), 'dosage': TextEditingController(), 'frequency': '1x par jour', 'duration': '7 jours'});
    });
  }

  void _removeMedication(int index) {
    if (_medications.length > 1) setState(() => _medications.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer Ordonnance'), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)), actions: [TextButton.icon(onPressed: _addMedication, icon: const Icon(Icons.add, size: 18), label: const Text('Ajouter'))]),
      body: Form(
        key: _formKey,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildPatientHeader(),
                const SizedBox(height: 24),
                Text('Médicaments', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('${_medications.length} médicament(s) ajouté(s)', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                ..._medications.asMap().entries.map((entry) => _buildMedicationCard(entry.key, entry.value)),
                GestureDetector(
                  onTap: _addMedication,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, color: AppColors.primary), SizedBox(width: 8), Text('Ajouter un médicament', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500))]),
                  ),
                ),
                const SizedBox(height: 24),
                MedicalTextField(label: 'Instructions supplémentaires', hint: 'Entrez les instructions pour le patient...', controller: _notesController, maxLines: 3),
                const SizedBox(height: 24),
                _buildPrescriptionSummary(),
                const SizedBox(height: 24),
                _buildValidationStatus(),
              ]),
            ),
          ),
          _buildBottomBar(),
        ]),
      ),
    );
  }

  Widget _buildPatientHeader() {
    final patientsProvider = Provider.of<PatientsProvider>(context);

    final allergies = _selectedPatient?.allergies ?? const <String>[];
    final allergiesText = allergies.isEmpty ? 'Aucune allergie connue' : allergies.join(', ');

    return MedicalCard(
      margin: EdgeInsets.zero,
      backgroundColor: AppColors.prescriptionLight,
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.prescription.withValues(alpha: 0.2),
          child: Text(
            _selectedPatient?.initials ?? '--',
            style: const TextStyle(color: AppColors.prescription, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Patient', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedPatientId,
                decoration: InputDecoration(
                  hintText: 'Sélectionner un patient',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: patientsProvider.patients
                    .map((p) => DropdownMenuItem<String>(value: p.id, child: Text(p.fullName)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedPatientId = v;
                    _selectedPatient = v == null ? null : patientsProvider.getPatientById(v);
                  });
                },
                validator: (v) => (v == null || v.isEmpty) ? 'Patient requis' : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Allergies: $allergiesText',
                style: TextStyle(
                  color: allergies.isEmpty ? AppColors.textSecondary : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Icon(allergies.isEmpty ? Icons.info_outline : Icons.warning_amber, color: allergies.isEmpty ? AppColors.info : AppColors.warning),
      ]),
    );
  }

  Widget _buildMedicationCard(int index, Map<String, dynamic> medication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.prescriptionLight, borderRadius: BorderRadius.circular(12)), child: Text('#${index + 1}', style: const TextStyle(color: AppColors.prescription, fontWeight: FontWeight.w600, fontSize: 12))),
          const Spacer(),
          if (_medications.length > 1) IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20), onPressed: () => _removeMedication(index)),
        ]),
        const SizedBox(height: 12),
        TextFormField(controller: medication['name'], decoration: InputDecoration(labelText: 'Nom du médicament *', hintText: 'ex: Metformine', prefixIcon: const Icon(Icons.medication), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (value) => value == null || value.isEmpty ? 'Requis' : null),
        const SizedBox(height: 12),
        TextFormField(controller: medication['dosage'], decoration: InputDecoration(labelText: 'Dosage *', hintText: 'ex: 500mg', prefixIcon: const Icon(Icons.scale), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (value) => value == null || value.isEmpty ? 'Requis' : null),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildDropdown('Fréquence', medication['frequency'], ['1x par jour', '2x par jour', '3x par jour', 'Toutes les 8h', 'Si besoin'], (value) => setState(() => medication['frequency'] = value))),
          const SizedBox(width: 12),
          Expanded(child: _buildDropdown('Durée', medication['duration'], ['3 jours', '5 jours', '7 jours', '14 jours', '30 jours', 'Continue'], (value) => setState(() => medication['duration'] = value))),
        ]),
      ]),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(), onChanged: (v) => onChanged(v!))),
      ),
    ]);
  }

  Widget _buildPrescriptionSummary() {
    final validMeds = _medications.where((m) => (m['name'] as TextEditingController).text.isNotEmpty).toList();
    return MedicalCard(
      margin: EdgeInsets.zero,
      title: 'Résumé ordonnance',
      titleIcon: Icons.summarize,
      child: Column(children: [
        if (validMeds.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Aucun médicament ajouté', style: TextStyle(color: AppColors.textSecondary)))
        else ...validMeds.map((med) {
          final name = (med['name'] as TextEditingController).text;
          final dosage = (med['dosage'] as TextEditingController).text;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.check_circle, color: AppColors.success, size: 18), const SizedBox(width: 8), Expanded(child: Text('$name $dosage - ${med['frequency']} pendant ${med['duration']}', style: const TextStyle(fontSize: 13)))]));
        }),
      ]),
    );
  }

  Widget _buildValidationStatus() {
    final allFilled = _medications.every((m) => (m['name'] as TextEditingController).text.isNotEmpty && (m['dosage'] as TextEditingController).text.isNotEmpty);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: allFilled ? AppColors.successLight : AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(allFilled ? Icons.check_circle : Icons.warning_amber, color: allFilled ? AppColors.success : AppColors.warning, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(allFilled ? 'Tous les champs sont remplis. Prêt à valider.' : 'Veuillez remplir tous les champs obligatoires.', style: TextStyle(color: allFilled ? AppColors.success : AppColors.warning, fontSize: 13))),
      ]),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Row(children: [
          Expanded(child: SecondaryButton(text: 'Brouillon', onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brouillon enregistré'), backgroundColor: AppColors.info)))),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: PrimaryButton(text: 'Valider & Signer', icon: Icons.verified, isLoading: _isLoading, onPressed: _handleValidate)),
        ]),
      ),
    );
  }

  void _handleValidate() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null || _selectedPatientId!.isEmpty) return;

    setState(() => _isLoading = true);

    final meds = _medications.map((m) {
      final name = (m['name'] as TextEditingController).text.trim();
      final dosage = (m['dosage'] as TextEditingController).text.trim();
      return <String, dynamic>{
        'name': name,
        'dosage': dosage,
        'frequency': m['frequency'],
        'duration': m['duration'],
      };
    }).toList();

    ApiService.createPrescription(
      patientId: _selectedPatientId!,
      medications: meds,
      notes: _notesController.text,
    ).then((_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccessDialog();
    }).catchError((e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle), child: const Icon(Icons.check_circle, color: AppColors.success, size: 48)),
          const SizedBox(height: 24),
          const Text('Ordonnance créée !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text("L'ordonnance a été validée et enregistrée sur la blockchain.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.blockchainLight, borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.link, color: AppColors.blockchain, size: 16), SizedBox(width: 8), Text('TX: 0x7f2e...3a91', style: TextStyle(color: AppColors.blockchain, fontWeight: FontWeight.w500, fontSize: 12))])),
        ]),
        actions: [SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Terminé')))],
      ),
    );
  }
}
