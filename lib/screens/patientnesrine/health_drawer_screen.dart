import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../centre_analyse/centers_list_screen.dart';
import '../centre_analyse/center_detail_screen.dart';

enum _HealthDrawerFilter { pharmacies, analysisCenters }

class HealthDrawerScreen extends StatefulWidget {
  const HealthDrawerScreen({super.key});

  @override
  State<HealthDrawerScreen> createState() => _HealthDrawerScreenState();
}

class _HealthDrawerScreenState extends State<HealthDrawerScreen> {
  _HealthDrawerFilter _selectedFilter = _HealthDrawerFilter.pharmacies;

  bool _isLoadingCenters = false;
  String? _centersError;
  List<Map<String, dynamic>> _centers = [];

  void _openCentersList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CentersListScreen()),
    );
  }

  Future<void> _loadCentersIfNeeded() async {
    if (_isLoadingCenters) return;
    if (_centers.isNotEmpty && _centersError == null) return;

    setState(() {
      _isLoadingCenters = true;
      _centersError = null;
    });

    try {
      final raw = await ApiService.getCentersList();

      final normalized = raw.map((center) {
        return <String, dynamic>{
          'id': center['_id']?.toString() ?? center['id']?.toString() ?? '',
          'name': (center['centreName'] ?? center['name'] ?? 'Centre sans nom').toString(),
          'location': (center['localisation'] ?? center['location'] ?? '').toString(),
          'isActive': center['isActive'] == true,
        };
      }).where((c) => (c['id'] as String).isNotEmpty).toList();

      if (!mounted) return;
      setState(() {
        _centers = normalized;
        _isLoadingCenters = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _centersError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingCenters = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: AppColors.colored(AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Health Drawer",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search pharmacy, analysis center...",
                        hintStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildFilterChip(
                        context,
                        label: "Pharmacies",
                        isSelected: _selectedFilter == _HealthDrawerFilter.pharmacies,
                        onTap: () {
                          setState(() => _selectedFilter = _HealthDrawerFilter.pharmacies);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: "Analysis Centers",
                        isSelected: _selectedFilter == _HealthDrawerFilter.analysisCenters,
                        onTap: () {
                          setState(() => _selectedFilter = _HealthDrawerFilter.analysisCenters);
                          _loadCentersIfNeeded();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Map Placeholder with Gradient Overlay
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade200, Colors.grey.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.map, size: 60, color: Colors.grey.shade400),
                    Positioned(
                      top: 100,
                      left: 100,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFF8E9E)]),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B9D).withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 36),
                      ),
                    ),
                    Positioned(
                      top: 150,
                      right: 80,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: AppColors.colored(AppColors.primary),
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 36),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Nearby List with Premium Design
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Nearby",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (_selectedFilter == _HealthDrawerFilter.analysisCenters) {
                              _openCentersList(context);
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Liste des pharmacies: bientôt disponible')),
                            );
                          },
                          child: Text(
                            "See All",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedFilter == _HealthDrawerFilter.pharmacies) ...[
                      _buildPlaceCard(
                        icon: Icons.local_pharmacy,
                        name: "MediCare Pharmacy",
                        distance: "1.2 km",
                        status: "Open 24/7",
                        statusColor: Colors.green,
                        gradient: const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]),
                      ),
                      const SizedBox(height: 16),
                      _buildPlaceCard(
                        icon: Icons.local_pharmacy,
                        name: "HealthPlus Drugstore",
                        distance: "0.8 km",
                        status: "Open",
                        statusColor: Colors.green,
                        gradient: AppColors.primaryGradient,
                      ),
                    ] else ...[
                      if (_isLoadingCenters)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_centersError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Erreur: $_centersError',
                                style: GoogleFonts.poppins(color: AppColors.textGrey, fontSize: 12),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _loadCentersIfNeeded,
                                  child: const Text('Réessayer'),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_centers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            "Aucun centre d'analyse trouvé",
                            style: GoogleFonts.poppins(color: AppColors.textGrey, fontSize: 12),
                          ),
                        )
                      else ...[
                        for (final c in _centers.take(5)) ...[
                          _buildPlaceCard(
                            icon: Icons.science,
                            name: (c['name'] as String),
                            distance: (c['location'] as String).isEmpty ? 'Localisation inconnue' : (c['location'] as String),
                            status: (c['isActive'] == true) ? 'Disponible' : 'Indisponible',
                            statusColor: (c['isActive'] == true) ? Colors.green : Colors.orange,
                            gradient: const LinearGradient(colors: [Color(0xFFFF9B71), Color(0xFFFFB88C)]),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CenterDetailScreen(centerId: c['id'] as String),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: isSelected ? 0.4 : 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceCard({
    required IconData icon,
    required String name,
    required String distance,
    required String status,
    required Color statusColor,
    required LinearGradient gradient,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.small,
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        distance,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textGrey,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }
}