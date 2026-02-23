import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../services/pharmacy_service.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class PatientMedicationRequestScreen extends StatefulWidget {
  const PatientMedicationRequestScreen({super.key});

  @override
  State<PatientMedicationRequestScreen> createState() => _PatientMedicationRequestScreenState();
}

class _PatientMedicationRequestScreenState extends State<PatientMedicationRequestScreen> {
  List<PharmacyInfo> _pharmacies = [];
  bool _isLoading = true;
  String? _error;
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];

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
      final pharmaciesData = await PharmacyService.getAllPharmacies();
      final pharmacies = pharmaciesData
          .map((item) => PharmacyInfo.fromJson(item as Map<String, dynamic>))
          .toList();
      
      // Create markers for map
      _markers.clear();
      for (var pharmacy in pharmacies) {
        if (pharmacy.latitude != null && pharmacy.longitude != null) {
          _markers.add(
            Marker(
              point: LatLng(pharmacy.latitude!, pharmacy.longitude!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _navigateToMedications(pharmacy),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FACFE),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        }
      }
      
      setState(() {
        _pharmacies = pharmacies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToMedications(PharmacyInfo pharmacy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectMedicationScreen(
          pharmacyId: pharmacy.pharmacyId,
          pharmacyOffersDelivery: pharmacy.offersDelivery,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pharmacies',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPharmacies,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _pharmacies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_pharmacy_outlined,
                            size: 80,
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune pharmacie disponible',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildListView(),
    );
  }

  Widget _buildMapPreview() {
    // Calculate center position from all pharmacies
    double centerLat = 36.7538; // Default to Algiers
    double centerLng = 3.0588;
    
    if (_pharmacies.isNotEmpty) {
      final pharmaciesWithLocation = _pharmacies.where((p) => p.latitude != null && p.longitude != null).toList();
      if (pharmaciesWithLocation.isNotEmpty) {
        centerLat = pharmaciesWithLocation.map((p) => p.latitude!).reduce((a, b) => a + b) / pharmaciesWithLocation.length;
        centerLng = pharmaciesWithLocation.map((p) => p.longitude!).reduce((a, b) => a + b) / pharmaciesWithLocation.length;
      }
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(centerLat, centerLng),
                initialZoom: 12.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.medaichain.medecin_app',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
            // Overlay with pharmacy count
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF4FACFE),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_markers.length} pharmacies',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Attribution (required by OpenStreetMap)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Demandez vos médicaments rapidement',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Map Preview
        _buildMapPreview(),
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFF4FACFE),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pharmacies disponibles (${_pharmacies.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _pharmacies.length,
            itemBuilder: (context, index) {
              final pharmacy = _pharmacies[index];
              return _buildPharmacyCard(pharmacy);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPharmacyCard(PharmacyInfo pharmacy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SelectMedicationScreen(
                  pharmacyId: pharmacy.pharmacyId,
                  pharmacyOffersDelivery: pharmacy.offersDelivery,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    color: Color(0xFF4FACFE),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name ?? 'Pharmacie ${pharmacy.pharmacyId.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (pharmacy.address != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pharmacy.address!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'Voir les médicaments disponibles',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF4FACFE),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PharmacyInfo {
  final String pharmacyId;
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool offersDelivery;

  PharmacyInfo({
    required this.pharmacyId,
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.offersDelivery = false,
  });

  factory PharmacyInfo.fromJson(Map<String, dynamic> json) {
    return PharmacyInfo(
      pharmacyId: json['pharmacyId'] as String,
      name: json['name'] as String?,
      address: json['address'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      offersDelivery: json['offersDelivery'] as bool? ?? false,
    );
  }
}

class SelectMedicationScreen extends StatefulWidget {
  final String pharmacyId;
  final bool pharmacyOffersDelivery;

  const SelectMedicationScreen({
    super.key,
    required this.pharmacyId,
    this.pharmacyOffersDelivery = false,
  });

  @override
  State<SelectMedicationScreen> createState() => _SelectMedicationScreenState();
}

class _SelectMedicationScreenState extends State<SelectMedicationScreen> {
  List<AvailableMedication> _medications = [];
  List<AvailableMedication> _filteredMedications = [];
  final Map<String, int> _selectedMedications = {}; // medicationId -> quantity
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  bool _requestDelivery = false;
  File? _prescriptionImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadMedications();
    _searchController.addListener(_filterMedications);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterMedications() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMedications = _medications;
      } else {
        _filteredMedications = _medications.where((med) {
          return med.name.toLowerCase().contains(query) ||
                 med.dosage.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _pickPrescriptionImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _prescriptionImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Ajouter une ordonnance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF4FACFE)),
              ),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPrescriptionImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Color(0xFF4FACFE)),
              ),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickPrescriptionImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final medicationsData = await PharmacyService.getAvailableMedications(widget.pharmacyId);
      final medications = medicationsData
          .map((item) => AvailableMedication.fromJson(item as Map<String, dynamic>))
          .toList();
      setState(() {
        _medications = medications;
        _filteredMedications = medications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedMedications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un médicament')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final patientId = user?.id ?? '';
      final patientName = user?.email ?? "Patient";

      // Build medications array
      final medications = _selectedMedications.entries.map((entry) {
        final medication = _medications.firstWhere((med) => med.id == entry.key);
        return {
          'medicationName': medication.name,
          'medicationDosage': medication.dosage,
          'quantity': entry.value,
          'unit': medication.unit,
        };
      }).toList();

      // Upload prescription image if present
      String? prescriptionImageUrl;
      if (_prescriptionImage != null) {
        try {
          prescriptionImageUrl = await ApiService.uploadPrescriptionImage(_prescriptionImage!.path);
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de l\'upload de l\'image: $e')),
            );
            return;
          }
        }
      }

      // Get patient location
      Map<String, dynamic>? patientLocation;
      try {
        // Check location permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          patientLocation = {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'address': 'Alger, Algérie', // In production, use reverse geocoding
          };
        }
      } catch (e) {
        print('Location error: $e');
        // Continue without location if there's an error
      }

      // Submit single request with multiple medications
      await PharmacyService.createRequest(
        widget.pharmacyId,
        {
          'patientId': patientId,
          'patientName': patientName,
          'patientPhone': user?.phone ?? '',
          'medications': medications,
          'isUrgent': false,
          'requestsDelivery': _requestDelivery,
          if (prescriptionImageUrl != null) 'prescriptionImageUrl': prescriptionImageUrl,
          if (patientLocation != null) 'patientLocation': patientLocation,
        },
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande envoyée avec succès')),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _showQuantityDialog(AvailableMedication medication) {
    final currentQuantity = _selectedMedications[medication.id] ?? 1;
    int tempQuantity = currentQuantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.medication,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medication.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                medication.dosage,
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
                    
                    const SizedBox(height: 32),
                    
                    // Quantity Label
                    Text(
                      'Quantité',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quantity Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4FACFE).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Decrease button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: tempQuantity > 1
                                  ? () {
                                      setModalState(() {
                                        tempQuantity--;
                                      });
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: tempQuantity > 1
                                      ? const Color(0xFF4FACFE).withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  color: tempQuantity > 1
                                      ? const Color(0xFF4FACFE)
                                      : AppColors.textSecondary.withValues(alpha: 0.3),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          
                          // Quantity display
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Text(
                                    '$tempQuantity',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4FACFE),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    medication.unit,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Increase button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  tempQuantity++;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xFF4FACFE),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick select buttons
                    Text(
                      'Sélection rapide',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [1, 2, 3, 5, 10].map((qty) {
                        final isSelected = tempQuantity == qty;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    tempQuantity = qty;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                                          )
                                        : null,
                                    color: isSelected ? null : AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : AppColors.textSecondary.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    '$qty',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: AppColors.textSecondary.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedMedications[medication.id] = tempQuantity;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF4FACFE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Confirmer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sélectionner un médicament',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMedications,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _medications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 80,
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun médicament disponible',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cardShadow,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: AppColors.textSecondary,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Rechercher un médicament...',
                                      hintStyle: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Médicaments disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_filteredMedications.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun médicament trouvé',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ..._filteredMedications.map((med) => _buildMedicationOption(med)),
                          
                          // Selected Medications Section
                          if (_selectedMedications.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF4FACFE).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart,
                                        color: Color(0xFF4FACFE),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Médicaments sélectionnés (${_selectedMedications.length})',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ..._selectedMedications.entries.map((entry) {
                                    final medication = _medications.firstWhere((m) => m.id == entry.key);
                                    return _buildSelectedMedicationItem(medication, entry.value);
                                  }),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            'Notes (optionnel)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Ajoutez des notes...',
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          
                          // Prescription Image Upload
                          const SizedBox(height: 24),
                          Text(
                            'Ordonnance (optionnel)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_prescriptionImage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF4FACFE).withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      _prescriptionImage!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _prescriptionImage = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _prescriptionImage != null ? Icons.edit : Icons.add_photo_alternate,
                                    color: const Color(0xFF4FACFE),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _prescriptionImage != null 
                                        ? 'Modifier l\'ordonnance'
                                        : 'Ajouter une photo de l\'ordonnance',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4FACFE),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Delivery Request Checkbox (only if pharmacy offers delivery)
                          if (widget.pharmacyOffersDelivery) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF4FACFE).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _requestDelivery,
                                    onChanged: (value) {
                                      setState(() {
                                        _requestDelivery = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xFF4FACFE),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.local_shipping,
                                              color: Color(0xFF4FACFE),
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Demander la livraison',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'La pharmacie livrera les médicaments à votre adresse',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _submitRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Envoyer la demande',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildMedicationOption(AvailableMedication medication) {
    final isSelected = _selectedMedications.containsKey(medication.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            if (isSelected) {
              setState(() {
                _selectedMedications.remove(medication.id);
              });
            } else {
              _showQuantityDialog(medication);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF10B981) 
                    : AppColors.textSecondary.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  color: isSelected ? const Color(0xFF10B981) : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        medication.dosage,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedMedications[medication.id]} ${medication.unit}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedMedicationItem(AvailableMedication medication, int quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medication,
              color: Color(0xFF4FACFE),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${medication.dosage} • $quantity ${medication.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: const Color(0xFF4FACFE),
            onPressed: () => _showQuantityDialog(medication),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () {
              setState(() {
                _selectedMedications.remove(medication.id);
              });
            },
          ),
        ],
      ),
    );
  }
}

class AvailableMedication {
  final String id;
  final String name;
  final String dosage;
  final String unit;

  AvailableMedication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
  });

  factory AvailableMedication.fromJson(Map<String, dynamic> json) {
    return AvailableMedication(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      unit: json['unit'] as String? ?? 'unités',
    );
  }
}
