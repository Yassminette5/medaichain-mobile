import 'package:flutter/material.dart';
import '../models/analysis_type_model.dart';

class AddAnalysisPage extends StatefulWidget {
  const AddAnalysisPage({super.key});

  @override
  State<AddAnalysisPage> createState() => _AddAnalysisPageState();
}

class _AddAnalysisPageState extends State<AddAnalysisPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subtitleController = TextEditingController();
  String _selectedCategory = 'Biochimie';
  String _selectedIcon = 'flask';

  final List<String> _categories = [
    'Biochimie',
    'Hématologie',
    'Endocrinologie',
    'Microbiologie',
    'Virologie',
    'Génétique',
  ];
  
  final Map<String, String> _categoryMapping = {
    'Biochimie': 'Biochemistry',
    'Hématologie': 'Hematology',
    'Endocrinologie': 'Endocrinology',
    'Microbiologie': 'Microbiology',
    'Virologie': 'Virology',
    'Génétique': 'Genetics',
  };

  final List<Map<String, dynamic>> _icons = [
    {'name': 'Flask', 'icon': 'flask', 'data': Icons.science_outlined},
    {'name': 'Drop', 'icon': 'drop', 'data': Icons.water_drop},
    {'name': 'Microscope', 'icon': 'microscope', 'data': Icons.science},
    {'name': 'Heart', 'icon': 'heart', 'data': Icons.favorite},
    {'name': 'Molecule', 'icon': 'molecule', 'data': Icons.ac_unit},
    {'name': 'Shield', 'icon': 'shield', 'data': Icons.shield},
    {'name': 'Syringe', 'icon': 'syringe', 'data': Icons.medical_services},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _saveAnalysis() {
    if (_formKey.currentState!.validate()) {
      final analysis = AnalysisTypeModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        category: _categoryMapping[_selectedCategory] ?? _selectedCategory,
        subtitle: '$_selectedCategory • ${_subtitleController.text}',
        icon: _selectedIcon,
        isActive: true,
      );

      Navigator.pop(context, analysis);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Ajouter une analyse',
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
          TextButton(
            onPressed: _saveAnalysis,
            child: const Text(
              'Enregistrer',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom de l'analyse
              const Text(
                'Nom de l\'analyse',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ex: Blood Sugar (Glucose)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom de l\'analyse';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Catégorie
              const Text(
                'Catégorie',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Détails/Sous-titre
              const Text(
                'Détails',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subtitleController,
                decoration: InputDecoration(
                  hintText: 'Ex: Fasting / PP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer les détails';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Sélection d'icône
              const Text(
                'Icône',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.map((iconData) {
                  final isSelected = _selectedIcon == iconData['icon'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconData['icon'];
                      });
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            iconData['data'],
                            color: isSelected ? Colors.blue[700] : Colors.grey[600],
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            iconData['name'],
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.blue[700] : Colors.grey[600],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              // Bouton Ajouter
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAnalysis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ajouter l\'analyse',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
