import 'package:flutter/material.dart';

/// Model for pharmacy stock management
class PharmacyStock {
  final StockSettings settings;
  final List<MedicationStock> medications;

  PharmacyStock({
    required this.settings,
    required this.medications,
  });

  factory PharmacyStock.fromJson(Map<String, dynamic> json) {
    return PharmacyStock(
      settings: StockSettings.fromJson(json['settings'] as Map<String, dynamic>),
      medications: (json['medications'] as List)
          .map((item) => MedicationStock.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settings': settings.toJson(),
      'medications': medications.map((item) => item.toJson()).toList(),
    };
  }
}

/// Model for stock alert settings
class StockSettings {
  final bool pushNotificationsEnabled;
  final bool weeklyReportsEnabled;
  final int criticalStockThreshold;
  final int alertStockThreshold;

  StockSettings({
    required this.pushNotificationsEnabled,
    required this.weeklyReportsEnabled,
    this.criticalStockThreshold = 8,
    this.alertStockThreshold = 12,
  });

  factory StockSettings.fromJson(Map<String, dynamic> json) {
    return StockSettings(
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool,
      weeklyReportsEnabled: json['weeklyReportsEnabled'] as bool,
      criticalStockThreshold: json['criticalStockThreshold'] as int? ?? 8,
      alertStockThreshold: json['alertStockThreshold'] as int? ?? 12,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'weeklyReportsEnabled': weeklyReportsEnabled,
      'criticalStockThreshold': criticalStockThreshold,
      'alertStockThreshold': alertStockThreshold,
    };
  }
}

/// Model for individual medication stock
class MedicationStock {
  final String id;
  final String name;
  final String dosage;
  final int currentStock;
  final int maxStock;
  final String unit;
  final StockLevel stockLevel;
  final double? price;

  MedicationStock({
    required this.id,
    required this.name,
    required this.dosage,
    required this.currentStock,
    required this.maxStock,
    this.unit = 'unités',
    required this.stockLevel,
    this.price,
  });

  factory MedicationStock.fromJson(Map<String, dynamic> json) {
    return MedicationStock(
      id: (json['id'] ?? json['_id']) as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      currentStock: json['currentStock'] as int,
      maxStock: json['maxStock'] as int,
      unit: json['unit'] as String? ?? 'unités',
      stockLevel: StockLevel.values.firstWhere(
        (e) => e.name == json['stockLevel'],
        orElse: () => StockLevel.normal,
      ),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'currentStock': currentStock,
      'maxStock': maxStock,
      'unit': unit,
      'stockLevel': stockLevel.name,
      if (price != null) 'price': price,
    };
  }

  double get stockPercentage => (currentStock / maxStock) * 100;
  String get displayName => '$name $dosage';
  String get displayStock => '$currentStock $unit';
  String get displayPrice => price != null ? '${price!.toStringAsFixed(2)} DA' : 'Prix non défini';
}

/// Enum for stock levels
enum StockLevel {
  critical,
  alert,
  normal;

  String get displayName {
    switch (this) {
      case StockLevel.critical:
        return 'Critique';
      case StockLevel.alert:
        return 'Alerte';
      case StockLevel.normal:
        return 'Normal';
    }
  }

  Color get color {
    switch (this) {
      case StockLevel.critical:
        return Colors.red;
      case StockLevel.alert:
        return Colors.orange;
      case StockLevel.normal:
        return Colors.green;
    }
  }
}

// ============================================================================
// PREVIEW WIDGET
// ============================================================================

/// Preview screen for Pharmacy Stock Management
class PharmacyStockPreview extends StatefulWidget {
  const PharmacyStockPreview({super.key});

