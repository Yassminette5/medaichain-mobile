import 'package:flutter/material.dart';
import '../models/analysis_type_model.dart';
import '../services/analysis_service.dart';
import 'add_analysis_page.dart';

class ManageAnalysisPage extends StatefulWidget {
  const ManageAnalysisPage({super.key});

  @override
  State<ManageAnalysisPage> createState() => _ManageAnalysisPageState();
}

class _ManageAnalysisPageState extends State<ManageAnalysisPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tous';
  final AnalysisService _analysisService = AnalysisService();

  List<AnalysisTypeModel> get _analysisTypes => _analysisService.centerAnalyses;

  List<String> get _categories {
    final categories = _analysisTypes.map((a) => _translateCategory(a.category)).toSet().toList();
    categories.insert(0, 'Tous');
    return categories;
  }

  String _translateCategory(String category) {
    switch (category) {
      case 'Biochemistry':
        return 'Biochimie';
      case 'Hematology':
        return 'Hématologie';
      case 'Endocrinology':
        return 'Endocrinologie';
      case 'Microbiology':
        return 'Microbiologie';
      case 'Virology':
        return 'Virologie';
      case 'Genetics':
        return 'Génétique';
      default:
        return category;
    }
  }

  List<AnalysisTypeModel> get _filteredAnalyses {
    var filtered = _analysisTypes;

    if (_selectedCategory != 'Tous') {
      filtered = filtered.where((a) => _translateCategory(a.category) == _selectedCategory).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((a) {
        return a.name.toLowerCase().contains(query) ||
            a.subtitle.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'drop':
        return Icons.water_drop;
      case 'microscope':
        return Icons.science;
      case 'heart':
        return Icons.favorite;
      case 'flask':
        return Icons.science_outlined;
      case 'molecule':
        return Icons.ac_unit;
      case 'shield':
        return Icons.shield;
      case 'syringe':
        return Icons.medical_services;
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Gestion des analyses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAnalysisPage(),
                ),
              );
              if (result != null) {
                setState(() {
                  _analysisService.addAnalysis(result);
                });
              }
            },
          ),
        ],
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
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
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
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[700] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                            if (isSelected) const SizedBox(width: 6),
                            Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
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
              children: _filteredAnalyses.map((analysis) => _buildAnalysisItem(analysis)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(AnalysisTypeModel analysis) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconData(analysis.icon),
                color: Colors.blue[700],
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analysis.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: analysis.isActive,
              onChanged: (value) {
                setState(() {
                  _analysisService.updateAnalysis(analysis.id, value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
