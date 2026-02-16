import 'package:flutter/material.dart';
import 'models/pharmacy_statistics.dart';
import 'models/pharmacy_dashboard.dart';
import 'models/medication_request.dart';

void main() {
  runApp(const PreviewApp());
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedaiChain Mobile Previews',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFF7C6FDC),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5FF),
      ),
      home: const PreviewHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PreviewHome extends StatelessWidget {
  const PreviewHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C6FDC),
        title: const Text(
          'MedaiChain Mobile - Interface Previews',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Select a screen to preview:',
            style: TextStyle(
              color: Color(0xFF2D3142),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildPreviewCard(
            context,
            icon: Icons.bar_chart,
            title: 'Pharmacy Statistics',
            description: 'View sales, trends, and top medications',
            color: const Color(0xFFFF6B9D),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PharmacyStatisticsPreview()),
              );
            },
          ),
          _buildPreviewCard(
            context,
            icon: Icons.dashboard,
            title: 'Pharmacy Dashboard',
            description: 'Manage medication requests and orders',
            color: const Color(0xFFFFB088),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PharmacyDashboardPreview()),
              );
            },
          ),
          _buildPreviewCard(
            context,
            icon: Icons.medication,
            title: 'Request Medication',
            description: 'Search and request medications from nearby pharmacies',
            color: const Color(0xFF7C6FDC),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MedicationRequestPreview()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0xFF0F1F35),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E3A5F)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
