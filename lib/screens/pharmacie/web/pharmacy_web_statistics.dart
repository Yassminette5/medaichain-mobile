import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/pharmacy_statistics.dart';
import '../../../models/pharmacy_dashboard.dart';
import '../../../services/api_service.dart';
import '../../../services/pharmacy_service.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/login_screen.dart';
import '../../../widgets/pharmacie/web/pharmacy_web_notifications_bell.dart';
import 'pharmacy_web_dashboard.dart';
import 'pharmacy_web_stock.dart';
import 'pharmacy_web_profile.dart';
import 'pharmacy_web_medication_statistics.dart';

class PharmacyWebStatistics extends StatefulWidget {
  const PharmacyWebStatistics({super.key});

  @override
  State<PharmacyWebStatistics> createState() => _PharmacyWebStatisticsState();
}

class _PharmacyWebStatisticsState extends State<PharmacyWebStatistics> {
  PharmacyStatistics? _statistics;
  PharmacyDashboard? _dashboard;
  bool _isLoading = true;
  String? _error;
  bool _sidebarVisible = true;

  bool _showingIncomingAlert = false;
  final Set<String> _handledIncomingNotificationIds = <String>{};
  static const Duration _pollInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadPharmacyInfo();
    _startIncomingRequestsPolling();
  }

  void _startIncomingRequestsPolling() {
    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      while (mounted) {
        await _pollUnreadNotificationsOnce();
        await Future<void>.delayed(_pollInterval);
      }
    });
  }

  Future<void> _pollUnreadNotificationsOnce() async {
    if (_showingIncomingAlert) return;
    try {
      final unread = await ApiService.getUnreadNotifications();
      if (!mounted) return;

      Map<String, dynamic>? candidate;
      for (final n in unread) {
        final data = (n['data'] is Map)
            ? (n['data'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        if (data['type']?.toString() != 'pharmacy_request_created') continue;
        final id = (n['id'] ?? n['_id'] ?? '').toString();
        if (id.isEmpty) continue;
        if (_handledIncomingNotificationIds.contains(id)) continue;
        candidate = n;
        break;
      }

      if (candidate == null) return;

      final notificationId = (candidate['id'] ?? candidate['_id'] ?? '')
          .toString();
      final data = (candidate['data'] is Map)
          ? (candidate['data'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final requestId = (data['requestId'] ?? candidate['relatedId'] ?? '')
          .toString();
      if (requestId.isEmpty) return;

      _handledIncomingNotificationIds.add(notificationId);
      _showingIncomingAlert = true;

      MedicationRequest? request;
      try {
        request = await PharmacyService.getMyRequestById(requestId);
      } catch (_) {
        request = null;
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          final title = (candidate?['title'] ?? 'Nouvelle demande').toString();
          final message = (candidate?['message'] ?? '').toString();

          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.isNotEmpty) Text(message),
                    const SizedBox(height: 12),
                    if (request != null) ...[
                      Text('Patient: ${request.patient.name}'),
                      if (request.patient.phoneNumber != null &&
                          request.patient.phoneNumber!.isNotEmpty)
                        Text('Téléphone: ${request.patient.phoneNumber}'),
                      const SizedBox(height: 12),
                      const Text(
                        'Médicaments:',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      ...request.medications.map((m) {
                        final dosage = m.dosage.isNotEmpty
                            ? ' — ${m.dosage}'
                            : '';
                        final qty = '${m.quantity} ${m.unit}'.trim();
                        return Text('- ${m.name}$dosage ($qty)');
                      }),
                      const SizedBox(height: 12),
                      if (request.requestsDelivery)
                        const Text('Livraison: demandée'),
                      if (request.isUrgent) const Text('Urgence: oui'),
                    ] else ...[
                      const Text(
                        'Détails indisponibles (échec du chargement).',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (notificationId.isNotEmpty) {
        try {
          await ApiService.markNotificationAsRead(notificationId);
        } catch (_) {}
      }
    } catch (_) {
      // Ignore polling errors
    } finally {
      _showingIncomingAlert = false;
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pharmacyId = authProvider.user?.id ?? 'pharmacy-1';

      final statistics = await PharmacyService.getStatistics(pharmacyId);

      setState(() {
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPharmacyInfo() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pharmacyId = authProvider.user?.id ?? 'pharmacy-1';

      final dashboard = await PharmacyService.getDashboard(pharmacyId);

      setState(() {
        _dashboard = dashboard;
      });
    } catch (e) {
      // Silently fail, sidebar will show default name
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMediumScreen = screenWidth > 800;
    final showSidebar = _sidebarVisible && isMediumScreen;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    onPressed: _loadStatistics,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                if (showSidebar) _buildSidebar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMediumScreen ? 40 : 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 32),
                            _buildSalesOverview(),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildDeliveryTrends(),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 1,
                                  child: _buildCategoryDistribution(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildTopMedications(),
                          ],
                        ),
                      ),
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
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PharmacyWebDashboard(),
                      ),
                    );
                  },
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
                  isSelected: true,
                  onTap: () {},
                ),
                _buildSidebarItem(
                  icon: Icons.medication_rounded,
                  label: 'Statistiques Médicaments',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PharmacyWebMedicationStatistics(),
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
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
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
                  color: isLogout
                      ? Colors.red
                      : (isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isLogout
                        ? Colors.red
                        : (isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary),
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
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMediumScreen = screenWidth > 800;

    return Row(
      children: [
        if (isMediumScreen) ...[
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              setState(() {
                _sidebarVisible = !_sidebarVisible;
              });
            },
            tooltip: 'Menu',
          ),
          const SizedBox(width: 8),
        ],
        const Text(
          'Statistiques',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        const PharmacyWebNotificationsBell(),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.primary),
          onPressed: _loadStatistics,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  Widget _buildSalesOverview() {
    if (_statistics == null) return const SizedBox.shrink();
    final sales = _statistics!.salesOverview;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
                  'Ventes totales',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  sales.formattedSales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sales.percentageChange > 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sales.formattedChange,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      '${sales.totalDeliveries} livraisons',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              size: 80,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTrends() {
    if (_statistics == null) return const SizedBox.shrink();

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.show_chart,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tendances des livraisons',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(height: 250, child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_statistics == null || _statistics!.deliveryTrends.dataPoints.isEmpty) {
      return Center(
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      );
    }

    final maxValue = _statistics!.deliveryTrends.dataPoints
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    if (maxValue == 0) {
      return Center(
        child: Text(
          'Aucune livraison enregistrée',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _statistics!.deliveryTrends.dataPoints.map((point) {
        final height = (point.value / maxValue) * 200;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${point.value}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: height > 0 ? height : 2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${point.date.day}/${point.date.month}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCategoryDistribution() {
    if (_statistics == null ||
        _statistics!.categoryDistribution.categories.isEmpty) {
      return Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.pie_chart,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Distribution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Aucune catégorie',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Distribution',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._statistics!.categoryDistribution.categories.map((category) {
            final categoryColor = _parseColor(category.color);
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${category.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: category.percentage / 100,
                      backgroundColor: categoryColor.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(categoryColor),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }

  Widget _buildTopMedications() {
    if (_statistics == null || _statistics!.topMedications.isEmpty) {
      return Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Médicaments les plus vendus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Aucun médicament vendu',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.medication,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Médicaments les plus vendus',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: _statistics!.topMedications.length,
            itemBuilder: (context, index) {
              final med = _statistics!.topMedications[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4FACFE),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            med.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${med.requestCount} demandes',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (med.pricePerUnit > 0)
                      Text(
                        '${med.pricePerUnit.toStringAsFixed(0)} DZD',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
