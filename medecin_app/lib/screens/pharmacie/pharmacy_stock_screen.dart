import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pharmacy_stock.dart';
import '../../services/pharmacy_service.dart';
import '../../providers/auth_provider.dart';

class PharmacyStockScreen extends StatefulWidget {
  const PharmacyStockScreen({super.key});

  @override
  State<PharmacyStockScreen> createState() => _PharmacyStockScreenState();
}

class _PharmacyStockScreenState extends State<PharmacyStockScreen> {
  PharmacyStock? _stock;
  String _selectedFilter = 'Tout';
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStock();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStock() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pharmacyId = authProvider.user?.id ?? 'pharmacy-1';
      
      final stock = await PharmacyService.getStock(pharmacyId);
      
      setState(() {
        _stock = stock;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MedicationStock> get _filteredMedications {
    if (_stock == null) return [];
    
    var medications = _stock!.medications;
    
    // Apply filter
    if (_selectedFilter == 'Critique') {
      medications = medications.where((m) => m.stockLevel == StockLevel.critical).toList();
    } else if (_selectedFilter == 'Alerte') {
      medications = medications.where((m) => m.stockLevel == StockLevel.alert).toList();
    } else if (_selectedFilter == 'Normal') {
      medications = medications.where((m) => m.stockLevel == StockLevel.normal).toList();
    }
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      medications = medications.where((m) {
        return m.name.toLowerCase().contains(query) ||
               m.dosage.toLowerCase().contains(query) ||
               m.displayName.toLowerCase().contains(query);
      }).toList();
    }
    
    return medications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gestion du Stock',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStock,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildStockSummary(),
                    _buildFilterChips(),
                    _buildSearchBar(),
                    Expanded(
                      child: _buildMedicationList(),
                    ),
                  ],
                ),
      floatingActionButton: SizedBox(
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: _showAddMedicationDialog,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, size: 24),
          label: const Text(
            'Ajouter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockSummary() {
    if (_stock == null) return const SizedBox.shrink();
    
    final criticalCount = _stock!.medications.where((m) => m.stockLevel == StockLevel.critical).length;
    final alertCount = _stock!.medications.where((m) => m.stockLevel == StockLevel.alert).length;
    final normalCount = _stock!.medications.where((m) => m.stockLevel == StockLevel.normal).length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          _buildSummaryItem('Critique', criticalCount, Colors.red),
          _buildSummaryItem('Alerte', alertCount, Colors.orange),
          _buildSummaryItem('Normal', normalCount, Colors.green),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Tout', 'Critique', 'Alerte', 'Normal'];
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher un médicament...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
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
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationList() {
    final medications = _filteredMedications;
    
    if (medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun médicament',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final med = medications[index];
        return _buildMedicationCard(med);
      },
    );
  }

  Widget _buildMedicationCard(MedicationStock medication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: medication.stockLevel.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: medication.stockLevel.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medication.displayStock,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: medication.stockLevel.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  medication.stockLevel.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: medication.stockLevel.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: medication.stockPercentage / 100,
              backgroundColor: medication.stockLevel.color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(medication.stockLevel.color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${medication.stockPercentage.toStringAsFixed(0)}% du stock maximum',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Remove stock button
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _showAdjustStockDialog(medication, isAdding: false),
                  icon: const Icon(Icons.remove, color: Colors.red, size: 20),
                  tooltip: 'Retirer du stock',
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${medication.currentStock}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              // Add stock button
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _showAdjustStockDialog(medication, isAdding: true),
                  icon: const Icon(Icons.add, color: Colors.green, size: 20),
                  tooltip: 'Ajouter au stock',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    if (_stock == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paramètres du stock',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Notifications push'),
              value: _stock!.settings.pushNotificationsEnabled,
              onChanged: (value) async {
                await _updateSettings({'pushNotificationsEnabled': value});
              },
            ),
            SwitchListTile(
              title: const Text('Rapports hebdomadaires'),
              value: _stock!.settings.weeklyReportsEnabled,
              onChanged: (value) async {
                await _updateSettings({'weeklyReportsEnabled': value});
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Seuil critique: ${_stock!.settings.criticalStockThreshold} unités',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              'Seuil d\'alerte: ${_stock!.settings.alertStockThreshold} unités',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSettings(Map<String, dynamic> updates) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pharmacyId = authProvider.user?.id ?? 'pharmacy-1';
      
      await PharmacyService.updateStockSettings(pharmacyId, updates);
      await _loadStock();
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final currentStockController = TextEditingController();
    final maxStockController = TextEditingController();
    final unitController = TextEditingController(text: 'boîtes');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un médicament'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: dosageController,
                  decoration: const InputDecoration(labelText: 'Dosage *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le dosage est requis';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: currentStockController,
                  decoration: const InputDecoration(labelText: 'Stock actuel *'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le stock actuel est requis';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number < 0) {
                      return 'Entrez un nombre valide >= 0';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: maxStockController,
                  decoration: const InputDecoration(labelText: 'Stock maximum *'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le stock maximum est requis';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number < 1) {
                      return 'Entrez un nombre valide >= 1';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Unité'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _addMedication({
                  'name': nameController.text.trim(),
                  'dosage': dosageController.text.trim(),
                  'currentStock': int.parse(currentStockController.text),
                  'maxStock': int.parse(maxStockController.text),
                  'unit': unitController.text.trim(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMedication(Map<String, dynamic> data) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pharmacyId = authProvider.user?.id ?? 'pharmacy-1';
      
      await PharmacyService.createStock(pharmacyId, data);
      await _loadStock();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Médicament ajouté avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _showAdjustStockDialog(MedicationStock medication, {required bool isAdding}) {
    final quantityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdding ? 'Ajouter au stock' : 'Retirer du stock'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medication.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stock actuel: ${medication.currentStock} ${medication.unit}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  hintText: 'Entrez la quantité',
                  suffixText: medication.unit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La quantité est requise';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Entrez un nombre valide > 0';
                  }
                  if (!isAdding && number > medication.currentStock) {
                    return 'Quantité supérieure au stock actuel';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final quantity = int.parse(quantityController.text);
                final newStock = isAdding
                    ? medication.currentStock + quantity
                    : medication.currentStock - quantity;
                
                await _updateMedicationStock(medication.id, newStock);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdding ? Colors.green : Colors.red,
            ),
            child: Text(isAdding ? 'Ajouter' : 'Retirer'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMedicationStock(String stockId, int newStock) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pharmacyId = authProvider.user?.id ?? 'pharmacy-1';
      
      await PharmacyService.updateStock(pharmacyId, stockId, {
        'currentStock': newStock,
      });
      await _loadStock();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock mis à jour avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }
}
