import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/patient_model.dart';

class PublishResultsPage extends StatefulWidget {
  final PatientModel patient;

  const PublishResultsPage({
    super.key,
    required this.patient,
  });

  @override
  State<PublishResultsPage> createState() => _PublishResultsPageState();
}

class _PublishResultsPageState extends State<PublishResultsPage> {
  final _resultTypeController = TextEditingController(text: 'Bilan sanguin');
  final _testDateController = TextEditingController(text: '24/10/2023');
  bool _patientNotificationEnabled = true;
  bool _shareWithDoctorEnabled = true;
  String? _selectedFile;

  @override
  void dispose() {
    _resultTypeController.dispose();
    _testDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Publier les résultats',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations patient
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
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
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.patient.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${widget.patient.patientId} • NDN: 05/12/1985',
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
            ),
            const SizedBox(height: 24),

            // Section Upload
            _buildSectionTitle('DOCUMENTS DE RÉSULTATS'),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                _selectFiles();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Appuyez pour télécharger des fichiers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PDF, JPG ou PNG (max. 10MB)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.insert_drive_file, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedFile!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _selectFiles();
                },
                icon: const Icon(Icons.folder_open, size: 20),
                label: const Text('Sélectionner des fichiers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Analysis Details
            _buildSectionTitle('DÉTAILS DE L\'ANALYSE'),
            const SizedBox(height: 16),
            TextField(
              controller: _resultTypeController,
              decoration: InputDecoration(
                labelText: 'Type de résultat',
                suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _testDateController,
              decoration: InputDecoration(
                labelText: 'Date du test',
                suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _testDateController.text = '${date.day}/${date.month}/${date.year}';
                  });
                }
              },
            ),
            const SizedBox(height: 32),

            // Automated Workflow
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSectionTitle('WORKFLOW AUTOMATISÉ'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildWorkflowItem(
                      icon: Icons.person,
                      text: 'Le patient sera notifié immédiatement',
                      isEnabled: _patientNotificationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _patientNotificationEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildWorkflowItem(
                      icon: Icons.business,
                      text: 'Partagé avec Dr. Sarah Smith (Référent)',
                      isEnabled: _shareWithDoctorEnabled,
                      onChanged: (value) {
                        setState(() {
                          _shareWithDoctorEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Publish Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _publishResults();
                },
                icon: const Icon(Icons.send, size: 20),
                label: const Text(
                  'Publier et partager les résultats',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'TRANSFERT SÉCURISÉ DE DONNÉES CLINIQUES • CONFORME HIPAA',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey[600],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildWorkflowItem({
    required IconData icon,
    required String text,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () {
        onChanged(!isEnabled);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.green[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? Colors.green[200]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isEnabled ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isEnabled ? Colors.green : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isEnabled
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _selectFiles() {
    // Simuler la sélection de fichiers
    setState(() {
      _selectedFile = 'result_analysis.pdf';
    });
    HapticFeedback.lightImpact();
  }

  void _publishResults() {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un fichier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publier les résultats'),
        content: Text(
          'Les résultats seront publiés et partagés avec:\n${_patientNotificationEnabled ? '• Patient\n' : ''}${_shareWithDoctorEnabled ? '• Médecin référent\n' : ''}${!_patientNotificationEnabled && !_shareWithDoctorEnabled ? 'Aucun destinataire sélectionné' : ''}\n\nContinuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Résultats publiés avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Publier', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}
