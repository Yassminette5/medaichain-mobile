import 'package:flutter/material.dart';

/// Model for medication request screen
class MedicationRequestForm {
  final String? searchQuery;
  final PrescriptionUpload? prescription;
  final bool isUrgent;
  final List<Pharmacy> closestPharmacies;
  final Pharmacy? selectedPharmacy;

  MedicationRequestForm({
    this.searchQuery,
    this.prescription,
    this.isUrgent = false,
    required this.closestPharmacies,
    this.selectedPharmacy,
  });

  factory MedicationRequestForm.fromJson(Map<String, dynamic> json) {
    return MedicationRequestForm(
      searchQuery: json['searchQuery'] as String?,
      prescription: json['prescription'] != null
          ? PrescriptionUpload.fromJson(json['prescription'] as Map<String, dynamic>)
          : null,
      isUrgent: json['isUrgent'] as bool? ?? false,
      closestPharmacies: (json['closestPharmacies'] as List)
          .map((item) => Pharmacy.fromJson(item as Map<String, dynamic>))
          .toList(),
      selectedPharmacy: json['selectedPharmacy'] != null
          ? Pharmacy.fromJson(json['selectedPharmacy'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searchQuery': searchQuery,
      'prescription': prescription?.toJson(),
      'isUrgent': isUrgent,
      'closestPharmacies': closestPharmacies.map((item) => item.toJson()).toList(),
      'selectedPharmacy': selectedPharmacy?.toJson(),
    };
  }

  MedicationRequestForm copyWith({
    String? searchQuery,
    PrescriptionUpload? prescription,
    bool? isUrgent,
    List<Pharmacy>? closestPharmacies,
    Pharmacy? selectedPharmacy,
  }) {
    return MedicationRequestForm(
      searchQuery: searchQuery ?? this.searchQuery,
      prescription: prescription ?? this.prescription,
      isUrgent: isUrgent ?? this.isUrgent,
      closestPharmacies: closestPharmacies ?? this.closestPharmacies,
      selectedPharmacy: selectedPharmacy ?? this.selectedPharmacy,
    );
  }
}

/// Model for prescription upload
class PrescriptionUpload {
  final String id;
  final String fileName;
  final String filePath;
  final DateTime uploadDate;
  final int fileSize;

  PrescriptionUpload({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.uploadDate,
    required this.fileSize,
  });

  factory PrescriptionUpload.fromJson(Map<String, dynamic> json) {
    return PrescriptionUpload(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      uploadDate: DateTime.parse(json['uploadDate'] as String),
      fileSize: json['fileSize'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'uploadDate': uploadDate.toIso8601String(),
      'fileSize': fileSize,
    };
  }
}

/// Model for pharmacy location and details
class Pharmacy {
  final String id;
  final String name;
  final PharmacyLocation location;
  final double distance;
  final String distanceUnit;
  final PharmacyHours hours;
  final bool isOpen;
  final String? logoUrl;

  Pharmacy({
    required this.id,
    required this.name,
    required this.location,
    required this.distance,
    this.distanceUnit = 'mi',
    required this.hours,
    required this.isOpen,
    this.logoUrl,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'] as String,
      name: json['name'] as String,
      location: PharmacyLocation.fromJson(json['location'] as Map<String, dynamic>),
      distance: (json['distance'] as num).toDouble(),
      distanceUnit: json['distanceUnit'] as String? ?? 'mi',
      hours: PharmacyHours.fromJson(json['hours'] as Map<String, dynamic>),
      isOpen: json['isOpen'] as bool,
      logoUrl: json['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location.toJson(),
      'distance': distance,
      'distanceUnit': distanceUnit,
      'hours': hours.toJson(),
      'isOpen': isOpen,
      'logoUrl': logoUrl,
    };
  }

  String get displayDistance => '$distance $distanceUnit';
  String get displayHours => hours.displayText;
}

/// Model for pharmacy location
class PharmacyLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;

  PharmacyLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
  });

  factory PharmacyLocation.fromJson(Map<String, dynamic> json) {
    return PharmacyLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
    };
  }

  String get fullAddress {
    final parts = [address, city, state, zipCode].where((p) => p != null && p.isNotEmpty);
    return parts.join(', ');
  }
}

/// Model for pharmacy operating hours
class PharmacyHours {
  final String? openTime;
  final String? closeTime;
  final bool is24Hours;

  PharmacyHours({
    this.openTime,
    this.closeTime,
    this.is24Hours = false,
  });

  factory PharmacyHours.fromJson(Map<String, dynamic> json) {
    return PharmacyHours(
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      is24Hours: json['is24Hours'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'openTime': openTime,
      'closeTime': closeTime,
      'is24Hours': is24Hours,
    };
  }

  String get displayText {
    if (is24Hours) return '24 Hours';
    if (openTime != null && closeTime != null) {
      return 'Open until $closeTime';
    }
    return 'Closes soon';
  }
}

// ============================================================================
// PREVIEW WIDGET
// ============================================================================

/// Preview screen for Medication Request interface
class MedicationRequestPreview extends StatefulWidget {
  const MedicationRequestPreview({super.key});

  @override
  State<MedicationRequestPreview> createState() => _MedicationRequestPreviewState();
}

class _MedicationRequestPreviewState extends State<MedicationRequestPreview> {
  bool isUrgent = false;
  Map<String, String?> pharmacyStatus = {}; // null = not processed, 'valid' or 'invalid' = processed

