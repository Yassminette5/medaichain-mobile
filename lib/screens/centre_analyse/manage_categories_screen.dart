import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Écran de gestion des catégories du laboratoire
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  List<String> _categories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryFilter = 'Tous';

  // Catégories avec leurs icônes et couleurs
  final Map<String, Map<String, dynamic>> _categoryData = {
    'Sang': {
      'icon': Icons.water_drop,
      'color': Colors.red,
      'bgColor': Colors.red.withValues(alpha: 0.1),
    },
    'Cardio': {
      'icon': Icons.favorite,
      'color': Colors.green,
      'bgColor': Colors.green.withValues(alpha: 0.1),
    },
    'Neuro': {
      'icon': Icons.psychology,
      'color': Colors.blue,
      'bgColor': Colors.blue.withValues(alpha: 0.1),
    },
    'Ortho': {
      'icon': Icons.accessibility_new,
      'color': Colors.orange,
      'bgColor': Colors.orange.withValues(alpha: 0.1),
    },
    'Pulmo': {
      'icon': Icons.air,
      'color': Colors.purple,
      'bgColor': Colors.purple.withValues(alpha: 0.1),
    },
    'Biologie': {
      'icon': Icons.science,
      'color': Colors.pink,
      'bgColor': Colors.pink.withValues(alpha: 0.1),
    },
    'Radiologie': {
      'icon': Icons.radio_button_checked,
      'color': Colors.teal,
      'bgColor': Colors.teal.withValues(alpha: 0.1),
    },
    'Imagerie': {
      'icon': Icons.image,
      'color': Colors.indigo,
      'bgColor': Colors.indigo.withValues(alpha: 0.1),
    },
    'Cardiologie': {
      'icon': Icons.favorite,
      'color': Colors.green,
      'bgColor': Colors.green.withValues(alpha: 0.1),
    },
    'Neurologie': {
      'icon': Icons.psychology,
      'color': Colors.blue,
      'bgColor': Colors.blue.withValues(alpha: 0.1),
    },
    'Oncologie': {
      'icon': Icons.local_hospital,
      'color': Colors.red,
      'bgColor': Colors.red.withValues(alpha: 0.1),
    },
    'Gynécologie': {
      'icon': Icons.pregnant_woman,
      'color': Colors.pink,
      'bgColor': Colors.pink.withValues(alpha: 0.1),
    },
    'Pédiatrie': {
      'icon': Icons.child_care,
      'color': Colors.amber,
      'bgColor': Colors.amber.withValues(alpha: 0.1),
    },
    'Génétique': {
      'icon': Icons.biotech,
      'color': Colors.purple,
      'bgColor': Colors.purple.withValues(alpha: 0.1),
    },
    'Microbiologie': {
      'icon': Icons.bug_report,
      'color': Colors.green,
      'bgColor': Colors.green.withValues(alpha: 0.1),
    },
    'Hématologie': {
      'icon': Icons.bloodtype,
      'color': Colors.red,
      'bgColor': Colors.red.withValues(alpha: 0.1),
    },
    'Biochimie': {
      'icon': Icons.science,
      'color': Colors.orange,
      'bgColor': Colors.orange.withValues(alpha: 0.1),
    },
    'Immunologie': {
      'icon': Icons.shield,
      'color': Colors.blue,
      'bgColor': Colors.blue.withValues(alpha: 0.1),
    },
    'Virologie': {
      'icon': Icons.coronavirus,
      'color': Colors.orange,
      'bgColor': Colors.orange.withValues(alpha: 0.1),
    },
    'Néphrologie': {
      'icon': Icons.water_drop,
      'color': Colors.purple,
      'bgColor': Colors.purple.withValues(alpha: 0.1),
    },
    'Tous': {
      'icon': Icons.apps,
      'color': AppColors.primary,
      'bgColor': AppColors.primary.withValues(alpha: 0.1),
    },
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await ApiService.getLabCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categories = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addCategory(String category) async {
    try {
      await ApiService.addLabCategories([category]);
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catégorie "$category" ajoutée'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeCategory(String category) async {
    try {
      await ApiService.removeLabCategories([category]);
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catégorie "$category" supprimée'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddCategoryDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une catégorie'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nom de la catégorie',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final category = controller.text.trim();
              if (category.isNotEmpty) {
                _addCategory(category);
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  List<String> get _allAvailableCategories {
    return _categoryData.keys.toList();
  }

  // ignore: unused_element
  List<String> get _categoriesToShow {
    if (_selectedCategoryFilter == 'Tous') {
      return _allAvailableCategories;
    }
    return _allAvailableCategories.where((cat) => cat == _selectedCategoryFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Gestion des Analyses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barre de recherche
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
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
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Rechercher une analyse...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.tune,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              onPressed: () {},
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  // Section Catégories
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Catégories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategoryFilter = 'Tous';
                            });
                          },
                          child: Text(
                            'Voir tout',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Liste horizontale des catégories
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _allAvailableCategories.length,
                      itemBuilder: (context, index) {
                        final category = _allAvailableCategories[index];
                        final isSelected = _categories.contains(category);
                        final categoryInfo = _categoryData[category] ?? {
                          'icon': Icons.category,
                          'color': AppColors.primary,
                          'bgColor': AppColors.primary.withValues(alpha: 0.1),
                        };
                        
                        return GestureDetector(
                          onTap: () {
                            if (isSelected) {
                              _removeCategory(category);
                            } else {
                              _addCategory(category);
                            }
                          },
                          onLongPress: () {
                            if (isSelected) {
                              _showDeleteConfirmation(category);
                            }
                          },
                          child: Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: categoryInfo['bgColor'] as Color,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? Border.all(
                                            color: categoryInfo['color'] as Color,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Icon(
                                          categoryInfo['icon'] as IconData,
                                          color: categoryInfo['color'] as Color,
                                          size: 32,
                                        ),
                                      ),
                                      if (isSelected)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Section Analyses Disponibles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text(
                      'Analyses Disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Liste des catégories sélectionnées
                  if (_categories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Aucune catégorie sélectionnée',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Appuyez sur une catégorie pour l\'ajouter',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._categories.map((category) {
                      final categoryInfo = _categoryData[category] ?? {
                        'icon': Icons.category,
                        'color': AppColors.primary,
                        'bgColor': AppColors.primary.withValues(alpha: 0.1),
                      };
                      
                      return Dismissible(
                        key: Key(category),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (direction) {
                          _removeCategory(category);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: categoryInfo['bgColor'] as Color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  categoryInfo['icon'] as IconData,
                                  color: categoryInfo['color'] as Color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Catégorie • Active',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  // Bouton ajouter catégorie personnalisée
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF5576C).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _showAddCategoryDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Ajouter une catégorie personnalisée',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  void _showDeleteConfirmation(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$category" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _removeCategory(category);
              Navigator.pop(context);
            },
            child: Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
