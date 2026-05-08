import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/subscription_service.dart';
import '../ai/premium_paywall_screen.dart';
import 'package:http/http.dart' as http;

class OcrDocumentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> document;
  const OcrDocumentDetailScreen({super.key, required this.document});

  @override
  State<OcrDocumentDetailScreen> createState() => _OcrDocumentDetailScreenState();
}

class _OcrDocumentDetailScreenState extends State<OcrDocumentDetailScreen> {
  bool _running = false;
  Map<String, dynamic>? _ocrResult;
  String? _error;

  bool _isPrescriptionDoc(Map<String, dynamic> doc) {
    final cat = (doc['documentCategory'] ?? '').toString().toLowerCase();
    if (cat == 'prescription') return true;
    final title = (doc['title'] ?? '').toString().toLowerCase();
    if (title.startsWith('ordonnance')) return true;
    final details = doc['details'];
    if (details is Map) {
      final k = details['document_type'] ?? details['documentType'] ?? details['kind'];
      if (k?.toString().toLowerCase() == 'prescription') return true;
    }
    final result = doc['result'];
    if (result is Map) {
      final dt = result['documentType'] ?? result['document_type'];
      if (dt?.toString().toLowerCase() == 'prescription') return true;
    }
    return false;
  }

  Future<void> _runOcrOnImage(String fileUrl, String fileName) async {
    setState(() {
      _running = true;
      _ocrResult = null;
      _error = null;
    });
    try {
      final resp = await http.get(Uri.parse(fileUrl));
      if (resp.statusCode != 200) {
        throw Exception('Impossible de récupérer l\'image (HTTP ${resp.statusCode})');
      }
      final bytes = resp.bodyBytes;
      final result = await ApiService.mlOcrAnalyze(fileBytes: bytes, fileName: fileName);
      if (mounted) {
        setState(() => _ocrResult = result);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamic lab = widget.document['labId'];
    final String labName = lab is Map
        ? (lab['centreName']?.toString() ?? lab['name']?.toString() ?? 'Laboratoire')
        : (lab?.toString() ?? 'Laboratoire');

    final String analysisType = (widget.document['analysisType'] ?? '').toString();
    final String notes = (widget.document['notes'] ?? '').toString();
    final String resultFile = (widget.document['resultFile'] ?? '').toString();
    final String imageName = (widget.document['image_name'] ?? '').toString();
    final String fileName =
        resultFile.isNotEmpty ? resultFile.split('/').last : imageName;
    final bool isFromLab = resultFile.isNotEmpty;
    final String rawDate = (widget.document['analysisDate'] ?? widget.document['createdAt'] ?? '').toString();
    String dateStr = rawDate;
    try {
      if (rawDate.isNotEmpty) {
        dateStr = DateFormat('dd MMM yyyy', 'fr').format(DateTime.parse(rawDate));
      }
    } catch (_) {}

    final bool isImage = fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.webp');

    final String? fileUrl = fileName.isEmpty
        ? null
        : (isFromLab
            ? '${ApiService.baseUrl}/lab/uploads/results/$fileName'.replaceAll('//lab', '/lab')
            : '${ApiService.baseUrl}/uploads/$fileName');

    final String headerTitle =
        isFromLab ? labName : ((widget.document['title'] ?? 'Document').toString());

    final bool isPrescription = _isPrescriptionDoc(widget.document);
    final Color accent = isPrescription ? AppColors.prescription : AppColors.primary;
    final String typeLabel = isPrescription
        ? 'Ordonnance'
        : (analysisType.isEmpty
            ? ((widget.document['documentCategory'] ?? widget.document['sourceType'] ?? '—').toString())
            : analysisType);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isPrescription ? 'Ordonnance' : 'Détail document',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPrescription
                      ? [
                          AppColors.prescription.withValues(alpha: 0.12),
                          AppColors.prescription.withValues(alpha: 0.04),
                        ]
                      : [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary.withValues(alpha: 0.03),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPrescription ? Icons.medication_rounded : Icons.local_hospital_rounded,
                      color: accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPrescription)
                          Text(
                            'Ordonnance',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        if (isPrescription) const SizedBox(height: 4),
                        Text(
                          headerTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _row(icon: Icons.calendar_today, label: 'Date', value: dateStr),
            const SizedBox(height: 12),
            _row(icon: Icons.category, label: 'Type', value: typeLabel),
            const SizedBox(height: 12),
            _row(icon: Icons.notes_rounded, label: 'Notes', value: notes.isEmpty ? '—' : notes),
            if (isPrescription) ...[
              const SizedBox(height: 14),
              Text(
                'Ce document est conservé tel quel dans votre dossier. Aucune analyse automatique n’est effectuée.',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
            const SizedBox(height: 20),
            // Aperçu image (analyses : option OCR ; ordonnances : lecture seule)
            if (isImage && fileUrl != null) ...[
              Text(
                isPrescription ? 'Aperçu' : 'Aperçu du document',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  color: AppColors.background,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: FutureBuilder<Map<String, String>>(
                      future: ApiService.authImageHeaders(),
                      builder: (context, snap) {
                        return Image.network(
                          fileUrl,
                          fit: BoxFit.contain,
                          headers: snap.data,
                          gaplessPlayback: true,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: CircularProgressIndicator(color: accent),
                              ),
                            );
                          },
                          errorBuilder: (context, _, __) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Impossible de charger l\'image',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: AppColors.textSecondary),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!isPrescription) ...[
                if (_running) const LinearProgressIndicator(),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: GoogleFonts.poppins(color: AppColors.error)),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _running ? null : () async {
                          // Vérifier premium
                          final sub = SubscriptionService();
                          await sub.refreshBackendStatus();
                          if (sub.isPremium || sub.adCredits > 0) {
                            _runOcrOnImage(fileUrl, fileName);
                            return;
                          }
                          // Paywall
                          if (!context.mounted) return;
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()),
                          );
                          if (result == true) {
                            await sub.refreshBackendStatus();
                            if (sub.isPremium || sub.adCredits > 0) {
                              _runOcrOnImage(fileUrl, fileName);
                            }
                          }
                        },
                        icon: const Icon(Icons.psychology_alt_rounded),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Analyser l\'image', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            if (!SubscriptionService().isPremium) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('PRO', style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                              ),
                            ],
                          ],
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_ocrResult != null) ...[
                  const SizedBox(height: 16),
                  Text('Description', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    (_ocrResult!['description'] ?? '').toString(),
                    style: GoogleFonts.poppins(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: fileName.isEmpty
                              ? null
                              : () async {
                                  final ok = await ApiService.saveOcrResult(
                                    fileName: fileName,
                                    result: _ocrResult!,
                                    title: headerTitle,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok ? 'Résultat enregistré' : 'Échec de l\'enregistrement'),
                                      backgroundColor: ok ? AppColors.success : AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.save_rounded),
                          label: Text('Enregistrer les résultats',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // NOUVEAU BOUTON TELECHARGEMENT PDF
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final token = await ApiService.getAccessToken();
                            final url = '${ApiService.baseUrl}/patient/ocr/export-pdf?token=$token';
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: Text('Télécharger le rapport (PDF)',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Analyses détectées', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ...List.generate(((_ocrResult!['analyses_detectees'] as List?)?.length ?? 0), (index) {
                    final a = (_ocrResult!['analyses_detectees'] as List)[index] as Map<String, dynamic>;
                    final nom = (a['nom'] ?? '').toString();
                    final valeur = (a['valeur'] ?? '').toString();
                    final statut = (a['statut'] ?? '').toString();
                    final color = switch (statut.toLowerCase()) {
                      'élevé' || 'eleve' || 'high' => AppColors.error,
                      'bas' || 'low' => AppColors.accentOrange,
                      _ => AppColors.success,
                    };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.medical_information_rounded, color: color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nom.isEmpty ? 'Analyse' : nom, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  if (valeur.isNotEmpty)
                                    Text('Valeur: $valeur', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(statut.isEmpty ? '-' : statut, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text('Ouvrir le fichier', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: fileUrl == null
                      ? null
                      : () async {
                          await launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
                        },
                  icon: Icon(isPrescription ? Icons.medication_rounded : Icons.picture_as_pdf_rounded),
                  label: Text(
                    isPrescription ? 'Ouvrir l\'ordonnance (PDF)' : 'Voir le document',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _row({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '—' : value,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

