import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/pharmacy_model.dart';
import 'select_documents_screen.dart';

class PharmaciesListScreen extends StatefulWidget {
  const PharmaciesListScreen({super.key, this.prescriptionId});

  final String? prescriptionId;

  @override
  State<PharmaciesListScreen> createState() => _PharmaciesListScreenState();
}

class _PharmaciesListScreenState extends State<PharmaciesListScreen> {
  List<PharmacyModel> _pharmacies = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  final Set<String> _selectedPharmacyIds = {};

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rawPharmacies = await ApiService.getPharmacies();
      final pharmacies = rawPharmacies
          .map((p) => PharmacyModel.fromJson(p))
          .toList();

      if (!mounted) return;
      setState(() {
        _pharmacies = pharmacies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      debugPrint('❌ Error loading pharmacies: $e');
    }
  }

  List<PharmacyModel> get _filteredPharmacies {
    final sorted = [..._pharmacies]..sort((a, b) {
      final aBoost = _isBoostActive(a) ? 1 : 0;
      final bBoost = _isBoostActive(b) ? 1 : 0;
      if (aBoost != bBoost) return bBoost - aBoost;
      if (a.boostScore != b.boostScore) return b.boostScore - a.boostScore;
      return a.pharmacyName.compareTo(b.pharmacyName);
    });

    if (_searchQuery.isEmpty) return sorted;
    return sorted
        .where((p) =>
            p.pharmacyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.wilaya.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  bool _isBoostActive(PharmacyModel pharmacy) {
    final boostedUntil = pharmacy.boostedUntil;
    return boostedUntil != null && boostedUntil.isAfter(DateTime.now());
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedPharmacyIds.contains(id)) {
        _selectedPharmacyIds.remove(id);
      } else {
        _selectedPharmacyIds.add(id);
      }
    });
  }

  void _navigateToDocuments() {
    final selectedPharmacies = _pharmacies
        .where((p) => _selectedPharmacyIds.contains(p.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectDocumentsScreen(
          selectedPharmacies: selectedPharmacies,
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        // Go back to health drawer after successful share
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Select Pharmacies',
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
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search pharmacy, city...',
                  hintStyle: GoogleFonts.poppins(color: AppColors.textGrey),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            // Selection Hint
            if (_selectedPharmacyIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedPharmacyIds.length} pharmacy(ies) selected',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _selectedPharmacyIds.clear()),
                        child: Text(
                          'Clear',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Pharmacies List
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
                                'Error loading pharmacies',
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
                                onPressed: _loadPharmacies,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _filteredPharmacies.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_pharmacy_outlined,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No pharmacies found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Try a different search'
                                        : 'No pharmacies available',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _filteredPharmacies.length,
                              itemBuilder: (context, index) {
                                final pharmacy = _filteredPharmacies[index];
                                return _buildPharmacyCard(
                                  context,
                                  pharmacy,
                                );
                              },
                            ),
            ),
            // Bottom Continue Button
            if (_selectedPharmacyIds.isNotEmpty)
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
                      onPressed: _navigateToDocuments,
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white),
                      label: Text(
                        'Continue — Select Documents',
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

  Widget _buildPharmacyCard(BuildContext context, PharmacyModel pharmacy) {
    final isOpen = pharmacy.isOpen;
    final statusColor = isOpen ? Colors.green : Colors.orange;
    final isSelected = _selectedPharmacyIds.contains(pharmacy.id);

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
        onTap: () => _toggleSelection(pharmacy.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name, status, and checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 26,
                    width: 26,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.textGrey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pharmacy.pharmacyName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pharmacy.ownerName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOpen ? 'Open' : 'Closed',
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isBoostActive(pharmacy)) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: const Color(0xFF7C3AED)
                            .withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          size: 14, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 6),
                      Text(
                        'Boosted by FRYMN',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Location
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${pharmacy.address}, ${pharmacy.city}, ${pharmacy.wilaya}',
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
              // Hours
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    pharmacy.is24Hours
                        ? 'Open 24/7'
                        : '${pharmacy.openingTime} - ${pharmacy.closingTime}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Services
              if (pharmacy.services.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  children: pharmacy.services.take(3).map((service) {
                    return Chip(
                      label: Text(
                        service,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              // Delivery info
              if (pharmacy.hasDelivery)
                Row(
                  children: [
                    const Icon(Icons.local_shipping,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      'Delivery up to ${pharmacy.deliveryRadius}km',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
