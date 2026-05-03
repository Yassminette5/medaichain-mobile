import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/prescriptions_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'ocr_analyze_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'ocr_document_detail_screen.dart';
import 'package:share_plus/share_plus.dart';

enum _DossierTab { analyses, ordonnances, informations }

class DocumentListScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;

  const DocumentListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
  });

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  List<Map<String, dynamic>> _docs = const [];
  _DossierTab _tab = _DossierTab.analyses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _docSortDate(Map<String, dynamic> doc) {
    for (final key in ['analysisDate', 'createdAt', 'updatedAt']) {
      final v = doc[key];
      if (v != null) {
        try {
          return DateTime.parse(v.toString());
        } catch (_) {}
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// URL pour ouvrir le fichier (résultat labo ou scan patient dans /uploads/).
  String? _documentFileUrl(Map<String, dynamic> doc) {
    // prescription image
    var presUrl = (doc['prescriptionImageUrl'] ?? '').toString();
    if (presUrl.isNotEmpty) {
      // Resolve relative URLs (starting with /) against backend baseUrl
      if (presUrl.startsWith('/')) {
        presUrl = '${ApiService.baseUrl}$presUrl';
      }
      return presUrl;
    }

    final rf = (doc['resultFile'] ?? '').toString();
    if (rf.isNotEmpty) {
      final fileName = rf.split('/').last;
      return '${ApiService.baseUrl}/lab/uploads/results/$fileName'.replaceAll('//lab', '/lab');
    }
    final imageName = (doc['image_name'] ?? '').toString();
    if (imageName.isNotEmpty) {
      return '${ApiService.baseUrl}/uploads/$imageName';
    }
    return null;
  }

  String _documentFileLabel(Map<String, dynamic> doc) {
    final rf = (doc['resultFile'] ?? '').toString();
    if (rf.isNotEmpty) return rf.split('/').last;
    return (doc['image_name'] ?? '').toString();
  }

  bool _isLabDocument(Map<String, dynamic> doc) =>
      (doc['_docSource'] ?? '') == 'lab' || (doc['resultFile'] ?? '').toString().isNotEmpty;

  bool _docHasOpenableFile(Map<String, dynamic> doc) {
    final u = _documentFileUrl(doc);
    return u != null && u.isNotEmpty;
  }

  bool _isPrescriptionDoc(Map<String, dynamic> doc) {
    final src = (doc['_docSource'] ?? '').toString().toLowerCase();
    if (src == 'prescription') return true;

    final cat = (doc['documentCategory'] ?? '').toString().toLowerCase();
    if (cat == 'prescription') return true;

    // direct prescription image/url field
    final presUrl = (doc['prescriptionImageUrl'] ?? '').toString();
    if (presUrl.isNotEmpty) return true;
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

  /// Uniquement les documents réellement consultables (évite les entrées vides / fantômes).
  List<Map<String, dynamic>> get _docsWithFiles =>
      _docs.where(_docHasOpenableFile).map((e) => Map<String, dynamic>.from(e)).toList();

  List<Map<String, dynamic>> get _analysisDocs {
    final list = _docsWithFiles.where((d) => !_isPrescriptionDoc(d)).toList();
    list.sort((a, b) => _docSortDate(b).compareTo(_docSortDate(a)));
    return list;
  }

  List<Map<String, dynamic>> get _prescriptionDocs {
    final list = _docsWithFiles.where(_isPrescriptionDoc).toList();
    list.sort((a, b) => _docSortDate(b).compareTo(_docSortDate(a)));
    return list;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = mounted ? Provider.of<AuthProvider>(context, listen: false) : null;
      final patientId = auth?.user?.id;

      final List<Map<String, dynamic>> lab = [];
      final List<Map<String, dynamic>> ocr = [];

      if (patientId != null && patientId.isNotEmpty) {
        try {
          final raw = await ApiService.getPatientAnalysisResults(patientId);
          for (final e in raw) {
            final m = Map<String, dynamic>.from(e as Map);
            m['_docSource'] = 'lab';
            lab.add(m);
          }
        } catch (_) {}
      }

      // fetch prescriptions for the patient
      try {
        final pres = await PrescriptionsService.getMyPrescriptions();
        for (final e in pres) {
          final m = Map<String, dynamic>.from(e);
          m['_docSource'] = 'prescription';
          // ensure image URL is present under prescriptionImageUrl
          // backend returns prescriptionImageUrl field when present
          lab.add(m);
        }
      } catch (_) {}

      try {
        final rawOcr = await ApiService.getOcrDocuments();
        for (final e in rawOcr) {
          final m = Map<String, dynamic>.from(e);
          m['_docSource'] = 'ocr';
          ocr.add(m);
        }
      } catch (_) {}

      final merged = <Map<String, dynamic>>[...lab, ...ocr];
      merged.sort((a, b) => _docSortDate(b).compareTo(_docSortDate(a)));

      if (mounted) {
        setState(() {
          _docs = merged;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _docs = const [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _showAddDocumentMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ajouter au dossier',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.science_rounded, color: AppColors.primary),
              title: Text('Analyse / bulletin', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text(
                'PDF ou image — analyse OCR (Tesseract) pour extraire le texte',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPatientDoc(isPrescription: false);
              },
            ),
            ListTile(
              leading: Icon(Icons.medication_rounded, color: AppColors.prescription),
              title: Text('Ordonnance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Image ou PDF : enregistrés tels quels dans votre dossier. Aucune lecture / OCR.',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPatientDoc(isPrescription: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPatientDoc({required bool isPrescription}) async {
    if (_uploading) return;
    try {
      final picked = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de lire le fichier. Réessayez.'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      setState(() => _uploading = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPrescription
                  ? 'Enregistrement de votre fichier (image/PDF), sans analyse…'
                  : 'Envoi et analyse du document…',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      late final Map<String, dynamic> uploadData;
      late final String titleOverride;

      if (isPrescription) {
        uploadData = await ApiService.uploadPatientOcrFileRaw(fileBytes: bytes, fileName: file.name);
        titleOverride = 'Ordonnance · ${file.name}';
        final okPresc = await ApiService.savePatientOcrAfterUpload(
          uploadData: {
            ...uploadData,
            'title': 'Ordonnance',
            'description': 'Ordonnance enregistrée depuis votre appareil',
            'details': <String, dynamic>{
              'kind': 'prescription',
              'originalName': uploadData['originalName'] ?? file.name,
            },
          },
          documentCategory: 'prescription',
          titleOverride: titleOverride,
        );
        if (!mounted) return;
        setState(() => _uploading = false);
        if (okPresc) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ordonnance ajoutée au dossier'), backgroundColor: AppColors.success),
          );
          await _load();
          if (mounted) await _maybePromptProfileGaps();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de l\'enregistrement'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      uploadData = await ApiService.uploadPatientOcrFile(fileBytes: bytes, fileName: file.name);
      titleOverride = 'Analyse · ${uploadData['title'] ?? file.name}';
      final ok = await ApiService.savePatientOcrAfterUpload(
        uploadData: uploadData,
        documentCategory: 'lab_analysis',
        titleOverride: titleOverride,
      );

      if (!mounted) return;
      setState(() => _uploading = false);

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document ajouté à votre dossier'), backgroundColor: AppColors.success),
        );
        await _load();
        if (mounted) await _maybePromptProfileGaps();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de l\'enregistrement du document'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _maybePromptProfileGaps() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final u = auth.user;
    if (u == null || u.role != UserRole.patient) return;

    final missingAllergies = u.allergies == null || u.allergies!.isEmpty;
    final missingDemographics = u.age == null ||
        u.height == null ||
        u.weight == null ||
        u.gender == null ||
        u.gender!.trim().isEmpty;

    if (!missingAllergies && !missingDemographics) return;

    final allergiesCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: u.age?.toString() ?? '');
    final heightCtrl = TextEditingController(text: u.height?.toString() ?? '');
    final weightCtrl = TextEditingController(text: u.weight?.toString() ?? '');
    String? genderVal = (u.gender != null && u.gender!.isNotEmpty) ? u.gender!.toLowerCase() : null;

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Compléter votre profil ?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vous pouvez envoyer ces informations au serveur pour les retrouver lors des prochains soins.',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
              ),
              if (missingAllergies) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: allergiesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Allergies (séparées par des virgules)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (missingDemographics) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Âge', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Taille (cm)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Poids (kg)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: genderVal,
                  decoration: const InputDecoration(labelText: 'Genre', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Homme')),
                    DropdownMenuItem(value: 'female', child: Text('Femme')),
                  ],
                  onChanged: (v) => genderVal = v,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Plus tard')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (go != true || !mounted) return;

    try {
      List<String>? allergiesList;
      if (missingAllergies && allergiesCtrl.text.trim().isNotEmpty) {
        allergiesList = allergiesCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      int? age;
      int? height;
      int? weight;
      if (missingDemographics) {
        age = int.tryParse(ageCtrl.text.trim());
        height = int.tryParse(heightCtrl.text.trim());
        weight = int.tryParse(weightCtrl.text.trim());
      }

      if (allergiesList == null && age == null && height == null && weight == null && genderVal == null) {
        return;
      }

      final updated = await ApiService.patchPatientProfileFields(
        allergies: allergiesList,
        age: age,
        height: height,
        weight: weight,
        gender: genderVal,
      );
      auth.setUser(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Style type segmented control (fond lavande, onglet actif violet plein).
  static const Color _segAccent = Color(0xFF5D5FEF);
  static const Color _segTrack = Color(0xFFF3F3FF);
  static const Color _segBorder = Color(0xFFE4E4F5);

  Widget _buildDossierSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _segTrack,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _segBorder, width: 1),
      ),
      child: Row(
        children: [
          _buildSegmentSlot(
            tab: _DossierTab.analyses,
            label: 'Analyses',
          ),
          _buildSegmentSlot(
            tab: _DossierTab.ordonnances,
            label: 'Ordonnances',
          ),
          _buildSegmentSlot(
            tab: _DossierTab.informations,
            label: 'Infos perso',
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentSlot({
    required _DossierTab tab,
    required String label,
  }) {
    final selected = _tab == tab;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _tab = tab),
          borderRadius: BorderRadius.circular(18),
          splashColor: _segAccent.withValues(alpha: 0.12),
          highlightColor: _segAccent.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? _segAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: selected ? Colors.white : _segAccent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _fileNameLooksLikeImage(String name) {
    final l = name.toLowerCase();
    return l.endsWith('.jpg') ||
        l.endsWith('.jpeg') ||
        l.endsWith('.png') ||
        l.endsWith('.webp');
  }

  Widget _buildCardLeadingVisual(
    String? openUrl,
    String fileName,
    bool isPrescription,
    Color accent,
    bool looksPdf,
  ) {
    final showThumb = openUrl != null && openUrl.isNotEmpty && _fileNameLooksLikeImage(fileName);
    if (showThumb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: FutureBuilder<Uint8List?>(
          future: kIsWeb ? _fetchImageBytes(openUrl) : Future.value(null),
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (kIsWeb) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  color: accent.withValues(alpha: 0.1),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                  ),
                );
              }
              if (bytes != null && bytes.isNotEmpty) {
                return Image.memory(
                  bytes,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              }
              return _buildCardIconPlaceholder(isPrescription, accent, looksPdf);
            }

            return FutureBuilder<Map<String, String>>(
              future: ApiService.authImageHeaders(),
              builder: (context, hdrSnap) {
                return Image.network(
                  openUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  headers: hdrSnap.data,
                  gaplessPlayback: true,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      color: accent.withValues(alpha: 0.1),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => _buildCardIconPlaceholder(isPrescription, accent, looksPdf),
                );
              },
            );
          },
        ),
      );
    }
    return _buildCardIconPlaceholder(isPrescription, accent, looksPdf);
  }

  Widget _buildCardIconPlaceholder(bool isPrescription, Color accent, bool looksPdf) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          isPrescription
              ? Icons.medication_rounded
              : (looksPdf ? Icons.picture_as_pdf : Icons.image),
          color: accent,
          size: 22,
        ),
      ),
    );
  }

  Future<Uint8List?> _fetchImageBytes(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final headers = await ApiService.authImageHeaders();
      final resp = await http.get(Uri.parse(url), headers: headers);
      if (resp.statusCode == 200) return resp.bodyBytes;
    } catch (_) {}
    return null;
  }

  Widget _buildTabScrollContent() {
    switch (_tab) {
      case _DossierTab.informations:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Informations personnelles',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Profil utilisé pour les rendez-vous et le dossier médical.',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 16),
            _buildPersonalInfoSection(),
            const SizedBox(height: 24),
            Text(
              'Documents',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              'Utilisez les onglets Analyses et Ordonnances pour consulter vos fichiers.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
            ),
          ],
        );
      case _DossierTab.analyses:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes analyses',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Laboratoire et documents analysés (OCR).',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (_analysisDocs.isEmpty)
              _buildEmptyHint('Aucune analyse. Appuyez sur + puis « Analyse / bulletin ».')
            else
              ..._analysisDocs.map((d) => _buildDocumentCard(context, d, isPrescription: false)),
          ],
        );
      case _DossierTab.ordonnances:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes ordonnances',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fichiers enregistrés tels quels (photo ou PDF), sans analyse automatique.',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                  ),
                ],
              ),
            ),
            if (_prescriptionDocs.isEmpty)
              _buildEmptyHint('Aucune ordonnance. Appuyez sur + puis « Ordonnance ».')
            else
              ..._prescriptionDocs.map((d) => _buildDocumentCard(context, d, isPrescription: true)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Même fond que le reste de l’écran (pas de bandeau blanc)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
              color: AppColors.background,
              child: Column(
                children: [
                  Row(
                    children: [
                      Material(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(10),
                          child: const SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Actualiser',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _loading || _uploading ? null : _load,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _segAccent.withValues(alpha: 0.35)),
                              ),
                              child: Icon(
                                Icons.sync_rounded,
                                size: 17,
                                color: _loading ? AppColors.textLight : _segAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Ajouter un document',
                        child: Material(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          elevation: 0,
                          child: InkWell(
                            onTap: _uploading ? null : _showAddDocumentMenu,
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: _uploading
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDossierSegmentedControl(),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Erreur: $_error',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: AppColors.error),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _buildTabScrollContent(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final u = auth.user;
        if (u == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Connectez-vous pour afficher vos informations personnelles.',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
            ),
          );
        }
        if (u.role != UserRole.patient) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Les informations détaillées du dossier patient sont disponibles avec un compte patient.',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
            ),
          );
        }
        final name = (u.fullName != null && u.fullName!.trim().isNotEmpty) ? u.fullName! : u.email;
        final g = u.gender?.toLowerCase();
        final genderFr = (g == 'male' || g == 'homme')
            ? 'Homme'
            : (g == 'female' || g == 'femme')
                ? 'Femme'
                : (u.gender ?? '—');
        final allergiesStr = (u.allergies != null && u.allergies!.isNotEmpty) ? u.allergies!.join(', ') : 'Aucune déclarée';
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Mes informations',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 6),
              Text(
                'Âge : ${u.age ?? '—'} · Genre : $genderFr · Taille : ${u.height ?? '—'} cm · Poids : ${u.weight ?? '—'} kg',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey),
              ),
              const SizedBox(height: 8),
              Text(
                'Allergies : $allergiesStr',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, Map<String, dynamic> doc, {required bool isPrescription}) {
    // Nom labo et métadonnées (compat lab results + OCR)
    final dynamic lab = doc['labId'];
    final String labName = lab is Map
        ? (lab['centreName']?.toString() ?? lab['name']?.toString() ?? 'Laboratoire')
        : (lab?.toString() ?? '');
    final String fileName = _documentFileLabel(doc);
    final String? openUrl = _documentFileUrl(doc);

    final String name = (labName.isNotEmpty
            ? labName
            : (doc['name'] ?? doc['title'] ?? doc['analysisType'] ?? 'Document'))
        .toString();

    final String rawDate = (doc['analysisDate'] ?? doc['date'] ?? doc['createdAt'] ?? '').toString();
    String date = rawDate;
    try {
      if (rawDate.isNotEmpty) {
        date = DateFormat('dd MMM yyyy', 'fr').format(DateTime.parse(rawDate));
      }
    } catch (_) {}
    final bool looksPdf =
        fileName.toLowerCase().endsWith('.pdf') || (doc['isPdf'] == true) || (doc['type']?.toString().toUpperCase() == 'PDF');
    final String type = looksPdf ? 'PDF' : (doc['type'] ?? 'IMG').toString().toUpperCase();
    final String sizeStr = (doc['size'] ?? doc['sizeMB'] ?? '').toString();
    final String status = (doc['status'] ?? 'Verified').toString();
    final bool isVerified = status.toLowerCase().contains('ver') || status.toLowerCase() == 'verified';
    final bool isActive = status.toLowerCase() == 'active';
    final Color accentColor = isPrescription ? AppColors.prescription : AppColors.primary;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OcrDocumentDetailScreen(document: doc)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Gradient accent on the left
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor,
                        accentColor.withOpacity(0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    _buildCardLeadingVisual(openUrl, fileName, isPrescription, accentColor, looksPdf),
                    const SizedBox(width: 12),

                    // Document Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isPrescription)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.prescription.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.receipt_long_rounded, size: 12, color: AppColors.prescription),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Fichier',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.prescription,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isVerified
                                        ? const Color(0xFF4ECDC4).withOpacity(0.15)
                                        : isActive
                                            ? const Color(0xFFFF9B71).withOpacity(0.15)
                                            : const Color(0xFFFFB88C).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isVerified
                                            ? Icons.verified
                                            : isActive
                                                ? Icons.access_time
                                                : Icons.pending,
                                        size: 12,
                                        color: isVerified
                                            ? const Color(0xFF4ECDC4)
                                            : isActive
                                                ? const Color(0xFFFF9B71)
                                                : const Color(0xFFFFB88C),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        status,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isVerified
                                              ? const Color(0xFF4ECDC4)
                                              : isActive
                                                  ? const Color(0xFFFF9B71)
                                                  : const Color(0xFFFFB88C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Date and Size
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 13, color: AppColors.textGrey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  date.isEmpty ? '—' : date,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.textGrey.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.storage, size: 13, color: AppColors.textGrey),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  sizeStr.isEmpty ? '—' : sizeStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Action Buttons
                    Column(
                      children: [
                        if (!isPrescription && type != 'PDF')
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const OcrAnalyzeScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.psychology_alt_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                          ),
                        if (!isPrescription && type != 'PDF') const SizedBox(height: 8),
                        // Voir document (ouvre le PDF)
                        GestureDetector(
                          onTap: () async {
                            if (openUrl == null || openUrl.isEmpty) return;
                            await launchUrl(Uri.parse(openUrl), mode: LaunchMode.externalApplication);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              looksPdf ? Icons.picture_as_pdf_rounded : Icons.visibility_rounded,
                              color: accentColor,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            _showDocumentOptions(doc);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.more_horiz,
                              color: AppColors.textMedium,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentOptions(Map<String, dynamic> doc) {
    final rootContext = context;
    final String? url = _documentFileUrl(doc);
    final String? docId = (doc['_id'] ?? doc['id'])?.toString();
    final bool allowDelete = !_isLabDocument(doc);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewPadding.bottom + 16),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildOptionTile(
                    Icons.ios_share_rounded,
                    "Partager",
                    AppColors.primary,
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      if (url == null || url.isEmpty) {
                        if (!rootContext.mounted) return;
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          SnackBar(content: Text("Lien indisponible"), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      await Share.share(url, subject: "Document médical");
                    },
                  ),
                  _buildOptionTile(
                    Icons.download_outlined,
                    "Download",
                    const Color(0xFF4ECDC4),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      if (url == null || url.isEmpty) {
                        if (!rootContext.mounted) return;
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          SnackBar(content: Text("Lien indisponible"), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                  ),
                  if (allowDelete)
                    _buildOptionTile(
                      Icons.delete_outline,
                      "Delete",
                      const Color(0xFFFF6B9D),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        final ok = await showDialog<bool>(
                              context: rootContext,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Supprimer'),
                                content: const Text('Confirmer la suppression de ce document ?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
                                ],
                              ),
                            ) ??
                            false;
                        if (!ok) return;
                        if (docId == null) {
                          if (!rootContext.mounted) return;
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(content: Text("ID document manquant"), backgroundColor: AppColors.error),
                          );
                          return;
                        }
                        final success = await ApiService.deleteOcrDocuments([docId]);
                        if (!mounted) return;
                        if (!rootContext.mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(content: Text("Document supprimé"), backgroundColor: AppColors.success),
                          );
                          _load();
                        } else {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(content: Text("Échec de la suppression"), backgroundColor: AppColors.error),
                          );
                        }
                      },
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, Color color, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}