import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pharmacy_service.dart';
import '../../../models/pharmacy_dashboard.dart';
import '../../../widgets/pharmacie/web/pharmacy_web_notifications_bell.dart';
import '../../auth/login_web_screen.dart';
import 'pharmacy_web_profile.dart';
import 'pharmacy_web_prescription_details.dart';
import 'pharmacy_web_stock.dart';
import 'pharmacy_web_statistics.dart';

/// Web-optimized Pharmacy Dashboard
class PharmacyWebDashboard extends StatefulWidget {
  const PharmacyWebDashboard({super.key});

  @override
  State<PharmacyWebDashboard> createState() => _PharmacyWebDashboardState();
}

class _PharmacyWebDashboardState extends State<PharmacyWebDashboard> {
  PharmacyDashboard? _dashboard;
  bool _isLoading = true;
  RequestStatus _selectedFilter = RequestStatus.enAttente;
  bool _sidebarVisible = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;
    final showSidebar = _sidebarVisible && isMediumScreen;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                if (showSidebar) _buildSidebar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isLargeScreen ? 40 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(isMediumScreen),
                        const SizedBox(height: 32),
                        _buildStatsGrid(isLargeScreen),
                        const SizedBox(height: 32),
                        _buildPrescriptionsSection(isLargeScreen),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.local_pharmacy_rounded,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  _dashboard?.pharmacyInfo.name ?? 'Pharmacie',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Tableau de bord',
                  isSelected: true,
                  onTap: () {},
                ),
                _buildSidebarItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Stock',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PharmacyWebStock(),
                      ),
                    );
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.analytics_rounded,
                  label: 'Statistiques',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PharmacyWebStatistics(),
                      ),
                    );
                  },
                ),
                const Divider(height: 32),
                _buildSidebarItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PharmacyWebProfile(),
                      ),
                    );
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.logout_rounded,
                  label: 'Déconnecter',
                  onTap: _handleLogout,
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
    bool isLogout = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isSelected ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isLogout ? Colors.red : (isSelected ? AppColors.primary : AppColors.textSecondary),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isLogout ? Colors.red : (isSelected ? AppColors.primary : AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginWebScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildHeader(bool showActions) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              _buildHeaderButton(
                icon: Icons.menu_rounded,
                onTap: () {
                  setState(() {
                    _sidebarVisible = !_sidebarVisible;
                  });
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tableau de bord',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gérez vos ordonnances et médicaments',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showActions)
          _buildHeaderButton(
            icon: Icons.refresh_rounded,
            onTap: _loadDashboard,
          ),
        const PharmacyWebNotificationsBell(),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: AppColors.textSecondary, size: 24),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isLargeScreen) {
    final totalRequests = _dashboard?.medicationRequests.length ?? 0;
    final pendingRequests = _dashboard?.medicationRequests
        .where((r) => r.status == RequestStatus.enAttente)
        .length ?? 0;
    final validatedRequests = _dashboard?.medicationRequests
        .where((r) => r.status == RequestStatus.valide)
        .length ?? 0;
    final completedRequests = _dashboard?.medicationRequests
        .where((r) => r.status == RequestStatus.termine)
        .length ?? 0;

    final cards = [
      _buildStatCard(
        title: 'Total',
        value: totalRequests.toString(),
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF4FACFE),
      ),
      _buildStatCard(
        title: 'En attente',
        value: pendingRequests.toString(),
        icon: Icons.hourglass_empty_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _buildStatCard(
        title: 'Validées',
        value: validatedRequests.toString(),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF10B981),
      ),
      _buildStatCard(
        title: 'Terminées',
        value: completedRequests.toString(),
        icon: Icons.done_all_rounded,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    if (isLargeScreen) {
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: cards,
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 20),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 20),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      height: 200,
      child: Container(
        padding: const EdgeInsets.all(24),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionsSection(bool isLargeScreen) {
    final filteredRequests = _dashboard?.medicationRequests
        .where((r) => r.status == _selectedFilter)
        .toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ordonnances',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            _buildFilterChips(),
          ],
        ),
        const SizedBox(height: 20),
        if (filteredRequests.isEmpty)
          _buildEmptyState()
        else
          _buildPrescriptionsList(filteredRequests, isLargeScreen),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'En attente',
            status: RequestStatus.enAttente,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Validées',
            status: RequestStatus.valide,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Terminées',
            status: RequestStatus.termine,
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required RequestStatus status,
    required Color color,
  }) {
    final isSelected = _selectedFilter == status;
    
    return Material(
      color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = status;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune ordonnance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionsList(List<MedicationRequest> requests, bool isLargeScreen) {
    return Column(
      children: [
        for (int i = 0; i < requests.length; i++) ...[
          _buildPrescriptionCard(requests[i], isLargeScreen),
          if (i < requests.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildPrescriptionCard(MedicationRequest request, bool isLargeScreen) {
    Color statusColor;
    
    switch (request.status) {
      case RequestStatus.urgent:
        statusColor = Colors.red;
        break;
      case RequestStatus.enAttente:
        statusColor = const Color(0xFFF59E0B);
        break;
      case RequestStatus.valide:
        statusColor = const Color(0xFF10B981);
        break;
      case RequestStatus.termine:
        statusColor = const Color(0xFF8B5CF6);
        break;
      default:
        statusColor = const Color(0xFF4FACFE);
    }

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PharmacyWebPrescriptionDetails(request: request),
            ),
          );
          if (result == true) {
            _loadDashboard();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.2),
              width: 2,
            ),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: statusColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.patient.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (request.isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.priority_high, color: Colors.red, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'URGENT',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${request.medications.length} médicament(s)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.requestDate.day}/${request.requestDate.month}/${request.requestDate.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request.status.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


