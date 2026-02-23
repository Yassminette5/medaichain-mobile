import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/medicines_provider.dart';
import '../../../models/medicine_model.dart';
import 'add_medicine_screen.dart';
import 'medicine_detail_screen.dart';

class MedicinesListView extends StatefulWidget {
  const MedicinesListView({super.key});

  @override
  State<MedicinesListView> createState() => _MedicinesListViewState();
}

class _MedicinesListViewState extends State<MedicinesListView> {
  int _selectedDayIndex = 0;
  String _selectedTab = "Today";
  late List<Map<String, dynamic>> _days;

  @override
  void initState() {
    super.initState();
    _generateDays();
    _selectedDayIndex = 0; // Today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicinesProvider>().fetchMedicines();
    });
  }

  void _generateDays() {
    final now = DateTime.now();
    _days = List.generate(7, (index) {
      final date = now.add(Duration(days: index));
      return {
        "day": date.day.toString(),
        "weekday": _getWeekdayName(date.weekday),
        "date": date,
      };
    });
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return "Mon";
      case 2: return "Tue";
      case 3: return "Wed";
      case 4: return "Thu";
      case 5: return "Fri";
      case 6: return "Sat";
      case 7: return "Sun";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildDateSelector(),
        const SizedBox(height: 32),
        Center(child: _buildTabs()),
        const SizedBox(height: 16),
        Expanded(
          child: _buildMedicinesList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(); // Placeholder or keep as is if empty
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDayIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 75,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary : Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: isSelected 
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                border: isSelected ? null : Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _days[index]["day"]!,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textDark.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _days[index]["weekday"]!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: ["Today", "Week", "Month"].map((tab) {
        final isSelected = tab == _selectedTab;
        return GestureDetector(
          onTap: () => setState(() => _selectedTab = tab),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  tab,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textGrey.withOpacity(0.6),
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 25,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ]
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMedicinesList() {
    return Consumer<MedicinesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.medicines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  "Encore aucun médicament",
                  style: GoogleFonts.poppins(color: AppColors.textGrey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: provider.medicines.length,
          itemBuilder: (context, index) {
            final med = provider.medicines[index];
            return _buildMedicineCard(med);
          },
        );
      },
    );
  }

  Widget _buildMedicineCard(Medicine med) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MedicineDetailScreen(medicine: med)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _getMedicineIcon(med.type),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (med.dosage.isNotEmpty)
                    Text(
                      med.dosage,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: med.schedule.map((time) => _buildBadge(time)).toList(),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String time) {
    final label = time.replaceAll('_', ' ');
    final color = time.contains('breakfast') ? const Color(0xFF4ECDC4) : const Color(0xFFFF9B71);
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _getMedicineIcon(String type) {
    String assetPath;
    switch (type.toLowerCase()) {
      case 'pill':
        assetPath = 'lib/assets/pill.png';
        break;
      case 'syringe':
        assetPath = 'lib/assets/syringes.png';
        break;
      case 'eye-drops':
        assetPath = 'lib/assets/eye-drops.png';
        break;
      default:
        assetPath = 'lib/assets/pill.png';
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }
}
