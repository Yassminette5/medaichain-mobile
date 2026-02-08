import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import 'patient_history_page.dart';

class PatientsListPage extends StatelessWidget {
   PatientsListPage({super.key});

  final List<PatientModel> _patients = [
    PatientModel(
      id: '1',
      name: 'John Doe',
      patientId: '#882931',
      recordCount: 24,
    ),
    PatientModel(
      id: '2',
      name: 'Sarah Jenkins',
      patientId: '#123456',
      recordCount: 12,
    ),
    PatientModel(
      id: '3',
      name: 'Robert Chen',
      patientId: '#789012',
      recordCount: 8,
    ),
    PatientModel(
      id: '4',
      name: 'Alice Murray',
      patientId: '#345678',
      recordCount: 15,
    ),
    PatientModel(
      id: '5',
      name: 'Michael Brown',
      patientId: '#999888',
      recordCount: 0, // Nouveau patient sans historique
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Patients',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._patients.map((patient) => _buildPatientCard(context, patient)),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, PatientModel patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      color: Colors.grey[100],
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientHistoryPage(patient: patient),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    patient.name.split(' ').map((n) => n[0]).join(),
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${patient.patientId} • ${patient.recordCount} Dossiers',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
