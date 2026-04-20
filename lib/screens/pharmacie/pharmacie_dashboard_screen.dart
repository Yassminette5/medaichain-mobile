import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/pharmacy_service.dart';
import '../../models/pharmacy_dashboard.dart';
import 'pharmacy_statistics_screen.dart';
import 'pharmacy_stock_screen.dart';
import 'prescription_details_screen.dart';
import 'pharmacy_profile_screen.dart';
import 'web/pharmacy_web_dashboard.dart';

/// Pharmacie Dashboard Screen - Automatically uses web version on web platform
class PharmacieDashboardScreen extends StatelessWidget {
  const PharmacieDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Automatically use web version when running on web
    if (kIsWeb) {
      return const PharmacyWebDashboard();
    }
    
    // Use mobile version for mobile platforms
    return const _PharmacieDashboardMobile();
  }
}

/// Mobile version of Pharmacy Dashboard
class _PharmacieDashboardMobile extends StatefulWidget {
  const _PharmacieDashboardMobile();

  @override
  State<_PharmacieDashboardMobile> createState() => _PharmacieDashboardMobileState();
}

class _PharmacieDashboardMobileState extends State<_PharmacieDashboardMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  PharmacyDashboard? _dashboard;
  bool _isLoading = true;
  RequestStatus _selectedFilter = RequestStatus.enAttente;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    _loadDashboard();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );
  }

  Future<void> _loadDashboard() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pharmacyId = authProvider.user?.id ?? 'pharmacy-1';
      
      final dashboard = await PharmacyService.getDashboard(pharmacyId);
      
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildWelcomeCard(),
                      const SizedBox(height: 24),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Services'),
                      const SizedBox(height: 16),
                      _buildServicesGrid(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Ordonnances'),
                      const SizedBox(height: 16),
                      _buildStatusFilter(),
                      const SizedBox(height: 16),
                      _buildRecentPrescriptions(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour 👋',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pharmacie',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildIconButton(Icons.notifications_outlined, () {}),
            const SizedBox(width: 12),
            _buildIconButton(Icons.person_outline_rounded, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PharmacyProfileScreen()),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Icon(icon, color: AppColors.textSecondary, size: 22),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FACFE).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pharmacie',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez vos ordonnances et\nmédicaments en toute sécurité',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalRequests = _dashboard?.medicationRequests.length ?? 0;
    final pendingRequests = _dashboard?.medicationRequests
        .where((r) => r.status == RequestStatus.enAttente || r.status == RequestStatus.urgent)
        .length ?? 0;
    final validatedRequests = _dashboard?.medicationRequests
        .where((r) => r.status == RequestStatus.valide)
        .length ?? 0;

    return Row(
      children: [
        _buildStatCard('Ordonnances', '$totalRequests', Icons.receipt_long_rounded, const Color(0xFF4FACFE)),
        const SizedBox(width: 12),
        _buildStatCard('En attente', '$pendingRequests', Icons.hourglass_empty_rounded, const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        _buildStatCard('Validées', '$validatedRequests', Icons.check_circle_rounded, const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
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
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    final filters = [
      {'status': RequestStatus.enAttente, 'label': 'En attente', 'icon': Icons.hourglass_empty},
      {'status': RequestStatus.valide, 'label': 'Validées', 'icon': Icons.check_circle},
      {'status': RequestStatus.nonValide, 'label': 'Rejetées', 'icon': Icons.cancel},
      {'status': RequestStatus.tout, 'label': 'Toutes', 'icon': Icons.list},
    ];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final status = filter['status'] as RequestStatus;
          final isSelected = _selectedFilter == status;
          
          Color chipColor;
          switch (status) {
            case RequestStatus.enAttente:
            case RequestStatus.urgent:
              chipColor = const Color(0xFFF59E0B);
              break;
            case RequestStatus.valide:
              chipColor = const Color(0xFF10B981);
              break;
            case RequestStatus.nonValide:
              chipColor = Colors.red;
              break;
            case RequestStatus.termine:
              chipColor = const Color(0xFF4FACFE);
              break;
            default:
              chipColor = AppColors.textSecondary;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : chipColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = status;
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: chipColor,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? chipColor : AppColors.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServicesGrid() {
    final services = [
      {
        'icon': Icons.inventory_2_rounded,
        'label': 'Catalogue',
        'color': const Color(0xFF10B981),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PharmacyStockScreen()),
          );
        },
      },
      {
        'icon': Icons.analytics_rounded,
        'label': 'Statistiques',
        'color': const Color(0xFFEC4899),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PharmacyStatisticsScreen()),
          );
        },
      },
      {
        'icon': Icons.person_rounded,
        'label': 'Profil',
        'color': const Color(0xFF7C3AED),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PharmacyProfileScreen()),
          );
        },
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: services.map((service) {
        return Container(
          width: 105,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: service['onTap'] as VoidCallback,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: (service['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (service['color'] as Color).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      service['icon'] as IconData,
                      color: service['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    service['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentPrescriptions() {
    if (_dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter requests based on selected status
    List<MedicationRequest> filteredRequests;
    if (_selectedFilter == RequestStatus.tout) {
      filteredRequests = _dashboard!.medicationRequests;
    } else if (_selectedFilter == RequestStatus.enAttente) {
      // Show EN_ATTENTE and URGENT requests
      filteredRequests = _dashboard!.medicationRequests
          .where((r) => r.status == RequestStatus.enAttente || r.status == RequestStatus.urgent)
          .toList();
    } else {
      filteredRequests = _dashboard!.medicationRequests
          .where((r) => r.status == _selectedFilter)
          .toList();
    }

    if (filteredRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune ordonnance ${_selectedFilter.displayName.toLowerCase()}',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: filteredRequests.map((request) {
        Color statusColor;
        switch (request.status) {
          case RequestStatus.urgent:
          case RequestStatus.enAttente:
            statusColor = const Color(0xFFF59E0B);
            break;
          case RequestStatus.valide:
            statusColor = const Color(0xFF10B981);
            break;
          case RequestStatus.nonValide:
            statusColor = Colors.red;
            break;
          case RequestStatus.termine:
            statusColor = const Color(0xFF4FACFE);
            break;
          default:
            statusColor = AppColors.textSecondary;
        }

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PrescriptionDetailsScreen(request: request),
              ),
            );
            
            // Refresh dashboard if prescription was updated
            if (result == true) {
              _loadDashboard();
            }
          },
          child: Container(
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.medications.length == 1
                            ? request.medications.first.displayName
                            : '${request.medications.length} médicaments',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient: ${request.patient.name}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (request.medications.length > 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          request.medications.map((m) => m.name).take(2).join(', ') + 
                              (request.medications.length > 2 ? '...' : ''),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        request.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

