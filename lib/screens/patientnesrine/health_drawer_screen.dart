import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../centre_analyse/centers_list_screen.dart';
import '../centre_analyse/center_detail_screen.dart';
import '../clinique/mobile/clinic_detail_screen.dart';

enum _HealthDrawerFilter { pharmacies, analysisCenters, clinics }

class HealthDrawerScreen extends StatefulWidget {
  const HealthDrawerScreen({super.key});

  @override
  State<HealthDrawerScreen> createState() => _HealthDrawerScreenState();
}

class _HealthDrawerScreenState extends State<HealthDrawerScreen> {
  _HealthDrawerFilter _selectedFilter = _HealthDrawerFilter.clinics;
  final MapController _mapController = MapController();
  LatLng _currentMapCenter = const LatLng(36.8065, 10.1815); // défaut: Tunis
  final Map<String, LatLng> _geocodeCache = <String, LatLng>{};

  bool _isLoadingCenters = false;
  String? _centersError;
  List<Map<String, dynamic>> _centers = [];

  bool _isLoadingClinics = false;
  String? _clinicsError;
  List<Map<String, dynamic>> _clinics = [];

  @override
  void initState() {
    super.initState();
    _loadClinicsIfNeeded(); // Load clinics by default since it's the default filter now
  }

  void _openCentersList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CentersListScreen()),
    );
  }

  Future<void> _loadClinicsIfNeeded() async {
    if (_isLoadingClinics) return;
    if (_clinics.isNotEmpty && _clinicsError == null) return;

    setState(() {
      _isLoadingClinics = true;
      _clinicsError = null;
    });

    try {
      final raw = await ApiService.getClinicsList();

      final normalized = raw.map((clinic) {
        return <String, dynamic>{
          'id': clinic['_id']?.toString() ?? clinic['id']?.toString() ?? '',
          'name': (clinic['name'] ?? 'Clinique').toString(),
          'address': (clinic['address'] ?? '').toString(),
          'isActive': clinic['isActive'] ?? true,
        };
      }).where((c) => (c['id'] as String).isNotEmpty).toList();

      if (!mounted) return;
      setState(() {
        _clinics = normalized;
        _isLoadingClinics = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _clinicsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingClinics = false;
      });
    }
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
        double? lat;
        double? lng;
        try {
          final c = Map<String, dynamic>.from(center);
          // Support de plusieurs formats possibles
          final rawLat = c['lat'] ?? c['latitude'];
          final rawLng = c['lng'] ?? c['lon'] ?? c['longitude'];
          if (rawLat is num) lat = rawLat.toDouble();
          if (rawLng is num) lng = rawLng.toDouble();
          if ((lat == null || lng == null) && c['coordinates'] is List) {
            // geojson: [lng, lat]
            final coords = List<dynamic>.from(c['coordinates'] as List);
            if (coords.length >= 2) {
              final a = coords[1];
              final o = coords[0];
              if (a is num) lat = a.toDouble();
              if (o is num) lng = o.toDouble();
            }
          }
        } catch (_) {}

        return <String, dynamic>{
          'id': center['_id']?.toString() ?? center['id']?.toString() ?? '',
          'name': (center['centreName'] ?? center['name'] ?? 'Centre sans nom').toString(),
          'location': (center['localisation'] ?? center['location'] ?? '').toString(),
          'isActive': center['isActive'] == true,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        };
      }).where((c) => (c['id'] as String).isNotEmpty).toList();

      if (!mounted) return;
      setState(() {
        _centers = normalized;
        _isLoadingCenters = false;
      });

      // Centrer la carte sur le premier centre quand on est sur le filtre analysisCenters
      if (_selectedFilter == _HealthDrawerFilter.analysisCenters) {
        await _centerMapOnFirstAnalysisCenter();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _centersError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingCenters = false;
      });
    }
  }

  Future<void> _centerMapOnFirstAnalysisCenter() async {
    if (!mounted) return;
    if (_centers.isEmpty) return;
    final center = _centers.first;
    final latLng = await _resolveCenterLatLng(center);
    if (latLng == null || !mounted) return;
    setState(() => _currentMapCenter = latLng);
    _mapController.move(latLng, 12.8);
  }

  LatLng? _quickCityFallback(String locationText) {
    final v = locationText.toLowerCase();
    if (v.contains('sfax')) return const LatLng(34.7406, 10.7603);
    if (v.contains('tunis')) return const LatLng(36.8065, 10.1815);
    if (v.contains('sousse')) return const LatLng(35.8256, 10.6411);
    if (v.contains('gab')) return const LatLng(33.8869, 10.0982); // Gabès
    return null;
  }

  Future<LatLng?> _resolveCenterLatLng(Map<String, dynamic> center) async {
    // 1) Coordonnées directes si disponibles
    final rawLat = center['lat'];
    final rawLng = center['lng'];
    if (rawLat is num && rawLng is num) {
      return LatLng(rawLat.toDouble(), rawLng.toDouble());
    }

    // 2) Fallback rapide par ville connue
    final loc = (center['location']?.toString() ?? '').trim();
    if (loc.isNotEmpty) {
      final quick = _quickCityFallback(loc);
      if (quick != null) return quick;
    }

    // 3) Géocodage Nominatim (OSM) à partir du texte
    if (loc.isEmpty) return null;
    if (_geocodeCache.containsKey(loc)) return _geocodeCache[loc];

    try {
      final q = Uri.encodeComponent('$loc, Tunisia');
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1');
      final res = await http.get(
        url,
        headers: const {
          'User-Agent': 'MEDAIChain/1.0 (flutter_app)',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map) {
          final latStr = first['lat']?.toString();
          final lonStr = (first['lon'] ?? first['lng'])?.toString();
          final lat = double.tryParse(latStr ?? '');
          final lon = double.tryParse(lonStr ?? '');
          if (lat != null && lon != null) {
            final ll = LatLng(lat, lon);
            _geocodeCache[loc] = ll;
            return ll;
          }
        }
      }
    } catch (_) {}

    return null;
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
                  // Titre centré
                  Center(
                    child: Text(
                      "Health Drawer",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Sélecteur premium (Cliniques / Pharmacies / Centres d'analyse)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton(
                            label: "Cliniques",
                            icon: Icons.local_hospital_rounded,
                            isSelected: _selectedFilter == _HealthDrawerFilter.clinics,
                            onTap: () {
                              setState(() => _selectedFilter = _HealthDrawerFilter.clinics);
                              _loadClinicsIfNeeded();
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildSegmentButton(
                            label: "Pharmacies",
                            icon: Icons.local_pharmacy_rounded,
                            isSelected: _selectedFilter == _HealthDrawerFilter.pharmacies,
                            onTap: () {
                              setState(() => _selectedFilter = _HealthDrawerFilter.pharmacies);
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildSegmentButton(
                            label: "Centres",
                            icon: Icons.science_rounded,
                            isSelected: _selectedFilter == _HealthDrawerFilter.analysisCenters,
                            onTap: () {
                              setState(() => _selectedFilter = _HealthDrawerFilter.analysisCenters);
                              _loadCentersIfNeeded();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Map (fonctionnelle)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentMapCenter,
                          initialZoom: 12.8,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            userAgentPackageName: 'com.example.madaichain',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentMapCenter,
                                width: 46,
                                height: 46,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: AppColors.colored(AppColors.primary),
                                  ),
                                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                                ),
                              ),
                            ],
                          ),
                          // Attribution OSM (recommandé)
                          RichAttributionWidget(
                            attributions: const [
                              TextSourceAttribution('OpenStreetMap contributors'),
                            ],
                          ),
                        ],
                      ),
                      // Overlay léger pour rester dans le thème
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.08),
                                  Colors.transparent,
                                  AppColors.primaryLight.withValues(alpha: 0.06),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 3,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _mapController.move(_currentMapCenter, 12.8);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(Icons.my_location_rounded, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    if (_selectedFilter == _HealthDrawerFilter.clinics) ...[
                      if (_isLoadingClinics)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_clinicsError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Erreur: $_clinicsError',
                                style: GoogleFonts.poppins(color: AppColors.textGrey, fontSize: 12),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _loadClinicsIfNeeded,
                                  child: const Text('Réessayer'),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_clinics.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            "Aucune clinique trouvée",
                            style: GoogleFonts.poppins(color: AppColors.textGrey, fontSize: 12),
                          ),
                        )
                      else ...[
                        for (final c in _clinics.take(5)) ...[
                          _buildPlaceCard(
                            icon: Icons.local_hospital,
                            name: (c['name'] as String),
                            distance: (c['address'] as String).isEmpty ? 'Localisation inconnue' : (c['address'] as String),
                            status: (c['isActive'] == true) ? 'Disponible' : 'Indisponible',
                            statusColor: (c['isActive'] == true) ? Colors.green : Colors.orange,
                            gradient: AppColors.primaryGradient,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClinicDetailScreen(
                                    clinicId: c['id'].toString(),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ] else if (_selectedFilter == _HealthDrawerFilter.pharmacies) ...[
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

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : Colors.white,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: isSelected ? AppColors.primary : Colors.white,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
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