// ignore_for_file: deprecated_member_use, unused_element
import 'package:flutter/material.dart';

/// Model for pharmacy statistics dashboard
class PharmacyStatistics {
  final SalesOverview salesOverview;
  final DeliveryTrends deliveryTrends;
  final CategoryDistribution categoryDistribution;
  final List<TopMedication> topMedications;

  PharmacyStatistics({
    required this.salesOverview,
    required this.deliveryTrends,
    required this.categoryDistribution,
    required this.topMedications,
  });

  factory PharmacyStatistics.fromJson(Map<String, dynamic> json) {
    return PharmacyStatistics(
      salesOverview: SalesOverview.fromJson(json['salesOverview'] as Map<String, dynamic>),
      deliveryTrends: DeliveryTrends.fromJson(json['deliveryTrends'] as Map<String, dynamic>),
      categoryDistribution: CategoryDistribution.fromJson(json['categoryDistribution'] as Map<String, dynamic>),
      topMedications: (json['topMedications'] as List)
          .map((item) => TopMedication.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salesOverview': salesOverview.toJson(),
      'deliveryTrends': deliveryTrends.toJson(),
      'categoryDistribution': categoryDistribution.toJson(),
      'topMedications': topMedications.map((item) => item.toJson()).toList(),
    };
  }
}

/// Model for sales overview
class SalesOverview {
  final double totalSales;
  final String currency;
  final int totalDeliveries;
  final double percentageChange;

  SalesOverview({
    required this.totalSales,
    required this.currency,
    required this.totalDeliveries,
    required this.percentageChange,
  });

