import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'ocr_analyze_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'ocr_document_detail_screen.dart';
import 'package:share_plus/share_plus.dart';

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
  String? _error;
  List<Map<String, dynamic>> _docs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = mounted ? Provider.of<AuthProvider>(context, listen: false) : null;
      final patientId = auth?.user?.id;
      List<Map<String, dynamic>> list = const [];
      if (patientId != null && patientId.isNotEmpty) {
        final raw = await ApiService.getPatientAnalysisResults(patientId);
        list = raw.map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>()).toList();
      } else {
        list = await ApiService.getOcrDocuments();
      }
      if (mounted) {
        setState(() {
          _docs = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.colors.first.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(widget.icon, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _load,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.description, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "${_docs.length} Documents",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_done, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Synchro",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Document List (dynamique depuis backend, via état local)
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            'Erreur: $_error',
                            style: GoogleFonts.poppins(color: AppColors.error),
                          ),
                        )
                      : _docs.isEmpty
                          ? Center(
                              child: Text(
                                'Aucun document',
                                style: GoogleFonts.poppins(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _docs.length,
                              itemBuilder: (context, index) {
                                return _buildDocumentCard(context, _docs[index]);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, Map<String, dynamic> doc) {
    // Nom labo et métadonnées (compat lab results + OCR)
    final dynamic lab = doc['labId'];
    final String labName = lab is Map
        ? (lab['centreName']?.toString() ?? lab['name']?.toString() ?? 'Laboratoire')
        : (lab?.toString() ?? '');
    final String analysisType = (doc['analysisType'] ?? '').toString();
    final String resultFile = (doc['resultFile'] ?? '').toString();
    final String fileName = resultFile.isNotEmpty ? resultFile.split('/').last : '';

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
    final String type = (doc['type'] ?? (doc['isPdf'] == true ? 'PDF' : 'PDF')).toString().toUpperCase();
    final String sizeStr = (doc['size'] ?? doc['sizeMB'] ?? '').toString();
    final String status = (doc['status'] ?? 'Verified').toString();
    final bool isVerified = status.toLowerCase().contains('ver') || status.toLowerCase() == 'verified';
    final bool isActive = status.toLowerCase() == 'active';
    final Color accentColor = AppColors.primary;

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
                    // Document Icon with gradient background
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.2),
                            accentColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          type == "PDF" ? Icons.picture_as_pdf : Icons.image,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                    ),
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
                              // Status Badge
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
                        if (type != 'PDF')
                          GestureDetector(
                            onTap: () {
                              // Ouvre l'écran d'analyse (l'utilisateur choisira l'image à envoyer)
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
                        if (type != 'PDF') const SizedBox(height: 8),
                        // Voir document (ouvre le PDF)
                        GestureDetector(
                          onTap: () async {
                            if (fileName.isEmpty) return;
                            final url = '${ApiService.baseUrl}/lab/uploads/results/$fileName'
                                .replaceAll('//lab', '/lab'); // éviter les doubles '/'
                            final uri = Uri.parse(url);
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.picture_as_pdf_rounded,
                              color: accentColor,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            _showDocumentOptions(context, doc);
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

  void _showDocumentOptions(BuildContext context, Map<String, dynamic> doc) {
    final String resultFile = (doc['resultFile'] ?? '').toString();
    final String fileName = resultFile.isNotEmpty ? resultFile.split('/').last : '';
    final String url = fileName.isEmpty
        ? ''
        : '${ApiService.baseUrl}/lab/uploads/results/$fileName'.replaceAll('//lab', '/lab');
    final String? docId = (doc['_id'] ?? doc['id'])?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom + 16),
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
                      Navigator.pop(context);
                      if (url.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
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
                      Navigator.pop(context);
                      if (url.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lien indisponible"), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      final uri = Uri.parse(url);
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                  _buildOptionTile(
                    Icons.delete_outline,
                    "Delete",
                    const Color(0xFFFF6B9D),
                    onTap: () async {
                      Navigator.pop(context);
                      final ok = await showDialog<bool>(
                            context: context,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("ID document manquant"), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      final success = await ApiService.deleteOcrDocuments([docId]);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Document supprimé"), backgroundColor: AppColors.success),
                        );
                        _load();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
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