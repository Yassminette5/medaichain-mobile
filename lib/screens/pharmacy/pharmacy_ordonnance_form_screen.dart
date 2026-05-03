import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/pharmacy_prescriptions_service.dart';
import '../../services/prescriptions_service.dart';
import '../../models/pharmacy_model.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class PharmacyOrdonnanceFormScreen extends StatefulWidget {
  final PharmacyModel pharmacy;
  final String? prescriptionId;

  const PharmacyOrdonnanceFormScreen({
    super.key,
    required this.pharmacy,
    this.prescriptionId,
  });

  @override
  State<PharmacyOrdonnanceFormScreen> createState() =>
      _PharmacyOrdonnanceFormScreenState();
}

class _PharmacyOrdonnanceFormScreenState
    extends State<PharmacyOrdonnanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isUrgent = false;
  bool _requestsDelivery = false;
  bool _isUploadingImage = false;
  String? _uploadedPrescriptionUrl;
  String? _prescriptionFileName;

  final List<MedicationItem> _medications = [];
  late TextEditingController _doctorNameController;

  @override
  void initState() {
    super.initState();
    _doctorNameController = TextEditingController();
    _addMedicationField();
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    super.dispose();
  }

  void _addMedicationField() {
    setState(() {
      _medications.add(MedicationItem());
    });
  }

  void _removeMedicationField(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  bool _isMedicationRowBlank(MedicationItem medication) {
    final name = medication.nameController.text.trim();
    final dosage = medication.dosageController.text.trim();
    final quantity = medication.quantityController.text.trim();
    final quantityIsDefault = quantity.isEmpty || quantity == '1';

    return name.isEmpty && dosage.isEmpty && quantityIsDefault;
  }

  List<Map<String, dynamic>> _buildManualMedicationsPayload() {
    return _medications
        .where((m) => !_isMedicationRowBlank(m))
        .map((m) => {
              'name': m.nameController.text.trim(),
              'dosage': m.dosageController.text.trim(),
              'quantity': int.tryParse(m.quantityController.text.trim()) ?? 1,
              'unit': m.unit,
            })
        .toList();
  }

  Future<void> _pickAndUploadPrescription() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return;

      final file = result.files.single;
      final bytes = file.bytes!;
      const maxSizeBytes = 5 * 1024 * 1024;
      if (bytes.length > maxSizeBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image trop volumineuse (max 5MB)')),
        );
        return;
      }

      setState(() {
        _isUploadingImage = true;
        _prescriptionFileName = file.name;
        _uploadedPrescriptionUrl = null;
      });

      final url = await PharmacyPrescriptionsService.uploadPrescriptionImage(
        bytes,
        file.name,
      );

      if (!mounted) return;

      setState(() {
        _uploadedPrescriptionUrl = url;
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordonnance téléchargée avec succès')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'upload: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patientez, l\'ordonnance est en cours d\'upload')),
      );
      return;
    }

    final medicationsData = _buildManualMedicationsPayload();
    final hasPrescriptionImage = _uploadedPrescriptionUrl != null;

    if (medicationsData.isEmpty && !hasPrescriptionImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'either a picture of the prescription or a list of medication should be present',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await PharmacyPrescriptionsService.sendMedicationRequest(
        pharmacyId: widget.pharmacy.id,
        patientId: user.id ?? '',
        patientName: user.fullName ?? 'Unknown Patient',
        patientPhone: user.phone ?? '',
        medications: medicationsData,
        prescriptionImageUrl: _uploadedPrescriptionUrl,
        doctorName: _doctorNameController.text.isNotEmpty
            ? _doctorNameController.text
            : null,
        isUrgent: _isUrgent,
        requestsDelivery: _requestsDelivery,
      );

      await _sharePrescriptionIfAvailable();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prescription sent successfully! ✅'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sharePrescriptionIfAvailable() async {
    final prescriptionId = widget.prescriptionId ?? await _getLatestPrescriptionId();
    if (prescriptionId == null || prescriptionId.isEmpty) {
      return;
    }

    try {
      await PharmacyPrescriptionsService.sharePrescriptionWithPharmacy(
        prescriptionId: prescriptionId,
        pharmacyId: widget.pharmacy.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ordonnance partagée en toute sécurité ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Share prescription failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Envoi réussi, mais partage sécurisé échoué: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<String?> _getLatestPrescriptionId() async {
    try {
      final prescriptions = await PrescriptionsService.getMyPrescriptions();
      if (prescriptions.isEmpty) return null;
      final latest = prescriptions.first;
      return _extractPrescriptionId(latest);
    } catch (e) {
      debugPrint('❌ Failed to load prescriptions: $e');
      return null;
    }
  }

  String? _extractPrescriptionId(Map<String, dynamic> data) {
    final id = data['_id'] ?? data['id'] ?? data['prescriptionId'];
    if (id == null) return null;
    return id.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Send Prescription',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pharmacy Info Card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send to:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.pharmacy.pharmacyName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${widget.pharmacy.address}, ${widget.pharmacy.city}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            widget.pharmacy.is24Hours
                                ? 'Open 24/7'
                                : '${widget.pharmacy.openingTime} - ${widget.pharmacy.closingTime}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Doctor Name
              Text(
                'Doctor Name (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _doctorNameController,
                decoration: InputDecoration(
                  hintText: 'Enter doctor\'s name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 24),

              // Prescription Image (Optional)
              Text(
                'Prescription Image (Optional - use image or manual entry)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attach a clear photo of the original prescription (max 5MB) to speed up validation.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_prescriptionFileName != null)
                                  Text(
                                    _prescriptionFileName!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                if (_uploadedPrescriptionUrl != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Upload ready',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (_isUploadingImage)
                                  Row(
                                    children: [
                                      const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Uploading...',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (_prescriptionFileName == null && !_isUploadingImage)
                                  Text(
                                    'No image selected',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _isUploadingImage ? null : _pickAndUploadPrescription,
                            icon: const Icon(Icons.upload_file),
                            label: Text(
                              _uploadedPrescriptionUrl != null ? 'Change' : 'Attach',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Medications Section
              Text(
                'Medications (Manual - optional if image is attached)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _medications.length,
                itemBuilder: (context, index) {
                  return _buildMedicationField(index);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addMedicationField,
                icon: const Icon(Icons.add),
                label: Text(
                  'Add Medication',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),

              // Options
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: Text(
                          'Urgent',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Mark as urgent request',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                        value: _isUrgent,
                        onChanged: (value) {
                          setState(() => _isUrgent = value ?? false);
                        },
                        activeColor: AppColors.primary,
                      ),
                      if (widget.pharmacy.hasDelivery)
                        CheckboxListTile(
                          title: Text(
                            'Request Delivery',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Deliver to my location',
                            style: GoogleFonts.poppins(fontSize: 11),
                          ),
                          value: _requestsDelivery,
                          onChanged: (value) {
                            setState(
                                () => _requestsDelivery = value ?? false);
                          },
                          activeColor: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : Text(
                          'Send Prescription',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationField(int index) {
    final medication = _medications[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medication ${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (_medications.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeMedicationField(index),
                    iconSize: 18,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Medication Name
            TextFormField(
              controller: medication.nameController,
              decoration: InputDecoration(
                labelText: 'Medication Name${_uploadedPrescriptionUrl == null ? ' *' : ''}',
                hintText: 'e.g., Paracetamol',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (_isMedicationRowBlank(medication)) {
                  return null;
                }
                if (value == null || value.trim().isEmpty) {
                  return 'Medication name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            // Dosage
            TextFormField(
              controller: medication.dosageController,
              decoration: InputDecoration(
                labelText: 'Dosage',
                hintText: 'e.g., 500mg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Quantity and Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: medication.quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity${_uploadedPrescriptionUrl == null ? ' *' : ''}',
                      hintText: '1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_isMedicationRowBlank(medication)) {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: medication.unit,
                    items: ['units', 'boxes', 'bottles', 'tubes', 'packs']
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        medication.unit = value;
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MedicationItem {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController quantityController =
      TextEditingController(text: '1');
  String unit = 'units';

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    quantityController.dispose();
  }
}
