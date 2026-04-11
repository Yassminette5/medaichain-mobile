import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

class OcrAnalyzeScreen extends StatefulWidget {
  const OcrAnalyzeScreen({super.key});

  @override
  State<OcrAnalyzeScreen> createState() => _OcrAnalyzeScreenState();
}

class _OcrAnalyzeScreenState extends State<OcrAnalyzeScreen> {
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _pickAndAnalyze() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final picked = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (picked == null || picked.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final file = picked.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _loading = false;
          _error = 'Fichier invalide.';
        });
        return;
      }

      final data = await ApiService.mlOcrAnalyze(
        fileBytes: bytes,
        fileName: file.name,
      );
      setState(() {
        _result = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyses = (_result?['analyses_detectees'] as List?)?.cast<dynamic>() ?? const [];
    final description = (_result?['description'] ?? '') as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analyse OCR', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _pickAndAnalyze,
                icon: const Icon(Icons.document_scanner_rounded),
                label: Text('Analyser un document', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(_error!, style: GoogleFonts.poppins(color: AppColors.error)),
            ],
            if (!_loading && _result != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Description', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(description.isEmpty ? '—' : description, style: GoogleFonts.poppins()),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Analyses détectées', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: analyses.isEmpty
                    ? Center(child: Text('Aucune analyse détectée', style: GoogleFonts.poppins(color: AppColors.textSecondary)))
                    : ListView.separated(
                        itemCount: analyses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final a = analyses[index] as Map<String, dynamic>? ?? {};
                          final nom = (a['nom'] ?? '').toString();
                          final valeur = a['valeur']?.toString() ?? '';
                          final statut = (a['statut'] ?? '').toString();
                          final color = switch (statut.toLowerCase()) {
                            'élevé' || 'eleve' || 'high' => AppColors.error,
                            'bas' || 'low' => AppColors.accentOrange,
                            _ => AppColors.success,
                          };
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
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
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

