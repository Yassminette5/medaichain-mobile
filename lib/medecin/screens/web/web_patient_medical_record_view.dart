import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/prescriptions_service.dart';
import '../../../widgets/medical_card.dart';
import '../prescription/create_prescription_screen.dart';

class WebPatientMedicalRecordView extends StatefulWidget {
  final String patientId;
  final String patientName;
  final VoidCallback onBack;

  const WebPatientMedicalRecordView({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.onBack,
  });

  @override
  State<WebPatientMedicalRecordView> createState() => _WebPatientMedicalRecordViewState();
}

class _WebPatientMedicalRecordViewState extends State<WebPatientMedicalRecordView> {
  List<dynamic> _medicalRecords = [];
  List<dynamic> _analysisResults = [];
  List<dynamic> _medicalHistory = [];
  List<dynamic> _prescriptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    List<dynamic> records = [];
    List<dynamic> analyses = [];
    List<dynamic> history = [];
    List<dynamic> prescriptions = [];
    String? errorMsg;

    try {
      records = await ApiService.getMyMedicalRecords(patientId: widget.patientId);
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
    }

    try {
      analyses = await ApiService.getPatientAnalysisResults(widget.patientId);
    } catch (_) {}

    try {
      history = await ApiService.getPatientMedicalHistory(widget.patientId);
    } catch (_) {}

