import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import 'center_detail_screen.dart';

/// Écran de liste des centres d'analyses pour les patients
class CentersListScreen extends StatefulWidget {
  const CentersListScreen({super.key});

  @override
  State<CentersListScreen> createState() => _CentersListScreenState();
}

class _CentersListScreenState extends State<CentersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _centers = [];
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> get _filteredCenters {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      return _centers;
    }
    return _centers.where((center) {
      // Recherche uniquement par NOM ou VILLE (localisation)
      final name = (center['name'] ?? '').toString().toLowerCase();
      final location = (center['location'] ?? '').toString().toLowerCase();
      return name.contains(query) || location.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCenters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final centers = await ApiService.getCentersList();
      debugPrint('🔍 Centers loaded: ${centers.length}');
      
      if (mounted) {
        setState(() {
          // Normaliser les données pour correspondre au format attendu par l'interface
          // Le backend retourne : _id, centreName, categorie, phone, email, localisation, profilePhoto, isVerified, etc.
          _centers = centers.map((center) {
            debugPrint('🔍 Processing center: ${center['centreName'] ?? 'Unknown'}');
            return {
              'id': center['_id']?.toString() ?? center['id']?.toString() ?? '',
              'name': center['centreName'] ?? center['name'] ?? 'Centre sans nom',
              'category': _formatCategory(center['categorie'] ?? center['category'] ?? ''),
              'phone': center['phone'] ?? '',
              'email': center['email'] ?? '',
              'location': center['localisation'] ?? center['location'] ?? '',
              'onlineAppointmentEnabled': center['onlineBooking'] ?? center['reservation_en_ligne'] ?? center['onlineAppointmentEnabled'] ?? false,
              'profilePhoto': center['profilePhoto'] ?? center['logo'] ?? center['logoUrl'],
              'isVerified': center['isVerified'] ?? false,
            };
          }).toList();
          debugPrint('🔍 Normalized centers: ${_centers.length}');
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading centers: $e');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatCategory(dynamic category) {
    if (category == null) return '';
    if (category is List) {
      return category.isNotEmpty ? category.join(', ') : '';
    }
    return category.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header style "centre d'analyse"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Centres d'Analyses",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Trouvez un centre proche et consultez ses infos",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom ou ville...',
                        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
                        prefixIcon: Icon(Icons.search, color: Colors.black.withValues(alpha: 0.55), size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildState(
                            icon: Icons.error_outline,
                            title: 'Erreur de chargement',
                            subtitle: _error!,
                            actionLabel: 'Réessayer',
                            onAction: _loadCenters,
                          )
                        : _centers.isEmpty
                            ? _buildState(
                                icon: Icons.business_outlined,
                                title: 'Aucun laboratoire disponible',
                                subtitle: 'Les laboratoires enregistrés apparaîtront ici',
                              )
                            : _filteredCenters.isEmpty
                                ? _buildState(
                                    icon: Icons.search_off,
                                    title: 'Aucun centre trouvé',
                                    subtitle: 'Essayez avec d\'autres mots-clés',
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(top: 6, bottom: 20),
                                    itemCount: _filteredCenters.length,
                                    itemBuilder: (context, index) => _buildCenterCard(_filteredCenters[index]),
                                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  elevation: 0,
                ),
                child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCenterCard(Map<String, dynamic> center) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CenterDetailScreen(
                centerId: center['id'] as String,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image du centre
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/labo_icone.jpg',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.science_rounded,
                                color: AppColors.primary,
                                size: 35,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Informations du centre
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          center['name'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                center['location'] as String? ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bouton d'action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CenterDetailScreen(
                          centerId: center['id'] as String,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Voir les informations',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
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
