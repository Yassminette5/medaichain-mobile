import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/prescriptions_service.dart';
import '../../services/pharmacy_prescriptions_service.dart';
import '../../models/pharmacy_model.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SelectDocumentsScreen extends StatefulWidget {
  final List<PharmacyModel> selectedPharmacies;

  const SelectDocumentsScreen({super.key, required this.selectedPharmacies});

  @override
  State<SelectDocumentsScreen> createState() => _SelectDocumentsScreenState();
}

class _SelectDocumentsScreenState extends State<SelectDocumentsScreen> {
  List<Map<String, dynamic>> _prescriptions = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = false;
  bool _isSharing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prescriptions = await PrescriptionsService.getMyPrescriptions();
      if (!mounted) return;
      setState(() {
        _prescriptions = prescriptions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _extractId(Map<String, dynamic> p) {
    return (p['_id'] ?? p['id'] ?? p['prescriptionId'] ?? '').toString();
  }

  String _formatDate(Map<String, dynamic> p) {
    final dateStr = p['prescriptionDate'] ?? p['createdAt'];
    if (dateStr == null) return '--';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  String _getDoctorName(Map<String, dynamic> p) {
    final doctor = p['doctorId'];
    if (doctor is Map) {
      return (doctor['fullName'] ?? doctor['email'] ?? 'Médecin').toString();
    }
    return 'Médecin';
  }

  String _getUrgency(Map<String, dynamic> p) {
    final raw = (p['urgency'] ?? p['priority'] ?? p['emergencyLevel'] ?? '').toString().toLowerCase().trim();
    if (raw.isEmpty || raw == 'normal' || raw == 'low') {
      return raw == 'low' ? 'BASSE' : 'NORMALE';
    }
    if (raw == 'urgent' || raw == 'high' || raw == 'emergency' || raw == 'urgent') {
      return 'URGENT';
    }
    return raw.toUpperCase();
  }

  Color _getUrgencyColor(String urgency) {
    final normalized = urgency.toLowerCase();
    if (normalized == 'urgent') return AppColors.error;
    if (normalized == 'basse' || normalized == 'low') return AppColors.success;
    return AppColors.warning;
  }

  String _getStatus(Map<String, dynamic> p) {
    final raw = (p['status'] ?? 'active').toString().toLowerCase().trim();
    if (raw == 'termine' || raw == 'terminé' || raw == 'terminée' || raw == 'done' || raw == 'finished') {
      return 'completed';
    }
    if (raw == 'completed' || raw == 'complété' || raw == 'complétée') {
      return 'completed';
    }
    if (raw == 'cancelled' || raw == 'canceled' || raw == 'annulé' || raw == 'annule' || raw == 'annulée') {
      return 'cancelled';
    }
    if (raw == 'active' || raw == 'pending' || raw == 'in_progress') {
      return 'active';
    }
    return raw;
  }

  Color _getStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'active') return Colors.green;
    if (normalized == 'completed') return Colors.blue;
    if (normalized == 'cancelled') return AppColors.error;
    return AppColors.warning;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _prescriptions.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (final p in _prescriptions) {
          _selectedIds.add(_extractId(p));
        }
      }
    });
  }

  Future<void> _shareDocuments() async {
    if (_selectedIds.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final patientId = user?.id ?? '';
    final patientName = user?.fullName ?? user?.email ?? 'Patient';
    final patientPhone = user?.phone ?? '';

    setState(() => _isSharing = true);

    try {
      final pharmacyIds = widget.selectedPharmacies.map((p) => p.id).toList();

      // First, share the documents normally
      await PharmacyPrescriptionsService.shareDocuments(
        prescriptionIds: _selectedIds.toList(),
        pharmacyIds: pharmacyIds,
      );

      // Second, generate a dynamic MedicationRequest so it appears in the dashboard stats
      final selectedPrescriptions = _prescriptions
          .where((p) => _selectedIds.contains(_extractId(p)))
          .toList();

      List<Map<String, dynamic>> allMedications = [];
      String? firstImageUrl;
      String? doctorName;

      for (var p in selectedPrescriptions) {
        if (p['medications'] != null && p['medications'] is List) {
          // Keep only name, dosage, quantity, unit
          for (var med in p['medications']) {
            allMedications.add({
              'name': med['name'] ?? med['medicationName'] ?? 'Médicament',
              'dosage': med['dosage'] ?? '',
              'quantity': med['quantity'] ?? 1,
              'unit': med['unit'] ?? 'unités',
            });
          }
        }
        if (firstImageUrl == null && p['prescriptionImageUrl'] != null) {
          firstImageUrl = p['prescriptionImageUrl'];
        }
        if (doctorName == null || doctorName == 'Médecin') {
          doctorName = _getDoctorName(p);
        }
      }

      if (allMedications.isNotEmpty) {
        for (var pharmacyId in pharmacyIds) {
          try {
            await PharmacyPrescriptionsService.sendMedicationRequest(
              pharmacyId: pharmacyId,
              patientId: patientId,
              patientName: patientName,
              patientPhone: patientPhone,
              medications: allMedications,
              prescriptionImageUrl: firstImageUrl,
              doctorName: doctorName,
              isUrgent: false,
              requestsDelivery: false,
            );
          } catch (_) {
            // Ignore individual pharmacy request failures
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedIds.length} document(s) partagé(s) avec ${pharmacyIds.length} pharmacie(s) ✅',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // Pop back to the pharmacy list, then pop that too
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyNames = widget.selectedPharmacies
        .map((p) => p.pharmacyName)
        .join(', ');

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
        actions: [
          if (_prescriptions.isNotEmpty)
            TextButton(
              onPressed: _selectAll,
              child: Text(
                _selectedIds.length == _prescriptions.length
                    ? 'Deselect All'
                    : 'Select All',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sharing To Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sharing with ${widget.selectedPharmacies.length} pharmacy(ies):',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pharmacyNames,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Documents List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading prescriptions',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error ?? 'Unknown error',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadPrescriptions,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _prescriptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No prescriptions found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have no prescriptions to share',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _prescriptions.length,
                      itemBuilder: (context, index) {
                        final p = _prescriptions[index];
                        final id = _extractId(p);
                        final isSelected = _selectedIds.contains(id);
                        return _buildDocumentCard(p, id, isSelected);
                      },
                    ),
            ),
            // Bottom Share Button
            if (_selectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isSharing ? null : _shareDocuments,
                      icon: _isSharing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.share_rounded,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isSharing
                            ? 'Sharing...'
                            : 'Share ${_selectedIds.length} Document(s)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
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

  Widget _buildDocumentCard(
    Map<String, dynamic> prescription,
    String id,
    bool isSelected,
  ) {
    final doctorName = _getDoctorName(prescription);
    final date = _formatDate(prescription);
    final status = _getStatus(prescription);
    final urgencyLabel = _getUrgency(prescription);
    final urgencyColor = _getUrgencyColor(urgencyLabel);
    final statusColor = _getStatusColor(status);
    final imageUrl = prescription['prescriptionImageUrl']?.toString();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSelected
                ? BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
          elevation: isSelected ? 4 : 2,
          child: InkWell(
            onTap: () => _toggleSelection(id),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildSelectionCheckbox(isSelected),
                            const SizedBox(width: 14),
                            _buildPrescriptionThumbnail(hasImage, imageUrl),
                            const SizedBox(width: 14),
                            Expanded(child: _buildDocumentInfo(doctorName, date, urgencyLabel, urgencyColor, status, statusColor)),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildSelectionCheckbox(isSelected),
                        const SizedBox(width: 14),
                        _buildPrescriptionThumbnail(hasImage, imageUrl),
                        const SizedBox(width: 14),
                        Expanded(child: _buildDocumentInfo(doctorName, date, urgencyLabel, urgencyColor, status, statusColor)),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionCheckbox(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.textGrey,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : null,
    );
  }

  Widget _buildPrescriptionThumbnail(bool hasImage, String? imageUrl) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: hasImage
            ? null
            : LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
        color: hasImage ? Colors.transparent : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: hasImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            )
          : Icon(
              Icons.description_rounded,
              color: AppColors.primary,
              size: 28,
            ),
    );
  }

  Widget _buildDocumentInfo(
    String doctorName,
    String date,
    String urgencyLabel,
    Color urgencyColor,
    String status,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dr. $doctorName',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Wrap(
          runSpacing: 6,
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: AppColors.textGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
            if (urgencyLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  urgencyLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: urgencyColor,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
