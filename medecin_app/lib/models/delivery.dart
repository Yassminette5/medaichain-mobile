import 'package:flutter/material.dart';

/// Model for delivery information
class Delivery {
  final String id;
  final String status;
  final DateTime timestamp;
  final PatientAddress patientAddress;
  final List<Medication> medications;
  final String? deliveryNotes;

  Delivery({
    required this.id,
    required this.status,
    required this.timestamp,
    required this.patientAddress,
    required this.medications,
    this.deliveryNotes,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      patientAddress: PatientAddress.fromJson(json['patientAddress'] as Map<String, dynamic>),
      medications: (json['medications'] as List)
          .map((item) => Medication.fromJson(item as Map<String, dynamic>))
          .toList(),
      deliveryNotes: json['deliveryNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'patientAddress': patientAddress.toJson(),
      'medications': medications.map((item) => item.toJson()).toList(),
      'deliveryNotes': deliveryNotes,
    };
  }
}

/// Model for patient address with privacy protection
class PatientAddress {
  final String street;
  final String sector;
  final String city;
  final String zipCode;
  final bool privacyProtected;

  PatientAddress({
    required this.street,
    required this.sector,
    required this.city,
    required this.zipCode,
    this.privacyProtected = true,
  });

  factory PatientAddress.fromJson(Map<String, dynamic> json) {
    return PatientAddress(
      street: json['street'] as String,
      sector: json['sector'] as String,
      city: json['city'] as String,
      zipCode: json['zipCode'] as String,
      privacyProtected: json['privacyProtected'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'sector': sector,
      'city': city,
      'zipCode': zipCode,
      'privacyProtected': privacyProtected,
    };
  }

  String get fullAddress => '$street, $sector\n$city, $zipCode';
}

/// Model for medication items
class Medication {
  final String id;
  final String name;
  final String dosage;
  final String quantity;
  final String unit;
  final bool isSelected;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.quantity,
    required this.unit,
    this.isSelected = false,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      quantity: json['quantity'] as String,
      unit: json['unit'] as String,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'quantity': quantity,
      'unit': unit,
      'isSelected': isSelected,
    };
  }

  String get displayName => '$name $dosage';
  String get displayQuantity => '$quantity $unit';
}

// ============================================================================
// PREVIEW WIDGET
// ============================================================================

/// Preview screen for Delivery interface
class DeliveryPreview extends StatelessWidget {
  const DeliveryPreview({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data matching the UI screenshot
    final delivery = Delivery(
      id: '4829',
      status: 'IN PROGRESS',
      timestamp: DateTime.now(),
      patientAddress: PatientAddress(
        street: '123 **** St',
        sector: 'Sector 6',
        city: 'New York',
        zipCode: 'NY 10101',
        privacyProtected: true,
      ),
      medications: [
        Medication(
          id: '1',
          name: 'Amoxicillin',
          dosage: '500mg',
          quantity: '1',
          unit: 'Box - 20 Tablets',
          isSelected: true,
        ),
        Medication(
          id: '2',
          name: 'Paracetamol',
          dosage: '1000mg',
          quantity: '2',
          unit: 'Boxes',
          isSelected: false,
        ),
        Medication(
          id: '3',
          name: 'Vitamin D3',
          dosage: 'drops',
          quantity: '1',
          unit: 'Bottle',
          isSelected: false,
        ),
      ],
      deliveryNotes: 'Please leave the package at the front desk. If no one answers the intercom.',
    );

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
          'Delivery',
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
                '${delivery.status} • Today, ${TimeOfDay.now().format(context)}',
                style: const TextStyle(color: Color(0xFF7C6FDC), fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            
            // Delivery ID
            Text(
              'Delivery #${delivery.id}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Order secured via MEDAIChain protocol',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Patient Address Card
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
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF7C6FDC), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Patient Address',
                        style: TextStyle(color: Color(0xFF2D3142), fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    delivery.patientAddress.fullAddress,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.grey, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Privacy Protected',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.map, color: Color(0xFF7C6FDC), size: 18),
                    label: const Text(
                      'View Restricted Map',
                      style: TextStyle(color: Color(0xFF7C6FDC), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Medications Section
            const Text(
              'Medications',
              style: TextStyle(color: Color(0xFF2D3142), fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...delivery.medications.map((med) => _buildMedicationItem(med)),
            const SizedBox(height: 24),
            
            // Delivery Notes
            const Text(
              'Delivery Notes',
              style: TextStyle(color: Color(0xFF2D3142), fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8F5)),
              ),
              child: Text(
                delivery.deliveryNotes ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            
            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
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
                      'Confirm Delivery',
                      style: TextStyle(color: Color(0xFF2D3142), fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildMedicationItem(Medication med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: med.isSelected ? const Color(0xFF7C6FDC) : const Color(0xFFE8E8F5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            med.isSelected ? Icons.check_box : Icons.check_box_outline_blank,
            color: med.isSelected ? const Color(0xFF7C6FDC) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.displayName,
                  style: const TextStyle(color: Color(0xFF2D3142), fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  med.displayQuantity,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


