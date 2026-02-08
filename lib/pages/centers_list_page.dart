import 'package:flutter/material.dart';
import '../models/center_model.dart';
import 'center_profile_patient_page.dart';

class CentersListPage extends StatelessWidget {
   CentersListPage({super.key});

  // Liste de centres d'exemple
  final List<CenterModel> _centers = [
    CenterModel(
      name: 'Laboratoire Bio-Santé Central',
      category: 'Laboratoire d\'analyses médicales',
      phone: '01 23 45 67 89',
      email: 'contact@bio-sante.fr',
      location: '15 Rue de la Paix, 75002 Paris',
      onlineAppointmentEnabled: true,
    ),
    CenterModel(
      name: 'Centre Médical Paris Nord',
      category: 'Laboratoire d\'analyses médicales',
      phone: '01 98 76 54 32',
      email: 'contact@parisnord.fr',
      location: '42 Avenue des Champs, 75008 Paris',
      onlineAppointmentEnabled: true,
    ),
    CenterModel(
      name: 'Labo Santé Express',
      category: 'Laboratoire d\'analyses médicales',
      phone: '01 11 22 33 44',
      email: 'contact@santeexpress.fr',
      location: '8 Boulevard Voltaire, 75011 Paris',
      onlineAppointmentEnabled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Centres d\'Analyse',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _centers.length,
        itemBuilder: (context, index) {
          final center = _centers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            color: Colors.white,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CenterProfilePatientPage(center: center),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medical_services,
                        color: Colors.blue[700],
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            center.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            center.category,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  center.location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
