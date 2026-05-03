// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// Model for pharmacy dashboard
class PharmacyDashboard {
  final PharmacyInfo pharmacyInfo;
  final List<MedicationRequest> medicationRequests;

  PharmacyDashboard({
    required this.pharmacyInfo,
    required this.medicationRequests,
  });

  factory PharmacyDashboard.fromJson(Map<String, dynamic> json) {
    return PharmacyDashboard(
      pharmacyInfo: PharmacyInfo.fromJson(json['pharmacyInfo'] as Map<String, dynamic>),
      medicationRequests: (json['medicationRequests'] as List)
          .map((item) => MedicationRequest.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pharmacyInfo': pharmacyInfo.toJson(),
      'medicationRequests': medicationRequests.map((item) => item.toJson()).toList(),
    };
  }

  List<MedicationRequest> getRequestsByStatus(RequestStatus status) {
    return medicationRequests.where((req) => req.status == status).toList();
  }
}

/// Model for pharmacy information
class PharmacyInfo {
  final String id;
  final String name;
  final int totalOrders;
  final int totalPackages;
  final bool offersDelivery;

  PharmacyInfo({
    required this.id,
    required this.name,
    required this.totalOrders,
    required this.totalPackages,
    this.offersDelivery = false,
  });

  factory PharmacyInfo.fromJson(Map<String, dynamic> json) {
    return PharmacyInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      totalOrders: json['totalOrders'] as int,
      totalPackages: json['totalPackages'] as int,
      offersDelivery: json['offersDelivery'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalOrders': totalOrders,
      'totalPackages': totalPackages,
      'offersDelivery': offersDelivery,
    };
  }
}

/// Enum for medication request status
enum RequestStatus {
  tout,
  urgent,
  enAttente,
  valide,
  nonValide;

  String get displayName {
    switch (this) {
      case RequestStatus.tout:
        return 'Tout';
      case RequestStatus.urgent:
        return 'Urgent';
      case RequestStatus.enAttente:
        return 'En Attente';
      case RequestStatus.valide:
        return 'Validée';
      case RequestStatus.nonValide:
        return 'Rejetée';
    }
  }
}

extension RequestStatusParsing on RequestStatus {
  static RequestStatus fromJson(String? rawStatus) {
    final raw = rawStatus?.toString().toLowerCase().trim() ?? '';
    if (raw.isEmpty) return RequestStatus.enAttente;
    if (raw == 'urgent' || raw == 'urgente') return RequestStatus.urgent;
    if (raw == 'enattente' || raw == 'en_attente' || raw == 'en attente' ||
        raw == 'en cours' || raw == 'pending' || raw == 'en attente') {
      return RequestStatus.enAttente;
    }
    if (raw == 'valide' || raw == 'validé' || raw == 'validée' || raw == 'completed') {
      return RequestStatus.valide;
    }
    if (raw == 'nonvalide' || raw == 'non_valide' || raw == 'non valable' ||
        raw == 'non valable' || raw == 'rejected' || raw == 'rejetée') {
      return RequestStatus.nonValide;
    }
    if (raw == 'termine' || raw == 'terminé' || raw == 'terminée' ||
        raw == 'done' || raw == 'finished') {
      return RequestStatus.valide;
    }
    return RequestStatus.enAttente;
  }
}

/// Model for medication request
class MedicationRequest {
  final String id;
  final Patient patient;
  final List<RequestedMedication> medications;
  final RequestStatus status;
  final DateTime requestDate;
  final bool isUrgent;
  final bool requestsDelivery;
  final String? prescriptionImageUrl;

  MedicationRequest({
    required this.id,
    required this.patient,
    required this.medications,
    required this.status,
    required this.requestDate,
    this.isUrgent = false,
    this.requestsDelivery = false,
    this.prescriptionImageUrl,
  });

