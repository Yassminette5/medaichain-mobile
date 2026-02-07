import 'package:flutter/material.dart';
import '../models/analysis_model.dart';

class AnalysisSelectionPage extends StatefulWidget {
  final String analysisType;

  const AnalysisSelectionPage({
    super.key,
    required this.analysisType,
  });

  @override
  State<AnalysisSelectionPage> createState() => _AnalysisSelectionPageState();
}

class _AnalysisSelectionPageState extends State<AnalysisSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Toutes';
  final Set<String> _selectedAnalyses = {};

  final List<AnalysisModel> _allAnalyses = [
    AnalysisModel(
      id: '1',
      name: 'NFS (Numération Formule Sanguine)',
      category: 'Hématologie',
      code: 'HEM-001',
      icon: 'flask',
      isFavorite: true,
    ),
    AnalysisModel(
      id: '2',
      name: 'Glycémie à jeun',
      category: 'Biochimie',
      code: 'BIO-104',
      icon: 'drop',
      isFavorite: true,
    ),
    AnalysisModel(
      id: '3',
      name: 'PCR COVID-19',
      category: 'Virologie',
      code: 'VIR-992',
      icon: 'virus',
      isFavorite: true,
      isUrgent: true,
    ),
    AnalysisModel(
      id: '4',
      name: 'Caryotype constitutionnel',
      category: 'Génétique',
      code: 'GEN-401',
      icon: 'dna',
    ),
    AnalysisModel(
      id: '5',
      name: 'Bilan Lipidique',
      category: 'Biochimie',
      code: 'BIO-202',
      icon: 'cross',
    ),
    AnalysisModel(
      id: '6',
      name: 'Troponine I',
      category: 'Biochimie',
      code: 'BIO-885',
      icon: 'chart',
    ),
    AnalysisModel(
      id: '7',
      name: 'Analyse d\'urine complète',
      category: 'Biochimie',
      code: 'BIO-301',
      icon: 'flask',
    ),
    AnalysisModel(
      id: '8',
      name: 'Créatinine',
      category: 'Biochimie',
      code: 'BIO-402',
      icon: 'drop',
    ),
  ];

  List<String> get _categories {
    final categories = _allAnalyses.map((a) => a.category).toSet().toList();
    categories.insert(0, 'Toutes');
    return categories;
  }

  List<AnalysisModel> get _filteredAnalyses {
    var filtered = _allAnalyses;

    // Filtre par catégorie
    if (_selectedCategory != 'Toutes') {
      filtered = filtered.where((a) => a.category == _selectedCategory).toList();
    }

    // Filtre par recherche
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((a) {
        return a.name.toLowerCase().contains(query) ||
            a.code.toLowerCase().contains(query);
      }).toList();
    }

    // Séparer favoris et autres
    final favorites = filtered.where((a) => a.isFavorite).toList();
    final others = filtered.where((a) => !a.isFavorite).toList();

    return [...favorites, ...others];
  }

  List<AnalysisModel> get _favoriteAnalyses {
    return _filteredAnalyses.where((a) => a.isFavorite).toList();
  }

  List<AnalysisModel> get _otherAnalyses {
    return _filteredAnalyses.where((a) => !a.isFavorite).toList();
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'flask':
        return Icons.science;
      case 'drop':
        return Icons.water_drop;
      case 'virus':
        return Icons.coronavirus;
      case 'dna':
        return Icons.dns;
      case 'cross':
        return Icons.medical_services;
      case 'chart':
        return Icons.bar_chart;
      default:
        return Icons.science;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou code...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Filtres par catégorie
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.blue[700],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Liste des analyses
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_favoriteAnalyses.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'ANALYSES FAVORITES (${_favoriteAnalyses.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ..._favoriteAnalyses.map((analysis) => _buildAnalysisItem(analysis)),
                  const SizedBox(height: 24),
                ],

                if (_otherAnalyses.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'AUTRES ANALYSES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ..._otherAnalyses.map((analysis) => _buildAnalysisItem(analysis)),
                ],
              ],
            ),
          ),

          // Bouton de confirmation
          if (_selectedAnalyses.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedNames = _selectedAnalyses
                          .map((id) => _allAnalyses.firstWhere((a) => a.id == id).name)
                          .toList();
                      Navigator.pop(context, selectedNames);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Confirmer (${_selectedAnalyses.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(AnalysisModel analysis) {
    final isSelected = _selectedAnalyses.contains(analysis.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedAnalyses.remove(analysis.id);
            } else {
              _selectedAnalyses.add(analysis.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(analysis.icon),
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            analysis.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (analysis.isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Urgent',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${analysis.category} • ${analysis.code}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedAnalyses.add(analysis.id);
                    } else {
                      _selectedAnalyses.remove(analysis.id);
                    }
                  });
                },
                activeColor: Colors.blue[700],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