  @override
  Widget build(BuildContext context) {
    // Sample data
    final pharmacies = [
      Pharmacy(
        id: '1',
        name: 'Pharmacie CVS',
        location: PharmacyLocation(
          latitude: 40.7128,
          longitude: -74.0060,
          address: '123 Main St',
          city: 'New York',
          state: 'NY',
          zipCode: '10001',
        ),
        distance: 0.8,
        distanceUnit: 'mi',
        hours: PharmacyHours(openTime: '8:00 AM', closeTime: '9:00 PM'),
        isOpen: true,
        logoUrl: null,
      ),
      Pharmacy(
        id: '2',
        name: 'Walgreens',
        location: PharmacyLocation(
          latitude: 40.7128,
          longitude: -74.0060,
          address: '456 Oak Ave',
          city: 'New York',
          state: 'NY',
          zipCode: '10002',
        ),
        distance: 1.2,
        distanceUnit: 'mi',
        hours: PharmacyHours(is24Hours: true),
        isOpen: true,
        logoUrl: null,
      ),
      Pharmacy(
        id: '3',
        name: 'Pharmacie Locale',
        location: PharmacyLocation(
          latitude: 40.7128,
          longitude: -74.0060,
          address: '789 Elm St',
          city: 'New York',
          state: 'NY',
          zipCode: '10003',
        ),
        distance: 2.4,
        distanceUnit: 'mi',
        hours: PharmacyHours(openTime: '9:00 AM', closeTime: '6:00 PM'),
        isOpen: false,
        logoUrl: null,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C6FDC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Demande de Médicament',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8F5)),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Rechercher un médicament...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Upload Prescription
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8F5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Télécharger l\'Ordonnance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Vous avez une photo? Téléchargez votre ordonnance directement.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6FDC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.upload_file, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Télécharger', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Urgent Request Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8F5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Demande Urgente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Prioriser la disponibilité et la rapidité',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isUrgent,
                    onChanged: (value) {
                      setState(() {
                        isUrgent = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF7C6FDC),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Closest Pharmacies Section
            const Text(
              'Pharmacies les Plus Proches',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Map Preview
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8F5)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.map,
                      size: 80,
                      color: const Color(0xFF7C6FDC).withOpacity(0.3),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E8F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.my_location, size: 20, color: Color(0xFF7C6FDC)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Pharmacy List
            ...pharmacies.map((pharmacy) => _buildPharmacyItem(pharmacy)),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyItem(Pharmacy pharmacy) {
    final status = pharmacyStatus[pharmacy.id];
    final isProcessed = status != null;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacyDetailsPage(pharmacy: pharmacy),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8F5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_pharmacy, color: Color(0xFF7C6FDC)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Color(0xFF7C6FDC)),
                          const SizedBox(width: 4),
                          Text(
                            pharmacy.displayDistance,
                            style: const TextStyle(color: Color(0xFF7C6FDC), fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            pharmacy.displayHours,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            ],
              ),
          
        
      ),
    );
  }
}

// ============================================================================
// PHARMACY DETAILS PAGE
// ============================================================================

/// Detailed view of a pharmacy
class PharmacyDetailsPage extends StatelessWidget {
  final Pharmacy pharmacy;

  const PharmacyDetailsPage({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C6FDC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détails de la Pharmacie',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pharmacy Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E8F5)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.local_pharmacy, color: Color(0xFF7C6FDC), size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pharmacy.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: pharmacy.isOpen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pharmacy.isOpen ? 'Ouvert' : 'Fermé',
                      style: TextStyle(
                        color: pharmacy.isOpen ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Location Info
            _buildInfoSection(
              icon: Icons.location_on,
              title: 'Adresse',
              content: pharmacy.location.fullAddress,
            ),
            const SizedBox(height: 16),
            
            // Distance Info
            _buildInfoSection(
              icon: Icons.directions,
              title: 'Distance',
              content: pharmacy.displayDistance,
            ),
            const SizedBox(height: 16),
            
            // Hours Info
            _buildInfoSection(
              icon: Icons.access_time,
              title: 'Horaires',
              content: pharmacy.hours.is24Hours 
                  ? '24 heures / 7 jours'
                  : 'Ouvert de ${pharmacy.hours.openTime ?? "N/A"} à ${pharmacy.hours.closeTime ?? "N/A"}',
            ),
            const SizedBox(height: 24),
            
            // Services Section
            const Text(
              'Services Disponibles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildServiceItem('Ordonnances', Icons.description, true),
            _buildServiceItem('Médicaments en vente libre', Icons.medication, true),
            _buildServiceItem('Conseils pharmaceutiques', Icons.support_agent, true),
            _buildServiceItem('Livraison à domicile', Icons.local_shipping, true),
            _buildServiceItem('Tests COVID-19', Icons.coronavirus, false),
            const SizedBox(height: 24),
            
            // Contact Section
            const Text(
              'Contact',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildContactButton(
              icon: Icons.phone,
              label: 'Appeler',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildContactButton(
              icon: Icons.directions,
              label: 'Itinéraire',
              onTap: () {},
            ),
            const SizedBox(height: 24),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: pharmacy.isOpen ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6FDC),
                  disabledBackgroundColor: const Color(0xFFE8E8F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  pharmacy.isOpen ? 'Demander un Médicament' : 'Pharmacie Fermée',
                  style: TextStyle(
                    color: pharmacy.isOpen ? Colors.white : Colors.grey,
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

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8F5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF7C6FDC), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

  Widget _buildServiceItem(String label, IconData icon, bool available) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8F5)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: available ? const Color(0xFF7C6FDC) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: available ? Colors.white : Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? Colors.green : Colors.grey,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8F5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF7C6FDC), size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}


