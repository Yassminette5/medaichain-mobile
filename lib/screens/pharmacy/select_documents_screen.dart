import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pharmacy_model.dart';
import '../../services/api_service.dart';
import '../../services/pharmacy_prescriptions_service.dart';

class SelectDocumentsScreen extends StatefulWidget {
  final List<PharmacyModel> selectedPharmacies;

  const SelectDocumentsScreen({
    super.key,
    required this.selectedPharmacies,
  });

  @override
  State<SelectDocumentsScreen> createState() => _SelectDocumentsScreenState();
}

class _SelectDocumentsScreenState extends State<SelectDocumentsScreen> {
  bool _isLoading = true;
  String? _error;

  List<dynamic> _prescriptions = [];
  List<dynamic> _documents = [];

  final Set<String> _selectedPrescriptionIds = {};
  final Set<String> _selectedDocumentIds = {};

  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        ApiService.getMyPrescriptions(),
        ApiService.getMedicalDocuments(category: 'Ordonnance'),
      ]);

      if (!mounted) return;
      setState(() {
        _prescriptions = futures[0] as List<dynamic>;
        _documents = futures[1] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _shareSelected() async {
    if (_selectedPrescriptionIds.isEmpty && _selectedDocumentIds.isEmpty) return;

    setState(() {
      _isSharing = true;
    });

    final pharmacyIds = widget.selectedPharmacies.map((p) => p.id).toList();

    final success = await PharmacyPrescriptionsService.shareDocuments(
      pharmacyIds: pharmacyIds,
      prescriptionIds: _selectedPrescriptionIds.toList(),
      documentIds: _selectedDocumentIds.toList(),
    );

    if (!mounted) return;

    setState(() {
      _isSharing = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully shared with ${pharmacyIds.length} pharmacies!'),
          backgroundColor: Colors.green,
        ),
      );
      // Mint some tokens as a reward for using the platform
      PharmacyPrescriptionsService.mintTokens(5.0, 'Shared prescriptions with pharmacy');
      Navigator.pop(context); // Go back to pharmacy list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share documents. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPrescriptionCard(dynamic prescription) {
    final String id = prescription['_id'] ?? prescription['id'] ?? '';
    final isSelected = _selectedPrescriptionIds.contains(id);
    final String dateStr = prescription['date'] ?? prescription['createdAt'] ?? '';
    final String title = 'Prescription ${dateStr.split('T').first}';

    return _buildSelectableCard(
      title: title,
      subtitle: 'Digital Prescription',
      icon: Icons.receipt_long,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedPrescriptionIds.remove(id);
          } else {
            _selectedPrescriptionIds.add(id);
          }
        });
      },
    );
  }

  Widget _buildDocumentCard(dynamic document) {
    final String id = document['_id'] ?? document['id'] ?? '';
    final isSelected = _selectedDocumentIds.contains(id);
    final String title = document['title'] ?? 'Document';
    final String category = document['category'] ?? 'Ordonnance';

    return _buildSelectableCard(
      title: title,
      subtitle: category,
      icon: Icons.description,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDocumentIds.remove(id);
          } else {
            _selectedDocumentIds.add(id);
          }
        });
      },
    );
  }

  Widget _buildSelectableCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        elevation: isSelected ? 4 : 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalSelected =
        _selectedPrescriptionIds.length + _selectedDocumentIds.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Select Documents',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary.withValues(alpha: 0.05),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sharing with ${widget.selectedPharmacies.length} pharmacies. Select prescriptions or documents to share.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade400),
                          ),
                        )
                      : (_prescriptions.isEmpty && _documents.isEmpty)
                          ? Center(
                              child: Text(
                                'No prescriptions or documents found.',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textGrey,
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (_prescriptions.isNotEmpty) ...[
                                  Text(
                                    'Digital Prescriptions',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._prescriptions
                                      .map((p) => _buildPrescriptionCard(p)),
                                  const SizedBox(height: 16),
                                ],
                                if (_documents.isNotEmpty) ...[
                                  Text(
                                    'Uploaded Documents',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._documents
                                      .map((d) => _buildDocumentCard(d)),
                                ],
                              ],
                            ),
            ),
            if (totalSelected > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSharing ? null : _shareSelected,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSharing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Share $totalSelected Documents',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
