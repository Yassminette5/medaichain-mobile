import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/prescriptions_service.dart';
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
  List<dynamic> _prescriptions = [];
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
    List<dynamic> prescriptions = [];
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

    try {
      prescriptions = await PrescriptionsService.getMyPrescriptions();
      if (prescriptions is! List) prescriptions = [];
    } catch (_) {
      prescriptions = [];
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AiAssistantChat(userId: widget.patientId),
          );
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.aiGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 30),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.background],
            stops: const [0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null) _buildError(),
                        _buildAiAssistantCard(),
                        const SizedBox(height: 20),
                        _buildPatientInfo(),
                        const SizedBox(height: 24),
                        _buildVitalSigns(),
                        const SizedBox(height: 24),
                        if (_hasRealData) _buildAnalysisSection(),
                        if (_hasRealData) const SizedBox(height: 24),
                        _buildMedicalHistory(),
                        const SizedBox(height: 24),
                        _buildPrescriptionsSection(),
                        const SizedBox(height: 24),
                        _buildCurrentMedications(),
                        const SizedBox(height: 24),
                        _buildRecentConsultations(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiAssistantCard() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AiAssistantChat(userId: widget.patientId),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.aiGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Besoin d\'aide ?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Posez vos questions à l\'assistant IA sur votre dossier.',
                    style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Dossier Médical',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AiAssistantChat(userId: widget.patientId),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.aiGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 8)],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
            tooltip: 'Assistant IA',
          ),
          const SizedBox(width: 8),
          if (widget.patientId != null && widget.patientId!.isNotEmpty)
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
                ),
                child: const Icon(Icons.more_vert, size: 20),
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
                const PopupMenuItem(
                  value: 'ordonnance',
                  child: Row(
                    children: [
                      Icon(Icons.description_rounded, color: AppColors.prescription, size: 20),
                      SizedBox(width: 12),
                      Text('Ajouter une ordonnance'),
                    ],
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
              ),
              child: const Icon(Icons.more_vert, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    final name = _patientDisplayName();
    final id = widget.patientId ?? 'PAT-2024-1234';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                _patientInitials(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '52 ans • Masculin',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID: $id',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
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
    if (heartRate != null) {
      if (heartRate is num) heartStr = heartRate.toInt().toString();
      else heartStr = heartRate.toString();
    } else if (!_hasRealData) heartStr = '72';

    String tensionStr = '—/—';
    if (sys != null && dia != null) {
      tensionStr = '${sys is num ? sys.toInt() : sys}/${dia is num ? dia.toInt() : dia}';
    } else if (!_hasRealData) tensionStr = '120/80';

    String tempStr = '—';
    if (temp != null) {
      tempStr = temp is num ? temp.toStringAsFixed(1) : temp.toString();
    } else if (!_hasRealData) tempStr = '36.8';

    return MedicalCard(
      title: 'Signes Vitaux',
      titleIcon: Icons.favorite_rounded,
      child: Row(
        children: [
          _buildVitalItem('❤️', heartStr, 'bpm', 'Rythme'),
          _buildVitalItem('🩺', tensionStr, 'mmHg', 'Tension'),
          _buildVitalItem('🌡️', tempStr, '°C', 'Temp.'),
          _buildVitalItem('🫁', _hasRealData ? '—' : '16', '/min', 'Resp.'),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String emoji, String value, String unit, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  /// Section Analyses (centre d'analyse) — affichée uniquement quand on a un patient lié et des données réelles
  Widget _buildAnalysisSection() {
    return MedicalCard(
      title: 'Analyses (centre d\'analyse)',
      titleIcon: Icons.science_rounded,
      child: _analysisResults.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucun résultat d\'analyse pour le moment.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            )
          : Column(
              children: [
                ..._analysisResults.map<Widget>((a) {
                  final m = a is Map<String, dynamic> ? a : <String, dynamic>{};
                  final type = m['analysisType'] ?? m['analysisTypeOther'] ?? 'Analyse';
                  final typeStr = type.toString().replaceAll('_', ' ').toLowerCase();
                  final date = m['analysisDate'];
                  String dateStr = '—';
                  if (date != null) {
                    try {
                      dateStr = DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(date.toString()));
                    } catch (_) {
                      dateStr = date.toString();
                    }
                  }
                  final lab = m['labId'];
                  String labName = '';
                  if (lab is Map<String, dynamic>) {
                    labName = lab['centreName'] ?? lab['name'] ?? '';
                  }
                  final resultFile = m['resultFile']?.toString() ?? '';
                  final filename = resultFile.contains('/') ? resultFile.split('/').last : resultFile;
                  final pdfUrl = filename.isNotEmpty
                      ? '${ApiService.baseUrl}/lab/uploads/results/$filename'
                      : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.biotech_rounded, color: AppColors.secondary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  typeStr.isNotEmpty ? typeStr : 'Résultat',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (labName.isNotEmpty)
                                  Text(
                                    labName,
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                Text(
                                  dateStr,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (pdfUrl != null && pdfUrl.isNotEmpty)
                            IconButton(
                              onPressed: () => _openPdfUrl(pdfUrl),
                              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 28),
                              tooltip: 'Ouvrir le PDF',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                              ),
                            )
                          else
                            Icon(Icons.description_outlined, color: AppColors.textLight, size: 24),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildMedicalHistory() {
    if (_hasRealData && _medicalHistory.isNotEmpty) {
      final items = _medicalHistory.take(5).map((r) {
        final m = r is Map<String, dynamic> ? r : <String, dynamic>{};
        final diagnosis = m['diagnosis'] ?? 'Consultation';
        final date = m['date'];
        String year = '—';
        if (date != null) {
          try {
            year = DateFormat('yyyy').format(DateTime.parse(date.toString()));
          } catch (_) {}
        }
        return _buildHistoryItem(diagnosis.toString(), year, AppColors.warning);
      }).toList();
      return MedicalCard(
        title: 'Antécédents',
        titleIcon: Icons.history_rounded,
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              items[i],
            ],
          ],
        ),
      );
    }
    return MedicalCard(
      title: 'Antécédents',
      titleIcon: Icons.history_rounded,
      child: Column(
        children: [
          _buildHistoryItem('Diabète Type 2', '2018', AppColors.warning),
          const SizedBox(height: 12),
          _buildHistoryItem('Hypertension', '2020', AppColors.error),
          const SizedBox(height: 12),
          _buildHistoryItem('Chirurgie appendice', '2010', AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String condition, String year, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(condition, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(year, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsSection() {
    if (_prescriptions.isEmpty) {
      return MedicalCard(
        title: 'Ordonnances reçues',
        titleIcon: Icons.receipt_long,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Aucune ordonnance pour le moment.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return MedicalCard(
      title: 'Ordonnances reçues',
      titleIcon: Icons.receipt_long,
      child: Column(
        children: _prescriptions.take(5).map((presc) {
          final map = presc is Map<String, dynamic> ? presc : <String, dynamic>{};
          final medications = map['medications'] is List ? (map['medications'] as List) : [];
          final medCount = medications.length;
          final createdAt = map['createdAt'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(map['createdAt'].toString()))
              : 'N/A';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.assignment, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ordonnance du $createdAt',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$medCount médicament(s)',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (map['prescriptionImageUrl'] != null && (map['prescriptionImageUrl'] as String).isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image, color: AppColors.success, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Image',
                              style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (medications.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 42),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: medications.take(2).map<Widget>((med) {
                        final m = med is Map<String, dynamic> ? med : <String, dynamic>{};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${m['name'] ?? 'N/A'} ${m['dosage'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (medCount > 2)
                    Padding(
                      padding: const EdgeInsets.only(left: 42, top: 4),
                      child: Text(
                        '+ ${medCount - 2} autres',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
                if (_prescriptions.indexOf(presc) < _prescriptions.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentMedications() {
    final record = _latestRecord;
    List<Widget> items = [];
    if (_hasRealData && record != null) {
      final meds = record['prescription'];
      if (meds is List && meds.isNotEmpty) {
        for (final m in meds.take(5)) {
          final map = m is Map<String, dynamic> ? m : <String, dynamic>{};
          items.add(_buildMedicationItem(
            map['name']?.toString() ?? '—',
            map['dosage']?.toString() ?? '',
            map['frequency']?.toString() ?? '',
            AppColors.primary,
          ));
          items.add(const SizedBox(height: 12));
        }
        if (items.isNotEmpty) items.removeLast();
      }
    }
    if (items.isEmpty) {
      items = [
        _buildMedicationItem('Metformine', '500mg', '2x/jour', AppColors.primary),
        const SizedBox(height: 12),
        _buildMedicationItem('Amlodipine', '5mg', '1x/jour', AppColors.secondary),
        const SizedBox(height: 12),
        _buildMedicationItem('Aspirine', '100mg', '1x/jour', AppColors.prescription),
      ];
    }
    return MedicalCard(
      title: 'Médicaments Actuels',
      titleIcon: Icons.medication_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }

  Widget _buildMedicationItem(String name, String dose, String frequency, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (dose.isNotEmpty) Text(dose, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          if (frequency.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(frequency, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentConsultations() {
    List<Widget> items = [];
    if (_hasRealData && _medicalHistory.isNotEmpty) {
      for (final r in _medicalHistory.take(3)) {
        final m = r is Map<String, dynamic> ? r : <String, dynamic>{};
        final doctorName = m['doctorName'] ?? 'Dr.';
        final date = m['date'];
        String dateStr = '—';
        if (date != null) {
          try {
            dateStr = DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(date.toString()));
          } catch (_) {}
        }
        final reason = m['chiefComplaint'] ?? m['diagnosis'] ?? 'Consultation';
        items.add(_buildConsultationItem(doctorName.toString(), dateStr, reason.toString()));
        items.add(const SizedBox(height: 12));
      }
      if (items.isNotEmpty) items.removeLast();
    }
    if (items.isEmpty) {
      items = [
        _buildConsultationItem('Dr. Sarah Mitchell', '15 Jan 2024', 'Suivi diabète'),
        const SizedBox(height: 12),
        _buildConsultationItem('Dr. Marc Laurent', '02 Jan 2024', 'Bilan cardiologique'),
        const SizedBox(height: 12),
        _buildConsultationItem('Dr. Sarah Mitchell', '18 Déc 2023', 'Contrôle tension'),
      ];
    }
    return MedicalCard(
      title: 'Consultations Récentes',
      titleIcon: Icons.calendar_today_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }

  Widget _buildConsultationItem(String doctor, String date, String reason) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.person, color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(reason, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Text(date, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
