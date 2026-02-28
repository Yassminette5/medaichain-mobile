import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Écran d'historique d'un patient
class PatientHistoryScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String? patientEmail;

  const PatientHistoryScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.patientEmail,
  });

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _selectedResult;
  String? _patientEmail;

  @override
  void initState() {
    super.initState();
    _loadPatientHistory();
  }

  Future<void> _loadPatientHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {

      if (widget.patientEmail != null &&
          widget.patientEmail!.isNotEmpty) {
        _patientEmail = widget.patientEmail;
      } else {
        try {
          final appointments = await ApiService.getLabAppointments();

          for (var appointment in appointments) {
            final status =
            appointment['status']?.toString().toLowerCase();

            if (status == 'accepted') {
              final patientId = appointment['patientId'];

              if (patientId != null && patientId is Map) {
                final patientIdStr =
                    patientId['_id']?.toString() ??
                        patientId['id']?.toString() ??
                        '';

                if (patientIdStr == widget.patientId) {
                  _patientEmail = patientId['email']?.toString();
                  break;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Erreur récupération email: $e');
        }
      }

      if (_patientEmail != null && _patientEmail!.isNotEmpty) {

        final results =
        await ApiService.getAnalysisResults(
            patientEmail: _patientEmail);

        if (mounted) {
          setState(() {
            debugPrint('Fetched ${results.length} results from API.');
            debugPrint('Target patient email for filtering: $_patientEmail');

            // Filtrage strict côté client pour éviter toute fuite de données
            _history = results
                .where((result) {
                  final resultEmail = result['patientEmail']?.toString().toLowerCase();
                  final targetEmail = _patientEmail?.toLowerCase();
                  final matches = resultEmail == targetEmail;
                  if (!matches) {
                    debugPrint('Filtering out result with email: $resultEmail (does not match $targetEmail)');
                  }
                  return matches;
                })
                .map((result) {
                  return {
                    'type': result['analysisType'] ?? 'Analyse',
                    'date': result['analysisDate'] ?? '',
                    'createdAt': result['createdAt'] ?? '',
                    'notes': result['notes'] ?? '',
                    'file': result['resultFile'] ?? '',
                    'fileSize': result['fileSize']?.toString() ?? 'N/A',
                    'id': result['_id'] ?? '',
                    'patientEmail': result['patientEmail'] ?? '',
                  };
                }).toList();

            debugPrint('Filtered history contains ${_history.length} results.');

            if (_history.isNotEmpty) {
              _selectedResult = _history.first;
            } else {
              _selectedResult = null;
            }

            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _history = [];
          _isLoading = false;
        });
      }

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getFileName(String? path) {
    if (path == null || path.isEmpty) return 'Fichier';
    return path.split('/').last;
  }

  String _prettyAnalysisType(String raw) {
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'analyse_sanguin':
      case 'analyse sanguine':
        return 'Analyse sanguine';
      case 'scanner':
        return 'Scanner';
      case 'radiologie':
        return 'Radiologie';
      case 'imagerie':
        return 'Imagerie';
      case 'biologie':
        return 'Biologie';
      case 'autre':
        return 'Autre';
      default:
        if (v.isEmpty) return 'Analyse';
        return v[0].toUpperCase() + v.substring(1);
    }
  }

  String _formatShortDateForFile(dynamic dateInput) {
    DateTime? date;
    if (dateInput is DateTime) {
      date = dateInput;
    } else {
      try {
        date = DateTime.parse(dateInput.toString());
      } catch (_) {
        return 'date';
      }
    }
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  String _friendlyFileDisplayName(Map<String, dynamic> result) {
    final type = _prettyAnalysisType(result['type']?.toString() ?? '');
    final dateLabel = _formatDate(result['date'] ?? result['createdAt']);
    return 'Rapport $type • $dateLabel.pdf';
  }

  String _getFileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiService.baseUrl}$path';
  }

  final TextEditingController _searchController = TextEditingController();
  
  String _formatDate(dynamic dateInput) {
    if (dateInput == null || dateInput.toString().isEmpty) return 'Date inconnue';
    
    DateTime? date;
    if (dateInput is DateTime) {
      date = dateInput;
    } else {
      try {
        date = DateTime.parse(dateInput.toString());
      } catch (e) {
        return dateInput.toString();
      }
    }

    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture du fichier: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Historique - ${widget.patientName}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Gauche : Liste de l'historique
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border: Border(
                            right: BorderSide(color: AppColors.divider.withValues(alpha: 0.1)),
                          ),
                        ),
                        child: _buildHistoryPanel(),
                      ),
                    ),
                    // Section Droite : Détail du dossier
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: AppColors.background,
                        child: _buildDetailPanel(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Une erreur est survenue',
            style: const TextStyle(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadPatientHistory(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historique de Santé',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dossiers de ${widget.patientName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSearchField(),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : () {
                  final filteredHistory = _history.where((item) {
                    final query = _searchController.text.toLowerCase();
                    if (query.isEmpty) return true;
                    final type = item['type']?.toString().toLowerCase() ?? '';
                    return type.contains(query);
                  }).toList();

                  if (filteredHistory.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      return _buildResultCard(filteredHistory[index]);
                    },
                  );
                }(),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 280,
      height: 45,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Rechercher un dossier...',
          hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }


  Widget _buildResultCard(Map<String, dynamic> result) {
    final isSelected = _selectedResult?['id'] == result['id'];
    final dateStr = _formatDate(result['date'] ?? result['createdAt']);
    final rawFileName = _getFileName(result['file']);
    final typeLabel = _prettyAnalysisType(result['type']?.toString() ?? 'Analyse');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedResult = result),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getAnalysisIcon(result['type']),
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PDF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Tooltip(
                          message: rawFileName,
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.10) : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAnalysisIcon(String type) {
    type = type.toLowerCase();
    if (type.contains('sang')) return Icons.bloodtype_rounded;
    if (type.contains('scan')) return Icons.biotech_rounded;
    if (type.contains('radio')) return Icons.settings_accessibility_rounded;
    if (type.contains('image')) return Icons.image_search_rounded;
    return Icons.assignment_rounded;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 64, color: AppColors.textLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Aucun dossier trouvé',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce patient n\'a pas encore d\'historique enregistré.',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    if (_selectedResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sélectionnez un document',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Cliquez sur un dossier médical pour\nvisualiser ses détails et le télécharger.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      );
    }

    final result = _selectedResult!;
    final dateStr = _formatDate(result['date'] ?? result['createdAt']);
    final rawFileName = _getFileName(result['file']);
    final displayFileName = _friendlyFileDisplayName(result);
    final analysisType = _prettyAnalysisType(result['type']?.toString() ?? 'Analyse médicale');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(Icons.print_rounded, () async {
                          // Logique d'impression/visualisation
                          if (result['file'] != null) {
                            final url = _getFileUrl(result['file']);
                            try {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            } catch (e) {
                              debugPrint('Erreur lors de l\'ouverture du fichier: $e');
                            }
                          }
                        }),
                        const SizedBox(width: 8),
                  ],
                ),
                Text(
                  analysisType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fichier attaché',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                            Text(
                              displayFileName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Tooltip(
                              message: rawFileName,
                              child: Text(
                                rawFileName,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLight),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildDetailSection('Informations Patient', [
                  _buildDetailItem(Icons.person_outline_rounded, 'Nom', widget.patientName),
                  _buildDetailItem(Icons.email_outlined, 'Email', widget.patientEmail ?? 'Non renseigné'),
                  _buildDetailItem(Icons.badge_outlined, 'ID Rapport', '#${result['id'].toString().substring(0, 8)}'),
                ]),
                const SizedBox(height: 32),
                _buildDetailSection('Observations Médicales', [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      result['notes'] ?? 'Aucune observation enregistrée.',
                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6, fontStyle: FontStyle.italic),
                    ),
                  ),
                ]),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (result['file'] != null) {
                            final url = _getFileUrl(result['file']);
                            try {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            } catch (e) {
                              debugPrint('Erreur lors de l\'ouverture du fichier: $e');
                            }
                          }
                        },
                        icon: const Icon(Icons.visibility_rounded, color: Colors.white),
                        label: const Text('Visualiser', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final fileName = _getFileName(result['file']);
                          _downloadFile(_getFileUrl(result['file']), fileName);
                        },
                        icon: const Icon(Icons.file_download_rounded, color: AppColors.primary),
                        label: const Text('Télécharger', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(Icons.share_rounded, () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        color: AppColors.primary,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textLight,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
