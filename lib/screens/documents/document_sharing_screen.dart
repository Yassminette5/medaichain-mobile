import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Screen for managing document sharing with doctors
/// Displays user's prescriptions/documents with checkboxes for sharing control
class DocumentSharingScreen extends StatefulWidget {
  const DocumentSharingScreen({super.key});

  @override
  State<DocumentSharingScreen> createState() => _DocumentSharingScreenState();
}

class _DocumentSharingScreenState extends State<DocumentSharingScreen> {
  List<Map<String, dynamic>> _documents = [];
  Map<String, bool> _sharingState = {};
  Map<String, bool> _loadingState = {};
  bool _isLoadingDocuments = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoadingDocuments = true;
      _error = null;
    });

    try {
      final docs = await ApiService.getMyPrescriptionsWithSharing();
      if (mounted) {
        setState(() {
          _documents = docs;
          // Initialize sharing state from document data
          for (var doc in docs) {
            final docId = doc['_id']?.toString() ?? doc['id']?.toString() ?? '';
            if (docId.isNotEmpty) {
              // Check if document has any sharing info
              _sharingState[docId] = (doc['sharedWith']?.length ?? 0) > 0;
            }
          }
          _isLoadingDocuments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement des documents: $e';
          _isLoadingDocuments = false;
        });
      }
    }
  }

  Future<void> _toggleDocumentSharing(String docId, bool newState) async {
    if (_loadingState[docId] ?? false) return;

    setState(() {
      _loadingState[docId] = true;
    });

    try {
      if (newState) {
        // Share document with all doctors
        final success = await ApiService.shareDocumentsWithDoctors(
          prescriptionIds: [docId],
          doctorIds: [], // Currently shares with all doctors
        );

        if (success && mounted) {
          setState(() {
            _sharingState[docId] = true;
            _loadingState[docId] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document partagé avec succès'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('Erreur lors du partage du document');
        }
      } else {
        // For now, unshare is not implemented on backend
        // Just update local state
        if (mounted) {
          setState(() {
            _sharingState[docId] = false;
            _loadingState[docId] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Partage annulé'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingState[docId] = false;
          // Revert state on error
          _sharingState[docId] = !newState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDocuments {
    if (_searchQuery.isEmpty) return _documents;
    final query = _searchQuery.toLowerCase();
    return _documents.where((doc) {
      final notes = (doc['notes'] ?? '').toString().toLowerCase();
      final prescriptionDate = (doc['prescriptionDate'] ?? '').toString().toLowerCase();
      return notes.contains(query) || prescriptionDate.contains(query);
    }).toList();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date inconnue';
    try {
      if (date is String) {
        final dateObj = DateTime.parse(date);
        return '${dateObj.day}/${dateObj.month}/${dateObj.year}';
      }
    } catch (_) {}
    return 'Date inconnue';
  }

  int _getMedicationCount(Map<String, dynamic> doc) {
    final medications = doc['medications'];
    if (medications is List) return medications.length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Mes documents',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Contrôlez le partage de vos documents avec les médecins',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Rechercher un document...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ),

          // Documents list
          Expanded(
            child: _isLoadingDocuments
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDocuments,
                              child: Text(
                                'Réessayer',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredDocuments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.folder_open, size: 64, color: AppColors.textLight),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Aucun document trouvé'
                                      : 'Aucun résultat',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredDocuments.length,
                            itemBuilder: (context, index) {
                              final doc = _filteredDocuments[index];
                              final docId = doc['_id']?.toString() ?? doc['id']?.toString() ?? '';
                              final isShared = _sharingState[docId] ?? false;
                              final isLoading = _loadingState[docId] ?? false;

                              return _buildDocumentCard(
                                doc: doc,
                                docId: docId,
                                isShared: isShared,
                                isLoading: isLoading,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required Map<String, dynamic> doc,
    required String docId,
    required bool isShared,
    required bool isLoading,
  }) {
    final medCount = _getMedicationCount(doc);
    final dateStr = _formatDate(doc['prescriptionDate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document header with date and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ordonnance',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$medCount médicament${medCount != 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Sharing checkbox
                Opacity(
                  opacity: isLoading ? 0.6 : 1,
                  child: GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => _toggleDocumentSharing(docId, !isShared),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isShared ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isShared ? AppColors.primary : AppColors.textLight,
                          width: isShared ? 0 : 1,
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            )
                          : Icon(
                              isShared ? Icons.check : Icons.add,
                              color: isShared ? Colors.white : AppColors.textLight,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ],
            ),

            // Notes (if available)
            if (doc['notes'] != null && (doc['notes'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Notes: ${doc['notes']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Sharing status indicator
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(
                    isShared ? Icons.share : Icons.lock,
                    size: 16,
                    color: isShared ? Colors.green : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isShared ? 'Partagé avec les médecins' : 'Non partagé',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isShared ? Colors.green : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
