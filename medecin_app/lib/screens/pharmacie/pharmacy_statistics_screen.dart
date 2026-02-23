import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pharmacy_statistics.dart';
import '../../services/pharmacy_service.dart';
import '../../providers/auth_provider.dart';
import 'web/pharmacy_web_statistics.dart';

/// Pharmacy Statistics Screen - Automatically uses web version on web platform
class PharmacyStatisticsScreen extends StatelessWidget {
  const PharmacyStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Automatically use web version when running on web
    if (kIsWeb) {
      return const PharmacyWebStatistics();
    }
    
    // Use mobile version for mobile platforms
    return const _PharmacyStatisticsMobile();
  }
}

/// Mobile version of Pharmacy Statistics
class _PharmacyStatisticsMobile extends StatefulWidget {
  const _PharmacyStatisticsMobile();

  @override
  State<_PharmacyStatisticsMobile> createState() => _PharmacyStatisticsMobileState();
}

class _PharmacyStatisticsMobileState extends State<_PharmacyStatisticsMobile> {
  PharmacyStatistics? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );
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
          'Statistiques',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
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
                        onPressed: _loadStatistics,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSalesOverview(),
                      const SizedBox(height: 24),
                      _buildDeliveryTrends(),
                      const SizedBox(height: 24),
                      _buildCategoryDistribution(),
                      const SizedBox(height: 24),
                      _buildTopMedications(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSalesOverview() {
    if (_statistics == null) return const SizedBox.shrink();
    final sales = _statistics!.salesOverview;
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventes totales',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sales.formattedSales,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      sales.percentageChange > 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sales.formattedChange,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${sales.totalDeliveries} livraisons',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTrends() {
    if (_statistics == null) return const SizedBox.shrink();
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tendances des livraisons',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: _buildSimpleChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart() {
    if (_statistics == null || _statistics!.deliveryTrends.dataPoints.isEmpty) {
      return Center(
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    
    final maxValue = _statistics!.deliveryTrends.dataPoints
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    
    // If all values are zero, show empty state
    if (maxValue == 0) {
      return Center(
        child: Text(
          'Aucune livraison enregistrée',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _statistics!.deliveryTrends.dataPoints.map((point) {
        final height = (point.value / maxValue) * 120;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
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
            const SizedBox(height: 8),
            Text(
              '${point.date.day}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCategoryDistribution() {
    if (_statistics == null || _statistics!.categoryDistribution.categories.isEmpty) {
      return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribution par catégorie',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Aucune catégorie disponible',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribution par catégorie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ..._statistics!.categoryDistribution.categories.map((category) {
            final categoryColor = _parseColor(category.color);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${category.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: category.percentage / 100,
                      backgroundColor: categoryColor.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(categoryColor),
                      minHeight: 8,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Médicaments les plus vendus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Aucun médicament vendu',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Médicaments les plus vendus',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._statistics!.topMedications.asMap().entries.map((entry) {
            final index = entry.key;
            final med = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4FACFE),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (med.changePercentage != 0)
                        Text(
                          med.displayChange,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: med.isIncreasing ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      if (med.pricePerUnit > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${med.pricePerUnit.toStringAsFixed(0)} DZD',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
