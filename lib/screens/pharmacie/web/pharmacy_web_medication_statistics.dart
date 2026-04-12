// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/pharmacy_dashboard.dart';
import '../../../models/pharmacy_statistics.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/pharmacy_service.dart';
import '../../auth/login_screen.dart';
import '../../../widgets/pharmacie/web/pharmacy_web_notifications_bell.dart';
import 'pharmacy_web_dashboard.dart';
import 'pharmacy_web_profile.dart';
import 'pharmacy_web_statistics.dart';
import 'pharmacy_web_stock.dart';

class PharmacyWebMedicationStatistics extends StatefulWidget {
  const PharmacyWebMedicationStatistics({super.key});

  @override
  State<PharmacyWebMedicationStatistics> createState() =>
      _PharmacyWebMedicationStatisticsState();
}

class _PharmacyWebMedicationStatisticsState
    extends State<PharmacyWebMedicationStatistics> {
  PharmacyDashboard? _dashboard;
  List<TopMedication> _topMedications = const [];
  bool _isLoading = true;
  String? _error;
  bool _sidebarVisible = true;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _showingIncomingAlert = false;
  final Set<String> _handledIncomingNotificationIds = <String>{};
  static const Duration _pollInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _loadPharmacyInfo();
    _loadMedicationStats();
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

  Future<void> _loadPharmacyInfo() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pharmacyId = authProvider.user?.id ?? 'pharmacy-1';
      final dashboard = await PharmacyService.getDashboard(pharmacyId);
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
      });
    } catch (e) {
      // Silently fail, sidebar will show default name
    }
  }

  Future<void> _loadMedicationStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final month = _formatMonthParam(_selectedMonth);
      final meds = await PharmacyService.getMyMedicationStatistics(
        month: month,
      );
      if (!mounted) return;

      setState(() {
        _topMedications = meds;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatMonthParam(DateTime month) {
    final m = month.month.toString().padLeft(2, '0');
    return '${month.year}-$m';
  }

  String _formatMonthLabel(DateTime month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: 'Choisir un mois',
    );

    if (picked == null) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });

    await _loadMedicationStats();
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
                    onPressed: _loadMedicationStats,
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
                            const SizedBox(height: 24),
                            _buildTopMedicationsCard(),
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

  Widget _buildHeader() {
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
                      'Statistiques Médicaments',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Médicaments les plus demandés',
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
        Row(
          children: [
            _buildMonthButton(),
            const SizedBox(width: 12),
            const PharmacyWebNotificationsBell(),
            const SizedBox(width: 12),
            _buildHeaderButton(
              icon: Icons.refresh_rounded,
              onTap: _loadMedicationStats,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthButton() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _pickMonth,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _formatMonthLabel(_selectedMonth),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.expand_more_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildTopMedicationsCard() {
    return Container(
      width: double.infinity,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Icons.medication_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Top médicaments demandés',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                _formatMonthParam(_selectedMonth),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_topMedications.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Aucune demande sur ce mois',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topMedications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final med = _topMedications[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                    ],
                  ),
                );
              },
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
                  label: 'Catalogue de médicament',
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
                _buildSidebarItem(
                  icon: Icons.medication_rounded,
                  label: 'Statistiques Médicaments',
                  isSelected: true,
                  onTap: () {},
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
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isLogout
                          ? Colors.red
                          : (isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary),
                    ),
                    overflow: TextOverflow.ellipsis,
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
}
