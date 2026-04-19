import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/medicines_provider.dart';
import '../../../models/medicine_model.dart';

class MedicineDetailScreen extends StatelessWidget {
  final Medicine medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          medicine.name,
          style: GoogleFonts.poppins(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: AppColors.textGrey),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildVisualHeader(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    medicine.name,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                _buildRemoveButton(context),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: medicine.schedule.map((time) => _buildScheduleBadge(time)).toList(),
            ),
            const SizedBox(height: 32),
            if (medicine.description != null && medicine.description!.isNotEmpty) ...[
              Text(
                "Medical Insights",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.08), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "AI-Generated Description",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      medicine.description!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textDark.withOpacity(0.8),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            _buildDetailGrid(),
            const SizedBox(height: 48),
            _buildEditButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualHeader() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
          Image.asset(_getImageForType(medicine.type), width: 120, height: 120, fit: BoxFit.contain),
        ],
      ),
    );
  }

  String _getImageForType(String type) {
    switch (type.toLowerCase()) {
      case 'pill':
        return 'lib/assets/pill.png';
      case 'syringe':
        return 'lib/assets/syringes.png';
      case 'eye-drops':
        return 'lib/assets/eye-drops.png';
      default:
        return 'lib/assets/pill.png';
    }
  }

  Widget _buildRemoveButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final success = await context.read<MedicinesProvider>().deleteMedicine(medicine.id);
        if (success) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "Remove",
          style: GoogleFonts.poppins(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleBadge(String time) {
    final label = time.replaceAll('_', ' ');
    final isMorning = time.contains('breakfast');
    final color = isMorning ? const Color(0xFF4ECDC4) : const Color(0xFFFF9B71);

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildDetailItem("Frequency", medicine.frequency, Icons.access_time, const Color(0xFF4ECDC4)),
        _buildDetailItem("Duration", medicine.duration, Icons.calendar_today, Colors.orangeAccent),
        _buildDetailItem("Cause", medicine.cause ?? "Général", Icons.favorite, Colors.pinkAccent),
        _buildDetailItem("Status", medicine.isActive ? "Active" : "Inactive", Icons.info_outline, Colors.blueAccent),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color.withOpacity(0.6)),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textGrey),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4ECDC4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Text(
          "Edit Schedule",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
