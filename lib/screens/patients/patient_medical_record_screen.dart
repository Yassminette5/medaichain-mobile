import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/medical_card.dart';
import '../../medecin/screens/prescription/create_prescription_screen.dart';
import '../../widgets/ai_assistant_chat.dart';

/// Écran du dossier médical patient.
/// Si [patientId] (et optionnellement [patientName]) sont fournis, charge les vraies données
/// (dossiers clinique, analyses centre d'analyse). Sinon affiche des données de démo statiques.
class PatientMedicalRecordScreen extends StatefulWidget {
  const PatientMedicalRecordScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.onBack,
  });

  final String? patientId;
  final String? patientName;
  /// Si fourni (ex. intégration web), le bouton retour appelle ce callback au lieu de Navigator.pop.
  final VoidCallback? onBack;

  @override
  State<PatientMedicalRecordScreen> createState() => _PatientMedicalRecordScreenState();
}

class _PatientMedicalRecordScreenState extends State<PatientMedicalRecordScreen> {
  List<dynamic> _medicalRecords = [];
  List<dynamic> _analysisResults = [];
  List<dynamic> _medicalHistory = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.patientId != null && widget.patientId!.isNotEmpty) {
      _loadPatientData();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPatientData() async {
    if (widget.patientId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    List<dynamic> records = [];
    List<dynamic> analyses = [];
    List<dynamic> history = [];
    String? errorMsg;

    try {
      records = await ApiService.getMyMedicalRecords(patientId: widget.patientId);
      if (records is! List) records = [];
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      records = [];
    }

    try {
      final res = await ApiService.getPatientAnalysisResults(widget.patientId!);
      analyses = res is List ? res : [];
    } catch (_) {
      analyses = [];
    }

    try {
      final h = await ApiService.getPatientMedicalHistory(widget.patientId!);
      history = h is List ? h : [];
    } catch (_) {
      history = [];
    }

    if (mounted) {
      setState(() {
        _medicalRecords = records;
        _analysisResults = analyses;
        _medicalHistory = history;
        _error = errorMsg;
        _loading = false;
      });
    }
  }

  bool get _hasRealData => widget.patientId != null && !_loading;

  Future<void> _openPdfUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ouverture du PDF...'), duration: Duration(seconds: 1)),
      );
    }
    try {
      // Priorité: navigateur externe / app PDF (plus fiable pour afficher un PDF sur mobile)
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted && !ok) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir le PDF. Vérifiez votre connexion.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString().replaceFirst('Exception: ', '')}')),
          );
        }
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
    if (vs is Map<String, dynamic>) return vs;
    return null;
  }

  String _patientDisplayName() {
    if (widget.patientName != null && widget.patientName!.isNotEmpty) return widget.patientName!;
    final record = _latestRecord;
    if (record != null && record['patientName'] != null) return record['patientName'].toString();
    return 'Jean Dupont';
  }

  String _patientInitials() {
    final name = _patientDisplayName();
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return 'JD';
  }

  // --- Local Theme Redesign ---
  static const Color _bgColor = Color(0xFFFDF6F0); // Soft Beige
  static const Color _accentColor = Color(0xFFFF6B6B); // Coral/Salmon
  static const Color _textColor = Color(0xFF4A4A4A);
  static const Color _cardColor = Colors.white;

  TextStyle _nunito({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? _textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      floatingActionButton: _buildChatFab(),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(context),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: _accentColor)),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) _buildError(),
                      _buildWarmHeroCard(),
                      const SizedBox(height: 24),
                      _buildAiAssistantBanner(),
                      const SizedBox(height: 24),
                      _buildWarmVitalSigns(),
                      const SizedBox(height: 24),
                      if (_hasRealData) _buildWarmAnalysisResults(),
                      if (_hasRealData) const SizedBox(height: 24),
                      _buildWarmMedicalHistory(),
                      const SizedBox(height: 24),
                      _buildWarmCurrentMedications(),
                      const SizedBox(height: 24),
                      _buildWarmRecentConsultations(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatFab() {
    return GestureDetector(
      onTap: () => _openChat(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_accentColor, Color(0xFFFFA07A)]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiAssistantChat(userId: widget.patientId),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: _textColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Patient Profile',
              style: _nunito(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _buildHeaderActions(context),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return Row(
      children: [
        if (widget.patientId != null && widget.patientId!.isNotEmpty)
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: const Icon(Icons.more_horiz, size: 20, color: _textColor),
            ),
            onSelected: (value) {
              if (value == 'ordonnance') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePrescriptionScreen(
                      initialPatientId: widget.patientId,
                      initialPatientName: widget.patientName ?? _patientDisplayName(),
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'ordonnance',
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded, color: _accentColor, size: 20),
                    const SizedBox(width: 12),
                    Text('Add Prescription', style: _nunito(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildWarmHeroCard() {
    final name = _patientDisplayName();
    final id = widget.patientId ?? 'PAT-2024-1234';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accentColor, Color(0xFFFFA07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Center(
                  child: Text(
                    _patientInitials(),
                    style: _nunito(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: _nunito(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildHeroTag('52 years'),
                        const SizedBox(width: 8),
                        _buildHeroTag('Male'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Patient ID',
                  style: _nunito(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
                Text(
                  id.toUpperCase(),
                  style: _nunito(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: _nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildAiAssistantBanner() {
    return GestureDetector(
      onTap: () => _openChat(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0ED),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _accentColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, color: _accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Health Assistant', style: _nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Ask anything about your records', style: _nunito(fontSize: 12, color: _textColor.withOpacity(0.7))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: _accentColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _WarmCard({required Widget child, String? title, IconData? icon, Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: _accentColor, size: 22),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: _nunito(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 20),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildWarmVitalSigns() {
    final vs = _vitalSigns;
    final heartRate = vs?['heartRate']?.toString() ?? (_hasRealData ? '—' : '72');
    final bp = vs != null ? '${vs['bloodPressureSystolic'] ?? '—'}/${vs['bloodPressureDiastolic'] ?? '—'}' : (_hasRealData ? '—/—' : '120/80');
    final temp = vs?['temperature']?.toString() ?? (_hasRealData ? '—' : '36.8');

    return _WarmCard(
      title: 'Vital Signs',
      icon: Icons.favorite_rounded,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildWarmVitalItem('Heart', heartRate, 'bpm', Icons.bolt_rounded),
          _buildWarmVitalItem('Blood', bp, 'mmHg', Icons.speed_rounded),
          _buildWarmVitalItem('Temp', temp, '°C', Icons.thermostat_rounded),
        ],
      ),
    );
  }

  Widget _buildWarmVitalItem(String label, String value, String unit, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: _accentColor, size: 20),
        ),
        const SizedBox(height: 12),
        Text(value, style: _nunito(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(unit, style: _nunito(fontSize: 11, color: _textColor.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildWarmAnalysisResults() {
    return _WarmCard(
      title: 'Lab Results',
      icon: Icons.science_rounded,
      child: _analysisResults.isEmpty
          ? Text('No results available.', style: _nunito(color: _textColor.withOpacity(0.5)))
          : Column(
              children: _analysisResults.map((a) {
                final m = a is Map<String, dynamic> ? a : {};
                final type = m['analysisType'] ?? m['analysisTypeOther'] ?? 'General Analysis';
                final date = m['analysisDate'] != null 
                  ? DateFormat('dd MMM yyyy').format(DateTime.parse(m['analysisDate'].toString()))
                  : '—';
                
                final resultFile = m['resultFile']?.toString() ?? '';
                final filename = resultFile.contains('/') ? resultFile.split('/').last : resultFile;
                final pdfUrl = filename.isNotEmpty
                    ? '${ApiService.baseUrl}/lab/uploads/results/$filename'
                    : null;

                return _buildWarmListItem(
                  type.toString(), 
                  date, 
                  Icons.biotech_rounded,
                  trailing: pdfUrl != null 
                    ? IconButton(
                        onPressed: () => _openPdfUrl(pdfUrl),
                        icon: const Icon(Icons.picture_as_pdf_rounded, color: _accentColor, size: 24),
                        style: IconButton.styleFrom(
                          backgroundColor: _accentColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : null,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildWarmMedicalHistory() {
    final history = _hasRealData && _medicalHistory.isNotEmpty 
      ? _medicalHistory.take(3).toList()
      : [{'diagnosis': 'Type 2 Diabetes', 'year': '2018'}, {'diagnosis': 'Hypertension', 'year': '2020'}];

    return _WarmCard(
      title: 'Medical History',
      icon: Icons.history_rounded,
      child: Column(
        children: history.map((h) {
          final m = h as Map<String, dynamic>;
          final diag = m['diagnosis'] ?? 'Consultation';
          final year = m['year'] ?? (m['date'] != null ? DateFormat('yyyy').format(DateTime.parse(m['date'].toString())) : '—');
          return _buildWarmListItem(diag.toString(), year.toString(), Icons.check_circle_rounded);
        }).toList(),
      ),
    );
  }

  Widget _buildWarmCurrentMedications() {
    final record = _latestRecord;
    List<dynamic> meds = [];
    if (_hasRealData && record != null) {
      meds = record['prescription'] is List ? record['prescription'] : [];
    } else {
      meds = [{'name': 'Metformin', 'dosage': '500mg'}, {'name': 'Amlodipine', 'dosage': '5mg'}];
    }

    return _WarmCard(
      title: 'Current Medications',
      icon: Icons.medication_rounded,
      child: Column(
        children: meds.take(4).map((m) {
          final map = m as Map<String, dynamic>;
          return _buildWarmListItem(map['name'] ?? '—', map['dosage'] ?? '', Icons.medication);
        }).toList(),
      ),
    );
  }

  Widget _buildWarmRecentConsultations() {
    final consults = _hasRealData && _medicalHistory.isNotEmpty 
      ? _medicalHistory.take(2).toList()
      : [{'doctorName': 'Dr. Sarah Mitchell', 'chiefComplaint': 'Regular Checkup'}];

    return _WarmCard(
      title: 'Recent Visits',
      icon: Icons.calendar_today_rounded,
      child: Column(
        children: consults.map((c) {
          final m = c as Map<String, dynamic>;
          final dr = m['doctorName'] ?? 'General Practitioner';
          final reason = m['chiefComplaint'] ?? 'Consultation';
          return _buildWarmListItem(dr.toString(), reason.toString(), Icons.person_rounded);
        }).toList(),
      ),
    );
  }

  Widget _buildWarmListItem(String title, String subtitle, IconData icon, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFFF6F0), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _accentColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _nunito(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: _nunito(fontSize: 12, color: _textColor.withOpacity(0.5))),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: _nunito(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
