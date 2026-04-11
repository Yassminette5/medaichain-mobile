import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
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
    final String fileName = resultFile.isNotEmpty ? resultFile.split('/').last : '';
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

    final String? fileUrl = fileName.isNotEmpty
        ? '${ApiService.baseUrl}/lab/uploads/results/$fileName'.replaceAll('//lab', '/lab')
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Détail analyse', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    labName,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _row(icon: Icons.calendar_today, label: 'Date', value: dateStr),
            const SizedBox(height: 8),
            _row(icon: Icons.category, label: 'Type', value: analysisType.isEmpty ? '—' : analysisType),
            const SizedBox(height: 8),
            _row(icon: Icons.notes_rounded, label: 'Notes', value: notes.isEmpty ? '—' : notes),
            const SizedBox(height: 16),
            // Aperçu du document: image inline si disponible; sinon bouton pour PDF
            if (isImage && fileUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Image.network(
                    fileUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, _, __) => Container(
                      alignment: Alignment.center,
                      color: AppColors.background,
                      child: Text(
                        'Impossible de charger l\'image',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_running) const LinearProgressIndicator(),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: GoogleFonts.poppins(color: AppColors.error)),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _running ? null : () => _runOcrOnImage(fileUrl, fileName),
                      icon: const Icon(Icons.psychology_alt_rounded),
                      label: Text('Analyser l\'image', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
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
                                );
                                if (!mounted) return;
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
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: fileUrl == null
                          ? null
                          : () async {
                              await launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
                            },
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text('Voir le document', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
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