  @override
  State<PharmacyStockPreview> createState() => _PharmacyStockPreviewState();
}

class _PharmacyStockPreviewState extends State<PharmacyStockPreview> {
  bool pushNotificationsEnabled = true;
  bool weeklyReportsEnabled = false;
  int criticalThreshold = 8;
  int alertThreshold = 12;
  bool showSearchBar = false;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  
  List<MedicationStock> medications = [
    MedicationStock(
      id: '1',
      name: 'Paracetamol Teva',
      dosage: '1000mg',
      currentStock: 45,
      maxStock: 100,
      unit: 'unités',
      stockLevel: StockLevel.normal,
    ),
    MedicationStock(
      id: '2',
      name: 'Ibuprofène Mylan',
      dosage: '400mg',
      currentStock: 23,
      maxStock: 100,
      unit: 'unités',
      stockLevel: StockLevel.alert,
    ),
    MedicationStock(
      id: '3',
      name: 'Captopril Sandoz',
      dosage: '10mg',
      currentStock: 12,
      maxStock: 100,
      unit: 'unités',
      stockLevel: StockLevel.alert,
    ),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<MedicationStock> get filteredMedications {
    if (searchQuery.isEmpty) {
      return medications;
    }
    return medications.where((med) {
      final query = searchQuery.toLowerCase();
      return med.name.toLowerCase().contains(query) ||
             med.dosage.toLowerCase().contains(query) ||
             med.displayName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = medications.where((m) => m.stockLevel == StockLevel.critical).length;
    final alertCount = medications.where((m) => m.stockLevel == StockLevel.alert).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C6FDC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Paramètres d\'Alerte',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF7C6FDC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bonjour ! Le suivi de stocks 24/7 sur la blockchain MEDAIChain.',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // General Settings
                  const Text(
                    'GÉNÉRAL',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildToggleItem(
                    icon: Icons.notifications,
                    title: 'Activer les notifications push',
                    subtitle: 'Alertes en temps réel sur les stocks',
                    value: pushNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        pushNotificationsEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  _buildToggleItem(
                    icon: Icons.email,
                    title: 'Rapports hebdomadaires',
                    subtitle: 'Envoyé chaque lundi à 9h',
                    value: weeklyReportsEnabled,
                    onChanged: (value) {
                      setState(() {
                        weeklyReportsEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Stock Critique Section
                  const Text(
                    'STOCK CRITIQUE',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStockCard(
                          label: 'Amoxicilline 500mg',
                          value: '$criticalThreshold',
                          unit: 'unités',
                          subtitle: 'Seuil: 20 unités',
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStockCard(
                          label: 'Ibuprofen 1000mg',
                          value: '$alertThreshold',
                          unit: 'unités',
                          subtitle: 'Seuil: 15 unités',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Medication Stock Levels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SEUILS PAR MÉDICAMENT',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            showSearchBar = !showSearchBar;
                            if (!showSearchBar) {
                              searchController.clear();
                              searchQuery = '';
                            }
                          });
                        },
                        icon: Icon(
                          showSearchBar ? Icons.close : Icons.search,
                          color: const Color(0xFF7C6FDC),
                          size: 16,
                        ),
                        label: Text(
                          showSearchBar ? 'Fermer' : 'Rechercher',
                          style: const TextStyle(color: Color(0xFF7C6FDC), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Search Bar
                  if (showSearchBar)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un médicament...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF7C6FDC)),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      searchController.clear();
                                      searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFFFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE8E8F5)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE8E8F5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7C6FDC), width: 2),
                          ),
                        ),
                      ),
                    ),
                  
                  ...filteredMedications.map((med) => _buildMedicationStockItem(med)),
                  
                  // No results message
                  if (filteredMedications.isEmpty && searchQuery.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off, color: Colors.grey, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Aucun médicament trouvé',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Add Medication Button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMedicationPreview(
                            onMedicationAdded: (newMed) {
                              setState(() {
                                medications.add(newMed);
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8E8F5)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, color: Color(0xFF7C6FDC)),
                          SizedBox(width: 8),
                          Text(
                            'AJOUTER UN NOUVEAU MÉDICAMENT',
                            style: TextStyle(
                              color: Color(0xFF7C6FDC),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C6FDC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'SAUVEGARDER LES MODIFICATIONS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8F5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF7C6FDC), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF7C6FDC),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard({
    required String label,
    required String value,
    required String unit,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationStockItem(MedicationStock med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: ${med.displayStock}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: med.stockLevel.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Stock: ${med.stockPercentage.toInt()}',
                  style: TextStyle(
                    color: med.stockLevel.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8F5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: med.stockPercentage / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: med.stockLevel.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stock adjustment controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minus button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: () {
                    final controller = TextEditingController();
                    _showQuantityDialog(context, med, controller, isAdding: false);
                  },
                  icon: const Icon(Icons.remove, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
              const SizedBox(width: 12),


              // Plus button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: () {
                    final controller = TextEditingController();
                    _showQuantityDialog(context, med, controller, isAdding: true);
                  },
                  icon: const Icon(Icons.add, color: Colors.green, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  StockLevel _calculateStockLevel(int current, int max) {
    final percentage = (current / max) * 100;
    if (percentage <= 20) return StockLevel.critical;
    if (percentage <= 40) return StockLevel.alert;
    return StockLevel.normal;
  }

  void _showQuantityDialog(BuildContext context, MedicationStock med, TextEditingController controller, {required bool isAdding}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE8E8F5)),
          ),
          title: Text(
            isAdding ? 'Ajouter au stock' : 'Retirer du stock',
            style: const TextStyle(color: Color(0xFF2D3142), fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                med.displayName,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Entrez la quantité',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFE8E8F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF7C6FDC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF7C6FDC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF7C6FDC), width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ANNULER',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity = int.tryParse(controller.text);
                if (quantity != null && quantity > 0) {
                  setState(() {
                    final index = medications.indexOf(med);
                    if (index != -1) {
                      int newStock;
                      if (isAdding) {
                        newStock = (med.currentStock + quantity).clamp(0, med.maxStock);
                      } else {
                        newStock = (med.currentStock - quantity).clamp(0, med.maxStock);
                      }
                      
                      medications[index] = MedicationStock(
                        id: med.id,
                        name: med.name,
                        dosage: med.dosage,
                        currentStock: newStock,
                        maxStock: med.maxStock,
                        unit: med.unit,
                        stockLevel: _calculateStockLevel(newStock, med.maxStock),
                      );
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6FDC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isAdding ? 'AJOUTER' : 'RETIRER',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// ADD MEDICATION PREVIEW
// ============================================================================

/// Page for adding a new medication to stock
class AddMedicationPreview extends StatefulWidget {
  final Function(MedicationStock) onMedicationAdded;

  const AddMedicationPreview({
    super.key,
    required this.onMedicationAdded,
  });

  @override
  State<AddMedicationPreview> createState() => _AddMedicationPreviewState();
}

class _AddMedicationPreviewState extends State<AddMedicationPreview> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final currentStockController = TextEditingController();
  final maxStockController = TextEditingController();
  final unitController = TextEditingController(text: 'unités');

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    currentStockController.dispose();
    maxStockController.dispose();
    unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C6FDC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajouter un médicament',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF7C6FDC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_box, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ajoutez un nouveau médicament à votre inventaire',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INFORMATIONS DU MÉDICAMENT',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Medication Name
                    _buildTextField(
                      controller: nameController,
                      label: 'Nom du médicament',
                      hint: 'Ex: Paracetamol Teva',
                      icon: Icons.medication,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le nom du médicament';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Dosage
                    _buildTextField(
                      controller: dosageController,
                      label: 'Dosage',
                      hint: 'Ex: 1000mg',
                      icon: Icons.science,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le dosage';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'QUANTITÉS',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Current Stock
                    _buildTextField(
                      controller: currentStockController,
                      label: 'Stock actuel',
                      hint: 'Ex: 50',
                      icon: Icons.inventory,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le stock actuel';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Max Stock
                    _buildTextField(
                      controller: maxStockController,
                      label: 'Stock maximum',
                      hint: 'Ex: 100',
                      icon: Icons.storage,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le stock maximum';
                        }
                        final maxStock = int.tryParse(value);
                        if (maxStock == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        final currentStock = int.tryParse(currentStockController.text);
                        if (currentStock != null && maxStock < currentStock) {
                          return 'Le stock max doit être ≥ au stock actuel';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Unit
                    _buildTextField(
                      controller: unitController,
                      label: 'Unité',
                      hint: 'Ex: unités, boîtes, flacons',
                      icon: Icons.label,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer l\'unité';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _addMedication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C6FDC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'AJOUTER LE MÉDICAMENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8F5)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: const Color(0xFF7C6FDC)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C6FDC), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  void _addMedication() {
    if (_formKey.currentState!.validate()) {
      final currentStock = int.parse(currentStockController.text);
      final maxStock = int.parse(maxStockController.text);
      final percentage = (currentStock / maxStock) * 100;
      
      StockLevel stockLevel;
      if (percentage <= 20) {
        stockLevel = StockLevel.critical;
      } else if (percentage <= 40) {
        stockLevel = StockLevel.alert;
      } else {
        stockLevel = StockLevel.normal;
      }
      
      final newMedication = MedicationStock(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text,
        dosage: dosageController.text,
        currentStock: currentStock,
        maxStock: maxStock,
        unit: unitController.text,
        stockLevel: stockLevel,
      );
      
      widget.onMedicationAdded(newMedication);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Médicament ajouté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    }
  }
}


