import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medicines_provider.dart';
import '../../../services/api_service.dart';
import '../../../models/medicine_model.dart';
import 'package:intl/intl.dart';

class MedicalRoutineSummaryScreen extends StatefulWidget {
  const MedicalRoutineSummaryScreen({super.key});

  @override
  State<MedicalRoutineSummaryScreen> createState() => _MedicalRoutineSummaryScreenState();
}

class _MedicalRoutineSummaryScreenState extends State<MedicalRoutineSummaryScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final medicinesProvider = Provider.of<MedicinesProvider>(context);
    final patientName = authProvider.user?.fullName ?? "Patient";
    final dateStr = DateFormat('dd MMMM yyyy', 'fr_FR').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Ma Routine Médicale', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Screenshot(
                controller: _screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 40),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          "Ma Routine Médicale",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "Généré pour $patientName\n$dateStr",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textGrey,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 24),
                      Text(
                        "Traitement en cours",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (medicinesProvider.medicines.isEmpty)
                        Text(
                          "Aucun médicament enregistré pour le moment.",
                          style: GoogleFonts.poppins(color: AppColors.textGrey, fontStyle: FontStyle.italic),
                        )
                      else
                        ...medicinesProvider.medicines.map((med) => _buildMedItem(med)),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          "MedAiChain - Votre Assistant Santé Digital",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.textGrey.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMedItem(Medicine med) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIconData(med.type), color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  med.dosage,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  "Prises : ${med.schedule.map((s) => s.replaceAll('_', ' ')).join(', ')}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String type) {
    switch (type.toLowerCase()) {
      case 'pill': return Icons.medication;
      case 'syringe': return Icons.medical_services_outlined;
      case 'eye-drops': return Icons.remove_red_eye_outlined;
      default: return Icons.medication_rounded;
    }
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isExporting ? null : _saveToGallery,
              icon: _isExporting 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_rounded),
              label: const Text('Enregistrer PNG'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _selectAndSendToDoctor,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Envoyer Docteur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToGallery() async {
    setState(() => _isExporting = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        await Gal.putImageBytes(imageBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Routine enregistrée dans votre galerie !'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _selectAndSendToDoctor() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DoctorPickerSheet(
        onSelected: (doctor) async {
          Navigator.pop(ctx);
          await _sendToDoctor(doctor);
        },
      ),
    );
  }

  Future<void> _sendToDoctor(Map<String, dynamic> doctor) async {
    setState(() => _isExporting = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes == null) return;

      // Uploader le PNG comme document médical
      final String doctorName = doctor['fullName'] ?? 'Docteur';
      await ApiService.uploadMedicalDocument(
        fileBytes: imageBytes,
        fileName: 'routine_export.png',
        title: 'Routine Médicale - Export',
        category: 'Verification',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Routine envoyée à $doctorName !'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'envoi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

class _DoctorPickerSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelected;
  const _DoctorPickerSheet({required this.onSelected});

  @override
  State<_DoctorPickerSheet> createState() => _DoctorPickerSheetState();
}

class _DoctorPickerSheetState extends State<_DoctorPickerSheet> {
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final list = await ApiService.searchDoctors();
      if (mounted) setState(() { _doctors = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text('Sélectionner un Médecin', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _doctors.isEmpty
                ? const Center(child: Text('Aucun médecin trouvé'))
                : ListView.builder(
                    itemCount: _doctors.length,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemBuilder: (ctx, i) {
                      final d = _doctors[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
                        title: Text(d['fullName'] ?? 'Médecin', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Text(d['speciality'] ?? 'Spécialiste', style: GoogleFonts.poppins(fontSize: 12)),
                        onTap: () => widget.onSelected(d),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