  factory SalesOverview.fromJson(Map<String, dynamic> json) {
    return SalesOverview(
      totalSales: (json['totalSales'] as num).toDouble(),
      currency: json['currency'] as String,
      totalDeliveries: json['totalDeliveries'] as int,
      percentageChange: (json['percentageChange'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSales': totalSales,
      'currency': currency,
      'totalDeliveries': totalDeliveries,
      'percentageChange': percentageChange,
    };
  }

  String get formattedSales => '$totalSales$currency';
  String get formattedChange => '${percentageChange > 0 ? '+' : ''}$percentageChange%';
}

/// Model for delivery trends over time
class DeliveryTrends {
  final List<TrendDataPoint> dataPoints;
  final String period;

  DeliveryTrends({
    required this.dataPoints,
    required this.period,
  });

  factory DeliveryTrends.fromJson(Map<String, dynamic> json) {
    return DeliveryTrends(
      dataPoints: (json['dataPoints'] as List)
          .map((item) => TrendDataPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      period: json['period'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataPoints': dataPoints.map((item) => item.toJson()).toList(),
      'period': period,
    };
  }
}

/// Model for individual trend data point
class TrendDataPoint {
  final DateTime date;
  final double value;

  TrendDataPoint({
    required this.date,
    required this.value,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
    };
  }
}

/// Model for category distribution
class CategoryDistribution {
  final List<CategoryData> categories;

  CategoryDistribution({
    required this.categories,
  });

  factory CategoryDistribution.fromJson(Map<String, dynamic> json) {
    return CategoryDistribution(
      categories: (json['categories'] as List)
          .map((item) => CategoryData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((item) => item.toJson()).toList(),
    };
  }

  double get totalPercentage => categories.fold(0.0, (sum, cat) => sum + cat.percentage);
}

/// Model for individual category data
class CategoryData {
  final String name;
  final double percentage;
  final String color;

  CategoryData({
    required this.name,
    required this.percentage,
    required this.color,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      name: json['name'] as String,
      percentage: (json['percentage'] as num).toDouble(),
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'percentage': percentage,
      'color': color,
    };
  }

  String get displayPercentage => '${percentage.toInt()}%';
}

/// Model for top medication
class TopMedication {
  final String id;
  final String name;
  final String dosage;
  final int requestCount;
  final String period;
  final double changePercentage;
  final double pricePerUnit;

  TopMedication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.requestCount,
    required this.period,
    required this.changePercentage,
    required this.pricePerUnit,
  });

  factory TopMedication.fromJson(Map<String, dynamic> json) {
    return TopMedication(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      requestCount: json['requestCount'] as int,
      period: json['period'] as String,
      changePercentage: (json['changePercentage'] as num).toDouble(),
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'requestCount': requestCount,
      'period': period,
      'changePercentage': changePercentage,
      'pricePerUnit': pricePerUnit,
    };
  }

  String get displayName => '$name $dosage';
  String get displayRequests => '$requestCount DEMANDES CE MOIS';
  String get displayChange => '${changePercentage > 0 ? '+' : ''}$changePercentage%';
  String get displayPrice => '${pricePerUnit.toStringAsFixed(2)}€ de bénéf. prévu';
  bool get isIncreasing => changePercentage > 0;
}

// ============================================================================
// PREVIEW WIDGET
// ============================================================================

/// Preview screen for Pharmacy Statistics interface
class PharmacyStatisticsPreview extends StatelessWidget {
  const PharmacyStatisticsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data
    final stats = PharmacyStatistics(
      salesOverview: SalesOverview(
        totalSales: 14250,
        currency: '€',
        totalDeliveries: 128,
        percentageChange: 12.5,
      ),
      deliveryTrends: DeliveryTrends(
        dataPoints: _generateTrendData(),
        period: 'DERNIERS JOURS',
      ),
      categoryDistribution: CategoryDistribution(
        categories: [
          CategoryData(name: 'Médicaments', percentage: 60, color: '#4A9EFF'),
          CategoryData(name: 'Fournitures', percentage: 25, color: '#00D9A5'),
          CategoryData(name: 'Urgences', percentage: 15, color: '#FF6B6B'),
        ],
      ),
      topMedications: [
        TopMedication(
          id: '1',
          name: 'Amoxicilline',
          dosage: '500mg',
          requestCount: 342,
          period: 'CE MOIS',
          changePercentage: 12,
          pricePerUnit: 45.50,
        ),
        TopMedication(
          id: '2',
          name: 'Paracetamol',
          dosage: '1g',
          requestCount: 289,
          period: 'CE MOIS',
          changePercentage: 8,
          pricePerUnit: 32.00,
        ),
        TopMedication(
          id: '3',
          name: 'Kit Premiers Secours',
          dosage: '',
          requestCount: 98,
          period: 'CE MOIS',
          changePercentage: -7,
          pricePerUnit: 15.75,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C6FDC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Statistiques Pharmacie',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sales Overview Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.euro,
                    title: 'VENTES TOTALES',
                    value: stats.salesOverview.formattedSales,
                    change: stats.salesOverview.formattedChange,
                    isPositive: stats.salesOverview.percentageChange > 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_shipping,
                    title: 'LIVRAISONS',
                    value: '${stats.salesOverview.totalDeliveries}',
                    change: '+5.2%',
                    isPositive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Delivery Trends Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8F5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Statistique Livraison',
                        style: TextStyle(color: Color(0xFF2D3142), fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        stats.deliveryTrends.period,
                        style: const TextStyle(color: Color(0xFF7C6FDC), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: _buildTrendChart(stats.deliveryTrends.dataPoints),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Category Distribution
            
            const SizedBox(height: 24),
            
            // Top Medications
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Médicaments les plus demandés',
                  style: TextStyle(color: Color(0xFF2D3142), fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...stats.topMedications.map((med) => _buildMedicationItem(med)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF7C6FDC), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF2D3142), fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<TrendDataPoint> dataPoints) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF7C6FDC).withOpacity(0.3),
            const Color(0xFF7C6FDC).withOpacity(0.0),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _TrendChartPainter(dataPoints),
      ),
    );
  }

  Widget _buildPieChart(List<CategoryData> categories) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(120, 120),
          painter: _PieChartPainter(categories),
        ),
        const Text(
          '100%',
          style: TextStyle(color: Color(0xFF2D3142), fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCategoryLegend(CategoryData category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _parseColor(category.color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(color: Color(0xFF2D3142), fontSize: 14),
            ),
          ),
          Text(
            category.displayPercentage,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(TopMedication med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8F5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medication, color: Color(0xFF7C6FDC), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.displayName.isNotEmpty ? med.displayName : med.name,
                  style: const TextStyle(color: Color(0xFF2D3142), fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  med.displayRequests,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                med.displayChange,
                style: TextStyle(
                  color: med.isIncreasing ? Colors.green : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                med.displayPrice,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }

  static List<TrendDataPoint> _generateTrendData() {
    final now = DateTime.now();
    return List.generate(30, (index) {
      return TrendDataPoint(
        date: now.subtract(Duration(days: 29 - index)),
        value: 50 + (index * 2) + (index % 5) * 10,
      );
    });
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<TrendDataPoint> dataPoints;

  _TrendChartPainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7C6FDC)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxValue = dataPoints.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final y = size.height - (dataPoints[i].value / maxValue) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PieChartPainter extends CustomPainter {
  final List<CategoryData> categories;

  _PieChartPainter(this.categories);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    double startAngle = -90 * (3.14159 / 180);

    for (final category in categories) {
      final sweepAngle = (category.percentage / 100) * 2 * 3.14159;
      final paint = Paint()
        ..color = _parseColor(category.color)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle for donut effect
    final centerPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, centerPaint);
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