  factory MedicationRequest.fromJson(Map<String, dynamic> json) {
    // Handle both old format (single medication) and new format (multiple medications)
    List<RequestedMedication> medications;
    if (json['medications'] != null) {
      medications = (json['medications'] as List)
          .map((item) => RequestedMedication.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (json['medication'] != null) {
      // Backward compatibility: convert single medication to list
      medications = [RequestedMedication.fromJson(json['medication'] as Map<String, dynamic>)];
    } else {
      medications = [];
    }

    return MedicationRequest(
      id: (json['id'] ?? json['_id']) as String,
      patient: Patient.fromJson(json['patient'] as Map<String, dynamic>),
      medications: medications,
      status: RequestStatusParsing.fromJson(json['status']?.toString()),
      requestDate: DateTime.parse(json['requestDate'] as String),
      isUrgent: json['isUrgent'] as bool? ?? false,
      requestsDelivery: json['requestsDelivery'] as bool? ?? false,
      prescriptionImageUrl: json['prescriptionImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient': patient.toJson(),
      'medications': medications.map((m) => m.toJson()).toList(),
      'status': status.name,
      'requestDate': requestDate.toIso8601String(),
      'isUrgent': isUrgent,
      'requestsDelivery': requestsDelivery,
      if (prescriptionImageUrl != null) 'prescriptionImageUrl': prescriptionImageUrl,
    };
  }

  // Helper getter for backward compatibility
  RequestedMedication get medication => medications.isNotEmpty ? medications.first : RequestedMedication(
    id: '',
    name: 'N/A',
    dosage: '',
    quantity: 0,
    unit: '',
  );
}

/// Model for patient information
class Patient {
  final String id;
  final String name;
  final String? phoneNumber;
  final PatientLocation? location;

  Patient({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.location,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      location: json['location'] != null 
          ? PatientLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      if (location != null) 'location': location!.toJson(),
    };
  }
}

/// Model for patient location
class PatientLocation {
  final double latitude;
  final double longitude;
  final String? address;

  PatientLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory PatientLocation.fromJson(Map<String, dynamic> json) {
    return PatientLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
    };
  }
}

/// Model for requested medication
class RequestedMedication {
  final String id;
  final String name;
  final String dosage;
  final int quantity;
  final String unit;

  RequestedMedication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.quantity,
    required this.unit,
  });

  factory RequestedMedication.fromJson(Map<String, dynamic> json) {
    return RequestedMedication(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'quantity': quantity,
      'unit': unit,
    };
  }

  String get displayName => '$name $dosage';
  String get displayQuantity => '$quantity $unit';
}

// ============================================================================
// PREVIEW WIDGET
// ============================================================================

/// Preview screen for Pharmacy Dashboard interface
class PharmacyDashboardPreview extends StatefulWidget {
  const PharmacyDashboardPreview({super.key});

  @override
  State<PharmacyDashboardPreview> createState() => _PharmacyDashboardPreviewState();
}

class _PharmacyDashboardPreviewState extends State<PharmacyDashboardPreview> {
  RequestStatus selectedStatus = RequestStatus.tout;