    try {
      final p = await PrescriptionsService.getMyPrescriptions();
      prescriptions = p;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _medicalRecords = records;
        _analysisResults = analyses;
        _medicalHistory = history;
        _prescriptions = prescriptions;
        _error = errorMsg;
        _loading = false;
      });
    }
  }

  Future<void> _openPdfUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir le PDF: $e')),
        );
      }
    }
  }

  Map<String, dynamic>? get _latestRecord {
    if (_medicalRecords.isEmpty) return null;
    final r = _medicalRecords.first;
    return r is Map<String, dynamic> ? r : null;
  }

  Map<String, dynamic>? get _vitalSigns {
    final record = _latestRecord;
    if (record == null) return null;
    final vs = record['vitalSigns'];
    return vs is Map<String, dynamic> ? vs : null;
  }

  String _patientInitials() {
    final name = widget.patientName;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return 'P';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (_error != null) _buildError(),
            const SizedBox(height: 32),
            _buildPatientHeader(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildVitalSigns(),
                      const SizedBox(height: 24),
                      _buildPrescriptionsSection(),
                      const SizedBox(height: 24),
                      _buildAnalysisSection(),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Right Column
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildMedicalHistory(),
                      const SizedBox(height: 24),
                      _buildCurrentMedications(),
                      const SizedBox(height: 24),
                      _buildRecentConsultations(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: widget.onBack,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Text(
            'Dossier Médical: ${widget.patientName}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatePrescriptionScreen(
                  initialPatientId: widget.patientId,
                  initialPatientName: widget.patientName,
                ),
              ),
            );
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nouvelle ordonnance', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _patientInitials(),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${widget.patientId}',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSigns() {
    final vs = _vitalSigns;
    final heartRate = vs?['heartRate'];
    final sys = vs?['bloodPressureSystolic'];
    final dia = vs?['bloodPressureDiastolic'];
    final temp = vs?['temperature'];

    String heartStr = '—';
    if (heartRate != null) heartStr = heartRate.toString();

    String tensionStr = '—/—';
    if (sys != null && dia != null) tensionStr = '$sys/$dia';

    String tempStr = '—';
    if (temp != null) tempStr = temp is num ? temp.toStringAsFixed(1) : temp.toString();

    return MedicalCard(
      title: 'Signes Vitaux',
      titleIcon: Icons.favorite_rounded,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildVitalItem('❤️', heartStr, 'bpm', 'Rythme'),
            _buildVitalItem('🩺', tensionStr, 'mmHg', 'Tension'),
            _buildVitalItem('🌡️', tempStr, '°C', 'Temp.'),
            _buildVitalItem('🫁', '—', '/min', 'Resp.'),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalItem(String emoji, String value, String unit, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              TextSpan(text: ' $unit', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildAnalysisSection() {
    return MedicalCard(
      title: 'Analyses (centre d\'analyse)',
      titleIcon: Icons.science_rounded,
      child: _analysisResults.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucun résultat d\'analyse pour le moment.', style: TextStyle(color: AppColors.textSecondary)),
            )
          : Column(
              children: _analysisResults.map<Widget>((a) {
                final m = a is Map<String, dynamic> ? a : <String, dynamic>{};
                final type = m['analysisType'] ?? m['analysisTypeOther'] ?? 'Analyse';
                final date = m['analysisDate'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(m['analysisDate'].toString())) : '—';
                final labName = m['labId'] is Map ? (m['labId']['centreName'] ?? m['labId']['name'] ?? '') : '';
                final resultFile = m['resultFile']?.toString() ?? '';
                final filename = resultFile.contains('/') ? resultFile.split('/').last : resultFile;
                final pdfUrl = filename.isNotEmpty ? '${ApiService.baseUrl}/lab/uploads/results/$filename' : null;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.biotech_rounded, color: AppColors.secondary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(type.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (labName.toString().isNotEmpty) Text(labName.toString(), style: const TextStyle(color: AppColors.textSecondary)),
                            Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (pdfUrl != null)
                        IconButton(
                          onPressed: () => _openPdfUrl(pdfUrl),
                          icon: const Icon(Icons.picture_as_pdf, color: AppColors.error),
                          tooltip: 'Ouvrir PDF',
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPrescriptionsSection() {
    return MedicalCard(
      title: 'Ordonnances reçues',
      titleIcon: Icons.receipt_long,
      child: _prescriptions.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucune ordonnance.', style: TextStyle(color: AppColors.textSecondary)),
            )
          : Column(
              children: _prescriptions.map((presc) {
                final map = presc is Map<String, dynamic> ? presc : <String, dynamic>{};
                final date = map['createdAt'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(map['createdAt'].toString())) : 'N/A';
                final medications = map['medications'] is List ? (map['medications'] as List) : [];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Ordonnance du $date', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Text('${medications.length} médicament(s)', style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                      if (medications.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...medications.map((m) {
                          final med = m as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(left: 36, bottom: 4),
                            child: Text('• ${med['name']} ${med['dosage'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary)),
                          );
                        }),
                      ]
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildMedicalHistory() {
    return MedicalCard(
      title: 'Antécédents',
      titleIcon: Icons.history_rounded,
      child: _medicalHistory.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucun antécédent.', style: TextStyle(color: AppColors.textSecondary)),
            )
          : Column(
              children: _medicalHistory.map((r) {
                final m = r is Map<String, dynamic> ? r : <String, dynamic>{};
                final diagnosis = m['diagnosis'] ?? 'Consultation';
                final date = m['date'] != null ? DateFormat('yyyy').format(DateTime.parse(m['date'].toString())) : '—';
                return ListTile(
                  leading: const Icon(Icons.circle, size: 12, color: AppColors.warning),
                  title: Text(diagnosis.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(date, style: const TextStyle(color: AppColors.textSecondary)),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildCurrentMedications() {
    List<Widget> items = [];
    if (_latestRecord != null && _latestRecord!['prescription'] is List) {
      final meds = _latestRecord!['prescription'] as List;
      for (final m in meds) {
        final map = m is Map<String, dynamic> ? m : <String, dynamic>{};
        items.add(ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.medication, color: AppColors.primary),
          ),
          title: Text(map['name']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(map['dosage']?.toString() ?? ''),
          trailing: Text(map['frequency']?.toString() ?? '', style: const TextStyle(color: AppColors.textSecondary)),
        ));
      }
    }
    return MedicalCard(
      title: 'Médicaments Actuels',
      titleIcon: Icons.medication_rounded,
      child: items.isEmpty
          ? const Padding(padding: EdgeInsets.all(24), child: Text('Aucun médicament.', style: TextStyle(color: AppColors.textSecondary)))
          : Column(children: items),
    );
  }

  Widget _buildRecentConsultations() {
    List<Widget> items = [];
    if (_medicalHistory.isNotEmpty) {
      for (final r in _medicalHistory.take(5)) {
        final m = r is Map<String, dynamic> ? r : <String, dynamic>{};
        final date = m['date'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(m['date'].toString())) : '—';
        items.add(ListTile(
          leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
          title: Text(m['doctorName'] ?? 'Dr.', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(m['chiefComplaint'] ?? m['diagnosis'] ?? 'Consultation'),
          trailing: Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ));
      }
    }
    return MedicalCard(
      title: 'Consultations Récentes',
      titleIcon: Icons.calendar_today_rounded,
      child: items.isEmpty
          ? const Padding(padding: EdgeInsets.all(24), child: Text('Aucune consultation.', style: TextStyle(color: AppColors.textSecondary)))
          : Column(children: items),
    );
  }
}
