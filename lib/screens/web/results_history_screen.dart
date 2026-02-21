import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Écran d'historique des résultats par patient
class ResultsHistoryScreen extends StatefulWidget {
  const ResultsHistoryScreen({super.key});

  @override
  State<ResultsHistoryScreen> createState() => _ResultsHistoryScreenState();
}

class _ResultsHistoryScreenState extends State<ResultsHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _filteredResults = [];
  bool _isLoading = true;
  String _selectedFilter = 'Tous';
  Map<String, dynamic>? _selectedResult;

  @override
  void initState() {
    super.initState();
    _loadResults();
    _searchController.addListener(_filterResults);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);

    try {
      // Simulation des données avec plus de détails pour le split view
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _results = [
            {
              'id': '1',
              'patientName': 'Ahmed Benali',
              'patientEmail': 'ahmed@example.com',
              'analysisType': 'Analyse sanguine',
              'date': DateTime.now().subtract(const Duration(days: 5)),
              'status': 'signé',
              'fileUrl': 'resultat_001.pdf',
              'notes': 'Taux d\'hémoglobine légèrement bas. À surveiller périodiquement.',
              'lab': 'Laboratoire Central de Tunis',
            },
            {
              'id': '2',
              'patientName': 'Fatima Zohra',
              'patientEmail': 'fatima@example.com',
              'analysisType': 'Scanner Thoracique',
              'date': DateTime.now().subtract(const Duration(days: 10)),
              'status': 'signé',
              'fileUrl': 'resultat_002.pdf',
              'notes': 'Absence de lésions suspectes. Bilan pulmonaire satisfaisant.',
              'lab': 'Centre d\'Imagerie Alpha',
            },
            {
              'id': '3',
              'patientName': 'Mohamed Amine',
              'patientEmail': 'mohamed@example.com',
              'analysisType': 'Radiologie Genou',
              'date': DateTime.now().subtract(const Duration(days: 2)),
              'status': 'en attente',
              'fileUrl': 'resultat_003.pdf',
              'notes': 'Rapport en cours de rédaction par le radiologue consultant.',
              'lab': 'Laboratoire Central de Tunis',
            },
            {
              'id': '4',
              'patientName': 'Sami Karray',
              'patientEmail': 'sami@example.com',
              'analysisType': 'Bilan Lipidique',
              'date': DateTime.now().subtract(const Duration(days: 12)),
              'status': 'signé',
              'fileUrl': 'resultat_004.pdf',
              'notes': 'Résultats dans les normes. Pas d\'anomalie détectée.',
              'lab': 'Laboratoire Pasteur',
            },
          ];
          _filteredResults = _results;
          if (_results.isNotEmpty) {
            _selectedResult = _results.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erreur lors du chargement: $e');
      }
    }
  }

  void _filterResults() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredResults = _results;
      } else {
        _filteredResults = _results.where((result) {
          final name = result['patientName']?.toString().toLowerCase() ?? '';
          final email = result['patientEmail']?.toString().toLowerCase() ?? '';
          final type = result['analysisType']?.toString().toLowerCase() ?? '';
          return name.contains(query) || email.contains(query) || type.contains(query);
        }).toList();
      }
      
      // Reset selection if current selection is filtered out
      if (_selectedResult != null && !_filteredResults.contains(_selectedResult)) {
        _selectedResult = _filteredResults.isNotEmpty ? _filteredResults.first : null;
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'signé':
        return AppColors.success;
      case 'en attente':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Gauche : Liste de l'historique
          Expanded(
            flex: 3,
            child: _buildHistoryPanel(),
          ),
          // Séparateur vertical subtil
          Container(
            width: 1,
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
          // Section Droite : Détail de l'analyse
          Expanded(
            flex: 2,
            child: _buildDetailPanel(),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Historique de Santé',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Accédez à tous vos rapports d\'analyses passés',
                          style: TextStyle(
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
              const SizedBox(height: 24),
              _buildFilters(),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredResults.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      itemCount: _filteredResults.length,
                      itemBuilder: (context, index) {
                        return _buildResultCard(_filteredResults[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 320,
      height: 45,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher un patient ou une analyse...',
          hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        _buildFilterChip('Tous', _selectedFilter == 'Tous'),
        const SizedBox(width: 8),
        _buildFilterChip('Signés', _selectedFilter == 'Signés'),
        const SizedBox(width: 8),
        _buildFilterChip('En attente', _selectedFilter == 'En attente'),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          if (label == 'Tous') {
            _filteredResults = _results;
          } else if (label == 'Signés') {
            _filteredResults = _results.where((r) => r['status']?.toString().toLowerCase() == 'signé').toList();
          } else if (label == 'En attente') {
            _filteredResults = _results.where((r) => r['status']?.toString().toLowerCase() == 'en attente').toList();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
          border: isSelected ? null : Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: AppColors.textLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Aucun résultat trouvé',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Réessayez avec d\'autres mots clés ou filtres',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final isSelected = _selectedResult?['id'] == result['id'];
    final status = result['status']?.toString() ?? '';
    final statusColor = _getStatusColor(status);
    final date = result['date'] as DateTime;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedResult = result),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getAnalysisIcon(result['analysisType']),
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result['patientName'] ?? 'Patient',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result['analysisType'] ?? 'Analyse',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAnalysisIcon(String type) {
    type = type.toLowerCase();
    if (type.contains('sang') || type.contains('lipide')) return Icons.bloodtype_rounded;
    if (type.contains('scan') || type.contains('radio')) return Icons.biotech_rounded;
    return Icons.assignment_rounded;
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
              child: Icon(Icons.touch_app_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sélectionnez une analyse',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Cliquez sur une analyse dans la liste pour\nconsulter ses détails et son rapport.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      );
    }

    final result = _selectedResult!;
    final statusColor = _getStatusColor(result['status'] ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result['status'].toString().toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_rounded),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            result['analysisType'] ?? 'Rapport d\'analyse',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(result['date']),
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 40),
          _buildDetailSection('Informations Patient', [
            _buildDetailItem(Icons.person_outline_rounded, 'Nom', result['patientName']),
            _buildDetailItem(Icons.email_outlined, 'Email', result['patientEmail']),
            _buildDetailItem(Icons.badge_outlined, 'ID Rapport', '#${result['id']}'),
          ]),
          const SizedBox(height: 32),
          _buildDetailSection('Origine & Audit', [
            _buildDetailItem(Icons.business_rounded, 'Laboratoire', result['lab']),
            _buildDetailItem(Icons.verified_user_outlined, 'Sécurité', 'Signé via MEDAIChain'),
          ]),
          const SizedBox(height: 32),
          _buildDetailSection('Observations Médicales', [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
              ),
              child: Text(
                result['notes'] ?? 'Aucun commentaire additionnel.',
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5, fontStyle: FontStyle.italic),
              ),
            ),
          ]),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download_rounded, color: Colors.white),
                  label: const Text('Télécharger PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_rounded),
                  color: AppColors.primary,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ],
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
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textLight,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(
            value ?? 'Non renseigné',
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

