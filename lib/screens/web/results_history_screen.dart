import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

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
      // TODO: Récupérer les résultats depuis l'API
      // Pour l'instant, on simule des données
      await Future.delayed(const Duration(seconds: 1));

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
            },
            {
              'id': '2',
              'patientName': 'Fatima Zohra',
              'patientEmail': 'fatima@example.com',
              'analysisType': 'Scanner',
              'date': DateTime.now().subtract(const Duration(days: 10)),
              'status': 'signé',
              'fileUrl': 'resultat_002.pdf',
            },
            {
              'id': '3',
              'patientName': 'Mohamed Amine',
              'patientEmail': 'mohamed@example.com',
              'analysisType': 'Radiologie',
              'date': DateTime.now().subtract(const Duration(days: 2)),
              'status': 'en attente',
              'fileUrl': 'resultat_003.pdf',
            },
          ];
          _filteredResults = _results;
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
          return name.contains(query) ||
              email.contains(query) ||
              type.contains(query);
        }).toList();
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
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Historique des résultats',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par patient, email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Filtres
          Row(
            children: [
              _buildFilterChip('Tous', _selectedFilter == 'Tous'),
              const SizedBox(width: 12),
              _buildFilterChip('Signés', _selectedFilter == 'Signés'),
              const SizedBox(width: 12),
              _buildFilterChip('En attente', _selectedFilter == 'En attente'),
            ],
          ),
          const SizedBox(height: 24),
          // Liste des résultats
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filteredResults.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun résultat trouvé',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._filteredResults.map((result) {
              return _buildResultCard(result);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
          if (label == 'Tous') {
            _filteredResults = _results;
          } else if (label == 'Signés') {
            _filteredResults = _results
                .where((r) => r['status']?.toString().toLowerCase() == 'signé')
                .toList();
          } else if (label == 'En attente') {
            _filteredResults = _results
                .where((r) =>
                    r['status']?.toString().toLowerCase() == 'en attente')
                .toList();
          }
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final status = result['status']?.toString() ?? '';
    final statusColor = _getStatusColor(status);
    final date = result['date'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['patientName']?.toString() ?? 'Patient',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result['patientEmail']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      result['analysisType']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              // TODO: Télécharger le fichier
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Téléchargement de ${result['fileUrl']}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Télécharger',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              // TODO: Partager avec médecin/patient
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Partage automatique activé'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Partager',
          ),
        ],
      ),
    );
  }
}
