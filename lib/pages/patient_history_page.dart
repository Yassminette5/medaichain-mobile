import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../models/test_result_model.dart';
import 'publish_results_page.dart';

class PatientHistoryPage extends StatefulWidget {
  final PatientModel patient;

  const PatientHistoryPage({
    super.key,
    required this.patient,
  });

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  String _selectedFilter = 'Tous les tests';

  final List<TestResultModel> _testResults = [
    TestResultModel(
      id: '1',
      testName: 'Complete Blood Count',
      status: 'FINALIZED',
      date: DateTime(2023, 10, 24, 9, 30),
      provider: 'LabCorp Diagnostic Center',
      doctor: 'Dr. Sarah Williams',
      testType: 'Blood',
    ),
    TestResultModel(
      id: '2',
      testName: 'Chest X-Ray',
      status: 'FINALIZED',
      date: DateTime(2023, 10, 20, 14, 15),
      provider: 'General Imaging Services',
      doctor: 'Dr. Kevin Vance',
      observation: 'Observation: Minor inflammation detected',
      hasWarning: true,
      testType: 'Radiology',
    ),
    TestResultModel(
      id: '3',
      testName: 'Urinalysis',
      status: 'ARCHIVED',
      date: DateTime(2023, 9, 30, 11, 15),
      provider: 'LabCorp Diagnostic Center',
      doctor: 'Dr. Sarah Williams',
      testType: 'Urine',
    ),
    TestResultModel(
      id: '4',
      testName: 'Glucose Level Check',
      status: 'PROCESSING',
      date: DateTime(2023, 11, 5, 8, 0),
      provider: 'Wellness Medical Center',
      doctor: 'Dr. Elena Rossi',
      testType: 'Blood',
    ),
  ];

  List<TestResultModel> get _filteredResults {
    if (_selectedFilter == 'Tous les tests') {
      return _testResults;
    }
    return _testResults.where((test) {
      switch (_selectedFilter) {
        case 'Sang':
          return test.testType == 'Blood';
        case 'Radiologie':
          return test.testType == 'Radiology';
        case 'Urine':
          return test.testType == 'Urine';
        default:
          return true;
      }
    }).toList();
  }

  Map<String, List<TestResultModel>> get _groupedByMonth {
    final grouped = <String, List<TestResultModel>>{};
    for (final test in _filteredResults) {
      final monthKey = '${_getMonthName(test.date.month)} ${test.date.year}';
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(test);
    }
    return grouped;
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    final month = _getMonthName(date.month);
    final day = date.day;
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$month $day • ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'FINALIZED':
        return Colors.green;
      case 'PROCESSING':
        return Colors.blue;
      case 'ARCHIVED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Historique',
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
      body: Column(
        children: [
          // En-tête patient
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.patient.name.split(' ').map((n) => n[0]).join(),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
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
                        widget.patient.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.patient.patientId} • ${widget.patient.recordCount} Dossiers',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filtres
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Tous les tests', 'Sang', 'Radiologie', 'Urine'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[700] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Liste des résultats
          Expanded(
            child: widget.patient.recordCount == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun historique',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ce patient n\'a pas encore d\'analyses.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PublishResultsPage(patient: widget.patient),
                              ),
                            );
                          },
                          icon: const Icon(Icons.upload_file, size: 20),
                          label: const Text('Publier les résultats'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: _groupedByMonth.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...entry.value.map((test) => _buildTestCard(test)),
                          const SizedBox(height: 24),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.patient.recordCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublishResultsPage(patient: widget.patient),
                  ),
                );
              },
              backgroundColor: Colors.blue[700],
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text(
                'Publier les résultats',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTestCard(TestResultModel test) {
    final isProcessing = test.status == 'PROCESSING';
    final statusColor = _getStatusColor(test.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      color: isProcessing ? Colors.blue[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (test.hasWarning)
                  Icon(
                    Icons.warning,
                    color: Colors.red[700],
                    size: 20,
                  ),
                if (test.hasWarning) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    test.testName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    test.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isProcessing ? 'Programmé: ${_formatDate(test.date)}' : _formatDate(test.date),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${test.provider} • ${test.doctor}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            if (test.observation != null) ...[
              const SizedBox(height: 8),
              Text(
                test.observation!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (!isProcessing) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Voir les résultats
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Voir'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Télécharger PDF
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