  @override
  Widget build(BuildContext context) {
    // Sample data
    final dashboard = PharmacyDashboard(
      pharmacyInfo: PharmacyInfo(
        id: '1',
        name: 'Pharmacie Centrale',
        totalOrders: 12,
        totalPackages: 48,
      ),
      medicationRequests: [
        MedicationRequest(
          id: '1',
          patient: Patient(id: '1', name: 'Jean Dupont', phoneNumber: '06 123 45 67'),
          medications: [
            RequestedMedication(
              id: '1',
              name: 'Amoxicilline',
              dosage: '500mg',
              quantity: 2,
              unit: 'boîtes',
            ),
          ],
          status: RequestStatus.tout,
          requestDate: DateTime.now(),
          isUrgent: false,
        ),
        MedicationRequest(
          id: '2',
          patient: Patient(id: '2', name: 'Marie Curie', phoneNumber: '06 987 65 43'),
          medications: [
            RequestedMedication(
              id: '2',
              name: 'Paracetamol',
              dosage: '1000mg',
              quantity: 1,
              unit: 'boîte + 2 blisters',
            ),
          ],
          status: RequestStatus.urgent,
          requestDate: DateTime.now(),
          isUrgent: true,
        ),
        MedicationRequest(
          id: '3',
          patient: Patient(id: '3', name: 'Pierre Martin', phoneNumber: '06 456 78 90'),
          medications: [
            RequestedMedication(
              id: '3',
              name: 'Ibuprofène',
              dosage: '400mg',
              quantity: 1,
              unit: 'boîte + 5 blisters par jour',
            ),
          ],
          status: RequestStatus.enAttente,
          requestDate: DateTime.now(),
          isUrgent: false,
        ),
        MedicationRequest(
          id: '4',
          patient: Patient(id: '4', name: 'Lucas Bernard', phoneNumber: '06 234 56 78'),
          medications: [
            RequestedMedication(
              id: '4',
              name: 'Sirop Toux Sèche',
              dosage: '',
              quantity: 1,
              unit: 'flacon',
            ),
          ],
          status: RequestStatus.valide,
          requestDate: DateTime.now().subtract(const Duration(hours: 2)),
          isUrgent: false,
        ),
      ],
    );

    final filteredRequests = selectedStatus == RequestStatus.tout
        ? dashboard.medicationRequests
        : dashboard.getRequestsByStatus(selectedStatus);

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
          'Tableau de bord pharmacie',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Pharmacy Info Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C6FDC), Color(0xFF2E7FD9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BIENVENUE',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  dashboard.pharmacyInfo.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.shopping_bag,
                        label: '${dashboard.pharmacyInfo.totalOrders} En attente',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.inventory_2,
                        label: '${dashboard.pharmacyInfo.totalPackages} Traitées',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Demandes de médicaments',
                  style: TextStyle(color: Color(0xFF2D3142), fontSize: 16, fontWeight: FontWeight.w600),
                ),

              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: RequestStatus.values.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(status),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Medication Requests List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                return _buildRequestItem(filteredRequests[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFilterChip(RequestStatus status) {
    final isSelected = selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C6FDC) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C6FDC) : const Color(0xFFE8E8F5),
          ),
        ),
        child: Text(
          status.displayName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestItem(MedicationRequest request) {
    return Container(
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.patient.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      request.patient.phoneNumber ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.medication, color: Color(0xFF7C6FDC), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.medication.displayName.isNotEmpty
                            ? request.medication.displayName
                            : request.medication.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.medication.displayQuantity,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicationRequestDetailPreview(request: request),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6FDC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Détails',
                style: TextStyle(color: Color(0xFF2D3142), fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MEDICATION REQUEST DETAIL PREVIEW
// ============================================================================

/// Detail screen for medication request with validation buttons
class MedicationRequestDetailPreview extends StatelessWidget {
  final MedicationRequest request;

  const MedicationRequestDetailPreview({
    super.key,
    required this.request,
  });

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
          'Détails de la demande',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${request.status.displayName.toUpperCase()} • ${_formatDate(request.requestDate)}',
                style: const TextStyle(color: Color(0xFF7C6FDC), fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            
            // Request ID
            Text(
              'Demande #${request.id}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Commande sécurisée via le protocole MEDAIChain',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Patient Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8F5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person, color: Color(0xFF7C6FDC), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Informations Patient',
                        style: TextStyle(color: Color(0xFF2D3142), fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    request.patient.name,
                    style: const TextStyle(color: Color(0xFF2D3142), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (request.patient.phoneNumber != null)
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          request.patient.phoneNumber!,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Medication Section
            const Text(
              'Médicament demandé',
              style: TextStyle(color: Color(0xFF2D3142), fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8F5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medication, color: Color(0xFF7C6FDC), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.medication.displayName.isNotEmpty
                              ? request.medication.displayName
                              : request.medication.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.medication.displayQuantity,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Urgent Badge
            if (request.isUrgent)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'DEMANDE URGENTE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (request.isUrgent) const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showValidationDialog(context, isValid: false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Non Valable',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showValidationDialog(context, isValid: true);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Valable',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Confirm Delivery Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _showDeliveryConfirmationDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6FDC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Confirmer Livraison',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.check, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }

  void _showValidationDialog(BuildContext context, {required bool isValid}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE8E8F5)),
          ),
          title: Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.cancel,
                color: isValid ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                isValid ? 'Demande Valable' : 'Demande Non Valable',
                style: const TextStyle(color: Color(0xFF2D3142), fontSize: 18),
              ),
            ],
          ),
          content: Text(
            isValid
                ? 'Confirmer que cette demande est valable et peut être traitée?'
                : 'Confirmer que cette demande n\'est pas valable?',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ANNULER',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isValid
                          ? 'Demande marquée comme valable'
                          : 'Demande marquée comme non valable',
                    ),
                    backgroundColor: isValid ? Colors.green : Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid ? Colors.green : Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'CONFIRMER',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeliveryConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE8E8F5)),
          ),
          title: const Row(
            children: [
              Icon(Icons.local_shipping, color: Color(0xFF7C6FDC), size: 28),
              SizedBox(width: 12),
              Text(
                'Confirmer Livraison',
                style: TextStyle(color: Color(0xFF2D3142), fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Confirmer que cette commande a été livrée au patient?',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ANNULER',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to dashboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Livraison confirmée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6FDC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'CONFIRMER',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}




