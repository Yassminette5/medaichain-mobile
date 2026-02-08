import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../widgets/medical_card.dart';

/// Écran Modèles d'Opérations - Design Ultra Moderne
class OperationPresetsScreen extends StatefulWidget {
  const OperationPresetsScreen({super.key});

  @override
  State<OperationPresetsScreen> createState() => _OperationPresetsScreenState();
}

class _OperationPresetsScreenState extends State<OperationPresetsScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Tous';
  late AnimationController _animController;

  final List<Map<String, dynamic>> _presets = [
    {'name': 'Suivi Diabète', 'category': 'Endocrinologie', 'description': 'Modèle standard pour les consultations de gestion du diabète', 'items': ['Vérifier HbA1c', 'Revoir glycémie', 'Évaluer compliance', 'Examen des pieds'], 'usageCount': 45, 'color': const Color(0xFF00BFA6)},
    {'name': 'Bilan Cardiaque', 'category': 'Cardiologie', 'description': 'Évaluation cardiovasculaire complète', 'items': ['Mesure tension', 'ECG', 'Évaluation risque', 'Revoir médication'], 'usageCount': 32, 'color': const Color(0xFFEF4444)},
    {'name': 'Consultation Générale', 'category': 'Médecine Générale', 'description': 'Modèle de consultation de routine', 'items': ['Signes vitaux', 'Plainte principale', 'Antécédents', 'Examen physique'], 'usageCount': 78, 'color': const Color(0xFF536DFE)},
    {'name': 'Santé Mentale', 'category': 'Psychiatrie', 'description': 'Évaluation de la condition psychologique', 'items': ['Évaluation humeur', 'Qualité sommeil', 'Niveau anxiété', 'Efficacité médication'], 'usageCount': 23, 'color': const Color(0xFFA855F7)},
    {'name': 'Suivi Pédiatrique', 'category': 'Pédiatrie', 'description': 'Visite de contrôle développement enfant', 'items': ['Croissance', 'Étapes développement', 'Vaccinations', 'Nutrition'], 'usageCount': 56, 'color': const Color(0xFFF59E0B)},
  ];

  List<String> get _categories => ['Tous', ..._presets.map((p) => p['category'] as String).toSet()];

  List<Map<String, dynamic>> get _filteredPresets {
    var filtered = _presets;
    if (_selectedCategory != 'Tous') filtered = filtered.where((p) => p['category'] == _selectedCategory).toList();
    if (_searchController.text.isNotEmpty) filtered = filtered.where((p) => (p['name'] as String).toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient orbs
          Positioned(top: -100, right: -50, child: _buildOrb(250, AppColors.primary.withValues(alpha: 0.15))),
          Positioned(bottom: 200, left: -80, child: _buildOrb(200, AppColors.secondary.withValues(alpha: 0.1))),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildCategoryChips(),
                const SizedBox(height: 20),
                Expanded(child: _buildPresetsList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Modèles', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                Text('${_filteredPresets.length} modèles disponibles', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12)],
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 15)],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Rechercher un modèle...',
            hintStyle: TextStyle(color: AppColors.textLight),
            prefixIcon: ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
              child: const Icon(Icons.search, color: Colors.white),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _searchController.clear()))
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.neonGradient : null,
                  color: isSelected ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: isSelected ? null : Border.all(color: AppColors.border),
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12)] : null,
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPresetsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredPresets.length,
      itemBuilder: (context, index) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _animController,
              curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutCubic),
            ),
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _animController, curve: Interval(index * 0.1, 1.0)),
            child: _buildPresetCard(_filteredPresets[index]),
          ),
        );
      },
    );
  }

  Widget _buildPresetCard(Map<String, dynamic> preset) {
    final color = preset['color'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(color: AppColors.cardShadow, blurRadius: 20),
                BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: -10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon with gradient glow
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color, color.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12)],
                      ),
                      child: const Icon(Icons.description_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(preset['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(preset['category'], style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    // Usage count with ring
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
                        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${preset['usageCount']}', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('fois', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(preset['description'], style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
                const SizedBox(height: 16),
                // Items preview
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...(preset['items'] as List).take(3).map<Widget>((item) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(item, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )),
                    if ((preset['items'] as List).length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)]),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Text('+${(preset['items'] as List).length - 3}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.edit_outlined, size: 18, color: color),
                          label: Text('Modifier', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: TextButton.icon(
                          onPressed: () => _showPresetDetails(preset),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                          label: const Text('Utiliser', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.neonGradient,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _showPresetDetails(Map<String, dynamic> preset) {
    final color = preset['color'] as Color;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3))),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16)],
                        ),
                        child: const Icon(Icons.description_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(preset['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text(preset['category'], style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(preset['description'], style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5)),
                  const SizedBox(height: 32),
                  const Text('Éléments inclus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  ...(preset['items'] as List).map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.check_circle, color: color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Text(item, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: const Text('Démarrer consultation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white),
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
